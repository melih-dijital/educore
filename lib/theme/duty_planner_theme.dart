/// Duty Planner Theme
/// Eğitim kurumlarına uygun tema ve renk paleti

import 'package:flutter/material.dart';

/// Nöbet planlayıcı için tema renkleri
class DutyPlannerColors {
  // Ana renkler
  static const Color primary = Color(0xFF1565C0); // Koyu mavi
  static const Color primaryLight = Color(0xFF42A5F5); // Açık mavi
  static const Color primaryDark = Color(0xFF0D47A1); // Daha koyu mavi

  // Yüzey renkleri
  static const Color surface = Color(0xFFFAFAFA); // Açık gri
  static const Color background = Color(0xFFFFFFFF); // Beyaz
  static const Color card = Color(0xFFFFFFFF); // Beyaz

  // Vurgu renkleri
  static const Color accent = Color(0xFF4CAF50); // Yeşil
  static const Color warning = Color(0xFFFFA726); // Turuncu
  static const Color error = Color(0xFFE53935); // Kırmızı
  static const Color success = Color(0xFF43A047); // Koyu yeşil

  // Metin renkleri
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Adım renkleri
  static const Color stepActive = primary;
  static const Color stepCompleted = success;
  static const Color stepInactive = Color(0xFFE0E0E0);

  // Tablo renkleri
  static const Color tableHeader = Color(0xFFE3F2FD);
  static const Color tableRowEven = Color(0xFFFAFAFA);
  static const Color tableRowOdd = Color(0xFFFFFFFF);
  static const Color tableBorder = Color(0xFFE0E0E0);
}

/// Tema oluşturucu
class DutyPlannerTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: DutyPlannerColors.primary,
        secondary: DutyPlannerColors.primaryLight,
        surface: DutyPlannerColors.surface,
        error: DutyPlannerColors.error,
      ),
      scaffoldBackgroundColor: DutyPlannerColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: DutyPlannerColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: DutyPlannerColors.card,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DutyPlannerColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DutyPlannerColors.primary,
          side: const BorderSide(color: DutyPlannerColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DutyPlannerColors.tableBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DutyPlannerColors.tableBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: DutyPlannerColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DutyPlannerColors.primary,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: DutyPlannerColors.tableBorder,
        thickness: 1,
      ),
    );
  }

  /// Responsive breakpoints
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  /// Responsive padding
  static EdgeInsets screenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Responsive max width for content
  static double maxContentWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 800;
    } else {
      return 1200;
    }
  }
}
