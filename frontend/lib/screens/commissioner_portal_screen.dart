import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/role_guard.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/compliance_provider.dart';

/// Executive Commissioner Screen: Digital Signature & Statutory Notice Portal
class CommissionerPortalScreen extends StatefulWidget {
  const CommissionerPortalScreen({super.key});

  @override
  State<CommissionerPortalScreen> createState() =>
      _CommissionerPortalScreenState();
}

class _CommissionerPortalScreenState extends State<CommissionerPortalScreen> {
  final _remarksController = TextEditingController(
    text:
        'Statutory digital signature applied under Rule 32 of Legal Metrology (Packaged Commodities) Rules, 2011. Notice issued.',
  );
  InspectionRecord? _selectedRecord;
  List<InspectionRecord> _pendingRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    RoleGuard.enforceAccess(
      context,
      allowedRoles: [UserRole.commissioner, UserRole.admin],
      featureTitle: 'Digital Signature & Notice Portal',
      authorizedRoleName: 'Legal Metrology Commissioner',
    );
    _loadPending();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final list = await compliance.fetchPendingCommissionerInspections();
    if (mounted) {
      setState(() {
        _pendingRecords = list;
        if (list.isNotEmpty && _selectedRecord == null) {
          _selectedRecord = list.first;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _applyDigitalSignature() async {
    if (_selectedRecord == null) return;
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);

    final success = await compliance.submitCommissionerSignature(
      inspectionId: _selectedRecord!.id,
      commissionerName: 'Dr. V. K. Verma (Food & Legal Metrology Commissioner)',
      remarks: _remarksController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: AppTheme.success, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Digital Signature Applied',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statutory Enforcement Notice has been cryptographically signed with RSA-2048 / SHA-256 e-Sign and sealed in the evidence chain.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Notice Ref: DOCA/LM/2026/${_selectedRecord!.id.substring(0, 8).toUpperCase()}\nSignatory: Dr. V. K. Verma\nAuthority: Food & Legal Metrology Commissioner',
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _loadPending();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(compliance.statusMessage ??
              'Failed to apply digital signature'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Commissioner Digital Signature Portal'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPending,
            tooltip: 'Refresh Queue',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined,
                          size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No Forwarded Dossiers Awaiting Signature',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'All scrutinized dossiers from Nodal Verifiers have been signed.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.marginMain),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Commissioner Authority Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.draw,
                                    color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DR. V. K. VERMA',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Food & Legal Metrology Commissioner\nNational Capital Territory of Delhi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_pendingRecords.length} Awaiting',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Queue Selector Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FORWARDED DOSSIERS AWAITING SIGNATURE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<InspectionRecord>(
                                value: _selectedRecord,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(),
                                ),
                                items: _pendingRecords.map((r) {
                                  return DropdownMenuItem<InspectionRecord>(
                                    value: r,
                                    child: Text(
                                      '${r.productName} • ${r.storeName}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedRecord = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_selectedRecord != null) ...[
                          // Nodal Endorsement Badge
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.successContainer.withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(
                                  color: AppTheme.success.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.verified,
                                        color: AppTheme.success, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'NODAL VERIFIER SCRUTINY ENDORSEMENT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.success,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedRecord!.verifierComment.isNotEmpty
                                      ? '"${_selectedRecord!.verifierComment}"'
                                      : '"Recommended for statutory notice by Nodal Verifier."',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Scrutinized by: Nodal Officer S. K. Sharma (North Zone)',
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dossier Details
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CASE DETAILS & STATUTORY FINDINGS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Divider(height: 20),
                                Text(
                                  _selectedRecord!.productName,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Establishment: ${_selectedRecord!.storeName} (${_selectedRecord!.shopOwnerName.isNotEmpty ? _selectedRecord!.shopOwnerName : "Proprietor"})',
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Address: ${_selectedRecord!.locationAddress}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'GTIN Barcode: ${_selectedRecord!.barcode}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700),
                                ),
                                if (_selectedRecord!.violations.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Flagged Statutory Violations:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.error),
                                  ),
                                  const SizedBox(height: 6),
                                  ..._selectedRecord!.violations.map((v) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.arrow_right,
                                                size: 16, color: AppTheme.error),
                                            Expanded(
                                              child: Text(
                                                '${v.ruleCode}: ${v.description}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.error,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Commissioner Remarks Field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'COMMISSIONER STATUTORY DIRECTIVE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _remarksController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText:
                                        'Enter directive or compounding terms...',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action: Apply Digital Signature
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                            onPressed: _applyDigitalSignature,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fingerprint, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'APPLY DIGITAL SIGNATURE & ISSUE NOTICE',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                ),
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
