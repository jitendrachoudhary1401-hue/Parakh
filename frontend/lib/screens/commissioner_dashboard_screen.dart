import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/compliance_provider.dart';
import '../widgets/action_tile.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_pill.dart';

/// Dedicated Food & Legal Metrology Commissioner Dashboard Screen
/// Exclusively for the Commissioner / Apex Authority:
/// - Executive Header: Dr. V. K. Verma, Food & Legal Metrology Commissioner
/// - Executive Enforcement Metrics: Awaiting e-Sign, Signed Notices (real data only)
/// - Digital Signature & Notice Portal (/commissioner-portal)
/// - Official Statutory Notice Archive (/history)
/// - Statewide Enforcement Analytics
/// - Pending Signature Queue Stream
/// - Strictly NO Field Intake or Nodal Scrutiny features!
class CommissionerDashboardScreen extends StatefulWidget {
  const CommissionerDashboardScreen({super.key});

  @override
  State<CommissionerDashboardScreen> createState() =>
      _CommissionerDashboardScreenState();
}

class _CommissionerDashboardScreenState
    extends State<CommissionerDashboardScreen> {
  int _currentNavIndex = 0;

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
                    Icon(Icons.switch_account,
                        color: Color(0xFF047857), size: 22),
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

    final history = compliance.inspectionHistory;
    final awaitingSignature = history
        .where((e) =>
            e.status == 'verified_accepted' ||
            e.commissionerStatus == 'FORWARDED_FOR_DIGITAL_SIGNATURE')
        .length;
    final signedNotices =
        history.where((e) => e.status == 'signed_notice_issued').length;

    const commColor = Color(0xFF047857);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: commColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.draw, color: commColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commissioner Executive Portal',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Dr. V. K. Verma • Commissioner (Food & LM)',
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
                color: commColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: commColor.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Text(
                    'COMMISSIONER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: commColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 14, color: commColor),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                size: 22, color: commColor),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.marginMain, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Commissioner Executive Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: commColor,
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
                      child: const Icon(Icons.draw, color: Colors.white, size: 28),
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: commColor,
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/commissioner-portal'),
                      child: const Text('PORTAL',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Commissioner Executive Metrics
              Text(
                'EXECUTIVE ENFORCEMENT METRICS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Awaiting e-Sign',
                      value: '$awaitingSignature',
                      subtext: 'From Nodal Verifier',
                      icon: Icons.fingerprint,
                      accentColor: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'Signed Notices',
                      value: '$signedNotices',
                      subtext: 'Legally issued',
                      icon: Icons.mark_email_read_outlined,
                      accentColor: commColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Commissioner Actions Exclusively
              Text(
                'COMMISSIONERATE EXECUTIVE ACTIONS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              ActionTile(
                title: 'Digital Signature & Notice Portal',
                description:
                    'Review scrutinized dossiers forwarded by Nodal Verifiers and apply RSA/SHA-256 e-Sign',
                icon: Icons.draw_outlined,
                primaryColor: commColor,
                badgeText: '$awaitingSignature Awaiting',
                badgeColor: awaitingSignature > 0
                    ? AppTheme.warningContainer
                    : AppTheme.successContainer,
                onTap: () => Navigator.pushNamed(context, '/commissioner-portal'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Official Statutory Notice Archive',
                description:
                    'Inspect signed notices with verification QR codes and cryptographic hashes',
                icon: Icons.picture_as_pdf_outlined,
                primaryColor: AppTheme.primary,
                onTap: () => Navigator.pushNamed(context, '/history'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Statewide Enforcement Analytics',
                description:
                    'Zone-level compliance rates, compounding penalties, and enforcement trends',
                icon: Icons.insights_outlined,
                primaryColor: AppTheme.secondary,
                onTap: () => Navigator.pushNamed(context, '/history'),
              ),
              const SizedBox(height: 24),

              // Awaiting Signature Stream
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DOSSIERS AWAITING COMMISSIONER e-SIGN',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, '/commissioner-portal'),
                    child: const Text(
                      'Open Portal',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: commColor),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              if (awaitingSignature == 0)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified, size: 36, color: commColor),
                        SizedBox(height: 8),
                        Text(
                          'No Dossiers Awaiting Signature',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All forwarded dossiers have been digitally signed.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...history
                    .where((e) =>
                        e.status == 'verified_accepted' ||
                        e.commissionerStatus ==
                            'FORWARDED_FOR_DIGITAL_SIGNATURE')
                    .take(3)
                    .map((record) => _buildSignatureQueueCard(context, record)),
            ],
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
            Navigator.pushNamed(context, '/commissioner-portal');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/history');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: commColor,
        unselectedItemColor: AppTheme.textMuted,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Executive Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint), label: 'e-Sign Portal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined), label: 'Notices'),
        ],
      ),
    );
  }

  Widget _buildSignatureQueueCard(
      BuildContext context, InspectionRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF047857).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.fingerprint,
                color: Color(0xFF047857), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.productName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.storeName} • GTIN: ${record.barcode}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),
                const StatusPill(
                  label: 'ACCEPTED BY NODAL • AWAITING e-SIGN',
                  isCompliant: true,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.draw, size: 20, color: Color(0xFF047857)),
            onPressed: () =>
                Navigator.pushNamed(context, '/commissioner-portal'),
          ),
        ],
      ),
    );
  }
}
