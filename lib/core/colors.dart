import 'package:flutter/material.dart';

class AppColors {
  // --- Lending Journey Theme Tokens ---
  static const Color primaryBlue = Color(0xFF0047FF); // --lending-journey-primary-blue: #0047FF
  static const Color darkNavy = Color(0xFF1A1F4E);    // --lending-journey-dark-navy: #1A1F4E
  static const Color footerNavy = Color(0xFF003087);  // --lending-journey-footer-navy: #003087
  static const Color gradientStart = Color(0xFF0047FF); // --lending-journey-gradient-start: #0047FF
  static const Color gradientEnd = Color(0xFF0028B5);   // --lending-journey-gradient-end: #0028B5
  static const Color linkLight = Color(0xFFB7E2FF);     // --lending-journey-link-light: #B7E2FF

  // Text tokens
  static const Color textPrimary = Color(0xFF1C2536);   // --lending-journey-text-primary: #1C2536
  static const Color textSecondary = Color(0xFF4A5263); // --lending-journey-text-secondary: #4A5263
  static const Color textMuted = Color(0xFF9BA1AE);     // --lending-journey-text-muted: #9BA1AE

  // Surface & Borders
  static const Color borderLight = Color(0xFFE7EAF0);   // --lending-journey-border-light: #E7EAF0
  static const Color bgPage = Color(0xFFF5F6F8);        // --lending-journey-bg-page: #F5F6F8
  static const Color white = Color(0xFFFFFFFF);         // --lending-journey-white: #FFFFFF

  // Radii
  static const double cardRadius = 20.0;  // --lending-journey-radius-card: 20px
  static const double innerRadius = 16.0; // --lending-journey-radius-inner: 16px

  // Milk Blue Color Scale (Harmonized with #0047FF & #1A1F4E)
  static const Color milkBlue900 = Color(0xFF1A1F4E); // Dark Navy
  static const Color milkBlue800 = Color(0xFF003087); // Deep Royal Navy
  static const Color milkBlue700 = Color(0xFF0028B5); // Gradient End Blue
  static const Color milkBlue600 = Color(0xFF0047FF); // Primary Electric Blue
  static const Color milkBlue500 = Color(0xFF2E6BFF);
  static const Color milkBlue400 = Color(0xFF5C8EFF);
  static const Color milkBlue300 = Color(0xFF8AB2FF);
  static const Color milkBlue200 = Color(0xFFB7E2FF); // Link Light
  static const Color milkBlue100 = Color(0xFFE5EFFF);
  static const Color milkBlue50 = Color(0xFFF0F5FF);

  // Dairy Green (Fresh emerald green accents)
  static const Color dairyGreen800 = Color(0xFF065F46);
  static const Color dairyGreen700 = Color(0xFF0E7A3E);
  static const Color dairyGreen600 = Color(0xFF169E53);
  static const Color dairyGreen500 = Color(0xFF22C55E);
  static const Color dairyGreen300 = Color(0xFF86EFAC);
  static const Color dairyGreen100 = Color(0xFFDCFCE7);
  static const Color dairyGreen50 = Color(0xFFF0FDF4);

  // Background / Surface
  static const Color background = Color(0xFFF5F6F8);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF8FAFC);

  // Ink (text) mapped to theme tokens
  static const Color ink900 = Color(0xFF1C2536); // Primary Text #1C2536
  static const Color ink800 = Color(0xFF1C2536);
  static const Color ink700 = Color(0xFF4A5263); // Secondary Text #4A5263
  static const Color ink600 = Color(0xFF4A5263);
  static const Color ink500 = Color(0xFF9BA1AE); // Muted Text #9BA1AE
  static const Color ink400 = Color(0xFF9BA1AE);
  static const Color ink300 = Color(0xFFCAD0DB);
  static const Color ink200 = Color(0xFFE2E8F0);
  static const Color ink100 = Color(0xFFF1F5F9);
  static const Color ink50 = Color(0xFFF8FAFC);

  // Border mapped to borderLight
  static const Color border = Color(0xFFE7EAF0); // #E7EAF0

  // Amber (warning)
  static const Color amber900 = Color(0xFF78350F);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber50 = Color(0xFFFFFBEB);

  // Red (error/pending)
  static const Color red800 = Color(0xFF991B1B);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red400 = Color(0xFFF87171);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red50 = Color(0xFFFEF2F2);

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    colors: [primaryBlue, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [darkNavy, footerNavy, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [darkNavy, footerNavy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
