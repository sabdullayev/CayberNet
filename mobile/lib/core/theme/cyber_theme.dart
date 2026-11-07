import 'package:flutter/material.dart';
import 'cyber_colors.dart';
import 'cyber_typography.dart';

class CyberTheme {
  CyberTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CyberColors.background,
      primaryColor: CyberColors.neonCrimson,
      canvasColor: CyberColors.background,
      cardColor: CyberColors.surface,
      colorScheme: const ColorScheme.dark(
        primary: CyberColors.neonCrimson,
        secondary: CyberColors.cyberCyan,
        tertiary: CyberColors.katanaGold,
        surface: CyberColors.surface,
        error: CyberColors.neonCrimson,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: CyberColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CyberColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: CyberTypography.headerMedium,
        iconTheme: const IconThemeData(color: CyberColors.cyberCyan),
      ),
      dividerTheme: const DividerThemeData(
        color: CyberColors.borderSubtle,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CyberColors.surface,
        contentTextStyle: CyberTypography.monoRegular,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: CyberColors.neonCrimson, width: 1),
        ),
      ),
    );
  }
}
