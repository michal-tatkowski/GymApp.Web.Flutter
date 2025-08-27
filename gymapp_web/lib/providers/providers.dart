import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ---------------- Theme ----------------
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  final _storage = const FlutterSecureStorage();

  ThemeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final value = await _storage.read(key: _key);
    state = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _storage.write(
      key: _key,
      value: state == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _storage.write(
      key: _key,
      value: mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

/// ---------------- Locale ----------------
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const _key = 'language';
  final _storage = const FlutterSecureStorage();

  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final code = await _storage.read(key: _key);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> toggle() async {
    state = state.languageCode == 'en'
        ? const Locale('pl')
        : const Locale('en');
    await _storage.write(key: _key, value: state.languageCode);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await _storage.write(key: _key, value: locale.languageCode);
  }
}
