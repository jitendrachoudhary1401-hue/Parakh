import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Minimalist Status Pill Badge
class StatusPill extends StatelessWidget {
  final String label;
  final bool isCompliant;
  final bool isPending;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    this.isCompliant = true,
    this.isPending = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    if (isPending) {
      bg = AppTheme.warningContainer;
      fg = AppTheme.warning;
      border = AppTheme.warning.withOpacity(0.3);
    } else if (isCompliant) {
      bg = AppTheme.successContainer;
      fg = AppTheme.success;
      border = AppTheme.success.withOpacity(0.3);
    } else {
      bg = AppTheme.errorContainer;
      fg = AppTheme.error;
      border = AppTheme.error.withOpacity(0.3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
