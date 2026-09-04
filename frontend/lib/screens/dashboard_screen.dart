import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'citizen_dashboard_screen.dart';
import 'commissioner_dashboard_screen.dart';
import 'inspector_dashboard_screen.dart';
import 'nodal_dashboard_screen.dart';

/// Separated Role-Based Dashboard Gateway Router
/// Dynamically dispatches to the dedicated, fully isolated dashboard screen
/// matching the active authenticated user role:
/// - UserRole.inspector: InspectorDashboardScreen
/// - UserRole.nodalOfficer: NodalDashboardScreen
/// - UserRole.commissioner: CommissionerDashboardScreen
/// - UserRole.citizen: CitizenDashboardScreen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final role = auth.currentUser?.role ?? UserRole.inspector;

    switch (role) {
      case UserRole.nodalOfficer:
        return const NodalDashboardScreen();
      case UserRole.commissioner:
        return const CommissionerDashboardScreen();
      case UserRole.citizen:
        return const CitizenDashboardScreen();
      case UserRole.admin:
      case UserRole.inspector:
        return const InspectorDashboardScreen();
    }
  }
}
