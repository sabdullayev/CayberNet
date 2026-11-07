import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cyber_colors.dart';

class CyberTypography {
  CyberTypography._();

  // Orbitron - Headers & Cyber Title
  static TextStyle headerLarge = GoogleFonts.orbitron(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: CyberColors.textPrimary,
  );

  static TextStyle headerMedium = GoogleFonts.orbitron(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: CyberColors.textPrimary,
  );

  static TextStyle headerSmall = GoogleFonts.orbitron(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: CyberColors.textPrimary,
  );

  // JetBrains Mono - Cyber-Tags, OTPs, Badges & Terminals
  static TextStyle monoBold = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: CyberColors.cyberCyan,
  );

  static TextStyle monoRegular = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: CyberColors.textPrimary,
  );

  static TextStyle monoSmall = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    color: CyberColors.textSecondary,
  );

  // Inter - Body, Inputs & General UI
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: CyberColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: CyberColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: CyberColors.textSecondary,
  );
}
