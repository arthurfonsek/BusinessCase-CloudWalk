import 'package:flutter/material.dart';

class RectangularButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const RectangularButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? const Color(0xFFd60000);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    // Ajustar tamanhos baseado na tela
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final padding = isSmallScreen 
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    final iconPadding = isSmallScreen 
        ? const EdgeInsets.all(6)
        : const EdgeInsets.all(8);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: buttonColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: iconPadding,
                decoration: BoxDecoration(
                  color: buttonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: buttonColor,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: buttonColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: isSmallScreen ? 14 : 16,
                color: buttonColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
