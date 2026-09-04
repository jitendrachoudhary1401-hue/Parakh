import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/scan_provider.dart';

/// Step 2: Strict Barcode & Packaged Product Verification Screen
/// Displays live hardware camera viewfinder to align commodity barcodes.
/// Scans every detail carefully only for products; denies any unusual barcodes or non-products.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final _barcodeController = TextEditingController();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isTorchOn = false;
  late AnimationController _laserAnimController;

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initCamera();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = Provider.of<ScanProvider>(context, listen: false);
      if (!scan.hasEstablishmentDetails) {
        // Must complete Step 1 first
        Navigator.pushReplacementNamed(context, '/establishment-intake');
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final controller = CameraController(
          _cameras[_selectedCameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        _cameraController = controller;
        await controller.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Barcode scanner camera error: $e');
    }
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      _isTorchOn = !_isTorchOn;
      await _cameraController!
          .setFlashMode(_isTorchOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _cameraController?.dispose();
    _cameraController = null;
    setState(() {
      _isCameraInitialized = false;
    });
    _initCamera();
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _cameraController?.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _onVerifyBarcode() async {
    final barcode = _barcodeController.text.trim();
    final scan = Provider.of<ScanProvider>(context, listen: false);

    FocusScope.of(context).unfocus();

    try {
      await scan.lookupBarcode(barcode);
    } catch (e) {
      if (!mounted) return;
      _showRejectionDialog(scan.barcodeErrorMessage ??
          e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showRejectionDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: AppTheme.error, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Product Scan Denied',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.error,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                reason,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Under statutory Legal Metrology (Packaged Commodities) Rules, 2011, inspections can ONLY be conducted on verified retail packaged goods with valid GTIN/EAN barcodes.\n\n'
              'Please scan a valid, intact product barcode from the commodity packaging.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.3,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss & Scan Again'),
          ),
        ],
      ),
    );
  }

  void _proceedToPackagingScan() {
    final scan = Provider.of<ScanProvider>(context, listen: false);
    if (scan.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please verify a valid product barcode before proceeding.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    Navigator.pushNamed(context, '/ar-camera');
  }

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Product Barcode Verification'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Establishment Header Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scan.shopName.isNotEmpty
                                ? scan.shopName
                                : 'Establishment Details',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Proprietor: ${scan.shopOwnerName.isNotEmpty ? scan.shopOwnerName : "Not specified"}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, '/establishment-intake'),
                      child:
                          const Text('Change', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Viewfinder HUD Card with Live Hardware Camera
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Live Camera Preview
                      if (_isCameraInitialized &&
                          _cameraController != null &&
                          _cameraController!.value.isInitialized)
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize?.height ??
                                  1,
                              height: _cameraController!.value.previewSize?.width ??
                                  1,
                              child: CameraPreview(_cameraController!),
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: Colors.white38, size: 40),
                              SizedBox(height: 10),
                              Text(
                                'INITIALIZING HARDWARE CAMERA...',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 2. Viewfinder Gradient Mask
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),

                      // 3. Barcode Target Frame with Animated Laser
                      Container(
                        width: 250,
                        height: 130,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: scan.product != null
                                ? AppTheme.success
                                : const Color(0xFF38BDF8),
                            width: 2,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (scan.product == null)
                              AnimatedBuilder(
                                animation: _laserAnimController,
                                builder: (context, child) {
                                  return Positioned(
                                    top: 8 + (_laserAnimController.value * 110),
                                    left: 8,
                                    right: 8,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Color(0xFF38BDF8),
                                            Colors.white,
                                            Color(0xFF38BDF8),
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.8),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  scan.product != null
                                      ? Icons.verified
                                      : Icons.qr_code_scanner,
                                  color: scan.product != null
                                      ? AppTheme.success
                                      : const Color(0xFF38BDF8),
                                  size: 32,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  scan.product != null
                                      ? 'PRODUCT VERIFIED'
                                      : 'ALIGN BARCODE WITHIN FRAME',
                                  style: TextStyle(
                                    color: scan.product != null
                                        ? AppTheme.success
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 4. Top HUD Overlay: Status Badge & Controls
                      Positioned(
                        top: 10,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _isCameraInitialized
                                          ? AppTheme.success
                                          : AppTheme.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isCameraInitialized
                                        ? 'LIVE CAMERA'
                                        : 'CONNECTING...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isTorchOn
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                                    color: _isTorchOn
                                        ? Colors.amber
                                        : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _toggleTorch,
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.5),
                                    padding: const EdgeInsets.all(6),
                                  ),
                                ),
                                if (_cameras.length > 1) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.flip_camera_ios,
                                        color: Colors.white, size: 20),
                                    onPressed: _switchCamera,
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.black.withValues(alpha: 0.5),
                                      padding: const EdgeInsets.all(6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 5. Processing Loader
                      if (scan.isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.secondary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Barcode Input & Verification Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'COMMODITY BARCODE (GTIN / EAN / UPC)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _barcodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText:
                                  'Enter or scan 8, 12, 13, 14 digit GTIN',
                              prefixIcon: Icon(Icons.barcode_reader),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onSubmitted: (_) => _onVerifyBarcode(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(80, 48),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                          ),
                          onPressed:
                              scan.isProcessing ? null : _onVerifyBarcode,
                          child: const Text('VERIFY',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    if (scan.statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        scan.statusMessage!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.primary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Verified Product Details or Denial Banner
              if (scan.product != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.success, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'COMMODITY VERIFIED IN REGISTRY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        scan.product!.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (scan.product!.brand.isNotEmpty)
                        Text(
                          'Brand: ${scan.product!.brand}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Manufacturer: ${scan.product!.registeredCompany}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      if (scan.product!.companyAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Address: ${scan.product!.companyAddress}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'GTIN Barcode: ${scan.product!.gtin}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Step 3 Action Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  onPressed: _proceedToPackagingScan,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CAPTURE PACKAGING & VERIFY LABELS (STEP 3)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.camera_alt, size: 18),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
