import 'package:flutter/material.dart';

class AppTheme {
  // Màu sắc chính
  static const Color primaryColor = Color(0xFFFF5722); // Cam đậm
  static const Color secondaryColor = Color(0xFFFFA000); // Vàng cam
  static const Color accentColor = Color(0xFF4CAF50); // Xanh lá

  // Màu background
  static const Color scaffoldBgColor = Color(0xFFF9F9F9); // Trắng ngà nhẹ
  static const Color cardBgColor = Colors.white;

  // Màu text
  static const Color textPrimaryColor = Color(0xFF212121); // Đen gần như
  static const Color textSecondaryColor = Color(0xFF757575); // Xám đậm
  static const Color textLightColor = Color(0xFF9E9E9E); // Xám nhạt

  // Màu status
  static const Color successColor = Color(0xFF4CAF50); // Xanh lá
  static const Color errorColor = Color(0xFFE53935); // Đỏ
  static const Color warningColor = Color(0xFFFFB300); // Vàng cam

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 20),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textSecondaryColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: textLightColor,
  );

  // Branded text style
  static const TextStyle brandTitleStyle = TextStyle(
    fontFamily: 'Lobster',
    fontSize: 28,
    color: primaryColor,
    fontWeight: FontWeight.w400,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primaryColor,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: primaryColor),
    ),
  );

  // Theme data
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBgColor,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    textTheme: TextTheme(
      displayLarge: headingStyle,
      displayMedium: subheadingStyle,
      bodyLarge: bodyStyle,
      bodySmall: captionStyle,
    ),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
  );
}
