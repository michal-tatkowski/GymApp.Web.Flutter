import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage_keys.dart';

/// ─── Theme ───────────────────────────────────────────────────────────────

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  bool _changedByUser = false;

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.themeMode);
    // A choice made while prefs were loading wins over the stored value.
    if (!ref.mounted || _changedByUser) return;
    state = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() => set(
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );

  Future<void> set(ThemeMode mode) async {
    _changedByUser = true;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.themeMode,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

/// ─── Locale ──────────────────────────────────────────────────────────────

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

const supportedLanguageCodes = ['en', 'pl'];

/// Language of the device if the app supports it, English otherwise.
/// Used until the user picks a language in Settings.
Locale deviceLocale([String? deviceLanguageCode]) {
  final code = deviceLanguageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return Locale(supportedLanguageCodes.contains(code) ? code : 'en');
}

class LocaleNotifier extends Notifier<Locale> {
  bool _changedByUser = false;

  @override
  Locale build() {
    _restore();
    return deviceLocale();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(StorageKeys.locale);
    if (!ref.mounted || _changedByUser || code == null) return;
    state = Locale(code);
  }

  Future<void> toggle() => set(
        state.languageCode == 'en' ? const Locale('pl') : const Locale('en'),
      );

  Future<void> set(Locale locale) async {
    _changedByUser = true;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.locale, locale.languageCode);
  }
}
