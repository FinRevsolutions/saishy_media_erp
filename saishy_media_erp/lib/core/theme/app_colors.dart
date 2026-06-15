import 'package:flutter/material.dart';

class AppColors {
  // ── Brand Colors ─────────────────────────────────────
  static const primary   = Color(0xFF6C63FF);  // Vibrant purple
  static const accent    = Color(0xFF00D9FF);  // Cyan accent
  static const success   = Color(0xFF22C55E);
  static const warning   = Color(0xFFF59E0B);
  static const error     = Color(0xFFEF4444);
  static const info      = Color(0xFF3B82F6);

  // ── Backgrounds ───────────────────────────────────────
  static const backgroundDark = Color(0xFF0F1117);
  static const surfaceDark    = Color(0xFF161B22);
  static const cardDark       = Color(0xFF1A1D27);
  static const navBarDark     = Color(0xFF13161E);

  // ── Text ─────────────────────────────────────────────
  static const textPrimary   = Color(0xFFEFEFF4);
  static const textSecondary = Color(0xFF9AA3B2);
  static const textMuted     = Color(0xFF6B7280);

  // ── Borders ───────────────────────────────────────────
  static const borderDark = Color(0xFF2A2D3A);

  // ── Gradients ─────────────────────────────────────────
  static const loginGradient = LinearGradient(
    colors: [Color(0xFF0A0C14), Color(0xFF14103D), Color(0xFF0A0C14)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6C63FF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF00D9FF), Color(0xFF0099CC)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.primary,
      secondary: AppColors.accent,
      error:     AppColors.error,
      surface:   AppColors.surfaceDark,
      background: AppColors.backgroundDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,

    fontFamily: 'Inter',

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
    ),

    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.borderDark)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navBarDark,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: AppColors.textMuted, fontSize: 11);
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.textMuted);
      }),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cardDark,
      selectedColor: AppColors.primary.withOpacity(0.2),
      side: const BorderSide(color: AppColors.borderDark),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    ),

    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
    ),

    dividerTheme: const DividerThemeData(color: AppColors.borderDark, thickness: 1),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: StadiumBorder(),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.primary,
      thumbColor: AppColors.primary,
      inactiveTrackColor: AppColors.borderDark,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
      side: const BorderSide(color: AppColors.borderDark, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.primary;
        return AppColors.textMuted;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.primary.withOpacity(0.4);
        return AppColors.borderDark;
      }),
    ),

    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.surfaceDark,
      headerBackgroundColor: AppColors.primary,
      dayStyle: TextStyle(color: AppColors.textPrimary),
    ),
  );
}
