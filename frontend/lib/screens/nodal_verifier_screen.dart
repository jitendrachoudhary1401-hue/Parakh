import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/role_guard.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/compliance_provider.dart';

/// Nodal Verifier Portal Screen
/// Allows Nodal Officers to scrutinize field inspection dossiers,
/// inspect evidence photos & OCR findings, add official comments,
/// and either "Accept & Send to Commissioner" or "Deny & Reject".
class NodalVerifierScreen extends StatefulWidget {
  final String? initialInspectionId;

  const NodalVerifierScreen({super.key, this.initialInspectionId});

  @override
  State<NodalVerifierScreen> createState() => _NodalVerifierScreenState();
}

class _NodalVerifierScreenState extends State<NodalVerifierScreen> {
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  List<InspectionRecord> _pendingDossiers = [];
  InspectionRecord? _selectedDossier;

  @override
  void initState() {
    super.initState();
    RoleGuard.enforceAccess(
      context,
      allowedRoles: [UserRole.nodalOfficer, UserRole.admin],
      featureTitle: 'Field Dossier Scrutiny Desk',
      authorizedRoleName: 'Nodal Verifier Authority (Nodal Officers)',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingDossiers();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingDossiers() async {
    setState(() => _isLoading = true);
    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final list = await compliance.fetchPendingNodalInspections();

    setState(() {
      _pendingDossiers = list;
      if (widget.initialInspectionId != null) {
        _selectedDossier = list.firstWhere(
          (d) => d.id == widget.initialInspectionId,
          orElse: () => compliance.currentInspection ?? (list.isNotEmpty ? list.first : null as dynamic),
        );
      } else if (compliance.currentInspection != null) {
        _selectedDossier = compliance.currentInspection;
      } else if (list.isNotEmpty) {
        _selectedDossier = list.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _handleDecision(String decision) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDossier == null) return;

    final compliance = Provider.of<ComplianceProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final verifierName = auth.currentUser?.fullName ?? 'Nodal Officer S. K. Sharma';

    setState(() => _isLoading = true);

    final success = await compliance.submitNodalDecision(
      inspectionId: _selectedDossier!.id,
      decision: decision,
      comment: _commentController.text.trim(),
      verifierName: verifierName,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      final isAccept = decision.toUpperCase() == 'ACCEPT';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAccept
                ? 'Dossier ACCEPTED & Forwarded to Commissioner for Digital Signature!'
                : 'Dossier DENIED & REJECTED by Nodal Authority.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: isAccept ? AppTheme.success : AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );

      // Refresh list
      await _loadPendingDossiers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final compliance = Provider.of<ComplianceProvider>(context);

    final dossier = _selectedDossier ?? compliance.currentInspection;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nodal Verifier Authority',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '${auth.currentUser?.fullName ?? "Nodal Officer S. K. Sharma"} • Scrutiny Division',
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Queue',
            onPressed: _loadPendingDossiers,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.marginMain),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gavel, color: AppTheme.primary, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'STATUTORY SCRUTINY PROTOCOL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Review field inspection reports, packaging evidence photos, and statutory violations prior to Commissioner digital signing.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textPrimary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dossier Selector (if multiple pending)
                      if (_pendingDossiers.length > 1) ...[
                        Text('SELECT DOSSIER FOR REVIEW', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.outline),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedDossier?.id,
                              items: _pendingDossiers.map((d) {
                                return DropdownMenuItem<String>(
                                  value: d.id,
                                  child: Text(
                                    '${d.productName} • ${d.storeName} (${d.status})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedDossier = _pendingDossiers.firstWhere((e) => e.id == val);
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (dossier == null) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.outline),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined, size: 40, color: AppTheme.textMuted),
                                SizedBox(height: 10),
                                Text(
                                  'No dossiers currently awaiting verification.',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // 1. Product Details Card
                        _buildSectionHeader('1. PRODUCT & COMMODITY IDENTIFICATION', Icons.inventory_2_outlined),
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
                                children: [
                                  Expanded(
                                    child: Text(
                                      dossier.productName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dossier.status.toLowerCase() == 'unverified'
                                          ? AppTheme.warningContainer
                                          : (dossier.status.toLowerCase().contains('accepted')
                                              ? AppTheme.successContainer
                                              : AppTheme.errorContainer),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      dossier.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: dossier.status.toLowerCase() == 'unverified'
                                            ? AppTheme.warning
                                            : (dossier.status.toLowerCase().contains('accepted')
                                                ? AppTheme.success
                                                : AppTheme.error),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('Barcode / GTIN', dossier.barcode.isNotEmpty ? dossier.barcode : 'GTIN-Unspecified'),
                              _buildInfoRow('Declared MRP', dossier.extractedData.mrp.isNotEmpty ? dossier.extractedData.mrp : '₹ 0.00'),
                              _buildInfoRow('Net Quantity', dossier.extractedData.netQuantity.isNotEmpty ? dossier.extractedData.netQuantity : 'Not Detected'),
                              _buildInfoRow('Mfg / Pkg Date', dossier.extractedData.mfgDate.isNotEmpty ? dossier.extractedData.mfgDate : 'Not Detected'),
                              _buildInfoRow('Manufacturer', dossier.extractedData.manufacturerName.isNotEmpty ? dossier.extractedData.manufacturerName : 'Open Food Facts Registered'),
                              _buildInfoRow('Consumer Care', dossier.extractedData.consumerCarePhone.isNotEmpty ? dossier.extractedData.consumerCarePhone : 'None Detected'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Establishment Intake Details Card
                        _buildSectionHeader('2. ESTABLISHMENT & GEOTAG INTAKE', Icons.store_outlined),
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
                              _buildInfoRow('Shop Name', dossier.storeName.isNotEmpty ? dossier.storeName : 'Unspecified Establishment'),
                              _buildInfoRow('Shop Owner', dossier.shopOwnerName.isNotEmpty ? dossier.shopOwnerName : 'Owner Name on Record'),
                              _buildInfoRow('Premises Address', dossier.locationAddress.isNotEmpty ? dossier.locationAddress : 'Jurisdiction Location'),
                              _buildInfoRow('GPS Coordinates', '${dossier.latitude.toStringAsFixed(6)}, ${dossier.longitude.toStringAsFixed(6)} (Fused High-Accuracy)'),
                              _buildInfoRow('Inspection Timestamp', '${dossier.timestamp.day}/${dossier.timestamp.month}/${dossier.timestamp.year} ${dossier.timestamp.hour.toString().padLeft(2, '0')}:${dossier.timestamp.minute.toString().padLeft(2, '0')} IST'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Packaging Evidence & Inspector Observations
                        _buildSectionHeader('3. INSPECTOR EVIDENCE & REMARKS', Icons.photo_library_outlined),
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
                              const Text('Field Observations / Comments:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                dossier.inspectorRemarks.isNotEmpty ? dossier.inspectorRemarks : 'No remarks provided by inspector.',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              if (dossier.violations.isNotEmpty) ...[
                                const Text('Statutory Violations Flagged:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.error)),
                                const SizedBox(height: 6),
                                ...dossier.violations.map((v) => Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorContainer.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.error),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${v.ruleCode}: ${v.ruleName}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ] else ...[
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 16, color: AppTheme.success),
                                    SizedBox(width: 8),
                                    Text('Zero computer rule violations flagged.', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                              if (dossier.imagePath.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text('Packaging Photo Evidence:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  child: Image.network(
                                    dossier.imagePath,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Text('Evidence image attached locally by field inspector', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Verifier Comment Box
                        _buildSectionHeader('4. VERIFIER EVALUATION & SCRUTINY COMMENTS', Icons.edit_note),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter official statutory verification remarks, compounding directives, or rejection reasons...',
                            hintStyle: const TextStyle(fontSize: 12),
                            filled: true,
                            fillColor: AppTheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: AppTheme.outline),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Mandatory: Verifier must add comments before making a determination.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // If already verified, show outcome badge
                        if (dossier.status.toLowerCase().contains('accepted') || dossier.status.toLowerCase().contains('rejected')) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: dossier.status.toLowerCase().contains('accepted')
                                  ? AppTheme.successContainer.withValues(alpha: 0.6)
                                  : AppTheme.errorContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(
                                color: dossier.status.toLowerCase().contains('accepted')
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      dossier.status.toLowerCase().contains('accepted') ? Icons.verified : Icons.cancel,
                                      color: dossier.status.toLowerCase().contains('accepted') ? AppTheme.success : AppTheme.error,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        dossier.status.toLowerCase().contains('accepted')
                                            ? 'VERIFIED & FORWARDED TO COMMISSIONER'
                                            : 'VERIFIED & REJECTED',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: dossier.status.toLowerCase().contains('accepted') ? AppTheme.success : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (dossier.verifierComment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Verifier Remarks: "${dossier.verifierComment}"',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                ],
                                if (dossier.commissionerStatus.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Commissioner Status: ${dossier.commissionerStatus}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Action Decision Buttons:
                        // 1. Accept and send to commissioner
                        // 2. Deny and reject button
                        Row(
                          children: [
                            // Button: Deny and Reject
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.error,
                                  side: const BorderSide(color: AppTheme.error, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                ),
                                icon: const Icon(Icons.block, size: 18),
                                label: const Text(
                                  'DENY & REJECT',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                                onPressed: _isLoading ? null : () => _handleDecision('REJECT'),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Button: Accept and Send to Commissioner
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 18),
                                label: const Text(
                                  'ACCEPT & SEND TO COMMISSIONER',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                                onPressed: _isLoading ? null : () => _handleDecision('ACCEPT'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
