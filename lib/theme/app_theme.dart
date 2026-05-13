import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF00897B);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: const CardThemeData(elevation: 1),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: const CardThemeData(elevation: 1),
      );
}
