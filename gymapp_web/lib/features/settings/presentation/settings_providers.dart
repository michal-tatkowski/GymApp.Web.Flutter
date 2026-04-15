import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/secure_storage_keys.dart';

/// ─── Theme ───────────────────────────────────────────────────────────────

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _restore();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _restore() async {
    final value = await _storage.read(key: StorageKeys.themeMode);
    state = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() => set(
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _storage.write(
      key: StorageKeys.themeMode,
      value: mode == ThemeMode.dark ? 'dark' : 'light',
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

  final _storage = const FlutterSecureStorage();

  Future<void> _restore() async {
    final code = await _storage.read(key: StorageKeys.locale);
    if (code != null) state = Locale(code);
  }

  Future<void> toggle() => set(
        state.languageCode == 'en' ? const Locale('pl') : const Locale('en'),
      );

  Future<void> set(Locale locale) async {
    state = locale;
    await _storage.write(key: StorageKeys.locale, value: locale.languageCode);
  }
}
