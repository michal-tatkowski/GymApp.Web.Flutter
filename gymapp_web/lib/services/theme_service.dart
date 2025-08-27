import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class ThemeService {
  static const _key = 'theme_mode';
  static final _storage = FlutterSecureStorage();

  static Future<void> loadTheme() async {
    final value = await _storage.read(key: _key);
    themeNotifier.value = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> saveTheme(ThemeMode mode) async {
    await _storage.write(
      key: _key,
      value: mode == ThemeMode.dark ? 'dark' : 'light',
    );
    themeNotifier.value = mode;
  }
}
