import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/compliance_provider.dart';
import '../widgets/action_tile.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_pill.dart';

/// Dedicated Nodal Verifier Dashboard Screen
/// Exclusively for Nodal Verification Authorities / Scrutiny Desk:
/// - Official Scrutiny Header: S. K. Sharma (North Zone Review Desk)
/// - Scrutiny Workspace Metrics: Awaiting Scrutiny, Accepted, Denied (real data only)
/// - Field Dossier Scrutiny Desk (/nodal-verifier)
/// - Statutory LM Rules Directory (/evidence-report)
/// - Verified Dossier Audit Ledger (/history)
/// - Pending Scrutiny Queue Preview
/// - Strictly NO Field Intake or Camera Scanning features!
class NodalDashboardScreen extends StatefulWidget {
  const NodalDashboardScreen({super.key});

  @override
  State<NodalDashboardScreen> createState() => _NodalDashboardScreenState();
}

class _NodalDashboardScreenState extends State<NodalDashboardScreen> {
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
                    Icon(Icons.switch_account, color: AppTheme.secondary, size: 22),
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
    final pendingScrutiny = history
        .where((e) =>
            e.status == 'unverified' ||
            e.status == 'pending_nodal_verification')
        .length;
    final acceptedCount =
        history.where((e) => e.status == 'verified_accepted').length;
    final rejectedCount =
        history.where((e) => e.status == 'verified_rejected').length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.fact_check, color: AppTheme.secondary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nodal Verifier Dashboard',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'S. K. Sharma • North Zone Review Desk',
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
                color: AppTheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Text(
                    'NODAL VERIFIER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.secondary),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                size: 22, color: AppTheme.secondary),
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
              // Nodal Authority Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
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
                      child: const Icon(Icons.fact_check,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NODAL SCRUTINY AUTHORITY',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Officer: S. K. Sharma (North Zone)\nLegal Metrology Enforcement Review',
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
                        foregroundColor: AppTheme.secondary,
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/nodal-verifier'),
                      child: const Text('QUEUE',
                          style:
                              TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Scrutiny Metrics
              Text(
                'SCRUTINY WORKSPACE METRICS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Awaiting Scrutiny',
                      value: '$pendingScrutiny',
                      subtext: 'Pending review',
                      icon: Icons.pending_actions,
                      accentColor: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'Accepted',
                      value: '$acceptedCount',
                      subtext: 'To Commissioner',
                      icon: Icons.verified_outlined,
                      accentColor: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'Denied',
                      value: '$rejectedCount',
                      subtext: 'Rejected dossiers',
                      icon: Icons.cancel_outlined,
                      accentColor: AppTheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nodal Specific Actions Exclusively
              Text(
                'VERIFICATION ACTIONS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              ActionTile(
                title: 'Field Dossier Scrutiny Desk',
                description:
                    'Examine packaging photos, OCR extracts, and rule violations submitted by inspectors',
                icon: Icons.rate_review_outlined,
                primaryColor: AppTheme.secondary,
                badgeText: '$pendingScrutiny Pending',
                badgeColor: pendingScrutiny > 0
                    ? AppTheme.warningContainer
                    : AppTheme.successContainer,
                onTap: () => Navigator.pushNamed(context, '/nodal-verifier'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Statutory LM Rules Directory',
                description:
                    'Review Legal Metrology (Packaged Commodities) Rules, 2011 compliance mandates',
                icon: Icons.menu_book_outlined,
                primaryColor: AppTheme.primary,
                onTap: () => Navigator.pushNamed(context, '/evidence-report'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Verified Dossier Audit Ledger',
                description:
                    'Browse all historical scrutiny decisions with timestamps and remarks',
                icon: Icons.history_edu_outlined,
                primaryColor: AppTheme.secondary,
                onTap: () => Navigator.pushNamed(context, '/history'),
              ),
              const SizedBox(height: 24),

              // Pending Scrutiny Queue Stream
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DOSSIERS AWAITING NODAL SCRUTINY',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/nodal-verifier'),
                    child: const Text(
                      'Open Queue',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              if (pendingScrutiny == 0)
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
                        Icon(Icons.check_circle_outline,
                            size: 36, color: AppTheme.success),
                        SizedBox(height: 8),
                        Text(
                          'Scrutiny Queue is Clear',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'No pending field dossiers awaiting verification.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...history
                    .where((e) =>
                        e.status == 'unverified' ||
                        e.status == 'pending_nodal_verification')
                    .take(3)
                    .map((record) => _buildDossierCard(context, record)),
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
            Navigator.pushNamed(context, '/nodal-verifier');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/history');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.secondary,
        unselectedItemColor: AppTheme.textMuted,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined), label: 'Scrutiny Desk'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Audit Log'),
        ],
      ),
    );
  }

  Widget _buildDossierCard(BuildContext context, InspectionRecord record) {
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
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.hourglass_top, color: AppTheme.warning, size: 20),
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
                  label: 'AWAITING SCRUTINY',
                  isPending: true,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.secondary),
            onPressed: () => Navigator.pushNamed(context, '/nodal-verifier'),
          ),
        ],
      ),
    );
  }
}
