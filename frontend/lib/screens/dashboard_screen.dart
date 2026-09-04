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

/// Separated Role-Based Dashboard Gateway
/// Dynamically renders the dedicated dashboard matching the active user role:
/// - Field Inspector (Field intake, barcode verification, AR packaging capture, sync)
/// - Nodal Verifier (Scrutiny queue, evidence review, rule assessment, accept/reject decisions)
/// - Food & Legal Metrology Commissioner (Digital signature queue, statutory notices, analytics)
/// - Citizen / Consumer (Product barcode lookup, grievance filing, consumer rights)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

    final role = auth.currentUser?.role ?? UserRole.inspector;

    String appTitle;
    String officialTag;
    String roleBadge;
    Color roleBadgeColor;

    switch (role) {
      case UserRole.nodalOfficer:
        appTitle = 'Nodal Verifier Dashboard';
        officialTag = 'S. K. Sharma • North Zone Desk';
        roleBadge = 'NODAL VERIFIER';
        roleBadgeColor = AppTheme.secondary;
        break;
      case UserRole.commissioner:
        appTitle = 'Commissioner Executive Portal';
        officialTag = 'Dr. V. K. Verma • Commissioner';
        roleBadge = 'COMMISSIONER';
        roleBadgeColor = const Color(0xFF047857);
        break;
      case UserRole.citizen:
        appTitle = 'Citizen Consumer Portal';
        officialTag = 'Project PARAKH Consumer Desk';
        roleBadge = 'CITIZEN';
        roleBadgeColor = AppTheme.warning;
        break;
      case UserRole.admin:
      case UserRole.inspector:
      default:
        appTitle = 'Inspector Dashboard';
        officialTag = auth.currentUser?.officialId ?? 'DOCA-INSP-2026';
        roleBadge = 'INSPECTOR';
        roleBadgeColor = AppTheme.primary;
        break;
    }

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
                  Text(
                    appTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    officialTag,
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
                color: roleBadgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: roleBadgeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(
                    roleBadge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: roleBadgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 14, color: roleBadgeColor),
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
          child: _buildRoleView(context, role, auth, compliance, sync, scan),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, role),
    );
  }

  Widget _buildRoleView(
    BuildContext context,
    UserRole role,
    AuthProvider auth,
    ComplianceProvider compliance,
    SyncProvider sync,
    ScanProvider scan,
  ) {
    switch (role) {
      case UserRole.nodalOfficer:
        return _buildNodalVerifierView(context, compliance);
      case UserRole.commissioner:
        return _buildCommissionerView(context, compliance);
      case UserRole.citizen:
        return _buildCitizenView(context, scan);
      case UserRole.admin:
      case UserRole.inspector:
      default:
        return _buildInspectorView(context, auth, compliance, sync, scan);
    }
  }

  // ==========================================
  // 1. FIELD INSPECTOR VIEW (Isolated Features)
  // ==========================================
  Widget _buildInspectorView(
    BuildContext context,
    AuthProvider auth,
    ComplianceProvider compliance,
    SyncProvider sync,
    ScanProvider scan,
  ) {
    final history = compliance.inspectionHistory;
    final compliantCount = history.where((e) => e.isCompliant).length;
    final violationCount = history.where((e) => !e.isCompliant).length;

    return Column(
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

        // Field Inspector Actions (NO verifier or commissioner actions)
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
    );
  }

  // ==========================================
  // 2. NODAL VERIFIER VIEW (Isolated Features)
  // ==========================================
  Widget _buildNodalVerifierView(
    BuildContext context,
    ComplianceProvider compliance,
  ) {
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

    return Column(
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

        // Nodal Specific Actions
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
      ],
    );
  }

  // ==========================================
  // 3. COMMISSIONER VIEW (Isolated Features)
  // ==========================================
  Widget _buildCommissionerView(
    BuildContext context,
    ComplianceProvider compliance,
  ) {
    final history = compliance.inspectionHistory;
    final awaitingSignature = history
        .where((e) =>
            e.status == 'verified_accepted' ||
            e.commissionerStatus == 'FORWARDED_FOR_DIGITAL_SIGNATURE')
        .length;
    final signedNotices =
        history.where((e) => e.status == 'signed_notice_issued').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Commissioner Executive Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF047857),
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
                  foregroundColor: const Color(0xFF047857),
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, '/commissioner-portal'),
                child: const Text('PORTAL',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
                accentColor: const Color(0xFF047857),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Commissioner Actions
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
          primaryColor: const Color(0xFF047857),
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
      ],
    );
  }

  // ==========================================
  // 4. CITIZEN VIEW (Isolated Features)
  // ==========================================
  Widget _buildCitizenView(
    BuildContext context,
    ScanProvider scan,
  ) {
    return Column(
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

        // Citizen Actions
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
                  type: record.status == 'signed_notice_issued'
                      ? StatusPillType.success
                      : record.status == 'verified_accepted'
                          ? StatusPillType.success
                          : record.status == 'unverified'
                              ? StatusPillType.warning
                              : StatusPillType.neutral,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, UserRole role) {
    if (role == UserRole.nodalOfficer) {
      return BottomNavigationBar(
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
      );
    } else if (role == UserRole.commissioner) {
      return BottomNavigationBar(
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
        selectedItemColor: const Color(0xFF047857),
        unselectedItemColor: AppTheme.textMuted,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Executive Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint), label: 'e-Sign Portal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined), label: 'Notices'),
        ],
      );
    } else if (role == UserRole.citizen) {
      return BottomNavigationBar(
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
      );
    }

    // Default: Field Inspector Navigation
    return BottomNavigationBar(
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
    );
  }
}
