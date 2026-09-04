import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/compliance_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/ar_overlay_box.dart';

/// AR Live Camera Screen with dynamic Bounding Box Projection and HUD controls
class ArCameraScreen extends StatefulWidget {
  const ArCameraScreen({super.key});

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initLiveCamera();
  }

  Future<void> _initLiveCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _handleCapture() async {
    final scan = Provider.of<ScanProvider>(context, listen: false);
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final sync = Provider.of<SyncProvider>(context, listen: false);

    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      try {
        final xFile = await _cameraController!.takePicture();
        await scan.processImageExtraction(imageFile: File(xFile.path));
      } catch (_) {
        await scan.processImageExtraction();
      }
    } else {
      await scan.processImageExtraction();
    }

    final extracted = scan.extractedData ?? OCRExtractedData.empty();
    final gs1 = scan.gs1Product ??
        GS1Product(
          gtin: scan.selectedBarcode,
          productName: 'Nutri-Crisp Multi-Grain Flakes',
          registeredCompany: 'Hindustan Consumer Foods Pvt Ltd',
          companyAddress: 'Okhla Phase III, New Delhi',
          brand: 'Nutri-Crisp',
          isVerified: true,
        );

    final record = await compliance.evaluateCompliance(
      extracted: extracted,
      gs1: gs1,
      storeName: 'Reliance Retail Superstore, Sector 18',
      locationAddress: scan.locationAddress.isNotEmpty ? scan.locationAddress : 'Sector 18, Noida, NCR Division',
      isOffline: !sync.isOnline,
    );

    if (!sync.isOnline) {
      await sync.queueInspection(record, scan.capturedImage?.path ?? '');
    }

    if (mounted) {
      Navigator.pushNamed(context, '/evidence-report');
    }
  }

  Future<void> _handleGalleryPicker() async {
    final scan = Provider.of<ScanProvider>(context, listen: false);
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final sync = Provider.of<SyncProvider>(context, listen: false);

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      await scan.processImageExtraction(imageFile: file);

      final extracted = scan.extractedData ?? OCRExtractedData.empty();
      final gs1 = scan.gs1Product ??
          GS1Product(
            gtin: scan.selectedBarcode,
            productName: 'Nutri-Crisp Multi-Grain Flakes',
            registeredCompany: 'Hindustan Consumer Foods Pvt Ltd',
            companyAddress: 'Okhla Phase III, New Delhi',
            brand: 'Nutri-Crisp',
            isVerified: true,
          );

      final record = await compliance.evaluateCompliance(
        extracted: extracted,
        gs1: gs1,
        storeName: 'Reliance Retail Superstore, Sector 18',
        locationAddress: scan.locationAddress.isNotEmpty ? scan.locationAddress : 'Sector 18, Noida, NCR Division',
        isOffline: !sync.isOnline,
      );

      if (!sync.isOnline) {
        await sync.queueInspection(record, scan.capturedImage?.path ?? '');
      }

      if (mounted) {
        Navigator.pushNamed(context, '/evidence-report');
      }
    } else {
      _handleCapture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Viewfinder Background with Live Feed
            Positioned.fill(
              child: _isCameraInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Container(
                      color: const Color(0xFF0F172A),
                      child: Center(
                        child: Container(
                          width: 320,
                          height: 440,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: 260,
                                  height: 360,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        width: 1),
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 54,
                                        color: Colors.white
                                            .withValues(alpha: 0.2)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ALIGN PACKAGED COMMODITY LABEL',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...scan.liveBoundingBoxes
                                  .map((box) => ArOverlayBoxWidget(box: box)),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            if (_isCameraInitialized)
              Positioned.fill(
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 280,
                        height: 420,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.primaryLight, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    ...scan.liveBoundingBoxes
                        .map((box) => ArOverlayBoxWidget(box: box)),
                  ],
                ),
              ),

            // Top HUD Overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: AppTheme.success, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AR HUD ACTIVE • ${(scan.ocrConfidence * 100).toInt()}% CONFIDENCE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            scan.isFlashOn ? Colors.amber : Colors.black54,
                        child: IconButton(
                          icon: Icon(
                            scan.isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: scan.isFlashOn ? Colors.black : Colors.white,
                            size: 18,
                          ),
                          onPressed: () => scan.toggleFlash(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: scan.isAutoFocusOn
                            ? AppTheme.primaryContainer
                            : Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.center_focus_strong,
                              color: Colors.white, size: 18),
                          onPressed: () => scan.toggleAutoFocus(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Processing Indicator
            if (scan.isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'AI PIPELINE EXECUTING',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scan.statusMessage ??
                                '3D Surface Unwarping & Named Entity Recognition...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom Viewfinder Controls
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GS1 Barcode: ${scan.selectedBarcode}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            InkWell(
                              onTap: () => Navigator.pushNamed(
                                  context, '/barcode-scanner'),
                              child: const Text(
                                'Change GTIN',
                                style: TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppTheme.secondary, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                scan.locationAddress,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined,
                            color: Colors.white, size: 28),
                        tooltip: 'Upload from Gallery',
                        onPressed: _handleGalleryPicker,
                      ),
                      // Shutter Button
                      GestureDetector(
                        onTap: scan.isProcessing ? null : _handleCapture,
                        child: Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.camera_alt,
                                  color: AppTheme.primary, size: 28),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner,
                            color: Colors.white, size: 28),
                        tooltip: 'Barcode Scanner',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/barcode-scanner'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
