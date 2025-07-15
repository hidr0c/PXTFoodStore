// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

// Extension to add withValues method to Color class
extension ColorExtension on Color {
  Color withValues({int? red, int? green, int? blue, int? alpha}) {
    return Color.fromARGB(
      alpha ?? this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}

class AppTheme {
  // Primary color for the app - Brown color
  static final Color primaryColor = const Color(0xFF8B5A2B);

  // Scaffold background color - Light cream
  static final Color scaffoldBgColor = const Color(0xFFFAF5EB);

  // Secondary color for the app - Lighter brown
  static final Color secondaryColor = const Color(0xFFB88A5F);

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

  // Gradient colors - Brown gradient
  static const List<Color> primaryGradient = [
    Color(0xFFB88A5F), // Lighter brown
    Color(0xFF8B5A2B), // Darker brown
  ];
  // Shadows with various intensities
  static BoxShadow boxShadowNone = BoxShadow(
    color: Colors.transparent,
    blurRadius: 0,
    offset: const Offset(0, 0),
  );

  static BoxShadow boxShadowLight = BoxShadow(
    color: Colors.black.withValues(alpha: 10), // 0.04 * 255 ≈ 10
    blurRadius: 4,
    offset: const Offset(0, 1),
  );

  static BoxShadow boxShadowMedium = BoxShadow(
    color: Colors.black.withValues(alpha: 18), // 0.07 * 255 ≈ 18
    blurRadius: 6,
    offset: const Offset(0, 2),
  );

  static BoxShadow boxShadow = BoxShadow(
    // Legacy shadow (maintained for backward compatibility)
    color: Colors.black.withValues(alpha: 26), // 0.1 * 255 ≈ 26
    blurRadius: 8, // Giảm từ 10 xuống 8
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

  // Responsive spacing values
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // Responsive border radius
  static const double borderRadiusXS = 4.0;
  static const double borderRadiusSM = 8.0;
  static const double borderRadiusMD = 12.0;
  static const double borderRadiusLG = 16.0;
  static const double borderRadiusXL = 24.0;

  // Responsive elevations
  static const double elevationNone = 0.0;
  static const double elevationXS = 1.0;
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;

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
      ); // Button styles
  static ButtonStyle get primaryButtonStyle => ButtonStyle(
        backgroundColor: MaterialStateProperty.all(primaryColor),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        padding:
            MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 15)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
}
