import 'dart:io';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/models.dart';

import 'package:geolocator/geolocator.dart';

/// Scan Provider managing AR camera HUD, image capture, GS1 barcode lookup, and AI OCR extraction
class ScanProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _isFlashOn = false;
  bool _isAutoFocusOn = true;
  bool _isProcessing = false;
  String _selectedBarcode = '';
  File? _capturedImage;
  OpenFoodFactsProduct? _product;
  OCRExtractedData? _extractedData;
  final List<BoundingBox> _liveBoundingBoxes = [];
  final double _ocrConfidence = 0.0;
  String? _statusMessage;
  Position? _currentLocation;
  String _locationAddress = 'Acquiring GPS location...';

  ScanProvider(this._apiClient) {
    fetchCurrentLocation();
  }

  Position? get currentLocation => _currentLocation;
  String get locationAddress => _locationAddress;

  bool get isFlashOn => _isFlashOn;
  bool get isAutoFocusOn => _isAutoFocusOn;
  bool get isProcessing => _isProcessing;
  String get selectedBarcode => _selectedBarcode;
  File? get capturedImage => _capturedImage;
  OpenFoodFactsProduct? get product => _product;
  OpenFoodFactsProduct? get gs1Product => _product;
  OCRExtractedData? get extractedData => _extractedData;
  List<BoundingBox> get liveBoundingBoxes => _liveBoundingBoxes;
  double get ocrConfidence => _ocrConfidence;
  String? get statusMessage => _statusMessage;

  void toggleFlash() {
    _isFlashOn = !_isFlashOn;
    notifyListeners();
  }

  void toggleAutoFocus() {
    _isAutoFocusOn = !_isAutoFocusOn;
    notifyListeners();
  }

  void setBarcode(String barcode) {
    _selectedBarcode = barcode;
    lookupBarcode(barcode);
    notifyListeners();
  }

  /// Fetch Real-Time GPS Location
  Future<Position?> fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      _currentLocation = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _locationAddress = 'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}, Long: ${_currentLocation!.longitude.toStringAsFixed(4)} (GPS Lock)';
      notifyListeners();
      return _currentLocation;
    } catch (_) {
      return null;
    }
  }

  /// Open Food Facts Barcode Lookup
  Future<OpenFoodFactsProduct> lookupBarcode(String barcode) async {
    _selectedBarcode = barcode;
    _isProcessing = true;
    _statusMessage = 'Cross-referencing Open Food Facts database...';
    notifyListeners();

    try {
      final response = await _apiClient.get('/scan/barcode/$barcode');
      if (response.success && response.data != null) {
        _product = OpenFoodFactsProduct.fromJson(response.data!);
        _statusMessage = null;
      } else {
        _product = null;
        _statusMessage = response.message ?? 'Barcode $barcode not found in Open Food Facts registry.';
        throw Exception(response.message ?? 'Barcode not found');
      }
    } catch (e) {
      _product = null;
      _statusMessage = 'Open Food Facts lookup failed: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }

    _isProcessing = false;
    _statusMessage = null;
    notifyListeners();
    return _product!;
  }

  Future<OpenFoodFactsProduct> lookupGS1Barcode(String barcode) => lookupBarcode(barcode);

  /// Trigger AI Vision & OCR Extraction
  Future<OCRExtractedData> processImageExtraction({File? imageFile}) async {
    _isProcessing = true;
    _statusMessage = 'Uploading scan to backend for AI Compliance Processing (OCR + ViT + NER)...';
    notifyListeners();

    if (imageFile != null) {
      _capturedImage = imageFile;
    }

    if (_capturedImage == null) {
      _isProcessing = false;
      _statusMessage = 'No image provided for processing';
      notifyListeners();
      throw Exception('No packaging image captured or selected.');
    }

    try {
      // 1. Upload inspection image to backend /scan/upload
      final uploadResponse = await _apiClient.uploadFile(
        AppConstants.scanUpload,
        file: _capturedImage!,
        fieldName: 'file',
        extraFields: {
          if (_selectedBarcode.isNotEmpty) 'product_barcode': _selectedBarcode,
          if (_currentLocation != null) 'latitude': _currentLocation!.latitude.toString(),
          if (_currentLocation != null) 'longitude': _currentLocation!.longitude.toString(),
          'location_name': _locationAddress,
        },
      );

      if (!uploadResponse.success || uploadResponse.data == null) {
        final errorMsg = uploadResponse.message ?? 'Failed to upload packaging image';
        _isProcessing = false;
        _statusMessage = errorMsg;
        notifyListeners();
        throw Exception(errorMsg);
      }

      final inspectionId = uploadResponse.data!['inspection_id'];
      if (inspectionId == null) {
        throw Exception('Backend did not return inspection ID.');
      }

      // 2. Trigger Full AI Pipeline (OpenCV Unwarp -> Cloud Vision OCR -> HuggingFace NER -> Rule Engine -> ViT Anomaly)
      _statusMessage = 'Running HuggingFace NER & ViT Anomaly Analysis...';
      notifyListeners();

      final analysisResponse = await _apiClient.post(
        AppConstants.verifyCompliance,
        body: {
          'inspection_id': inspectionId,
          if (_selectedBarcode.isNotEmpty) 'product_barcode': _selectedBarcode,
        },
      );

      if (!analysisResponse.success || analysisResponse.data == null) {
        final errorMsg = analysisResponse.message ?? 'AI Compliance Analysis failed on backend';
        _isProcessing = false;
        _statusMessage = errorMsg;
        notifyListeners();
        throw Exception(errorMsg);
      }

      _extractedData = OCRExtractedData.fromJson(analysisResponse.data!);
      _isProcessing = false;
      _statusMessage = null;
      notifyListeners();
      return _extractedData!;
    } catch (e) {
      _isProcessing = false;
      _statusMessage = 'AI Processing Error: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}
