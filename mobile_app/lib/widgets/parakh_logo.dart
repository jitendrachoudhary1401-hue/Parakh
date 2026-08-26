import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme.dart';

/// Minimalist Vector SVG Logo Widget for Project PARAKH
class ParakhLogo extends StatelessWidget {
  final double width;
  final double height;
  final bool showText;
  final bool lightMode;

  const ParakhLogo({
    super.key,
    this.width = 120,
    this.height = 65,
    this.showText = false,
    this.lightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/logo.svg',
          width: width,
          height: height,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => Image.asset(
            'assets/logo.png',
            width: width,
            height: height,
            fit: BoxFit.contain,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'PROJECT PARAKH',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: lightMode ? Colors.white : AppTheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ministry of Consumer Affairs (DoCA)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: lightMode ? Colors.white70 : AppTheme.secondary,
            ),
          ),
        ]
      ],
    );
  }
}
