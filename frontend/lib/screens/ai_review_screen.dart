import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/compliance_provider.dart';
import '../providers/scan_provider.dart';

import '../providers/sync_provider.dart';

/// AI Extraction Review Screen (Visual Sanity Check)
class AiReviewScreen extends StatefulWidget {
  const AiReviewScreen({super.key});

  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  late final TextEditingController _storeNameController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final scan = Provider.of<ScanProvider>(context, listen: false);
    _storeNameController = TextEditingController();
    _locationController = TextEditingController(
      text: scan.locationAddress.isNotEmpty &&
              scan.locationAddress != 'Acquiring GPS location...'
          ? scan.locationAddress
          : '',
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleProceedCompliance() async {
    final scan = Provider.of<ScanProvider>(context, listen: false);
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final sync = Provider.of<SyncProvider>(context, listen: false);
    final isOffline = !sync.isOnline;

    final extracted = scan.extractedData ?? OCRExtractedData.empty();
    final gs1 = scan.gs1Product ??
        GS1Product(
          gtin: scan.selectedBarcode,
          productName: scan.selectedBarcode.isNotEmpty
              ? 'Commodity (GTIN: ${scan.selectedBarcode})'
              : 'Packaged Commodity',
          registeredCompany: extracted.manufacturerName.isNotEmpty
              ? extracted.manufacturerName
              : 'Unknown / Unregistered Manufacturer',
          companyAddress: extracted.manufacturerAddress.isNotEmpty
              ? extracted.manufacturerAddress
              : '',
          brand: '',
          isVerified: false,
        );

    final record = await compliance.evaluateCompliance(
      extracted: extracted,
      gs1: gs1,
      storeName: _storeNameController.text.trim().isNotEmpty
          ? _storeNameController.text.trim()
          : 'Inspection Location',
      locationAddress: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : (scan.locationAddress.isNotEmpty && scan.locationAddress != 'Acquiring GPS location...'
              ? scan.locationAddress
              : 'GPS Geo-Coordinate Location'),
      isOffline: isOffline,
    );

    if (isOffline) {
      await sync.queueInspection(record, scan.capturedImage?.path ?? '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline: Inspection saved locally and queued to Sync Hub.'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    }

    if (mounted) {
      Navigator.pushNamed(context, '/verdict');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = Provider.of<ScanProvider>(context);
    final extracted = scan.extractedData ?? OCRExtractedData.empty();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Extraction Review'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unwarped Image Sanity Check Banner
              Container(
                padding: const EdgeInsets.all(12),
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
                        Text(
                          'SURFACE UNWARPED IMAGE (OPENCV 3D)',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successContainer,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: const Text(
                            'Flattened 100%',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: scan.capturedImage != null &&
                              File(scan.capturedImage!.path).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              child: Image.file(
                                File(scan.capturedImage!.path),
                                fit: BoxFit.contain,
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.crop_original,
                                      size: 36, color: Colors.white60),
                                  SizedBox(height: 6),
                                  Text(
                                    'Surface Unwarped Label Evidence',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inspection Context
              Text(
                'FIELD INSPECTION DETAILS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Retail Outlet / Store Name',
                  hintText: 'Enter retail outlet / premise name',
                  prefixIcon: Icon(Icons.storefront_outlined,
                      size: 18, color: AppTheme.secondary),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Market Division',
                  hintText: 'Enter division or city',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      size: 18, color: AppTheme.secondary),
                ),
              ),
              const SizedBox(height: 20),

              // Extracted Mandatory Declarations
              Text(
                'EXTRACTED LEGAL METROLOGY DECLARATIONS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),

              _buildFieldCard(
                context,
                title: 'MRP Declaration (Rule 6(1)(e))',
                value: extracted.mrp.isNotEmpty
                    ? extracted.mrp
                    : 'Not Detected (Non-compliant)',
                isValid: extracted.mrp.isNotEmpty,
                icon: Icons.currency_rupee,
              ),
              const SizedBox(height: 8),

              _buildFieldCard(
                context,
                title: 'Net Quantity (Rule 6(1)(f))',
                value: extracted.netQuantity.isNotEmpty
                    ? extracted.netQuantity
                    : 'Not Detected (Non-compliant)',
                isValid: extracted.netQuantity.isNotEmpty,
                icon: Icons.scale_outlined,
              ),
              const SizedBox(height: 8),

              _buildFieldCard(
                context,
                title: 'Mfg / Packaging Date (Rule 6(1)(d))',
                value: extracted.mfgDate.isNotEmpty
                    ? (extracted.expiryDate.isNotEmpty
                        ? 'Mfg: ${extracted.mfgDate} • Exp: ${extracted.expiryDate}'
                        : 'Mfg: ${extracted.mfgDate}')
                    : 'Not Detected (Non-compliant)',
                isValid: extracted.mfgDate.isNotEmpty,
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 8),

              _buildFieldCard(
                context,
                title: 'Consumer Care Grievance (Rule 6(1)(h))',
                value: (extracted.consumerCarePhone.isNotEmpty ||
                        extracted.consumerCareEmail.isNotEmpty)
                    ? 'Tel: ${extracted.consumerCarePhone.isNotEmpty ? extracted.consumerCarePhone : "Not Declared"} | Email: ${extracted.consumerCareEmail.isNotEmpty ? extracted.consumerCareEmail : "Not Declared"}'
                    : 'Not Detected (Non-compliant)',
                isValid: extracted.consumerCareEmail.isNotEmpty,
                icon: Icons.support_agent_outlined,
              ),
              const SizedBox(height: 8),

              _buildFieldCard(
                context,
                title: 'Manufacturer / Packer (Rule 6(1)(a))',
                value: extracted.manufacturerName.isNotEmpty
                    ? (extracted.manufacturerAddress.isNotEmpty
                        ? '${extracted.manufacturerName}, ${extracted.manufacturerAddress}'
                        : extracted.manufacturerName)
                    : 'Not Detected (Non-compliant)',
                isValid: extracted.manufacturerName.isNotEmpty,
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _handleProceedCompliance,
                icon: const Icon(Icons.rule_folder_outlined, size: 18),
                label: const Text('EXECUTE LEGAL COMPLIANCE VERDICT'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard(
    BuildContext context, {
    required String title,
    required String value,
    required bool isValid,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
            color: isValid
                ? AppTheme.outline
                : AppTheme.error.withValues(alpha: 0.4),
            width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18, color: isValid ? AppTheme.primary : AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isValid ? AppTheme.textPrimary : AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isValid ? AppTheme.success : AppTheme.error,
          ),
        ],
      ),
    );
  }
}
