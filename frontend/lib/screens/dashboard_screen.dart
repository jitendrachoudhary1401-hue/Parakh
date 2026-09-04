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
    final compliantCount = history.where((e) => e.isCompliant).length + 12;
    final violationCount = history.where((e) => !e.isCompliant).length + 2;

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inspector Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  auth.currentUser?.officialId ?? 'DOCA-INSP-2026',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMain, vertical: 16),
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
                          const SizedBox(height: 4),
                          Text(
                            scan.locationAddress.isNotEmpty &&
                                    scan.locationAddress != 'Acquiring GPS location...'
                                ? scan.locationAddress
                                : (auth.currentUser?.zone ?? 'North Zone (New Delhi Division)'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
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
                      onPressed: () => Navigator.pushNamed(context, '/ar-camera'),
                      child: const Text('SCAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metrics Section
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

              // Quick Actions
              Text(
                'FIELD ACTIONS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              ActionTile(
                title: 'New Inspection & Packaging Scan',
                description: 'Record establishment details then verify commodity & packaging',
                icon: Icons.camera_alt_outlined,
                primaryColor: AppTheme.primary,
                onTap: () => Navigator.pushNamed(context, '/establishment-intake'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Open Food Facts Barcode Lookup',
                description: 'Step 1: Establishment intake -> Step 2: Barcode registry verification',
                icon: Icons.qr_code_scanner,
                primaryColor: AppTheme.secondary,
                onTap: () => Navigator.pushNamed(context, '/establishment-intake'),
              ),
              const SizedBox(height: 10),
              ActionTile(
                title: 'Offline Sync Hub',
                description: 'Manage queued inspections taken without active internet',
                icon: Icons.cloud_sync_outlined,
                primaryColor: AppTheme.secondary,
                badgeText: sync.pendingCount > 0 ? '${sync.pendingCount} Pending' : 'All Synced',
                badgeColor: sync.pendingCount > 0 ? AppTheme.warningContainer : AppTheme.successContainer,
                onTap: () => Navigator.pushNamed(context, '/sync-hub'),
              ),
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
                      compliance.evaluateCompliance(
                        extracted: item.extractedData,
                        gs1: GS1Product(
                          gtin: item.barcode,
                          productName: item.productName,
                          registeredCompany: 'Registered Manufacturer',
                          companyAddress: item.locationAddress,
                          brand: 'Standard Brand',
                          isVerified: true,
                        ),
                        storeName: item.storeName,
                        locationAddress: item.locationAddress,
                      );
                      Navigator.pushNamed(context, '/evidence-report');
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 1) Navigator.pushNamed(context, '/establishment-intake');
          if (index == 2) Navigator.pushNamed(context, '/history');
          if (index == 3) Navigator.pushNamed(context, '/sync-hub');
          if (index == 4) Navigator.pushNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), activeIcon: Icon(Icons.camera_alt), label: 'AR Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Ledger'),
          BottomNavigationBarItem(icon: Icon(Icons.sync_outlined), activeIcon: Icon(Icons.sync), label: 'Sync'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Settings'),
        ],
      ),
    );
  }
}
