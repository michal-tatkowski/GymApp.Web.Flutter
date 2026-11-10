import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/app/config/app_config.dart';

void main() {
  String resolve({String env = '', bool web = false, TargetPlatform platform = TargetPlatform.android}) =>
      AppConfig.resolveApiBaseUrl(fromEnv: env, isWeb: web, platform: platform);

  test('Android emulator reaches the computer at 10.0.2.2', () {
    expect(resolve(), 'http://10.0.2.2:5035/api/');
  });

  test('iOS simulator and web use localhost', () {
    expect(resolve(platform: TargetPlatform.iOS), 'http://localhost:5035/api/');
    expect(resolve(web: true), 'http://localhost:5035/api/'); // web build in a browser on Android too
  });

  test('--dart-define=API_BASE_URL wins and always ends with a slash', () {
    expect(resolve(env: 'http://192.168.1.20:5035/api'), 'http://192.168.1.20:5035/api/');
    expect(resolve(env: 'https://api.example.com/api/', platform: TargetPlatform.iOS), 'https://api.example.com/api/');
  });
}
