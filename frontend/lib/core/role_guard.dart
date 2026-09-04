import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';

/// Statutory Role-Based Access Control (RBAC) Guard
/// Enforces strict role isolation per §11/§12 of the statutory specification.
/// If an unauthorized role attempts to access a protected feature/route,
/// this guard displays an official denial alert and navigates back.
class RoleGuard {
  static bool hasAccess(BuildContext context, List<UserRole> allowedRoles) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userRole = auth.currentUser?.role ?? UserRole.inspector;
    return allowedRoles.contains(userRole) || userRole == UserRole.admin;
  }

  static void enforceAccess(
    BuildContext context, {
    required List<UserRole> allowedRoles,
    required String featureTitle,
    required String authorizedRoleName,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userRole = auth.currentUser?.role ?? UserRole.inspector;

      if (!allowedRoles.contains(userRole) && userRole != UserRole.admin) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.error, size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Access Restricted (RBAC)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Current Identity: ${auth.currentUser?.fullName ?? "Enforcement Official"} (${userRole.name.toUpperCase()})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The feature "$featureTitle" is restricted strictly to $authorizedRoleName.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Under the Department of Consumer Affairs statutory mandate, officers may only access features within their authorized jurisdiction.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacementNamed('/dashboard');
                },
                child: const Text('RETURN TO MY DASHBOARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      }
    });
  }
}
