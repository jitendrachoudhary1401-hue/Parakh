import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/scan_provider.dart';

/// GS1 Barcode & Registry Scanner Screen
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _barcodeController = TextEditingController(text: '8901030382910');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = Provider.of<ScanProvider>(context, listen: false);
      scan.lookupGS1Barcode(_barcodeController.text);
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _onLookup() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isNotEmpty) {
      final scan = Provider.of<ScanProvider>(context, listen: false);
      scan.lookupGS1Barcode(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Open Food Facts Barcode Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scanner HUD Viewfinder
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 240,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.success, width: 2),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2,
                                size: 48, color: Colors.white70),
                            SizedBox(height: 6),
                            Text(
                              'ALIGN EAN-13 BARCODE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt, size: 14, color: AppTheme.warning),
                          SizedBox(width: 4),
                          Text(
                            'Real-Time Open Food Facts Database Cross-Check',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, AppTheme.touchTargetMin),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: scan.isProcessing ? null : _onLookup,
                    child: const Text('LOOKUP'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Open Food Facts Registry Result Card
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
                              Icon(Icons.verified,
                                  size: 16, color: AppTheme.success),
                              SizedBox(width: 6),
                              Text(
                                'Verified Product Registry',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Text(
                              scan.product!.gtin,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                          'Product Name', scan.product!.productName),
                      const SizedBox(height: 8),
                      _buildInfoRow('Registered Company',
                          scan.product!.registeredCompany),
                      const SizedBox(height: 8),
                      _buildInfoRow('Brand', scan.product!.brand),
                      const SizedBox(height: 8),
                      _buildInfoRow('Registered Address',
                          scan.product!.companyAddress),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    scan.setBarcode(scan.gs1Product!.gtin);
                    Navigator.pushReplacementNamed(context, '/ar-camera');
                  },
                  child: const Text('ATTACH TO SCAN & PROCEED'),
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
              color: AppTheme.textMuted),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
