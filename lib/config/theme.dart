import 'package:flutter/material.dart';

class AppTheme {
  // Monochrome palette
  static const Color _dark = Color(0xFF111111);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _surfaceLight = Color(0xFF242424);
  static const Color _border = Color(0xFF2E2E2E);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFF9E9E9E);
  static const Color _accent = Color(0xFFFFFFFF);

  // Light palette
  static const Color _lightBg = Color(0xFFF7F7F8);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceAlt = Color(0xFFF0F0F2);
  static const Color _lightBorder = Color(0xFFE0E0E0);
  static const Color _lightText = Color(0xFF111111);
  static const Color _lightTextSecondary = Color(0xFF6B6B6B);

  // Functional colors — use withValues(alpha: 0.15) for backgrounds
  static const Color danger   = Color(0xFFCC3333);
  static const Color lost     = Color(0xFF994444);
  static const Color found    = Color(0xFF449944);
  static const Color resolved = Color(0xFF4466AA);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _dark,
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        onPrimary: _dark,
        secondary: _textSecondary,
        surface: _surface,
        onSurface: _textPrimary,
        outline: _border,
        error: Color(0xFFCF6679),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _dark,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _dark,
        indicatorColor: Colors.white.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _accent,
            );
          }
          return const TextStyle(fontSize: 11, color: _textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _accent, size: 24);
          }
          return const IconThemeData(color: _textSecondary, size: 24);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: _dark,
        elevation: 0,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: _textSecondary),
        hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
        prefixIconColor: _textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _dark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: const BorderSide(color: _border),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _textSecondary),
      ),
      dividerTheme: const DividerThemeData(color: _border),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceLight,
        contentTextStyle: const TextStyle(color: _textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceLight,
        selectedColor: _accent,
        labelStyle: const TextStyle(color: _textPrimary, fontSize: 13),
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: const ColorScheme.light(
        primary: _lightText,
        onPrimary: _lightSurface,
        secondary: _lightTextSecondary,
        surface: _lightSurface,
        onSurface: _lightText,
        outline: _lightBorder,
        error: Color(0xFFB00020),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _lightBg,
        foregroundColor: _lightText,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _lightBg,
        indicatorColor: _lightText.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _lightText,
            );
          }
          return const TextStyle(fontSize: 11, color: _lightTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _lightText, size: 24);
          }
          return const IconThemeData(color: _lightTextSecondary, size: 24);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _lightText,
        foregroundColor: _lightSurface,
        elevation: 0,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightText, width: 1.5),
        ),
        labelStyle: const TextStyle(color: _lightTextSecondary),
        hintStyle: TextStyle(color: _lightTextSecondary.withValues(alpha: 0.5)),
        prefixIconColor: _lightTextSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightText,
          foregroundColor: _lightSurface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightText,
          side: const BorderSide(color: _lightBorder),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _lightTextSecondary),
      ),
      dividerTheme: const DividerThemeData(color: _lightBorder),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightText,
        contentTextStyle: const TextStyle(color: _lightSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurfaceAlt,
        selectedColor: _lightText,
        labelStyle: const TextStyle(color: _lightText, fontSize: 13),
        side: const BorderSide(color: _lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
