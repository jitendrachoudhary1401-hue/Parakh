import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';

/// AR Bounding Box Overlay for live packaging inspection
class ArOverlayBoxWidget extends StatelessWidget {
  final BoundingBox box;

  const ArOverlayBoxWidget({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    final color = box.isCompliant ? AppTheme.success : AppTheme.error;

    return Positioned(
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(2),
          color: color.withValues(alpha: 0.12),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.only(bottomRight: Radius.circular(4)),
            ),
            child: Text(
              '${box.label} (${(box.confidence * 100).toInt()}%)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
