import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/scan_provider.dart';
import '../widgets/ar_overlay_box.dart';

/// AR Live Camera Screen with dynamic Bounding Box Projection and HUD controls
class ArCameraScreen extends StatefulWidget {
  const ArCameraScreen({super.key});

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  Future<void> _handleCapture() async {
    final scan = Provider.of<ScanProvider>(context, listen: false);
    await scan.processImageExtraction();
    if (mounted) {
      Navigator.pushNamed(context, '/ai-review');
    }
  }

  Future<void> _handleGalleryPicker() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final scan = Provider.of<ScanProvider>(context, listen: false);
      await scan.processImageExtraction(imageFile: file);
      if (mounted) {
        Navigator.pushNamed(context, '/ai-review');
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
            // Camera Viewfinder Background Simulation
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: Container(
                    width: 320,
                    height: 440,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Stack(
                      children: [
                        // Guide Reticle
                        Center(
                          child: Container(
                            width: 260,
                            height: 360,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                            ),
                          ),
                        ),
                        // Packaging Simulation Art
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 54, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 8),
                              Text(
                                'ALIGN PACKAGED COMMODITY LABEL',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Project live AR bounding boxes
                        ...scan.liveBoundingBoxes.map((box) => ArOverlayBoxWidget(box: box)),
                      ],
                    ),
                  ),
                ),
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        backgroundColor: scan.isFlashOn ? Colors.amber : Colors.black54,
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
                        backgroundColor: scan.isAutoFocusOn ? AppTheme.primaryContainer : Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.center_focus_strong, color: Colors.white, size: 18),
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
                  color: Colors.black.withOpacity(0.75),
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
                            child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'AI PIPELINE EXECUTING',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scan.statusMessage ?? '3D Surface Unwarping & Named Entity Recognition...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GS1 Barcode: 8901030382910',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, '/barcode-scanner'),
                          child: const Text(
                            'Change GTIN',
                            style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
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
                              child: Icon(Icons.camera_alt, color: AppTheme.primary, size: 28),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                        tooltip: 'Barcode Scanner',
                        onPressed: () => Navigator.pushNamed(context, '/barcode-scanner'),
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
