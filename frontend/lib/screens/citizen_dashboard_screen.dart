import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../widgets/action_tile.dart';

/// Dedicated Citizen Consumer Dashboard Screen
/// Exclusively for Citizens and Consumers:
/// - Consumer Rights Desk Header (DoCA)
/// - Verify Commodity Barcode (Registry lookup)
/// - Report Non-Compliant Commodity (Grievance intake)
/// - Know Your Rights (Legal Metrology Rules 2011 Guide)
/// - Strictly NO Field Intake, Nodal Scrutiny, or Commissioner e-Sign features!
class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
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
        onTap: () {
          auth.switchRole(role);
          Navigator.pop(ctx);
          Navigator.pushReplacementNamed(context, '/dashboard');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

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
        child: SingleChildScrollView(
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

              // Citizen Actions Exclusively
              Text(
                'CONSUMER EMPOWERMENT ACTIONS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              ActionTile(
                title: 'Verify Commodity Barcode',
                description:
                    'Scan or enter product barcode to verify MRP, net weight, and manufacturer against official registry',
                icon: Icons.qr_code_scanner,
                primaryColor: AppTheme.primary,
                onTap: () => Navigator.pushNamed(context, '/barcode-scanner'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Report Non-Compliant Commodity',
                description:
                    'File grievance for overcharging over MRP, missing date of mfg, or incorrect declarations',
                icon: Icons.report_problem_outlined,
                primaryColor: AppTheme.error,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Consumer Grievance Intake: Please scan product barcode to initiate report.'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                  Navigator.pushNamed(context, '/barcode-scanner');
                },
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
            Navigator.pushNamed(context, '/barcode-scanner');
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
              icon: Icon(Icons.qr_code_scanner), label: 'Scan Product'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
