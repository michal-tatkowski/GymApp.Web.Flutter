import 'package:flutter/material.dart';

/// App-wide themes. Extend this when introducing a design system.
class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFFEF6C00);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
      );
}
