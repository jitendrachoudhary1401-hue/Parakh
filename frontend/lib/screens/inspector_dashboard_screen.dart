import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/compliance_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/action_tile.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_pill.dart';

/// Dedicated Field Inspector Dashboard Screen
/// Exclusively for Field Enforcement Officers:
/// - Real-Time High-Accuracy GPS Jurisdiction (Place Name in Large, small coordinates)
/// - Today's Enforcement Metrics (Compliant: 0, Violations: 0 - Real data only)
/// - New Inspection & Packaging Scan
/// - Commodity Barcode Verification (with live camera)
/// - Offline Sync Hub
/// - Recent Field Inspections Ledger
/// - Role Switcher Modal in AppBar
class InspectorDashboardScreen extends StatefulWidget {
  const InspectorDashboardScreen({super.key});

  @override
  State<InspectorDashboardScreen> createState() => _InspectorDashboardScreenState();
}

class _InspectorDashboardScreenState extends State<InspectorDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScanProvider>(context, listen: false)
          .fetchCurrentLocation(requestIfDenied: true);
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
                    Icon(Icons.switch_account, color: AppTheme.primary, size: 22),
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
    final compliance = Provider.of<ComplianceProvider>(context);
    final sync = Provider.of<SyncProvider>(context);
    final scan = Provider.of<ScanProvider>(context);

    final history = compliance.inspectionHistory;
    final compliantCount = history.where((e) => e.isCompliant).length;
    final violationCount = history.where((e) => !e.isCompliant).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inspector Dashboard',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    auth.currentUser?.officialId ?? 'DOCA-INSP-2026',
                    style: const TextStyle(
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
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Text(
                    'INSPECTOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.primary),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                size: 22, color: AppTheme.primary),
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
              // Welcome Banner with Real-Time Location
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.my_location, size: 12, color: Colors.white70),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'REAL-TIME GPS JURISDICTION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // PLACE NAME IN LARGE
                          Text(
                            scan.placeName.isNotEmpty
                                ? scan.placeName
                                : 'Central Vista, New Delhi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // LATITUDE AND LONGITUDE IN SMALL
                          Text(
                            scan.formattedCoordinates,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Legal Metrology Rules 2011 Active',
                                style: TextStyle(fontSize: 10, color: Colors.white70),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/establishment-intake'),
                      child: const Text('SCAN',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metrics Section (Starts at 0, only real data)
              Text(
                "TODAY'S ENFORCEMENT METRICS",
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Compliant',
                      value: '$compliantCount',
                      subtext: 'Passed all rules',
                      icon: Icons.check_circle_outline,
                      accentColor: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'Violations',
                      value: '$violationCount',
                      subtext: 'Flagged for notice',
                      icon: Icons.gavel_outlined,
                      accentColor: AppTheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Field Inspector Actions Exclusively
              Text(
                'FIELD ENFORCEMENT ACTIONS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              ActionTile(
                title: 'New Inspection & Packaging Scan',
                description:
                    'Record commercial premise details then verify commodity & packaging',
                icon: Icons.camera_alt_outlined,
                primaryColor: AppTheme.primary,
                onTap: () => Navigator.pushNamed(context, '/establishment-intake'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Commodity Barcode Verification',
                description:
                    'Step 1: Commercial premise -> Step 2: Camera barcode scan',
                icon: Icons.qr_code_scanner,
                primaryColor: AppTheme.secondary,
                onTap: () => Navigator.pushNamed(context, '/establishment-intake'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Offline Sync Hub',
                description:
                    'Manage queued inspections taken without active internet',
                icon: Icons.cloud_sync_outlined,
                primaryColor: AppTheme.secondary,
                badgeText: sync.pendingCount > 0
                    ? '${sync.pendingCount} Pending'
                    : 'All Synced',
                badgeColor: sync.pendingCount > 0
                    ? AppTheme.warningContainer
                    : AppTheme.successContainer,
                onTap: () => Navigator.pushNamed(context, '/sync-hub'),
              ),
              const SizedBox(height: 24),

              // Recent Inspections Ledger Stream
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT FIELD INSPECTIONS',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/history'),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              if (history.isEmpty)
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
                        Icon(Icons.inventory_2_outlined,
                            size: 36, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No inspections conducted yet today',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap "New Inspection" to start statutory verification.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...history.take(3).map((record) => _buildInspectionCard(record)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex.clamp(0, 4),
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 0) {
            // Home
          } else if (index == 1) {
            Navigator.pushNamed(context, '/establishment-intake');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/history');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/sync-hub');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined), label: 'Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Ledger'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sync_outlined), label: 'Sync'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildInspectionCard(InspectionRecord record) {
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
              color: record.isCompliant
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              record.isCompliant ? Icons.check_circle : Icons.warning_rounded,
              color: record.isCompliant ? AppTheme.success : AppTheme.error,
              size: 20,
            ),
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
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),
                StatusPill(
                  label: record.status.toUpperCase(),
                  isCompliant: record.isCompliant,
                  isPending: record.status == 'unverified' || record.status == 'pending_nodal_verification',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
