import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage_keys.dart';

/// ─── Theme ───────────────────────────────────────────────────────────────

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// Follows the phone by default (many people keep dark mode on in the evening,
/// when they train); Light / Dark override it. Stored as 'system' | 'light' | 'dark'.
class ThemeNotifier extends Notifier<ThemeMode> {
  bool _changedByUser = false;

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.themeMode);
    // A choice made while prefs were loading wins over the stored value.
    if (!ref.mounted || _changedByUser) return;
    state = ThemeMode.values.where((m) => m.name == value).firstOrNull ?? ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    _changedByUser = true;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.themeMode, mode.name);
  }
}

/// Dark theme on pure black (OLED: black pixels are off). Off by default.
final pureBlackProvider = NotifierProvider<BoolSetting, bool>(() => BoolSetting(StorageKeys.pureBlack));

/// Bigger steppers and a full-width "set done" button during a workout. Off by default.
final largeSessionControlsProvider =
    NotifierProvider<BoolSetting, bool>(() => BoolSetting(StorageKeys.largeSessionControls));

/// Warm-up and stretching checklists in a workout are shown unless turned off.
final hideRoutinesProvider = NotifierProvider<BoolSetting, bool>(() => BoolSetting(StorageKeys.hideRoutines));

/// An on/off preference in SharedPreferences, false until stored otherwise.
class BoolSetting extends Notifier<bool> {
  BoolSetting(this._key);

  final String _key;
  bool _changedByUser = false;

  @override
  bool build() {
    _restore();
    return false;
  }

  Future<void> _restore() async {
    final value = (await SharedPreferences.getInstance()).getBool(_key);
    if (!ref.mounted || _changedByUser || value == null) return;
    state = value;
  }

  Future<void> set(bool value) async {
    _changedByUser = true;
    state = value;
    await (await SharedPreferences.getInstance()).setBool(_key, value);
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
