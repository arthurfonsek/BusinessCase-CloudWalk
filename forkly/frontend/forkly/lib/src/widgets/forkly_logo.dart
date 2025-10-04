import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForklyLogo extends StatelessWidget {
  final double? fontSize;
  final Color? color;
  final bool showIcon;
  final double iconSize;

  const ForklyLogo({
    Key? key,
    this.fontSize,
    this.color,
    this.showIcon = true,
    this.iconSize = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? const Color(0xFFd60000);
    final defaultFontSize = fontSize ?? 36;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.restaurant,
            size: iconSize,
            color: defaultColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          'Forkly',
          style: GoogleFonts.poppins(
            fontSize: defaultFontSize,
            fontWeight: FontWeight.w800,
            color: defaultColor,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: defaultColor.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ForklyLogoVertical extends StatelessWidget {
  final double? fontSize;
  final Color? color;
  final bool showIcon;
  final double iconSize;

  const ForklyLogoVertical({
    Key? key,
    this.fontSize,
    this.color,
    this.showIcon = true,
    this.iconSize = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? const Color(0xFFd60000);
    final defaultFontSize = fontSize ?? 36;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.restaurant,
            size: iconSize,
            color: defaultColor,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Forkly',
          style: GoogleFonts.poppins(
            fontSize: defaultFontSize,
            fontWeight: FontWeight.w800,
            color: defaultColor,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: defaultColor.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
