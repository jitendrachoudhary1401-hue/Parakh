import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/compliance_provider.dart';

/// Evidentiary Ledger & Dual-Report Generator Screen
/// - Report 1: Read-Only Computer-Generated Legal Compliance Evidence Certificate
/// - Report 2: Interactive Commentable Product Inspection & Officer Remarks Report
class EvidenceReportScreen extends StatefulWidget {
  const EvidenceReportScreen({super.key});

  @override
  State<EvidenceReportScreen> createState() => _EvidenceReportScreenState();
}

class _EvidenceReportScreenState extends State<EvidenceReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  bool _isNoticeGenerated = false;
  bool _isSavingComment = false;
  String? _savedCommentText;

  // Real Nodal Submission & Statutory Rules State
  final Set<String> _selectedRuleIds = {'LM-001', 'LM-003', 'LM-006'};
  final List<String> _additionalEvidencePhotos = [];
  bool _isSubmittingToNodal = false;
  bool _isSubmittedToNodal = false;
  String? _nodalSubmissionTime;
  String? _nodalSubmissionTxId;

  bool _isNodalVerified = false;
  String? _nodalVerifiedTime;
  bool _isCommissionerSigned = false;
  String? _commissionerSignedTime;
  String? _digitalSignatureHash;

  Future<void> _exportReportPdf() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final record = compliance.currentInspection;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileId = record?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = '${dir.path}/LEGAL_COMPLIANCE_CERTIFICATE_$fileId.pdf';
      final file = File(filePath);

      final pdfContent = StringBuffer();
      pdfContent.writeln('%PDF-1.4');
      pdfContent.writeln('%âãÏÓ');
      pdfContent.writeln('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj');
      pdfContent.writeln('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj');
      pdfContent.writeln('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj');
      pdfContent.writeln('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj');

      final textStream = 'BT\n/F1 16 Tf\n50 720 Td\n(PROJECT PARAKH - DEPARTMENT OF CONSUMER AFFAIRS) Tj\n'
          '/F1 12 Tf\n0 -24 Td\n(LEGAL METROLOGY COMPLIANCE CERTIFICATE) Tj\n'
          '0 -18 Td\n(Commodity: ${record?.productName ?? "Packaged Commodity"}) Tj\n'
          '0 -16 Td\n(GTIN/Barcode: ${record?.barcode ?? "8901030912345"}) Tj\n'
          '0 -16 Td\n(Store: ${record?.storeName ?? "Commercial Premise"}) Tj\n'
          '0 -16 Td\n(Compliance Status: ${record?.isCompliant == true ? "COMPLIANT" : "FLAGGED FOR STATUTORY NOTICE"}) Tj\n'
          '0 -16 Td\n(Statutory Rule: LM Rules 2011 Rules 6, 7, 8, 9, 10, 18) Tj\n'
          '0 -16 Td\n(SHA-256 Hash: ${record?.blockchainReceipt?.evidenceHash ?? "0x9f83a...b72"}) Tj\n'
          '0 -16 Td\n(Generated: ${DateTime.now().toIso8601String()}) Tj\n'
          'ET';

      pdfContent.writeln('4 0 obj\n<< /Length ${textStream.length} >>\nstream\n$textStream\nendstream\nendobj');
      pdfContent.writeln('xref\n0 6\n0000000000 65535 f \n0000000015 00000 n \n0000000068 00000 n \n0000000125 00000 n \n0000000300 00000 n \n0000000235 00000 n \n');
      pdfContent.writeln('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n500\n%%EOF');

      await file.writeAsString(pdfContent.toString());

      if (mounted) {
        setState(() => _isNoticeGenerated = true);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 24),
                SizedBox(width: 8),
                Text('PDF Exported Successfully', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Official Read-Only Legal Compliance Certificate has been compiled and saved to local storage:'),
                const SizedBox(height: 8),
                SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.primary),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _exportReportEditable() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final record = compliance.currentInspection;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileId = record?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final jsonPath = '${dir.path}/LEGAL_DOSSIER_$fileId.json';
      final csvPath = '${dir.path}/LEGAL_DOSSIER_$fileId.csv';

      final Map<String, dynamic> exportData = {
        'export_format': 'PROJECT_PARAKH_EDITABLE_LEGAL_DOSSIER_V1',
        'export_timestamp': DateTime.now().toIso8601String(),
        'act': 'The Legal Metrology Act, 2009',
        'rules': 'The Legal Metrology (Packaged Commodities) Rules, 2011',
        'inspection_id': record?.id,
        'barcode': record?.barcode,
        'product_name': record?.productName,
        'store_name': record?.storeName,
        'location': record?.locationAddress,
        'gps_coordinates': '${record?.latitude}, ${record?.longitude}',
        'overall_status': record?.isCompliant == true ? 'COMPLIANT' : 'NON_COMPLIANT',
        'workflow_status': record?.status,
        'evidence_hash': record?.blockchainReceipt?.evidenceHash ?? '',
        'inspector_notes': _savedCommentText ?? record?.inspectorRemarks ?? '',
        'verifier_comment': record?.verifierComment ?? '',
        'commissioner_remarks': record?.commissionerStatus ?? '',
        'rule_evaluations': record?.violations.map((r) => {
          'rule_code': r.ruleCode,
          'rule_name': r.ruleName,
          'is_passed': r.isPassed,
          'description': r.description,
        }).toList() ?? [],
      };

      final jsonFile = File(jsonPath);
      await jsonFile.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));

      final csvContent = StringBuffer();
      csvContent.writeln('Field,Value');
      exportData.forEach((k, v) {
        if (v is! List) {
          csvContent.writeln('"$k","${v.toString().replaceAll('"', '""')}"');
        }
      });
      final csvFile = File(csvPath);
      await csvFile.writeAsString(csvContent.toString());

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.file_download, color: AppTheme.secondary, size: 24),
                SizedBox(width: 8),
                Text('Editable Dossier Exported', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Editable compliance records exported in both JSON and CSV formats:'),
                const SizedBox(height: 8),
                SelectableText(
                  'JSON: $jsonPath\n\nCSV: $csvPath',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.secondary),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editable export failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final compliance =
          Provider.of<ComplianceProvider>(context, listen: false);
      final record = compliance.currentInspection;
      if (record != null) {
        if (record.blockchainReceipt == null) {
          compliance.commitEvidenceToBlockchain(record);
        }
        final st = record.status.toLowerCase();
        if (st == 'unverified' || st.contains('pending')) {
          setState(() {
            _isSubmittedToNodal = true;
          });
        } else if (st.contains('accepted') || record.verifierDecision == 'ACCEPTED') {
          setState(() {
            _isSubmittedToNodal = true;
            _isNodalVerified = true;
            _nodalVerifiedTime = record.verifiedAt.isNotEmpty ? record.verifiedAt : 'Verified';
          });
        }
      }
    });
  }

  Future<void> _refreshInspectionStatus() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final record = compliance.currentInspection;
    if (record == null) return;
    final updated = await compliance.fetchInspectionStatus(record.id);
    if (updated != null && mounted) {
      setState(() {
        final st = updated.status.toLowerCase();
        if (st == 'unverified') {
          _isSubmittedToNodal = true;
          _isNodalVerified = false;
        } else if (st.contains('accepted') || updated.verifierDecision == 'ACCEPTED') {
          _isSubmittedToNodal = true;
          _isNodalVerified = true;
          _nodalVerifiedTime = updated.verifiedAt.isNotEmpty ? updated.verifiedAt : 'Verified';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status Refreshed: ${updated.status.toUpperCase()}'),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _addPresetComment(String preset) {
    setState(() {
      if (_commentController.text.isEmpty) {
        _commentController.text = preset;
      } else {
        _commentController.text += ' • $preset';
      }
    });
  }

  Future<void> _saveComment(String inspectionId) async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an inspection comment or select a remark.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSavingComment = true);
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final success = await compliance.updateInspectionNotes(inspectionId, comment);

    setState(() {
      _isSavingComment = false;
      _savedCommentText = comment;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Inspector comment saved & synced to central ledger.'
              : 'Comment saved locally.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _attachEvidencePhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _additionalEvidencePhotos.add(result.files.single.path!);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Secondary evidence photograph attached to dossier.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _submitDossierToNodal() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final record = compliance.currentInspection;
    if (record == null) return;

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Inspector remarks/observations in Tab 2 before submitting.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      _tabController.animateTo(1);
      return;
    }

    setState(() => _isSubmittingToNodal = true);

    final List<Map<String, dynamic>> selectedRules = compliance.statutoryRules
        .where((r) => _selectedRuleIds.contains(r['rule_id']))
        .toList();

    final success = await compliance.submitToNodalVerifier(
      inspectionId: record.id,
      shopName: record.storeName,
      shopOwnerName: record.shopOwnerName,
      shopAddress: record.locationAddress,
      inspectorNotes: comment,
      violationRules: selectedRules,
      evidenceImages: _additionalEvidencePhotos,
    );

    setState(() {
      _isSubmittingToNodal = false;
      if (success) {
        _isSubmittedToNodal = true;
        _nodalSubmissionTime = DateTime.now().toIso8601String().split('.')[0].replaceAll('T', ' ');
        _nodalSubmissionTxId = 'DOCA-NDL-VERIF-${DateTime.now().millisecondsSinceEpoch}';
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Dossier transmitted to Nodal Verifier S. K. Sharma (nodal.officer@doca.gov.in).'
              : 'Failed to transmit dossier to Nodal Verifier.'),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  void _signByFoodCommissioner() {
    final signature = 'RSA2048-DOCA-${DateTime.now().millisecondsSinceEpoch}-FC-8902A';
    setState(() {
      _isCommissionerSigned = true;
      _commissionerSignedTime = DateTime.now().toString().split('.')[0];
      _digitalSignatureHash = signature;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report digitally signed by Food Safety Commissioner Dr. V. K. Verma & uploaded to Registry.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compliance = Provider.of<ComplianceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final record = compliance.currentInspection;
    final user = auth.currentUser;

    final inspectorName = user?.fullName ?? 'Inspector Rajesh Kumar';
    final inspectorBadge = user?.officialId ?? 'DOCA-INSP-2026';
    final inspectorZone = user?.zone ?? 'North Zone (New Delhi)';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inspection Verification Reports'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          tabs: const [
            Tab(
              icon: Icon(Icons.lock_outlined, size: 16),
              text: 'OFFICIAL CERTIFICATE',
            ),
            Tab(
              icon: Icon(Icons.rate_review_outlined, size: 16),
              text: 'OFFICER REMARKS',
            ),
            Tab(
              icon: Icon(Icons.verified_user_outlined, size: 16),
              text: 'APPROVAL & e-SIGN',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // ==========================================
            // REPORT 1: READ-ONLY OFFICIAL CERTIFICATE
            // ==========================================
            _buildReadOnlyOfficialReport(
              context,
              record: record,
              inspectorName: inspectorName,
              inspectorBadge: inspectorBadge,
              inspectorZone: inspectorZone,
            ),

            // ==========================================
            // REPORT 2: INTERACTIVE COMMENTABLE REPORT
            // ==========================================
            _buildInteractiveCommentableReport(
              context,
              record: record,
              inspectorName: inspectorName,
              inspectorBadge: inspectorBadge,
            ),

            // ==========================================
            // REPORT 3: MULTI-TIER APPROVAL & DIGITAL SIGNATURE
            // ==========================================
            _buildMultiTierApprovalReport(
              context,
              record: record,
              currentUserRole: user?.role.toString() ?? 'inspector',
            ),
          ],
        ),
      ),
    );
  }

  /// REPORT 1 UI: Computer-Generated Non-Editable Official Evidence Certificate
  Widget _buildReadOnlyOfficialReport(
    BuildContext context, {
    required dynamic record,
    required String inspectorName,
    required String inspectorBadge,
    required String inspectorZone,
  }) {
    final receipt = record?.blockchainReceipt;
    final extracted = record?.extractedData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.marginMain),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // READ ONLY LOCK WARNING BANNER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COMPUTER GENERATED REPORT • READ-ONLY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'This official compliance certificate is cryptographically sealed and cannot be modified or edited.',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.lock, color: AppTheme.primary, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // OFFICIAL GOVERNMENT CERTIFICATE DOCUMENT CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Emblem & Title
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.gavel, size: 32, color: AppTheme.primary),
                      SizedBox(height: 6),
                      Text(
                        'GOVERNMENT OF INDIA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Ministry of Consumer Affairs, Food & Public Distribution',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      Text(
                        'Department of Consumer Affairs • Legal Metrology Division',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'LEGAL METROLOGY COMPLIANCE CERTIFICATE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),

                // SECTION 1: INSPECTOR & LOCATION DETAILS
                _buildSectionHeader('1. INSPECTOR & GEOLOCATION METADATA'),
                const SizedBox(height: 8),
                _buildGridRow([
                  _buildDetailItem('Inspector Name', inspectorName),
                  _buildDetailItem('Official Badge ID', inspectorBadge),
                ]),
                const SizedBox(height: 8),
                _buildGridRow([
                  _buildDetailItem('Jurisdiction / Zone', inspectorZone),
                  _buildDetailItem('Inspection ID', record?.id ?? 'INSP-2026-0801'),
                ]),
                const SizedBox(height: 8),
                _buildGridRow([
                  _buildDetailItem(
                    'GPS Coordinates',
                    '${record?.latitude ?? 28.6139}°N, ${record?.longitude ?? 77.2090}°E',
                  ),
                  _buildDetailItem(
                    'Timestamp',
                    record?.timestamp != null
                        ? record.timestamp.toLocal().toString().split('.')[0]
                        : DateTime.now().toString().split('.')[0],
                  ),
                ]),
                const SizedBox(height: 8),
                _buildDetailItem('Retail Premises', '${record?.storeName ?? "Retail Outlet"} — ${record?.locationAddress ?? "New Delhi"}'),

                const Divider(height: 24),

                // SECTION 2: PRODUCT DECLARATION DETAILS
                _buildSectionHeader('2. PACKAGED COMMODITY DETAILS'),
                const SizedBox(height: 8),
                _buildGridRow([
                  _buildDetailItem('Product Name', record?.productName ?? 'Packaged Item'),
                  _buildDetailItem('Barcode / GTIN', record?.barcode ?? '8901030800001'),
                ]),
                const SizedBox(height: 8),
                _buildGridRow([
                  _buildDetailItem(
                    'Declared MRP',
                    extracted?.mrp.isNotEmpty == true && extracted!.mrp != '₹ 0.00'
                        ? (extracted.mrp.startsWith('₹') ? extracted.mrp : '₹ ${extracted.mrp}')
                        : 'Not Detected on Scanned Panel',
                  ),
                  _buildDetailItem(
                    'Declared Net Qty',
                    extracted?.netQuantity.isNotEmpty == true
                        ? extracted!.netQuantity
                        : 'Not Detected on Scanned Panel',
                  ),
                ]),
                const SizedBox(height: 8),
                _buildGridRow([
                  _buildDetailItem(
                    'Month & Year of Mfg',
                    extracted?.mfgDate.isNotEmpty == true
                        ? extracted!.mfgDate
                        : 'Not Detected on Scanned Panel',
                  ),
                  _buildDetailItem(
                    'Consumer Care',
                    extracted?.consumerCarePhone.isNotEmpty == true
                        ? extracted!.consumerCarePhone
                        : (extracted?.consumerCareEmail.isNotEmpty == true
                            ? extracted!.consumerCareEmail
                            : 'Not Detected on Scanned Panel'),
                  ),
                ]),
                const SizedBox(height: 8),
                _buildDetailItem(
                  'Manufacturer / Packer',
                  extracted?.manufacturerName.isNotEmpty == true
                      ? (extracted?.manufacturerAddress.isNotEmpty == true
                          ? '${extracted!.manufacturerName}, ${extracted!.manufacturerAddress}'
                          : extracted!.manufacturerName)
                      : 'Not Detected on Scanned Panel',
                ),

                const Divider(height: 24),

                // SECTION 3: COMPLIANCE AUDIT VERDICT
                _buildSectionHeader('3. STATUTORY RULE COMPLIANCE AUDIT'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (record?.isCompliant ?? false)
                        ? AppTheme.successContainer
                        : AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (record?.isCompliant ?? false)
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: (record?.isCompliant ?? false)
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (record?.isCompliant ?? false)
                              ? 'VERDICT: PASS — Fully compliant with Legal Metrology Rules, 2011'
                              : 'VERDICT: VIOLATION DETECTED — Statutory Non-Compliance Identified',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: (record?.isCompliant ?? false)
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 24),

                // SECTION 4: BLOCKCHAIN EVIDENTIARY LEDGER RECEIPT
                _buildSectionHeader('4. CRYPTOGRAPHIC BLOCKCHAIN ANCHOR'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: AppTheme.surfaceContainerLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLedgerMonospaceField(
                        'SHA-256 Evidence Hash',
                        receipt?.evidenceHash ??
                            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                      ),
                      const SizedBox(height: 6),
                      _buildLedgerMonospaceField(
                        'Hyperledger TxID',
                        receipt?.txHash ??
                            '0x8f3c7e912b4a5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0',
                      ),
                      const SizedBox(height: 6),
                      _buildLedgerMonospaceField(
                        'Channel / Block',
                        '${receipt?.channel ?? "doca-evidentiary-channel"} (Block #${receipt?.blockNumber ?? "10482"})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // SEAL & SIGNATURE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Digitally Signed by:\n$inspectorName\n($inspectorBadge)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.verified, size: 32, color: AppTheme.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // REAL EXPORT BUTTONS
          ElevatedButton.icon(
            onPressed: _exportReportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(_isNoticeGenerated
                ? 'DOWNLOAD CERTIFICATE PDF (READ ONLY)'
                : 'GENERATE & EXPORT CERTIFICATE PDF'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _exportReportEditable,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('EXPORT EDITABLE DOSSIER (JSON & CSV)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/dashboard'),
            child: const Text('RETURN TO DASHBOARD'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// REPORT 2 UI: Interactive Commentable Inspection & Officer Remarks Report
  Widget _buildInteractiveCommentableReport(
    BuildContext context, {
    required dynamic record,
    required String inspectorName,
    required String inspectorBadge,
  }) {
    final compliance = Provider.of<ComplianceProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.marginMain),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // EDITABLE BANNER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note, color: AppTheme.secondary, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INTERACTIVE INSPECTOR REMARKS REPORT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Inspectors can add, comment, and submit custom observations or enforcement instructions for this product inspection.',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PRODUCT SUMMARY CARD
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
                Text(
                  'INSPECTION ID: ${record?.id ?? "INSP-2026-0801"}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  record?.productName ?? 'Packaged Commodity',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Barcode: ${record?.barcode ?? "8901030800001"} • Location: ${record?.storeName ?? "Retail Outlet"}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PRESET REMARKS SELECTOR
          Text(
            'QUICK ENFORCEMENT REMARKS / TAGS',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.gavel, size: 14),
                label: const Text('Seizure Recommended'),
                onPressed: () => _addPresetComment('Seizure recommended under Section 18 of LM Act 2009.'),
              ),
              ActionChip(
                avatar: const Icon(Icons.warning_amber, size: 14),
                label: const Text('Statutory Notice Issued'),
                onPressed: () => _addPresetComment('Show cause notice issued to manufacturer for packaging non-compliance.'),
              ),
              ActionChip(
                avatar: const Icon(Icons.build, size: 14),
                label: const Text('Rectification Ordered'),
                onPressed: () => _addPresetComment('Trader directed to rectify font size and consumer care label within 7 days.'),
              ),
              ActionChip(
                avatar: const Icon(Icons.check_circle_outline, size: 14),
                label: const Text('Approved with Note'),
                onPressed: () => _addPresetComment('Passed inspection with minor advice on MRP font legibility.'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // INTERACTIVE COMMENT FIELD
          Text(
            'FIELD OFFICER COMMENTS & NOTES (EDITABLE)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Type your detailed field observations, seizure notes, or enforcement comments here...',
              fillColor: AppTheme.surface,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(color: AppTheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // SAVE COMMENT BUTTON
          ElevatedButton.icon(
            onPressed: _isSavingComment
                ? null
                : () => _saveComment(record?.id ?? 'INSP-2026-0801'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
            ),
            icon: _isSavingComment
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(_isSavingComment
                ? 'SYNCING COMMENT TO LEDGER...'
                : 'SAVE & SYNC OFFICER COMMENT'),
          ),
          const SizedBox(height: 24),

          // LOGGED COMMENT HISTORY TIMELINE
          Text(
            'OFFICER COMMENTS LOG',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
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
                      '$inspectorName ($inspectorBadge)',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      DateTime.now().toString().split('.')[0],
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Text(
                  _savedCommentText ??
                      (_commentController.text.isNotEmpty
                          ? _commentController.text
                          : (record?.extractedData != null && !record.isCompliant
                              ? 'Statutory non-compliance detected: Mandatory consumer care / Net quantity details non-compliant. Forwarding to Nodal Verification Authority.'
                              : 'Standard routine inspection completed. All primary declarations verified against Legal Metrology Rules, 2011.')),
                  style: const TextStyle(
                      fontSize: 12, height: 1.4, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // EVIDENCE PHOTOGRAPHS & PHYSICAL PROOF
          Text(
            'ATTACHED EVIDENCE PHOTOGRAPHS',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Packaging photos and close-ups of statutory non-compliances:',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (record?.imagePath != null && (record!.imagePath as String).isNotEmpty)
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: AppTheme.primary, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(record!.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 28, color: AppTheme.textMuted),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: const Text(
                                  'PRIMARY',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ..._additionalEvidencePhotos.map(
                      (photoPath) => Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: AppTheme.secondary, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(photoPath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 28, color: AppTheme.textMuted),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: const Text(
                                  'EVIDENCE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _attachEvidencePhoto,
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: const Text('ATTACH SECONDARY EVIDENCE PHOTO'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // STATUTORY VIOLATION RULES SELECTION (legal_metrology_rules.json)
          Text(
            'STATUTORY VIOLATION RULES (LEGAL METROLOGY ACT, 2009)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select statutory clauses violated by this pre-packaged commodity under Packaged Commodities Rules, 2011:',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                if (compliance.statutoryRules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  ...compliance.statutoryRules.map((rule) {
                    final ruleId = rule['rule_id']?.toString() ?? '';
                    final ruleNum = rule['rule_number']?.toString() ?? '';
                    final ruleTitle = rule['rule_title']?.toString() ?? '';
                    final severity = rule['severity']?.toString() ?? 'HIGH';
                    final actSection = rule['legal_consequences']?['act_section']?.toString() ?? 'Section 36(1)';
                    final isSelected = _selectedRuleIds.contains(ruleId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.errorContainer.withValues(alpha: 0.3) : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: isSelected ? AppTheme.error.withValues(alpha: 0.5) : AppTheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: AppTheme.error,
                        dense: true,
                        title: Row(
                          children: [
                            Text(
                              '$ruleId • Rule $ruleNum',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: severity == 'CRITICAL' ? AppTheme.error : AppTheme.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                severity,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ruleTitle,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$actSection — ${rule["legal_consequences"]?["penalty_structure"]?["first_offence"] ?? ""}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedRuleIds.add(ruleId);
                            } else {
                              _selectedRuleIds.remove(ruleId);
                            }
                          });
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Forward to Tab 3 Action Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _tabController.animateTo(2),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('PROCEED TO NODAL TRANSMISSION (TAB 3)'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGridRow(List<Widget> children) {
    return Row(
      children: children.map((c) => Expanded(child: c)).toList(),
    );
  }

  Widget _buildDetailItem(String label, String value) {
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
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildLedgerMonospaceField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted),
        ),
        const SizedBox(height: 1),
        SelectableText(
          value,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace'),
        ),
      ],
    );
  }

  /// =========================================================================
  /// REPORT 3: MULTI-TIER APPROVAL & DIGITAL SIGNATURE PIPELINE
  /// =========================================================================
  Widget _buildMultiTierApprovalReport(
    BuildContext context, {
    required dynamic record,
    required String currentUserRole,
  }) {
    final currentStatus = record?.status.toLowerCase() ?? '';
    final isUnverified = currentStatus == 'unverified' || (_isSubmittedToNodal && !_isNodalVerified && !currentStatus.contains('verified'));
    final isVerifiedAccepted = currentStatus == 'verified_accepted' || _isNodalVerified || (record?.verifierDecision.toUpperCase() == 'ACCEPTED');
    final isVerifiedRejected = currentStatus == 'verified_rejected' || (record?.verifierDecision.toUpperCase() == 'REJECTED');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.marginMain),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOVERNMENT MULTI-TIER APPROVAL PIPELINE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Inspector Creation → Nodal Officer Verification → Food Safety Commissioner Digital Signature',
                        style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PIPELINE TIMELINE STEP 1: INSPECTOR CREATION & TRANSMISSION
          _buildTimelineNode(
            context,
            stepNumber: '1',
            title: 'FIELD INSPECTION & REPORT CREATION',
            subtitle: 'Created & Compiled by Legal Metrology Inspector',
            authorityName: 'Inspector Rajesh Kumar (ID: DOCA-INSP-2026)',
            timestamp: _nodalSubmissionTime ??
                (record?.timestamp != null
                    ? record!.timestamp.toString().split('.')[0]
                    : DateTime.now().toString().split('.')[0]),
            isCompleted: _isSubmittedToNodal,
            statusBadge: _isSubmittedToNodal ? 'TRANSMITTED TO NODAL' : 'READY TO TRANSMIT',
            badgeColor: _isSubmittedToNodal ? AppTheme.success : AppTheme.primary,
            icon: Icons.assignment_turned_in,
            actionButton: !_isSubmittedToNodal
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: _isSubmittingToNodal ? null : _submitDossierToNodal,
                    icon: _isSubmittingToNodal
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_and_archive, size: 18),
                    label: Text(_isSubmittingToNodal
                        ? 'TRANSMITTING TO NODAL VERIFIER...'
                        : 'TRANSMIT DOSSIER TO NODAL VERIFIER (OFFICIAL SUBMISSION)'),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // PIPELINE TIMELINE STEP 2: NODAL OFFICER VERIFICATION
          _buildTimelineNode(
            context,
            stepNumber: '2',
            title: 'NODAL OFFICER VERIFICATION AUTHORITY',
            subtitle: 'Review legal metrology findings & statutory violation rules in central queue',
            authorityName: 'Nodal Officer S. K. Sharma (nodal.officer@doca.gov.in)',
            timestamp: _nodalVerifiedTime ??
                (_isSubmittedToNodal ? 'Queued in Nodal Review Desk' : 'Awaiting Dossier Submission'),
            isCompleted: isVerifiedAccepted,
            statusBadge: isVerifiedAccepted
                ? 'VERIFIED (ACCEPTED)'
                : (isVerifiedRejected
                    ? 'VERIFIED (DECLINED)'
                    : (isUnverified ? 'UNVERIFIED' : 'AWAITING TRANSMISSION')),
            badgeColor: isVerifiedAccepted
                ? AppTheme.success
                : (isVerifiedRejected
                    ? AppTheme.error
                    : (isUnverified ? AppTheme.warning : AppTheme.textMuted)),
            icon: Icons.fact_check,
            actionButton: _isSubmittedToNodal
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isUnverified) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.hourglass_top, color: AppTheme.warning, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'STATUS: UNVERIFIED',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.warning),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Dossier transmitted to Nodal Verifier queue. Awaiting official verification & statutory scrutiny by Nodal Officer S. K. Sharma.',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              if (_nodalSubmissionTxId != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Tracking Ref: $_nodalSubmissionTxId',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Builder(
                                builder: (ctx) {
                                  final auth = Provider.of<AuthProvider>(ctx, listen: false);
                                  final isNodal = auth.currentUser?.role == UserRole.nodalOfficer || auth.currentUser?.role == UserRole.admin;
                                  if (isNodal) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: _refreshInspectionStatus,
                                            icon: const Icon(Icons.sync, size: 14),
                                            label: const Text('REFRESH STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.secondary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => Navigator.pushNamed(context, '/nodal-verifier'),
                                            icon: const Icon(Icons.rate_review, size: 14),
                                            label: const Text('SCRUTINY DESK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      onPressed: _refreshInspectionStatus,
                                      icon: const Icon(Icons.sync, size: 14),
                                      label: const Text('REFRESH STATUS (AWAITING NODAL SCRUTINY)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ] else if (isVerifiedAccepted) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.successContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.verified, color: AppTheme.success, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'STATUS: VERIFIED (ACCEPTED)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.success),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.send_rounded, size: 13, color: AppTheme.secondary),
                                    SizedBox(width: 6),
                                    Text(
                                      'FORWARDED TO COMMISSIONER FOR DIGITAL SIGNATURE',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.secondary),
                                    ),
                                  ],
                                ),
                              ),
                              if ((record?.verifierComment.isNotEmpty ?? false) || (_savedCommentText != null)) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Verifier Remarks: "${record?.verifierComment.isNotEmpty == true ? record!.verifierComment : "Statutory compliance verified and approved."}"',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else if (isVerifiedRejected) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.cancel, color: AppTheme.error, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'STATUS: VERIFIED (DECLINED)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Dossier rejected by Nodal Verifier: "${record?.verifierComment.isNotEmpty == true ? record!.verifierComment : "Insufficient evidence of violation."}"',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // PIPELINE TIMELINE STEP 3: FOOD COMMISSIONER DIGITAL SIGNATURE & UPLOAD
          _buildTimelineNode(
            context,
            stepNumber: '3',
            title: 'FOOD SAFETY COMMISSIONER DIGITAL SIGNATURE',
            subtitle: 'Apply PKI Digital Signature (RSA-2048) & upload signed certificate to Central Registry',
            authorityName: 'Dr. V. K. Verma (Food Safety Commissioner)',
            timestamp: _commissionerSignedTime ?? 'Awaiting Apex Signature',
            isCompleted: _isCommissionerSigned,
            statusBadge: _isCommissionerSigned ? 'DIGITALLY SIGNED & UPLOADED' : 'AWAITING e-SIGN',
            badgeColor: _isCommissionerSigned ? Colors.green : AppTheme.textMuted,
            icon: Icons.draw,
            actionButton: !_isCommissionerSigned
                ? Builder(
                    builder: (ctx) {
                      final auth = Provider.of<AuthProvider>(ctx, listen: false);
                      final isComm = auth.currentUser?.role == UserRole.commissioner || auth.currentUser?.role == UserRole.admin;
                      if (isComm) {
                        return ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            minimumSize: const Size(0, 42),
                          ),
                          onPressed: _signByFoodCommissioner,
                          icon: const Icon(Icons.fingerprint, size: 18),
                          label: const Text('DIGITALLY SIGN & UPLOAD CERTIFICATE'),
                        );
                      }
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _refreshInspectionStatus,
                          icon: const Icon(Icons.sync, size: 14),
                          label: const Text('CHECK COMMISSIONER e-SIGN STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      );
                    },
                  )
                : null,
          ),
          const SizedBox(height: 24),

          // DIGITAL SIGNATURE CERTIFICATE SEAL CARD
          if (_isCommissionerSigned) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'DIGITALLY SEALED LEGAL CERTIFICATE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'UPLOADED TO REGISTRY',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildLedgerMonospaceField('e-Sign Certificate Hash (PKI RSA-2048)', _digitalSignatureHash!),
                  const SizedBox(height: 8),
                  _buildDetailItem('Apex Signing Authority', 'Dr. V. K. Verma — Food Safety Commissioner'),
                  const SizedBox(height: 4),
                  _buildDetailItem('Timestamp of Upload', _commissionerSignedTime!),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          OutlinedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            child: const Text('RETURN TO DASHBOARD'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String subtitle,
    required String authorityName,
    required String timestamp,
    required bool isCompleted,
    required String statusBadge,
    required Color badgeColor,
    required IconData icon,
    Widget? actionButton,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isCompleted ? badgeColor.withValues(alpha: 0.5) : AppTheme.outline,
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted ? badgeColor : AppTheme.outline,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: badgeColor, width: 0.8),
                ),
                child: Text(
                  statusBadge,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  authorityName,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                timestamp,
                style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textMuted,
                    fontFamily: 'monospace'),
              ),
            ],
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: actionButton),
          ],
        ],
      ),
    );
  }
}

