import 'package:flutter/material.dart';
import 'responsive_button.dart';

// Enum para tamanhos de botão
enum ButtonSize {
  small,
  medium,
  large,
}

// Widget PrimaryButton que usa ResponsiveButton internamente
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isFullWidth;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.size = ButtonSize.medium,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    // Converter ButtonSize para parâmetros do ResponsiveButton
    double? height;
    double? width;
    
    switch (size) {
      case ButtonSize.small:
        height = 36;
        break;
      case ButtonSize.medium:
        height = 48;
        break;
      case ButtonSize.large:
        height = 56;
        break;
    }

    return ResponsiveButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
      height: height,
      width: width,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }
}
