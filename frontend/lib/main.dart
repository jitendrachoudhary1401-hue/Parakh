import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/constants.dart';
import 'core/storage_service.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/compliance_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/ai_review_screen.dart';
import 'screens/ar_camera_screen.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/compliance_verdict_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/evidence_report_screen.dart';
import 'screens/inspection_history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/offline_sync_hub_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.init();
  final apiClient = ApiClient(storage, baseUrl: storage.getCustomApiUrl() ?? AppConstants.defaultApiBaseUrl);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient, storage)),
        ChangeNotifierProvider(create: (_) => ScanProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ComplianceProvider(apiClient, storage)),
        ChangeNotifierProvider(create: (_) => SyncProvider(apiClient, storage)),
      ],
      child: const ParakhMobileApp(),
    ),
  );
}

/// Root Application Widget
class ParakhMobileApp extends StatelessWidget {
  const ParakhMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/ar-camera': (context) => const ArCameraScreen(),
        '/barcode-scanner': (context) => const BarcodeScannerScreen(),
        '/ai-review': (context) => const AiReviewScreen(),
        '/verdict': (context) => const ComplianceVerdictScreen(),
        '/evidence-report': (context) => const EvidenceReportScreen(),
        '/history': (context) => const InspectionHistoryScreen(),
        '/sync-hub': (context) => const OfflineSyncHubScreen(),
        '/profile': (context) => const ProfileSettingsScreen(),
      },
    );
  }
}
