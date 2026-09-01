import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // Headings — Poppins
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.ink900,
    height: 1.2,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.ink900,
    height: 1.25,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.ink900,
    height: 1.3,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.ink900,
    height: 1.35,
  );

  // Body — Inter
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.ink700,
    height: 1.5,
  );
  static const TextStyle bodyBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink900,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.ink500,
    height: 1.4,
  );
  static const TextStyle captionBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.ink700,
    height: 1.4,
  );
  static const TextStyle data = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink900,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.4,
  );
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.ink700,
    letterSpacing: 0.2,
  );
  static const TextStyle overline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.ink500,
    letterSpacing: 0.8,
  );
}
