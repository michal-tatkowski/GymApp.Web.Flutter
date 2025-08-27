// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));
//
// class LanguageService {
//   static const _key = 'language';
//   static final _storage = FlutterSecureStorage();
//  
//   static Future<void> loadLocale() async {
//     final code = await _storage.read(key: _key);
//     if (code != null) {
//       localeNotifier.value = Locale(code);
//     }
//   }
//  
//   static Future<void> saveLocale(Locale locale) async {
//     await _storage.write(key: _key, value: locale.languageCode);
//     localeNotifier.value = locale;
//   }
// }
