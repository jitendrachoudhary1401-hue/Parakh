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

/// Stitch Minimalist Inspector Dashboard (Home)
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final compliance = Provider.of<ComplianceProvider>(context);
    final sync = Provider.of<SyncProvider>(context);
    final scan = Provider.of<ScanProvider>(context);

    final history = compliance.inspectionHistory;
    final compliantCount = history.where((e) => e.isCompliant).length;
    final violationCount = history.where((e) => !e.isCompliant).length;

    final user = auth.currentUser;
    final roleTitle = user?.role == UserRole.foodSafetyCommissioner
        ? 'Commissioner Console'
        : (user?.role == UserRole.nodalOfficer
            ? 'Nodal Officer Console'
            : 'Inspector Dashboard');
    final officialIdDisplay =
        user?.officialId ?? user?.email ?? 'DOCA Official';

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    roleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    officialIdDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          IconButton(
            icon: const Icon(Icons.my_location, size: 20, color: AppTheme.primary),
            tooltip: 'Refresh Location',
            onPressed: () => scan.fetchCurrentLocation(requestIfDenied: true),
          ),
          IconButton(
            icon: const Icon(Icons.sync, size: 20, color: AppTheme.secondary),
            tooltip: 'Sync Hub',
            onPressed: () => Navigator.pushNamed(context, '/sync-hub'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 22, color: AppTheme.primary),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => compliance.fetchRemoteInspections(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMain, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role-Specific Welcome Banner
              _buildRoleBanner(context, user?.role, scan, auth),
              const SizedBox(height: 20),

              // Metrics Section
              Text(
                user?.role == UserRole.foodSafetyCommissioner
                    ? 'STATE REGULATORY OVERSIGHT METRICS'
                    : (user?.role == UserRole.nodalOfficer
                        ? 'DISTRICT ADJUDICATION METRICS'
                        : "TODAY'S ENFORCEMENT METRICS"),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              _buildRoleMetrics(context, user?.role, compliantCount, violationCount, history.length),
              const SizedBox(height: 20),

              // Role-Specific Actions
              Text(
                user?.role == UserRole.foodSafetyCommissioner
                    ? 'EXECUTIVE AUDIT ACTIONS'
                    : (user?.role == UserRole.nodalOfficer
                        ? 'ADJUDICATION & ENFORCEMENT ACTIONS'
                        : 'FIELD ACTIONS'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              ..._buildRoleActions(context, user?.role, sync, compliance),
              const SizedBox(height: 24),

              // Recent Inspections Ledger Stream
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT INSPECTIONS',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/history'),
                    child: const Text(
                      'View All Ledger',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.take(4).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return InkWell(
                    onTap: () {
                      compliance.setCurrentInspection(item);
                      Navigator.pushNamed(context, '/verdict');
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.outline, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.isCompliant ? AppTheme.successContainer : AppTheme.errorContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Icon(
                              item.isCompliant ? Icons.check : Icons.warning_amber_rounded,
                              color: item.isCompliant ? AppTheme.success : AppTheme.error,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.storeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusPill(
                                label: item.isCompliant ? 'PASS' : 'VIOLATION',
                                isCompliant: item.isCompliant,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 1) Navigator.pushNamed(context, '/ar-camera');
          if (index == 2) Navigator.pushNamed(context, '/history');
          if (index == 3) Navigator.pushNamed(context, '/sync-hub');
          if (index == 4) Navigator.pushNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'AR Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Ledger'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sync_outlined),
              activeIcon: Icon(Icons.sync),
              label: 'Sync'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildRoleBanner(
      BuildContext context, UserRole? role, ScanProvider scan, AuthProvider auth) {
    final isCommissioner = role == UserRole.foodSafetyCommissioner;
    final isNodal = role == UserRole.nodalOfficer;

    final bannerTitle = isCommissioner
        ? 'STATE APEX REGULATORY OVERSIGHT'
        : (isNodal
            ? 'DISTRICT ADJUDICATION HEADQUARTERS'
            : 'REAL-TIME GPS JURISDICTION');

    final locationDisplay = isCommissioner
        ? (auth.currentUser?.zone ?? 'National & State Enforcement Directorate')
        : (isNodal
            ? (auth.currentUser?.zone ?? 'District Enforcement Division - Central HQ')
            : (scan.locationAddress.isNotEmpty &&
                    scan.locationAddress != 'Acquiring GPS location...'
                ? scan.locationAddress
                : (auth.currentUser?.zone ?? 'North Zone (New Delhi Division)')));

    final subtitle = isCommissioner
        ? 'Statutory Legal Metrology Act, 2009 • Directorate Oversight'
        : (isNodal
            ? 'Supervising Field Officers • Statutory Notice Authority'
            : 'Legal Metrology Rules 2011 Active • Field Operations');

    final buttonText = isCommissioner ? 'AUDIT' : (isNodal ? 'REVIEW' : 'SCAN');
    void handleButtonTap() {
      if (isCommissioner || isNodal) {
        Navigator.pushNamed(context, '/history');
      } else {
        Navigator.pushNamed(context, '/ar-camera');
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCommissioner
            ? const Color(0xFF1E293B)
            : (isNodal ? const Color(0xFF1E3A5F) : AppTheme.primary),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCommissioner
                          ? Icons.account_balance
                          : (isNodal ? Icons.gavel_rounded : Icons.my_location),
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        bannerTitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  locationDisplay,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
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
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isCommissioner
                  ? const Color(0xFF1E293B)
                  : (isNodal ? const Color(0xFF1E3A5F) : AppTheme.primary),
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: handleButtonTap,
            child: Text(buttonText,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleMetrics(BuildContext context, UserRole? role,
      int compliantCount, int violationCount, int totalCount) {
    if (role == UserRole.foodSafetyCommissioner) {
      final passRate =
          totalCount > 0 ? (compliantCount * 100 ~/ totalCount) : 100;
      return Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'Total Inspected',
              value: '$totalCount',
              subtext: 'Statewide audits',
              icon: Icons.fact_check_outlined,
              accentColor: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MetricCard(
              label: 'Compliance',
              value: '$passRate%',
              subtext: 'Passed ratio',
              icon: Icons.verified_outlined,
              accentColor: AppTheme.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MetricCard(
              label: 'Violations',
              value: '$violationCount',
              subtext: 'Flagged actions',
              icon: Icons.warning_amber_rounded,
              accentColor: AppTheme.error,
            ),
          ),
        ],
      );
    }

    if (role == UserRole.nodalOfficer) {
      return Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'Pending Notice',
              value: '$violationCount',
              subtext: 'Requires action',
              icon: Icons.gavel_outlined,
              accentColor: AppTheme.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MetricCard(
              label: 'Compliant',
              value: '$compliantCount',
              subtext: 'Verified sound',
              icon: Icons.check_circle_outline,
              accentColor: AppTheme.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MetricCard(
              label: 'Total Logs',
              value: '$totalCount',
              subtext: 'District ledger',
              icon: Icons.inventory_2_outlined,
              accentColor: AppTheme.secondary,
            ),
          ),
        ],
      );
    }

    return Row(
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
    );
  }

  List<Widget> _buildRoleActions(
      BuildContext context, UserRole? role, SyncProvider sync, ComplianceProvider compliance) {
    if (role == UserRole.foodSafetyCommissioner) {
      return [
        ActionTile(
          title: 'Statewide Statutory Certification Queue',
          description:
              'Review Nodal verified dossiers and attach sovereign digital seal',
          icon: Icons.verified_user_outlined,
          primaryColor: const Color(0xFF059669),
          onTap: () => _showCommissionerCertificationQueue(context, compliance),
        ),
        const SizedBox(height: 10),
        ActionTile(
          title: 'Statewide Enforcement Audit Ledger',
          description:
              'Complete forensic audit trail with SHA-256 blockchain verification',
          icon: Icons.analytics_outlined,
          primaryColor: const Color(0xFF1E293B),
          onTap: () => Navigator.pushNamed(context, '/history'),
        ),
        const SizedBox(height: 10),
        ActionTile(
          title: 'Legal Metrology Gazette & Policy Engine',
          description:
              'Reference active rules: Rule 6(1)(e) MRP, Rule 6(1)(f) Net Qty, Rule 6(1)(d) Date',
          icon: Icons.menu_book_outlined,
          primaryColor: AppTheme.secondary,
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Statutory Enforcement Rules'),
                content: const SingleChildScrollView(
                  child: Text(
                    'Active Regulatory Standards (SIH 2026):\n\n'
                    '1. Legal Metrology (Packaged Commodities) Rules, 2011\n'
                    '   - Rule 6(1)(e): Maximum Retail Price with currency symbol (₹/Rs) and inclusive of all taxes.\n'
                    '   - Rule 6(1)(f): Net quantity declared in standard SI metric units (g, kg, ml, l).\n'
                    '   - Rule 6(1)(d): Month and year of manufacture or pre-packaging.\n'
                    '   - Rule 6(1)(h): Complete grievance officer email and phone contact.\n\n'
                    '2. Digital Evidence Admissibility:\n'
                    '   - Section 65B Indian Evidence Act compliant.\n'
                    '   - Deterministic SHA-256 hashed and verifiable against Hyperledger Fabric.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('DISMISS'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        ActionTile(
          title: 'Officer Sync & Node Health Hub',
          description: 'Monitor subordinate field sync states and MeghRaj persistence',
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
      ];
    }

    if (role == UserRole.nodalOfficer) {
      return [
        ActionTile(
          title: 'Adjudicate Statutory Verification Queue',
          description:
              'Review inspector dossiers, attach legal observations & forward to Commissioner',
          icon: Icons.gavel_outlined,
          primaryColor: const Color(0xFFD97706),
          onTap: () => _showNodalVerificationQueue(context, compliance),
        ),
        const SizedBox(height: 10),
        ActionTile(
          title: 'Field Spot-Check AR Scan',
          description: 'Conduct immediate on-site AR label and font validation',
          icon: Icons.camera_alt_outlined,
          primaryColor: AppTheme.primary,
          onTap: () => Navigator.pushNamed(context, '/ar-camera'),
        ),
        const SizedBox(height: 10),
        ActionTile(
          title: 'Open Food Facts Barcode Lookup',
          description: 'Cross-reference product barcodes against manufacturer registry',
          icon: Icons.qr_code_scanner,
          primaryColor: AppTheme.secondary,
          onTap: () => Navigator.pushNamed(context, '/barcode-scanner'),
        ),
        const SizedBox(height: 10),
        ActionTile(
          title: 'District Offline Sync Hub',
          description: 'Manage queued inspections and synchronization',
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
      ];
    }

    return [
      ActionTile(
        title: 'New AR Packaging Scan',
        description: 'Live camera overlay with green/red AR bounding boxes',
        icon: Icons.camera_alt_outlined,
        primaryColor: AppTheme.primary,
        onTap: () => Navigator.pushNamed(context, '/ar-camera'),
      ),
      const SizedBox(height: 10),
      ActionTile(
        title: 'Open Food Facts Barcode Lookup',
        description: 'Quick barcode reader to verify registered manufacturer',
        icon: Icons.qr_code_scanner,
        primaryColor: AppTheme.secondary,
        onTap: () => Navigator.pushNamed(context, '/barcode-scanner'),
      ),
      const SizedBox(height: 10),
      ActionTile(
        title: 'Offline Sync Hub',
        description: 'Manage queued inspections taken without active internet',
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
    ];
  }

  void _showNodalVerificationQueue(BuildContext context, ComplianceProvider compliance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<ReportWorkflowRecord>>(
          future: compliance.fetchNodalQueue(),
          builder: (context, snapshot) {
            final reports = compliance.nodalQueue;
            final isLoading = snapshot.connectionState == ConnectionState.waiting && reports.isEmpty;

            return Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gavel_rounded, color: Color(0xFFD97706), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Nodal Officer Verification Queue',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 40, color: AppTheme.success),
                            SizedBox(height: 8),
                            Text('All inspector dossiers verified!',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('No reports currently awaiting Nodal review.',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reports.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, i) {
                          final r = reports[i];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'DOSSIER #${r.reportId.substring(0, 8).toUpperCase()}',
                                      style: const TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'AWAITING REVIEW',
                                        style: TextStyle(
                                            fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r.inspectorNotes?.isNotEmpty == true
                                      ? 'Inspector Note: ${r.inspectorNotes}'
                                      : 'Submitted by Field Officer for statutory verification.',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    minimumSize: const Size(double.infinity, 32),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await compliance.loadOrCreateReport(r.inspectionId);
                                    if (context.mounted) {
                                      Navigator.pushNamed(context, '/evidence-report', arguments: r);
                                    }
                                  },
                                  icon: const Icon(Icons.rate_review_outlined, size: 14),
                                  label: const Text('ADJUDICATE & ATTACH STATUTORY COMMENTS',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCommissionerCertificationQueue(BuildContext context, ComplianceProvider compliance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<ReportWorkflowRecord>>(
          future: compliance.fetchCommissionerQueue(),
          builder: (context, snapshot) {
            final reports = compliance.commissionerQueue;
            final isLoading = snapshot.connectionState == ConnectionState.waiting && reports.isEmpty;

            return Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: Color(0xFF059669), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Statewide Certification & Seal Queue',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.verified, size: 40, color: Color(0xFF059669)),
                            SizedBox(height: 8),
                            Text('All forwarded dossiers certified!',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('No reports currently awaiting FSC certification.',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reports.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, i) {
                          final r = reports[i];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'DOSSIER #${r.reportId.substring(0, 8).toUpperCase()}',
                                      style: const TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'AWAITING SOVEREIGN SEAL',
                                        style: TextStyle(
                                            fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r.nodalComments?.isNotEmpty == true
                                      ? 'Nodal Officer Finding: ${r.nodalComments}'
                                      : 'Verified by Zonal Nodal Officer under Section 23/26.',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    minimumSize: const Size(double.infinity, 32),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await compliance.loadOrCreateReport(r.inspectionId);
                                    if (context.mounted) {
                                      Navigator.pushNamed(context, '/evidence-report', arguments: r);
                                    }
                                  },
                                  icon: const Icon(Icons.draw_outlined, size: 14),
                                  label: const Text('CERTIFY & AFFIX DIGITAL SEAL',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
