import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get display => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.dmSans(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 12,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      );

  static TextStyle get button => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
        letterSpacing: 1.1,
      );
}
