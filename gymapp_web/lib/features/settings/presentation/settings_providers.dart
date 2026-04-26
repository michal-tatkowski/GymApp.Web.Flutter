import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage_keys.dart';

/// ─── Theme ───────────────────────────────────────────────────────────────

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.themeMode);
    state = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() => set(
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.themeMode,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

/// ─── Locale ──────────────────────────────────────────────────────────────

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(StorageKeys.locale);
    if (code != null) state = Locale(code);
  }

  Future<void> toggle() => set(
        state.languageCode == 'en' ? const Locale('pl') : const Locale('en'),
      );

  Future<void> set(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.locale, locale.languageCode);
  }
}
