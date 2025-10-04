import 'package:flutter/material.dart';

enum ButtonSize { small, medium, large }

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;

  const ResponsiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    // Ajustar tamanho baseado na tela
    final effectiveSize = isSmallScreen && size == ButtonSize.large 
        ? ButtonSize.medium 
        : size;

    final padding = _getPadding(effectiveSize);
    final fontSize = _getFontSize(effectiveSize);
    final iconSize = _getIconSize(effectiveSize);

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? Colors.white,
              ),
            ),
          )
        else
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: padding,
          foregroundColor: foregroundColor ?? const Color(0xFFd60000),
          side: BorderSide(
            color: foregroundColor ?? const Color(0xFFd60000),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: padding,
        backgroundColor: backgroundColor ?? const Color(0xFFd60000),
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: buttonChild,
    );
  }

  EdgeInsets _getPadding(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getIconSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

// Alias para compatibilidade
class PrimaryButton extends ResponsiveButton {
  const PrimaryButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          size: size,
          icon: icon,
          isLoading: isLoading,
        );
}

class SecondaryButton extends ResponsiveButton {
  const SecondaryButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          size: size,
          icon: icon,
          isLoading: isLoading,
          isOutlined: true,
        );
}