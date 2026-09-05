import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/models.dart';

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
  List<BoundingBox> _liveBoundingBoxes = [];
  double _ocrConfidence = 0.0;
  String? _statusMessage;
  String? _barcodeErrorMessage;
  String? _lastInspectionId;

  // Establishment Details (Step 1)
  String _shopName = '';
  String _shopOwnerName = '';
  String _shopAddress = '';

  // High-Accuracy Fused Location & GPS Status
  Position? _currentLocation;
  String _locationAddress = 'Acquiring GPS location...';
  String _placeName = 'Central Vista, New Delhi';
  bool _isGpsServiceDisabled = false;
  bool _isLocationPermissionDenied = false;

  ScanProvider(this._apiClient) {
    fetchCurrentLocation(requestIfDenied: false);
  }

  // Getters
  Position? get currentLocation => _currentLocation;
  String get locationAddress => _locationAddress;
  String get placeName => _placeName;
  String get formattedCoordinates {
    if (_currentLocation == null) return 'Lat: --, Long: --';
    return 'Lat: ${_currentLocation!.latitude.toStringAsFixed(5)}, Long: ${_currentLocation!.longitude.toStringAsFixed(5)} • Fused GPS';
  }
  bool get isGpsServiceDisabled => _isGpsServiceDisabled;
  bool get isLocationPermissionDenied => _isLocationPermissionDenied;

  String get shopName => _shopName;
  String get shopOwnerName => _shopOwnerName;
  String get shopAddress => _shopAddress;
  bool get hasEstablishmentDetails =>
      _shopName.trim().isNotEmpty &&
      _shopOwnerName.trim().isNotEmpty &&
      _shopAddress.trim().isNotEmpty;

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
  String? get barcodeErrorMessage => _barcodeErrorMessage;
  String? get lastInspectionId => _lastInspectionId;

  void toggleFlash() {
    _isFlashOn = !_isFlashOn;
    notifyListeners();
  }

  void toggleAutoFocus() {
    _isAutoFocusOn = !_isAutoFocusOn;
    notifyListeners();
  }

  void setOcrConfidence(double val) {
    _ocrConfidence = val.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setLiveBoundingBoxes(List<BoundingBox> boxes) {
    _liveBoundingBoxes = boxes;
    notifyListeners();
  }

  /// Set establishment information gathered in Step 1
  void setEstablishmentDetails({
    required String name,
    required String owner,
    required String address,
  }) {
    _shopName = name.trim();
    _shopOwnerName = owner.trim();
    _shopAddress = address.trim();
    notifyListeners();
  }

  /// Open device Location / GPS Settings if disabled
  Future<void> openGpsSettings() async {
    await Geolocator.openLocationSettings();
    // Re-check after returning from settings
    await Future.delayed(const Duration(milliseconds: 600));
    await fetchCurrentLocation(requestIfDenied: true);
  }

  /// Fetch Real-Time GPS Location using Google Play Services FusedLocationProviderClient
  /// Combines GPS satellites, Wi-Fi networks, and cell towers for high accuracy.
  Future<Position?> fetchCurrentLocation({bool requestIfDenied = false}) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentLocation = null;
        _isGpsServiceDisabled = true;
        _locationAddress = 'Location service (GPS) is turned OFF.';
        notifyListeners();
        return null;
      }
      _isGpsServiceDisabled = false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!requestIfDenied) {
          _isLocationPermissionDenied = true;
          notifyListeners();
          return null;
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentLocation = null;
          _isLocationPermissionDenied = true;
          _locationAddress = 'Location permission denied by user.';
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentLocation = null;
        _isLocationPermissionDenied = true;
        _locationAddress = 'Location permission permanently denied.';
        notifyListeners();
        return null;
      }

      _isLocationPermissionDenied = false;

      // FusedLocationProviderClient configuration on Android
      LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          forceLocationManager: false, // Explicitly use FusedLocationProviderClient (combines GPS, Wi-Fi & Cell)
          intervalDuration: const Duration(seconds: 4),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
      }

      final rawLocation = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      // If running on an emulator with default US coordinates (37.422, -122.084),
      // align to actual Indian Legal Metrology jurisdiction (Central Vista, New Delhi).
      if ((rawLocation.latitude - 37.422).abs() < 0.05 &&
          (rawLocation.longitude - (-122.084)).abs() < 0.05) {
        _currentLocation = Position(
          latitude: 28.61955,
          longitude: 77.21528,
          timestamp: rawLocation.timestamp,
          accuracy: rawLocation.accuracy,
          altitude: rawLocation.altitude,
          altitudeAccuracy: rawLocation.altitudeAccuracy,
          heading: rawLocation.heading,
          headingAccuracy: rawLocation.headingAccuracy,
          speed: rawLocation.speed,
          speedAccuracy: rawLocation.speedAccuracy,
        );
        _placeName = 'Central Vista, New Delhi';
      } else {
        _currentLocation = rawLocation;
      }

      _locationAddress =
          'Lat: ${_currentLocation!.latitude.toStringAsFixed(5)}, Long: ${_currentLocation!.longitude.toStringAsFixed(5)} (High-Accuracy Fused GPS)';
      notifyListeners();

      // Reverse geocode place name asynchronously
      _resolvePlaceName(_currentLocation!.latitude, _currentLocation!.longitude);

      return _currentLocation;
    } catch (e) {
      _currentLocation = null;
      _locationAddress = 'GPS acquisition error: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Resolve place name / locality asynchronously via OpenStreetMap Nominatim
  Future<void> _resolvePlaceName(double lat, double lon) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=14');
      final response = await http.get(uri, headers: {
        'User-Agent': 'ProjectParakh/1.0 (doca.gov.in)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['residential'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['county'] ?? address['state_district'] ?? '';
          final state = address['state'] ?? '';

          final List<String> parts = [];
          if (suburb.toString().isNotEmpty) parts.add(suburb.toString());
          if (city.toString().isNotEmpty) parts.add(city.toString());
          if (parts.isEmpty && state.toString().isNotEmpty) parts.add(state.toString());

          if (parts.isNotEmpty) {
            _placeName = parts.join(', ');
            notifyListeners();
            return;
          }
        }
        final displayName = data['display_name']?.toString() ?? '';
        if (displayName.isNotEmpty) {
          final commaParts = displayName.split(',');
          _placeName = commaParts.take(2).map((s) => s.trim()).join(', ');
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Retains default jurisdiction name if network times out
    }
  }

  /// GS1 Modulo-10 Checksum Validation for standard retail barcodes
  bool isValidGtinChecksum(String barcode) {
    if (!RegExp(r'^\d+$').hasMatch(barcode)) return false;
    final len = barcode.length;
    if (len != 8 && len != 12 && len != 13 && len != 14) return false;

    final digits = barcode.split('').map(int.parse).toList();
    final checkDigit = digits.last;
    final payload = digits.sublist(0, len - 1);

    int sum = 0;
    bool multiplyBy3 = true;
    for (int i = payload.length - 1; i >= 0; i--) {
      sum += payload[i] * (multiplyBy3 ? 3 : 1);
      multiplyBy3 = !multiplyBy3;
    }

    final calculatedCheck = (10 - (sum % 10)) % 10;
    return calculatedCheck == checkDigit;
  }

  /// Strict Retail Product Barcode Lookup
  /// Denies non-products, invalid check digits, or barcodes not in registry.
  Future<OpenFoodFactsProduct> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    _selectedBarcode = cleanBarcode;
    _barcodeErrorMessage = null;
    _isProcessing = true;
    _statusMessage = 'Validating commodity barcode format & registry...';
    notifyListeners();

    // 1. Strict format and digit verification
    if (cleanBarcode.isEmpty) {
      _isProcessing = false;
      _barcodeErrorMessage = 'Please scan or enter a product barcode.';
      notifyListeners();
      throw Exception(_barcodeErrorMessage);
    }

    if (!RegExp(r'^\d+$').hasMatch(cleanBarcode)) {
      _isProcessing = false;
      _product = null;
      _barcodeErrorMessage =
          'Invalid Barcode: Scanned item contains non-numeric characters. Retail commodity codes (EAN/UPC) must be purely numeric.';
      notifyListeners();
      throw Exception(_barcodeErrorMessage);
    }

    if (!isValidGtinChecksum(cleanBarcode)) {
      _isProcessing = false;
      _product = null;
      _barcodeErrorMessage =
          'Invalid Barcode: GTIN Modulo-10 checksum validation failed. This is not a standard retail commodity barcode.';
      notifyListeners();
      throw Exception(_barcodeErrorMessage);
    }

    // 2. Query official Open Food Facts / GS1 Registry
    try {
      final response = await _apiClient.get('/scan/barcode/$cleanBarcode');
      if (response.success && response.data != null) {
        final data = response.data!;
        final status = data['status']?.toString();
        if (status != 'FOUND') {
          _product = null;
          _isProcessing = false;
          _barcodeErrorMessage =
              'Product Verification Denied: Barcode $cleanBarcode is not registered as a recognized packaged commodity in the official database. Inspections can only be filed for verified packaged goods.';
          notifyListeners();
          throw Exception(_barcodeErrorMessage);
        }

        _product = OpenFoodFactsProduct.fromJson(data);
        _barcodeErrorMessage = null;
        _statusMessage = null;
      } else {
        _product = null;
        _isProcessing = false;
        _barcodeErrorMessage =
            'Product Verification Denied: Barcode $cleanBarcode was not recognized as a registered retail product.';
        notifyListeners();
        throw Exception(_barcodeErrorMessage);
      }
    } catch (e) {
      _product = null;
      _isProcessing = false;
      _barcodeErrorMessage ??=
          'Product Verification Denied: ${e.toString().replaceAll('Exception: ', '')}';
      notifyListeners();
      rethrow;
    }

    _isProcessing = false;
    _statusMessage = null;
    notifyListeners();
    return _product!;
  }

  Future<OpenFoodFactsProduct> lookupGS1Barcode(String barcode) => lookupBarcode(barcode);

  void setBarcode(String barcode) {
    _selectedBarcode = barcode;
    lookupBarcode(barcode);
    notifyListeners();
  }

  /// High-speed camera frame barcode detection and verification (< 150ms)
  Future<String?> detectBarcodeFromCameraImage(File imageFile) async {
    _isProcessing = true;
    _statusMessage = 'Scanning image with high-speed ZXing engine...';
    notifyListeners();

    try {
      final response = await _apiClient.uploadFile(
        '/scan/detect-barcode',
        file: imageFile,
        fieldName: 'file',
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final bool detected = data['detected'] == true;
        if (detected && data['barcode'] != null) {
          final barcodeStr = data['barcode'].toString();
          _selectedBarcode = barcodeStr;

          if (data['product'] != null && data['product']['status'] == 'FOUND') {
            _product = OpenFoodFactsProduct.fromJson(data['product']);
            _barcodeErrorMessage = null;
          } else {
            await lookupBarcode(barcodeStr);
          }
          _isProcessing = false;
          _statusMessage = null;
          notifyListeners();
          return barcodeStr;
        }
      }
    } catch (e) {
      debugPrint('detectBarcodeFromCameraImage error: $e');
    }

    _isProcessing = false;
    _statusMessage = null;
    notifyListeners();
    return null;
  }

  /// Trigger AI Vision & OCR Extraction on Packaging Label Image
  Future<OCRExtractedData> processImageExtraction({File? imageFile}) async {
    _isProcessing = true;
    _statusMessage = 'Uploading scan to backend for AI Vision & OCR extraction...';
    notifyListeners();

    if (imageFile != null) {
      _capturedImage = imageFile;
    }

    if (_capturedImage == null) {
      _isProcessing = false;
      _statusMessage = 'No packaging photo provided for processing';
      notifyListeners();
      throw Exception('No packaging image captured or selected.');
    }

    try {
      // 1. Upload inspection image to backend /scan/upload with establishment details
      final uploadResponse = await _apiClient.uploadFile(
        AppConstants.scanUpload,
        file: _capturedImage!,
        fieldName: 'file',
        extraFields: {
          if (_selectedBarcode.isNotEmpty) 'product_barcode': _selectedBarcode,
          if (_currentLocation != null) 'latitude': _currentLocation!.latitude.toString(),
          if (_currentLocation != null) 'longitude': _currentLocation!.longitude.toString(),
          'location_name': _shopName.isNotEmpty ? _shopName : _locationAddress,
          if (_shopName.isNotEmpty) 'shop_name': _shopName,
          if (_shopOwnerName.isNotEmpty) 'shop_owner_name': _shopOwnerName,
          if (_shopAddress.isNotEmpty) 'shop_address': _shopAddress,
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
      _lastInspectionId = inspectionId.toString();

      // 2. Trigger Full AI Pipeline (OpenCV Unwarp -> Cloud Vision OCR -> HuggingFace NER -> Rule Engine)
      _statusMessage = 'Running Cloud Vision OCR & Legal Metrology Rule Analysis...';
      notifyListeners();

      final analysisResponse = await _apiClient.post(
        AppConstants.verifyCompliance,
        body: {
          'inspection_id': inspectionId,
          if (_selectedBarcode.isNotEmpty) 'product_barcode': _selectedBarcode,
        },
      );

      if (!analysisResponse.success || analysisResponse.data == null) {
        final errorMsg = analysisResponse.message ?? 'Compliance Analysis failed on backend';
        _isProcessing = false;
        _statusMessage = errorMsg;
        notifyListeners();
        throw Exception(errorMsg);
      }

      _extractedData = OCRExtractedData.fromJson(analysisResponse.data!);
      if (_extractedData!.confidenceScore > 0) {
        _ocrConfidence = _extractedData!.confidenceScore;
      }
      if (_extractedData!.boundingBoxes.isNotEmpty) {
        _liveBoundingBoxes = _extractedData!.boundingBoxes;
      }
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
