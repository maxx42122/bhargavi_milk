import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Headings — Figtree
  static TextStyle get h1 => GoogleFonts.figtree(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.ink900,
        height: 1.2,
      );
  static TextStyle get h2 => GoogleFonts.figtree(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.ink900,
        height: 1.25,
      );
  static TextStyle get h3 => GoogleFonts.figtree(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink900,
        height: 1.3,
      );
  static TextStyle get h4 => GoogleFonts.figtree(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.ink900,
        height: 1.35,
      );

  // Body — Figtree
  static TextStyle get body => GoogleFonts.figtree(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.ink700,
        height: 1.5,
      );
  static TextStyle get bodyBold => GoogleFonts.figtree(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink900,
        height: 1.5,
      );
  static TextStyle get caption => GoogleFonts.figtree(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.ink500,
        height: 1.4,
      );
  static TextStyle get captionBold => GoogleFonts.figtree(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink700,
        height: 1.4,
      );
  static TextStyle get data => GoogleFonts.figtree(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.ink900,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.4,
      );
  static TextStyle get label => GoogleFonts.figtree(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.ink700,
        letterSpacing: 0.2,
      );
  static TextStyle get overline => GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.ink500,
        letterSpacing: 0.8,
      );
}
