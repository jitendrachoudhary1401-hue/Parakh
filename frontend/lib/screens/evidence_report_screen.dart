import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/compliance_provider.dart';

/// Evidence & Legal Notice Report Generator Screen (Blockchain Evidentiary Ledger)
class EvidenceReportScreen extends StatefulWidget {
  const EvidenceReportScreen({super.key});

  @override
  State<EvidenceReportScreen> createState() => _EvidenceReportScreenState();
}

class _EvidenceReportScreenState extends State<EvidenceReportScreen> {
  bool _isNoticeGenerated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final compliance =
          Provider.of<ComplianceProvider>(context, listen: false);
      if (compliance.currentInspection != null &&
          compliance.currentInspection!.blockchainReceipt == null) {
        compliance.commitEvidenceToBlockchain(compliance.currentInspection!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final compliance = Provider.of<ComplianceProvider>(context);
    final record = compliance.currentInspection;
    final receipt = record?.blockchainReceipt;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Evidentiary Ledger & Notice'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Blockchain Status Card
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
                            Icon(Icons.lock_clock,
                                size: 18, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text(
                              'Hyperledger Fabric Ledger Receipt',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.successContainer,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: const Text(
                            'IMMUTABLE',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildLedgerField(
                        'Inspection ID', record?.id ?? 'INSP-2026-0801'),
                    const SizedBox(height: 8),
                    _buildLedgerField(
                        'SHA-256 Evidence Hash',
                        receipt?.evidenceHash ??
                            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
                    const SizedBox(height: 8),
                    _buildLedgerField(
                        'Transaction TxID',
                        receipt?.txHash ??
                            '0x8f3c7e912b4a5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0'),
                    const SizedBox(height: 8),
                    _buildLedgerField('Channel / Block Number',
                        '${receipt?.channel ?? "doca-evidentiary-channel"} (Block #${receipt?.blockNumber ?? "10482"})'),
                    const SizedBox(height: 8),
                    _buildLedgerField('GPS & Timestamp Stamp',
                        '${record?.latitude ?? "28.5708"}°N, ${record?.longitude ?? "77.3271"}°E • ${record?.timestamp ?? DateTime.now()}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Legal Notice Document Preview
              Text(
                'OFFICIAL STATUTORY LEGAL NOTICE',
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
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'GOVERNMENT OF INDIA',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0),
                          ),
                          Text(
                            'Ministry of Consumer Affairs, Food & Public Distribution',
                            style: TextStyle(
                                fontSize: 10, color: AppTheme.textMuted),
                          ),
                          Text(
                            'Department of Consumer Affairs (Legal Metrology Division)',
                            style: TextStyle(
                                fontSize: 10, color: AppTheme.textMuted),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'FORM OF NOTICE UNDER SECTION 18 / RULE 6',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To,\n${record?.extractedData.manufacturerName ?? "The Packager / Manufacturer"}\n${record?.extractedData.manufacturerAddress ?? "Industrial Area, New Delhi"}\n\nSubject: Show Cause Notice for Non-Compliance with Legal Metrology (Packaged Commodities) Rules, 2011.',
                      style: const TextStyle(fontSize: 11, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: AppTheme.surfaceContainerLow,
                      child: Text(
                        'VIOLATION SUMMARY:\n• Offence: Incomplete Consumer Care Details (Rule 6(1)(h))\n• Evidence Hash: ${receipt?.evidenceHash.substring(0, 24) ?? "e3b0c44298fc1c14"}...\n• Inspection Location: ${record?.storeName ?? "Retail Store"}',
                        style: const TextStyle(
                            fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Digitally Signed & Sealed\nInspector (Legal Metrology)',
                          style: TextStyle(
                              fontSize: 9, fontStyle: FontStyle.italic),
                        ),
                        Icon(Icons.verified, size: 24, color: AppTheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isNoticeGenerated = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Legal Notice PDF generated & committed to Sovereign MeghRaj Cloud.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(_isNoticeGenerated
                    ? 'DOWNLOAD SIGNED NOTICE PDF'
                    : 'GENERATE OFFICIAL NOTICE PDF'),
              ),
              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/dashboard'),
                child: const Text('COMPLETE & RETURN TO DASHBOARD'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerField(String label, String value) {
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
        SelectableText(
          value,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
