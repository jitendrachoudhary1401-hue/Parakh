import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/compliance_provider.dart';
import '../providers/scan_provider.dart';

/// GS1 Barcode & Open Food Facts Registry Scanner Screen
/// Directs automatically to Statutory Evidence Report Dossier after barcode scan.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _barcodeController = TextEditingController(text: '8901030382910');
  bool _isProceeding = false;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = Provider.of<ScanProvider>(context, listen: false);
      if (scan.selectedBarcode.isNotEmpty) {
        _barcodeController.text = scan.selectedBarcode;
      }
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  /// Scans/looks up the barcode and automatically directs the inspector to the report dossier.
  Future<void> _handleBarcodeScanAndProceed() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or scan a valid product barcode / GTIN.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final scan = Provider.of<ScanProvider>(context, listen: false);
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);

    setState(() {
      _isProceeding = true;
      _statusText = 'Verifying with Open Food Facts registry...';
    });

    OpenFoodFactsProduct? offProduct;
    try {
      offProduct = await scan.lookupBarcode(barcode);
    } catch (_) {
      // Barcode unlisted or offline — proceed with statutory report so violation can be recorded
      offProduct = scan.product;
    }

    if (!mounted) return;

    setState(() {
      _statusText = 'Evaluating Legal Metrology Rules & generating report...';
    });

    try {
      final extracted = scan.extractedData ?? OCRExtractedData.empty();
      final gs1 = GS1Product(
        gtin: barcode,
        productName: (offProduct != null && offProduct.productName.isNotEmpty)
            ? offProduct.productName
            : 'Packaged Commodity (GTIN: $barcode)',
        registeredCompany: (offProduct != null && offProduct.registeredCompany.isNotEmpty)
            ? offProduct.registeredCompany
            : (extracted.manufacturerName.isNotEmpty
                ? extracted.manufacturerName
                : 'Registered Packager / Manufacturer'),
        companyAddress: (offProduct != null && offProduct.companyAddress.isNotEmpty)
            ? offProduct.companyAddress
            : extracted.manufacturerAddress,
        brand: offProduct?.brand ?? '',
        isVerified: offProduct != null,
      );

      final record = await compliance.evaluateCompliance(
        extracted: extracted,
        gs1: gs1,
        storeName: 'Field Inspection Site',
        locationAddress: scan.locationAddress.isNotEmpty &&
                scan.locationAddress != 'Acquiring GPS location...'
            ? scan.locationAddress
            : 'On-Site GPS Jurisdiction',
      );

      // Create or sync the statutory report dossier in backend
      await compliance.loadOrCreateReport(record.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcode verified! Opening Statutory Evidence Dossier...'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
        // Automatically direct inspector to the official report screen
        Navigator.pushReplacementNamed(context, '/evidence-report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProceeding = false;
          _statusText = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanProvider>(context);
    final hasCapturedImage = scan.capturedImage != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Product Barcode Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flow Step Indicator Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: hasCapturedImage
                      ? const Color(0xFFE8F5E9)
                      : AppTheme.secondaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: hasCapturedImage
                        ? AppTheme.success.withValues(alpha: 0.4)
                        : AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasCapturedImage ? Icons.check_circle : Icons.qr_code_scanner,
                      color: hasCapturedImage ? AppTheme.success : AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasCapturedImage
                                ? 'STEP 2 OF 2: SCAN BARCODE FOR REPORT'
                                : 'STEP 2: SCAN PRODUCT BARCODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: hasCapturedImage
                                  ? const Color(0xFF2E7D32)
                                  : AppTheme.primary,
                            ),
                          ),
                          Text(
                            hasCapturedImage
                                ? 'Packaging photo verified ✓ Scan barcode to generate dossier automatically.'
                                : 'Enter or scan product barcode to cross-check registry and generate dossier.',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasCapturedImage
                                  ? const Color(0xFF1B5E20)
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scanner HUD Viewfinder
              GestureDetector(
                onTap: _isProceeding ? null : _handleBarcodeScanAndProceed,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 230,
                          height: 110,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.success, width: 2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2, size: 44, color: Colors.white70),
                              SizedBox(height: 6),
                              Text(
                                'TAP TO SCAN / VERIFY BARCODE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 10,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt, size: 14, color: AppTheme.warning),
                            SizedBox(width: 4),
                            Text(
                              'Real-Time Open Food Facts Cross-Check',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Barcode Input
              Text(
                'ENTER OR SCANNED GTIN / BARCODE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 8901030382910',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _handleBarcodeScanAndProceed(),
                      enabled: !_isProceeding,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, AppTheme.touchTargetMin),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _isProceeding ? null : _handleBarcodeScanAndProceed,
                    child: _isProceeding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'SCAN & DIRECT TO REPORT',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),

              // Status message if processing
              if (_statusText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _statusText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Open Food Facts Registry Result Card (if previously loaded)
              if (scan.product != null) ...[
                Text(
                  'OPEN FOOD FACTS REGISTRY RECORD',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified, size: 16, color: AppTheme.success),
                              SizedBox(width: 6),
                              Text(
                                'Verified Product Registry',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryLight,
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Text(
                              scan.product!.gtin,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Product Name', scan.product!.productName),
                      const SizedBox(height: 8),
                      _buildInfoRow('Registered Company', scan.product!.registeredCompany),
                      const SizedBox(height: 8),
                      _buildInfoRow('Brand', scan.product!.brand),
                      const SizedBox(height: 8),
                      _buildInfoRow('Registered Address', scan.product!.companyAddress),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.assignment_turned_in, size: 20),
                  onPressed: _isProceeding ? null : _handleBarcodeScanAndProceed,
                  label: const Text(
                    'PROCEED TO STATUTORY EVIDENCE REPORT',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value.isNotEmpty ? value : 'Not Specified',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
