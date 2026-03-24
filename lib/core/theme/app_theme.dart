/// Application theme for Stock Pilot IMS.
library;

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ─── Color palette ───────────────────────────────────────────────
  static const Color _primaryDark = Color(0xFF1A1A2E);
  static const Color _primaryMid = Color(0xFF16213E);
  static const Color _accent = Color(0xFF0F3460);
  static const Color _highlight = Color(0xFF00B4D8);
  static const Color _success = Color(0xFF06D6A0);
  static const Color _warning = Color(0xFFFFD166);

  static const Color _error = Color(0xFFEF476F);
  static const Color _surface = Color(0xFF1E1E2F);
  static const Color _cardDark = Color(0xFF252540);

  // ─── Light theme colors ──────────────────────────────────────────
  static const Color _primaryLight = Color(0xFFF0F2F5);
  static const Color _primaryMidLight = Color(0xFFFFFFFF);
  static const Color _accentLight = Color(0xFFE1E4E8);
  static const Color _highlightLight = Color(0xFF0077B6);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _cardLight = Color(0xFFF8F9FA);
  static const Color _textLight = Color(0xFF1A1A2E);
  static const Color _textSecondaryLight = Color(0xFF4A4A6A);

  // ─── Light theme ─────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _primaryLight,
      colorScheme: const ColorScheme.light(
        primary: _highlightLight,
        secondary: _accentLight,
        surface: _surfaceLight,
        error: _error,
        onPrimary: Colors.white,
        onSecondary: _textLight,
        onSurface: _textLight,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryMidLight,
        foregroundColor: _textLight,
        elevation: 0,
        centerTitle: false,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _primaryMidLight,
        selectedIconTheme: const IconThemeData(color: _highlightLight),
        unselectedIconTheme: IconThemeData(
          color: _textLight.withValues(alpha: 0.5),
        ),
        selectedLabelTextStyle: const TextStyle(
          color: _highlightLight,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: _highlightLight.withValues(alpha: 0.1),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _primaryMidLight,
        selectedItemColor: _highlightLight,
        unselectedItemColor: _textLight.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _highlightLight,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _highlightLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _highlightLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _accentLight,
        labelStyle: const TextStyle(color: _textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(_primaryMidLight),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return _highlightLight.withValues(alpha: 0.05);
          }
          return Colors.transparent;
        }),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _highlightLight,
        ),
      ),
      dividerColor: Colors.black12,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: _textLight,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: _textLight,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: _textLight),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: _textLight,
        ),
        bodyLarge: TextStyle(color: _textLight),
        bodyMedium: TextStyle(color: _textSecondaryLight),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // ─── Dark theme (primary) ────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: _highlight,
        secondary: _accent,
        surface: _surface,
        error: _error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryMid,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _primaryMid,
        selectedIconTheme: const IconThemeData(color: _highlight),
        unselectedIconTheme: IconThemeData(
          color: Colors.white.withValues(alpha: 0.5),
        ),
        selectedLabelTextStyle: const TextStyle(
          color: _highlight,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: _highlight.withValues(alpha: 0.15),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _primaryMid,
        selectedItemColor: _highlight,
        unselectedItemColor: Colors.white.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _highlight,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _highlight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _highlight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _accent.withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(_primaryMid),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return _accent.withValues(alpha: 0.15);
          }
          return Colors.transparent;
        }),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _highlight,
        ),
      ),
      dividerColor: Colors.white12,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // ─── Helper colors for status indicators ─────────────────────────
  static const Color success = _success;
  static const Color warning = _warning;
  static const Color error = _error;
  static const Color highlight = _highlight;
}
