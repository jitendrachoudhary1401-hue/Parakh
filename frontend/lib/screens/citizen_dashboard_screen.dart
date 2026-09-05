import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/compliance_provider.dart';
import '../widgets/action_tile.dart';
import '../widgets/status_pill.dart';

/// Dedicated Citizen Consumer Dashboard Screen
/// Exclusively for Citizens and Consumers:
/// - Consumer Rights Desk Header (DoCA)
/// - AR Live Packaging Scanner (Real-time AR detection)
/// - Know Your Rights (Legal Metrology Rules 2011 Guide)
/// - Statutory Verified Commodity Reports (Public transparency ledger)
/// - Strictly NO Inspector intake or Nodal/Commissioner signing actions!
class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final compliance = Provider.of<ComplianceProvider>(context, listen: false);
      compliance.fetchCitizenVerifiedReports();
    });
  }

  void _showRoleSwitchModal(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.switch_account, color: AppTheme.warning, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Switch Enforcement Role Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select an official role to access its isolated, dedicated dashboard and features.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                _roleTile(
                  ctx: ctx,
                  auth: auth,
                  role: UserRole.inspector,
                  title: 'Field Enforcement Inspector',
                  subtitle: 'Intake, Barcode Scan, AR Packaging Capture, Sync Hub',
                  icon: Icons.badge_outlined,
                  color: AppTheme.primary,
                ),
                _roleTile(
                  ctx: ctx,
                  auth: auth,
                  role: UserRole.nodalOfficer,
                  title: 'Nodal Verifier Authority',
                  subtitle: 'Scrutiny Queue, Evidence Review, Accept / Reject Decisions',
                  icon: Icons.fact_check_outlined,
                  color: AppTheme.secondary,
                ),
                _roleTile(
                  ctx: ctx,
                  auth: auth,
                  role: UserRole.commissioner,
                  title: 'Legal Metrology Commissioner',
                  subtitle: 'Executive Portal, RSA Digital Signature, Statutory Notices',
                  icon: Icons.gavel_outlined,
                  color: const Color(0xFF047857),
                ),
                _roleTile(
                  ctx: ctx,
                  auth: auth,
                  role: UserRole.citizen,
                  title: 'Citizen Consumer Portal',
                  subtitle: 'Commodity Barcode Lookup, File Non-Compliance Grievance',
                  icon: Icons.person_outline,
                  color: AppTheme.warning,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _roleTile({
    required BuildContext ctx,
    required AuthProvider auth,
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = auth.currentUser?.role == role;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isSelected ? color : AppTheme.borderLight,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? color : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color, size: 20)
            : const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
        onTap: () async {
          Navigator.pop(ctx);
          await auth.switchRole(role);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final compliance = Provider.of<ComplianceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.verified_user,
                  color: AppTheme.warning, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Citizen Consumer Portal',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Department of Consumer Affairs (DoCA)',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Role Perspective Switcher Badge
          InkWell(
            onTap: () => _showRoleSwitchModal(context, auth),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Text(
                    'CITIZEN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down,
                      size: 14, color: AppTheme.warning),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                size: 22, color: AppTheme.warning),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await compliance.fetchCitizenVerifiedReports();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.marginMain, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Citizen Portal Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_outlined,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONSUMER RIGHTS DESK',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Department of Consumer Affairs\nLegal Metrology (Packaged Commodities)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Citizen Action Exclusively: AR Live Scanning Only!
                Text(
                  'CONSUMER AR INSPECTION ACTION',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                ActionTile(
                  title: 'AR Live Packaging Scanner',
                  description:
                      'Point camera at any packaged commodity to inspect statutory declarations, MRP compliance & legal notices in real-time AR',
                  icon: Icons.view_in_ar_rounded,
                  primaryColor: AppTheme.primary,
                  onTap: () => Navigator.pushNamed(context, '/ar-camera'),
                ),
                const SizedBox(height: 10),
                ActionTile(
                  title: 'Know Your Rights (LM Rules 2011 Guide)',
                  description:
                      'Mandatory declarations every packaged commodity in India must carry under law',
                  icon: Icons.gavel_outlined,
                  primaryColor: AppTheme.secondary,
                  onTap: () => Navigator.pushNamed(context, '/evidence-report'),
                ),
                const SizedBox(height: 24),

                // Only Verified Reports visible to Citizen
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STATUTORY VERIFIED COMMODITY REPORTS',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${compliance.citizenVerifiedReports.length} VERIFIED',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (compliance.isLoadingCitizenReports) ...[
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.warning)),
                  ),
                ] else if (compliance.citizenVerifiedReports.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.verified_outlined, size: 36, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No Verified Reports Published Yet',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Only reports officially verified and approved by Nodal Authority or Commissioner appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...compliance.citizenVerifiedReports.map(
                    (report) => _buildVerifiedReportCard(context, report),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex.clamp(0, 2),
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 0) {
            // Home
          } else if (index == 1) {
            // AR Scanner Only
            Navigator.pushNamed(context, '/ar-camera');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.warning,
        unselectedItemColor: AppTheme.textMuted,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.view_in_ar_rounded), label: 'AR Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildVerifiedReportCard(BuildContext context, InspectionRecord report) {
    final serverImageUrl = '${ApiClient.baseUrl}/inspections/${report.id}/image';
    final hasLocalFile = report.imagePath.isNotEmpty && File(report.imagePath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () => _showVerifiedDossierModal(context, report, serverImageUrl, hasLocalFile),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Evidence Thumbnail Preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 54,
                    height: 54,
                    color: const Color(0xFF0F172A),
                    child: hasLocalFile
                        ? Image.file(File(report.imagePath), fit: BoxFit.cover)
                        : Image.network(
                            serverImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.verified,
                              color: AppTheme.success,
                              size: 26,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Report Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.productName.isNotEmpty ? report.productName : 'Verified Packaged Commodity',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${report.storeName} • GTIN: ${report.barcode}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (report.status == 'signed_notice_issued' || report.commissionerStatus.contains('SIGNED')) ...[
                            const StatusPill(
                              label: 'NOTICE ISSUED',
                              isViolation: true,
                            ),
                          ] else ...[
                            const StatusPill(
                              label: 'NODAL VERIFIED',
                              isSuccess: true,
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year}',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVerifiedDossierModal(
    BuildContext context,
    InspectionRecord report,
    String serverImageUrl,
    bool hasLocalFile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, color: AppTheme.success, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Statutory Verification Dossier',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                              Text(
                                'Legal Metrology Enforcement Public Record',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Packaging Evidence Photo Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.photo_camera_outlined, color: Colors.cyanAccent, size: 14),
                                const SizedBox(width: 6),
                                const Text(
                                  'PHOTOMETRIC EVIDENCE CAPTURE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'AR SCAN',
                                    style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 200,
                            color: Colors.black,
                            child: hasLocalFile
                                ? Image.file(File(report.imagePath), fit: BoxFit.contain)
                                : Image.network(
                                    serverImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.verified, color: AppTheme.success, size: 48),
                                    ),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: const Color(0xFF1E293B),
                            child: Text(
                              'Geotag: ${report.latitude.toStringAsFixed(5)}°N, ${report.longitude.toStringAsFixed(5)}°E',
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Statutory Commodity Details
                    _buildModalSectionHeader('COMMODITY DETAILS', Icons.inventory_2_outlined),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Column(
                        children: [
                          _buildModalRow('Product Name', report.productName),
                          _buildModalRow('Barcode (GTIN)', report.barcode),
                          _buildModalRow('Establishment', report.storeName),
                          _buildModalRow('Premises Address', report.locationAddress),
                          _buildModalRow('Inspection Date', '${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year} ${report.timestamp.hour.toString().padLeft(2, '0')}:${report.timestamp.minute.toString().padLeft(2, '0')} IST'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scrutiny Verification & Signatures
                    _buildModalSectionHeader('STATUTORY DETERMINATION', Icons.gavel_outlined),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Column(
                        children: [
                          _buildModalRow('Nodal Verifier', report.extractedData.rawText.isNotEmpty ? 'Nodal Officer S. K. Sharma' : 'Nodal Scrutiny Authority'),
                          _buildModalRow('Scrutiny Status', report.status.toUpperCase()),
                          if (report.verifierComment.isNotEmpty)
                            _buildModalRow('Verifier Comment', report.verifierComment),
                          if (report.blockchainReceipt != null)
                            _buildModalRow('Evidence SHA-256', '${report.blockchainReceipt!.evidenceHash.substring(0, 16)}...'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'CLOSE DOSSIER',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.warning),
        const SizedBox(width: 6),
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

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
