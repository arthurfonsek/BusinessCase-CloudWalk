import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double elevation;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonStyle? style;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
    this.isLoading = false,
    this.isFullWidth = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    // Ajustar tamanhos baseado na plataforma e tamanho da tela
    double buttonHeight = height ?? _getButtonHeight(isSmallScreen, isMediumScreen, isLargeScreen);
    double fontSize = _getFontSize(isSmallScreen, isMediumScreen, isLargeScreen);
    double iconSize = _getIconSize(isSmallScreen, isMediumScreen, isLargeScreen);
    EdgeInsetsGeometry buttonPadding = padding ?? _getButtonPadding(isSmallScreen, isMediumScreen, isLargeScreen);

    Widget buttonChild = isLoading
        ? SizedBox(
            height: iconSize,
            width: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    Widget button = Container(
      width: isFullWidth ? double.infinity : width,
      height: buttonHeight,
      constraints: BoxConstraints(
        minHeight: buttonHeight,
        minWidth: _getMinWidth(isSmallScreen, isMediumScreen, isLargeScreen),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style ??
            ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? const Color(0xFFd60000),
              foregroundColor: textColor ?? Colors.white,
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: elevation,
              shadowColor: backgroundColor?.withOpacity(0.3) ?? const Color(0xFFd60000).withOpacity(0.3),
            ),
        child: buttonChild,
      ),
    );

    // Adicionar animação de toque para melhor UX
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: button,
      ),
    );
  }

  double _getButtonHeight(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge ? 56 : isMedium ? 52 : 48;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge ? 56 : 52;
    } else {
      // Mobile
      return isSmall ? 44 : 48;
    }
  }

  double _getFontSize(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge ? 16 : isMedium ? 15 : 14;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge ? 16 : 15;
    } else {
      // Mobile
      return isSmall ? 14 : 16;
    }
  }

  double _getIconSize(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge ? 24 : isMedium ? 22 : 20;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge ? 24 : 22;
    } else {
      // Mobile
      return isSmall ? 18 : 20;
    }
  }

  EdgeInsetsGeometry _getButtonPadding(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
          : isMedium
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    } else {
      // Mobile
      return isSmall
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
  }

  double _getMinWidth(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge ? 120 : isMedium ? 100 : 80;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge ? 120 : 100;
    } else {
      // Mobile
      return isSmall ? 80 : 100;
    }
  }
}

class ResponsiveIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double borderRadius;
  final double elevation;

  const ResponsiveIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    double buttonSize = size ?? _getButtonSize(isSmallScreen, isMediumScreen, isLargeScreen);
    double iconSize = _getIconSize(isSmallScreen, isMediumScreen, isLargeScreen);

    Widget button = Container(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFFd60000),
          foregroundColor: iconColor ?? Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: elevation,
          shadowColor: backgroundColor?.withOpacity(0.3) ?? const Color(0xFFd60000).withOpacity(0.3),
        ),
        child: Icon(icon, size: iconSize),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }

  double _getButtonSize(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge ? 56 : isMedium ? 52 : 48;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge ? 56 : 52;
    } else {
      // Mobile
      return isSmall ? 44 : 48;
    }
  }

  double _getIconSize(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge ? 24 : isMedium ? 22 : 20;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge ? 24 : 22;
    } else {
      // Mobile
      return isSmall ? 18 : 20;
    }
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;
  final double elevation;
  final Color? shadowColor;
  final Border? border;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 16.0,
    this.elevation = 4.0,
    this.shadowColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    EdgeInsetsGeometry cardPadding = padding ?? _getCardPadding(isSmallScreen, isMediumScreen, isLargeScreen);
    EdgeInsetsGeometry cardMargin = margin ?? _getCardMargin(isSmallScreen, isMediumScreen, isLargeScreen);

    return Container(
      margin: cardMargin,
      padding: cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.grey.withOpacity(0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: child,
    );
  }

  EdgeInsetsGeometry _getCardPadding(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge
          ? const EdgeInsets.all(24)
          : isMedium
              ? const EdgeInsets.all(20)
              : const EdgeInsets.all(16);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge
          ? const EdgeInsets.all(24)
          : const EdgeInsets.all(20);
    } else {
      // Mobile
      return isSmall
          ? const EdgeInsets.all(16)
          : const EdgeInsets.all(20);
    }
  }

  EdgeInsetsGeometry _getCardMargin(bool isSmall, bool isMedium, bool isLarge) {
    if (kIsWeb) {
      return isLarge
          ? const EdgeInsets.all(16)
          : isMedium
              ? const EdgeInsets.all(12)
              : const EdgeInsets.all(8);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return isLarge
          ? const EdgeInsets.all(16)
          : const EdgeInsets.all(12);
    } else {
      // Mobile
      return isSmall
          ? const EdgeInsets.all(8)
          : const EdgeInsets.all(12);
    }
  }
}