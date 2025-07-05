import 'package:flutter/material.dart';

class AppTheme {
  // Primary color for the app
  static final Color primaryColor =
      Colors.orange[700] ?? const Color(0xFFE65100);

  // Scaffold background color
  static final Color scaffoldBgColor =
      Colors.grey[100] ?? const Color(0xFFF5F5F5);

  // Secondary color for the app
  static final Color secondaryColor =
      Colors.green[600] ?? const Color(0xFF43A047);

  // Error color
  static const Color errorColor = Color(0xFFE53935);

  // Success color
  static const Color successColor = Color(0xFF4CAF50);

  // Warning color
  static const Color warningColor = Color(0xFFFFC107);

  // Info color
  static const Color infoColor = Color(0xFF2196F3);

  // Card background color
  static const Color cardColor = Colors.white;

  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);

  // Border color
  static final Color borderColor = Colors.grey[300] ?? const Color(0xFFE0E0E0);

  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFFFF9800),
    Color(0xFFE65100),
  ];
  // Shadow
  static BoxShadow boxShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 26), // 0.1 * 255 ≈ 26
    blurRadius: 10,
    offset: const Offset(0, 2),
  );

  // Rating star color
  static const Color ratingColor = Color(0xFFFFC107);

  // Order status colors
  static const Map<String, Color> orderStatusColors = {
    'pending': Color(0xFFFF9800), // Orange
    'processing': Color(0xFF2196F3), // Blue
    'shipping': Color(0xFF9C27B0), // Purple
    'delivered': Color(0xFF4CAF50), // Green
    'cancelled': Color(0xFFE53935), // Red
  };

  // Text styles
  static TextStyle get headingStyle => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get subheadingStyle => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontSize: 16,
        color: textSecondaryColor,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontSize: 14,
        color: textSecondaryColor,
      );
  // Button styles
  static ButtonStyle get primaryButtonStyle => ButtonStyle(
        backgroundColor: WidgetStateProperty.all(primaryColor),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        padding:
            WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 15)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
}
