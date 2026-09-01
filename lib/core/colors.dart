import 'package:flutter/material.dart';

class AppColors {
  // Milk Blue
  static const Color milkBlue900 = Color(0xFF0F3D66);
  static const Color milkBlue800 = Color(0xFF0F3D66);
  static const Color milkBlue700 = Color(0xFF1660A6);
  static const Color milkBlue600 = Color(0xFF1B7BD6);
  static const Color milkBlue500 = Color(0xFF3B94E8);
  static const Color milkBlue400 = Color(0xFF3B94E8);
  static const Color milkBlue300 = Color(0xFF3B94E8);
  static const Color milkBlue200 = Color(0xFF3B94E8);
  static const Color milkBlue100 = Color(0xFFE4F1FD);
  static const Color milkBlue50 = Color(0xFFF3F9FE);

  // Dairy Green
  static const Color dairyGreen700 = Color(0xFF1F8A4C);
  static const Color dairyGreen600 = Color(0xFF1F8A4C);
  static const Color dairyGreen500 = Color(0xFF2FA85F);
  static const Color dairyGreen300 = Color(0xFF8CD8A7);
  static const Color dairyGreen100 = Color(0xFFE4F7EB);

  // Background / Surface
  static const Color background = Color(0xFFF4F9FE);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Ink (text)
  static const Color ink900 = Color(0xFF152439);
  static const Color ink800 = Color(0xFF152439);
  static const Color ink700 = Color(0xFF3B4A5E);
  static const Color ink600 = Color(0xFF3B4A5E);
  static const Color ink500 = Color(0xFF6B7A8F);
  static const Color ink400 = Color(0xFF6B7A8F);
  static const Color ink300 = Color(0xFFAEBACB);

  // Border
  static const Color border = Color(0xFFE4EBF3);

  // Amber (warning)
  static const Color amber700 = Color(0xFFB4740A);
  static const Color amber600 = Color(0xFFB4740A);
  static const Color amber500 = Color(0xFFF0A82A);
  static const Color amber100 = Color(0xFFFEF3DD);

  // Red (error/pending)
  static const Color red600 = Color(0xFFC23A3A);
  static const Color red500 = Color(0xFFE4534F);
  static const Color red100 = Color(0xFFFBE7E7);

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    colors: [milkBlue700, milkBlue500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [milkBlue900, milkBlue700, milkBlue500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
