import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color bgDeep = Color(0xFF070A0F);
  static const Color bgElevated = Color(0xFF0E131C);
  static const Color cardBg = Color(0xFF131A26);
  static const Color cardBorder = Color(0x22FFFFFF);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accent2 = Color(0xFF22D3EE);
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [
      Color(0xFF06080D),
      Color(0xFF0C1118),
      Color(0xFF0A0E16),
      Color(0xFF070A10),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradientLight = LinearGradient(
    colors: [
      Color(0xFFEEF0F7),
      Color(0xFFE4E8F2),
      Color(0xFFDFE4EF),
      Color(0xFFE8EBF5),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient scaffoldGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? bgGradient : bgGradientLight;
  }

  static Color cardSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? cardBg : const Color(0xFFF8F9FD);
  }

  static Color cardBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);
  }

  static Color onCardPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF1A1D26);
  }

  static Color onCardSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.58)
        : const Color(0xFF5C6270);
  }

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        surface: cardBg,
        onSurface: Colors.white,
        primary: accent,
        secondary: accent2,
        surfaceContainerHighest: bgElevated,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: Colors.white.withValues(alpha: 0.9),
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.92)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent2, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300.withValues(alpha: 0.8)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bgElevated,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent2,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE8EAF0),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        surface: const Color(0xFFF8F9FD),
        onSurface: const Color(0xFF1A1D26),
        primary: accent,
        secondary: accent2,
        surfaceContainerHighest: const Color(0xFFE8EBF2),
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF1A1D26),
        displayColor: const Color(0xFF12151C),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.grey.shade900.withValues(alpha: 0.88)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF12151C),
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.grey.shade600.withValues(alpha: 0.65)),
        labelStyle: TextStyle(color: Colors.grey.shade800.withValues(alpha: 0.75)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent2, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400.withValues(alpha: 0.9)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFF8F9FD),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D3140),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1,
      ),
    );
  }
}
