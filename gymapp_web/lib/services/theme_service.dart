// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
// final _storage = FlutterSecureStorage();
// const _key = 'theme_mode';
//
// class ThemeService {
//   static Future<ThemeMode> loadTheme() async {
//     final value = await _storage.read(key: _key);
//     final mode = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
//     themeNotifier.value = mode;
//     return mode; // <-- zwracamy ThemeMode
//   }
//
//   static Future<void> saveTheme(ThemeMode mode) async {
//     await _storage.write(
//       key: _key,
//       value: mode == ThemeMode.dark ? 'dark' : 'light',
//     );
//     themeNotifier.value = mode;
//   }
// }
