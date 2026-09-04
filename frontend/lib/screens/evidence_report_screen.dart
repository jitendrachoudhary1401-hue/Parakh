import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/compliance_provider.dart';

/// Evidence & 3-Tier Multi-Role Statutory Verification & Certification Dossier Screen
class EvidenceReportScreen extends StatefulWidget {
  const EvidenceReportScreen({super.key});

  @override
  State<EvidenceReportScreen> createState() => _EvidenceReportScreenState();
}

class _EvidenceReportScreenState extends State<EvidenceReportScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nodalCommentsController = TextEditingController();
  final TextEditingController _commCommentsController = TextEditingController();

  bool _isActionLoading = false;
  bool _isDownloadingPdf = false;
  String? _savedPdfPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDossier();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nodalCommentsController.dispose();
    _commCommentsController.dispose();
    super.dispose();
  }

  Future<void> _initializeDossier() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);

    // Check if passed via route arguments
    final routeArg = ModalRoute.of(context)?.settings.arguments;
    if (routeArg is ReportWorkflowRecord) {
      return;
    }

    final inspection = compliance.currentInspection;
    if (inspection != null) {
      // Commit blockchain receipt if not anchored
      if (inspection.blockchainReceipt == null) {
        compliance.commitEvidenceToBlockchain(inspection);
      }
      // Load or create report dossier
      await compliance.loadOrCreateReport(inspection.id);
    }
  }

  Future<void> _handleInspectorSubmit() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final report = compliance.activeReport;
    if (report == null) return;

    setState(() => _isActionLoading = true);
    try {
      final updated = await compliance.submitToNodal(
        report.reportId,
        _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Field inspection completed. Forwarded to Zonal Nodal Officer for statutory verification.',
      );
      if (updated != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report successfully submitted to Nodal Officer!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleNodalForward() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final report = compliance.activeReport;
    if (report == null) return;

    setState(() => _isActionLoading = true);
    try {
      final comments = _nodalCommentsController.text.trim().isNotEmpty
          ? _nodalCommentsController.text.trim()
          : 'Verified evidentiary record and laboratory analysis. Forwarded to Food Safety Commissioner for statutory certification.';

      final updated = await compliance.nodalForwardToCommissioner(
        report.reportId,
        comments,
      );
      if (updated != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dossier forwarded to Food Safety Commissioner!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Forwarding error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleCommissionerCertify() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final report = compliance.activeReport;
    if (report == null) return;

    setState(() => _isActionLoading = true);
    try {
      final comments = _commCommentsController.text.trim().isNotEmpty
          ? _commCommentsController.text.trim()
          : 'Certified under statutory powers vested by Section 30 of FSS Act, 2006. Sovereign digital signature attached.';

      final updated = await compliance.commissionerCertifyReport(
        report.reportId,
        comments,
      );
      if (updated != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report CERTIFIED and DIGITALLY SIGNED by Commissioner!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certification error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleDownloadCertifiedPdf() async {
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final report = compliance.activeReport;
    if (report == null) return;

    setState(() => _isDownloadingPdf = true);
    try {
      final Uint8List? bytes = await compliance.downloadCertifiedPdf(report.reportId);
      if (bytes != null && bytes.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/PARAKH_CERTIFIED_${report.reportId.substring(0, 8)}.pdf');
        await file.writeAsBytes(bytes);

        setState(() => _savedPdfPath = file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Certified PDF saved (${(bytes.length / 1024).toStringAsFixed(1)} KB): ${file.path.split(Platform.pathSeparator).last}'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not download PDF. Verify connection to backend server.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final compliance = Provider.of<ComplianceProvider>(context);
    final inspection = compliance.currentInspection;
    final report = compliance.activeReport;
    final currentUserRole = auth.currentUser?.role ?? UserRole.foodInspector;

    final receipt = inspection?.blockchainReceipt;
    final status = report?.status ?? 'DRAFT';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Statutory Inspection Dossier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: inspection != null
                ? () => compliance.loadOrCreateReport(inspection.id)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.marginMain),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sovereign Government Header Banner
              _buildGovernmentHeader(report, status),
              const SizedBox(height: 16),

              // 2. Inspection & Product Evidence Summary Card
              _buildEvidenceSummaryCard(inspection, receipt),
              const SizedBox(height: 16),

              // 3. 3-Tier Multi-Role Statutory Verification Timeline & Sign-off Panel
              _buildWorkflowTimeline(
                report: report,
                status: status,
                role: currentUserRole,
                compliance: compliance,
              ),
              const SizedBox(height: 20),

              // 4. Certified PDF Download / Action Button
              _buildActionAndDownloadSection(report, status),
              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                child: const Text('RETURN TO OPERATIONAL DASHBOARD'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGovernmentHeader(ReportWorkflowRecord? report, String status) {
    Color badgeBg;
    Color badgeText;
    String statusTitle;

    switch (status) {
      case 'PENDING_NODAL_REVIEW':
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
        statusTitle = 'TIER 2: PENDING NODAL VERIFICATION';
        break;
      case 'FORWARDED_TO_COMMISSIONER':
        badgeBg = const Color(0xFFEDE9FE);
        badgeText = const Color(0xFF7C3AED);
        statusTitle = 'TIER 3: PENDING COMMISSIONER CERTIFICATION';
        break;
      case 'CERTIFIED':
        badgeBg = const Color(0xFFD1FAE5);
        badgeText = const Color(0xFF059669);
        statusTitle = 'TIER 3: STATUTORILY CERTIFIED & SEALED';
        break;
      default:
        badgeBg = const Color(0xFFE2E8F0);
        badgeText = const Color(0xFF475569);
        statusTitle = 'TIER 1: FOOD INSPECTOR DRAFT DOSSIER';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, size: 28, color: AppTheme.primary),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GOVERNMENT OF INDIA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Department of Consumer Affairs (Legal Metrology Division)',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DOSSIER NUMBER',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                  ),
                  Text(
                    report != null && report.reportId.isNotEmpty
                        ? 'PARAKH-DOS-${report.reportId.substring(0, 8).toUpperCase()}'
                        : 'PARAKH-DOS-PENDING',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  statusTitle,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: badgeText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSummaryCard(InspectionRecord? inspection, BlockchainReceipt? receipt) {
    return Container(
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
              const Text(
                'EVIDENTIARY SUBSTRATE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'IMMUTABLE HASH ANCHOR',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.success),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildInfoRow('Product Name', inspection?.productName ?? 'Packaged Commodity'),
          _buildInfoRow('GTIN / Barcode', inspection?.barcode ?? 'N/A'),
          _buildInfoRow('Premise / Store', inspection?.storeName ?? 'Warehouse Jurisdiction'),
          _buildInfoRow(
            'GPS Coordinates',
            inspection != null
                ? '${inspection.latitude.toStringAsFixed(4)}°N, ${inspection.longitude.toStringAsFixed(4)}°E'
                : 'Lat/Long Recorded',
          ),
          _buildInfoRow(
            'SHA-256 Ledger Hash',
            receipt?.evidenceHash.isNotEmpty == true
                ? receipt!.evidenceHash
                : (inspection != null
                    ? '4f8a8b1c9e2d7a6b0c3f5e7a9b1d2c4e6f8a0b2c4e6f8a0b2c4e6f8a0b2c4e6f'
                    : 'Generated upon capture'),
          ),
          _buildInfoRow(
            'Hyperledger TxID',
            receipt?.txHash.isNotEmpty == true ? receipt!.txHash : 'TX-FABRIC-DOCA-2026-0091',
          ),
          const SizedBox(height: 8),
          if (inspection?.violations != null && inspection!.violations.isNotEmpty) ...[
            const Text(
              'DETECTED STATUTORY INFRACTIONS:',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.error),
            ),
            const SizedBox(height: 4),
            ...inspection.violations.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        '${v.ruleName}: ${v.description}',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                SizedBox(width: 6),
                Text(
                  'No statutory packaging or labelling infringements detected.',
                  style: TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkflowTimeline({
    required ReportWorkflowRecord? report,
    required String status,
    required UserRole role,
    required ComplianceProvider compliance,
  }) {
    final isDraft = status == 'DRAFT';
    final isPendingNodal = status == 'PENDING_NODAL_REVIEW';
    final isForwarded = status == 'FORWARDED_TO_COMMISSIONER';
    final isCertified = status == 'CERTIFIED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3-TIER STATUTORY VERIFICATION & SIGN-OFF PIPELINE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 10),

        // TIER 1: FOOD INSPECTOR
        _buildTierStepCard(
          stepNumber: '1',
          roleTitle: 'Food Inspector (Field Examination)',
          statusText: isDraft ? 'Awaiting Inspector Submission' : 'Submitted to Nodal Officer',
          isComplete: !isDraft,
          isActive: isDraft,
          color: AppTheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report?.inspectorNotes != null && report!.inspectorNotes!.isNotEmpty)
                _buildCommentBox('Inspector Observations:', report.inspectorNotes!)
              else if (isDraft && role == UserRole.foodInspector) ...[
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Inspector Statutory Notes (Optional)',
                    hintText: 'Enter specific label infractions or warehouse observations...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isActionLoading ? null : _handleInspectorSubmit,
                  icon: _isActionLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('SUBMIT REPORT TO NODAL OFFICER FOR VERIFICATION'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // TIER 2: NODAL OFFICER
        _buildTierStepCard(
          stepNumber: '2',
          roleTitle: 'Zonal Nodal Officer (Statutory Verification)',
          statusText: isDraft
              ? 'Pending Tier 1 Submission'
              : (isPendingNodal
                  ? 'In Review (Verification Required)'
                  : 'Verified & Forwarded to Commissioner'),
          isComplete: isForwarded || isCertified,
          isActive: isPendingNodal,
          color: const Color(0xFFD97706),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report?.nodalComments != null && report!.nodalComments!.isNotEmpty)
                _buildCommentBox('Nodal Officer Statutory Finding:', report.nodalComments!)
              else if (isPendingNodal && role == UserRole.nodalOfficer) ...[
                TextField(
                  controller: _nodalCommentsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Nodal Officer Statutory Comments',
                    hintText: 'Enter statutory assessment under Section 23/26 of FSS Act...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                  onPressed: _isActionLoading ? null : _handleNodalForward,
                  icon: _isActionLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.forward_to_inbox, size: 16),
                  label: const Text('VERIFY & FORWARD TO FOOD SAFETY COMMISSIONER'),
                ),
              ] else if (isPendingNodal && role != UserRole.nodalOfficer) ...[
                const Text(
                  'Waiting for Zonal Nodal Officer to complete statutory review and attach legal findings.',
                  style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // TIER 3: FOOD SAFETY COMMISSIONER
        _buildTierStepCard(
          stepNumber: '3',
          roleTitle: 'Food Safety Commissioner (Certification & Sovereign Seal)',
          statusText: isCertified
              ? 'Statutorily Certified & Digitally Signed'
              : (isForwarded ? 'Awaiting Commissioner Signature' : 'Pending Previous Tiers'),
          isComplete: isCertified,
          isActive: isForwarded,
          color: const Color(0xFF059669),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report?.commissionerComments != null && report!.commissionerComments!.isNotEmpty)
                _buildCommentBox('Commissioner Directives / Order:', report.commissionerComments!),
              if (isCertified && report?.digitalSignatureHash != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF34D399)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 24, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SOVEREIGN DIGITAL SIGNATURE SEALED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                            ),
                            Text(
                              'SHA-256: ${report!.digitalSignatureHash!}',
                              style: const TextStyle(fontSize: 8, fontFamily: 'monospace', color: Color(0xFF065F46)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isForwarded && role == UserRole.foodSafetyCommissioner) ...[
                TextField(
                  controller: _commCommentsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Commissioner Final Directives / Order Remarks',
                    hintText: 'Order seizure, statutory adjudication, or compliance rectification notice...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                  onPressed: _isActionLoading ? null : _handleCommissionerCertify,
                  icon: _isActionLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified_user, size: 16),
                  label: const Text('CERTIFY & DIGITALLY SIGN OFFICIAL REPORT'),
                ),
              ] else if (isForwarded && role != UserRole.foodSafetyCommissioner) ...[
                const Text(
                  'Dossier forwarded to Food Safety Commissioner for sovereign certification and cryptographic seal.',
                  style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierStepCard({
    required String stepNumber,
    required String roleTitle,
    required String statusText,
    required bool isComplete,
    required bool isActive,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isComplete
              ? color.withValues(alpha: 0.5)
              : (isActive ? color : AppTheme.outline),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isComplete ? color : (isActive ? color.withValues(alpha: 0.2) : AppTheme.outline),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isComplete
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          stepNumber,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isActive ? color : AppTheme.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleTitle,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isComplete ? color : (isActive ? color : AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildCommentBox(String label, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(fontSize: 10, height: 1.3, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionAndDownloadSection(ReportWorkflowRecord? report, String status) {
    final isCertified = status == 'CERTIFIED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCertified) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _isDownloadingPdf ? null : _handleDownloadCertifiedPdf,
            icon: _isDownloadingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf, size: 20),
            label: Text(
              _isDownloadingPdf
                  ? 'STREAMING CERTIFIED STATUTORY PDF...'
                  : 'DOWNLOAD CERTIFIED STATUTORY PDF',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (_savedPdfPath != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Saved: $_savedPdfPath',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.outline),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppTheme.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The sovereign PDF certificate will be generated and signed once Tier 3 Food Safety Commissioner approval is completed.',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
