import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class TeamfitColors {
  // Coral (primary brand)
  static const coral50 = Color(0xFFFFF3F0);
  static const coral100 = Color(0xFFFFDFD8);
  static const coral200 = Color(0xFFFFBCAD);
  static const coral300 = Color(0xFFFF9077);
  static const coral400 = Color(0xFFFF6B4A);
  static const coral500 = Color(0xFFFF4A2E);
  static const coral600 = Color(0xFFE13114);
  static const coral700 = Color(0xFFAD2410);

  // Sand
  static const sand50 = Color(0xFFFFF9F7);
  static const sand100 = Color(0xFFFBF0EC);
  static const sand200 = Color(0xFFF2E2DC);

  // Ink
  static const ink950 = Color(0xFF05070F);
  static const ink900 = Color(0xFF0A0F1E);
  static const ink800 = Color(0xFF111931);
  static const ink700 = Color(0xFF1B2646);
  static const ink600 = Color(0xFF2A3862);
  static const ink500 = Color(0xFF465686);
  static const ink400 = Color(0xFF6E7DA6);
  static const ink300 = Color(0xFF9BA7C4);
  static const ink200 = Color(0xFFC7CEDE);
  static const ink100 = Color(0xFFE5E9F1);
  static const ink50 = Color(0xFFF4F6FA);
  static const white = Color(0xFFFFFFFF);

  // Cyan (accent)
  static const cyan50 = Color(0xFFECFDFF);
  static const cyan100 = Color(0xFFC7F7FF);
  static const cyan200 = Color(0xFF8DEFFF);
  static const cyan300 = Color(0xFF4FE3FA);
  static const cyan400 = Color(0xFF00D3EE);
  static const cyan500 = Color(0xFF00B2CD);

  // Streak (amber)
  static const streak100 = Color(0xFFFFEFCC);
  static const streak300 = Color(0xFFFFCF6B);
  static const streak500 = Color(0xFFFFB020);
  static const streak700 = Color(0xFFB77500);

  // Semantic aliases
  static const brand = coral500;
  static const brandHot = coral400;
  static const brandDeep = coral600;
  static const accent = cyan400;
  static const accentDeep = cyan500;
  static const surfaceInverse = ink900;
  static const textOnInverse = white;
  static const textOnInverseMuted = ink300;
  static const statusGo = cyan400;

  // Lane colors (per-participant identification)
  static const lane1 = coral500;
  static const lane2 = cyan400;
  static const lane3 = streak500;
  static const lane4 = coral300;
  static const lane5 = ink500;
}

abstract final class TeamfitSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
  static const s12 = 48.0;
  static const s16 = 64.0;
  static const s20 = 80.0;

  static const radiusLg = 16.0;
  static const radiusPill = 999.0;
}

abstract final class TeamfitTypo {
  static TextStyle mono({
    double fontSize = 34,
    FontWeight fontWeight = FontWeight.w600,
    Color color = TeamfitColors.textOnInverse,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

abstract final class TeamfitTheme {
  static ThemeData dark() {
    final displayFont = GoogleFonts.anton();
    final condensedFont = GoogleFonts.barlowCondensed();
    final textFont = GoogleFonts.barlow();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TeamfitColors.surfaceInverse,
      colorScheme: const ColorScheme.dark(
        primary: TeamfitColors.brand,
        secondary: TeamfitColors.accent,
        surface: TeamfitColors.ink800,
        onPrimary: TeamfitColors.white,
        onSecondary: TeamfitColors.ink900,
        onSurface: TeamfitColors.white,
      ),
      textTheme: TextTheme(
        displayLarge: displayFont.copyWith(
          fontSize: 88,
          height: 0.92,
          letterSpacing: -0.01 * 88,
          color: TeamfitColors.textOnInverse,
        ),
        displayMedium: displayFont.copyWith(
          fontSize: 64,
          height: 0.92,
          letterSpacing: -0.01 * 64,
          color: TeamfitColors.textOnInverse,
        ),
        displaySmall: displayFont.copyWith(
          fontSize: 44,
          height: 0.92,
          letterSpacing: -0.01 * 44,
          color: TeamfitColors.textOnInverse,
        ),
        headlineLarge: displayFont.copyWith(
          fontSize: 32,
          height: 0.92,
          color: TeamfitColors.textOnInverse,
        ),
        headlineMedium: condensedFont.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 24 * 0.06,
          color: TeamfitColors.textOnInverse,
        ),
        headlineSmall: condensedFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 20 * 0.06,
          color: TeamfitColors.textOnInverse,
        ),
        titleLarge: condensedFont.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 24 * 0.14,
          color: TeamfitColors.textOnInverse,
        ),
        titleMedium: condensedFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: TeamfitColors.textOnInverse,
        ),
        titleSmall: condensedFont.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: TeamfitColors.textOnInverse,
        ),
        bodyLarge: textFont.copyWith(
          fontSize: 18,
          height: 1.55,
          color: TeamfitColors.textOnInverse,
        ),
        bodyMedium: textFont.copyWith(
          fontSize: 16,
          height: 1.55,
          color: TeamfitColors.textOnInverse,
        ),
        bodySmall: textFont.copyWith(
          fontSize: 14,
          height: 1.55,
          color: TeamfitColors.textOnInverseMuted,
        ),
        labelLarge: condensedFont.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 14 * 0.14,
          color: TeamfitColors.textOnInverseMuted,
        ),
        labelMedium: condensedFont.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 12 * 0.14,
          color: TeamfitColors.textOnInverseMuted,
        ),
      ),
    );
  }
}
