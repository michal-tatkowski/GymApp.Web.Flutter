// Host side of integration_test/store_screenshots_test.dart: saves each screenshot as a PNG
// where Google Play tooling (fastlane supply) expects it.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  final locale = Platform.environment['SCREENSHOT_LOCALE'] == 'en' ? 'en-US' : 'pl-PL';
  final dir = Directory('fastlane/metadata/android/$locale/images/phoneScreenshots')..createSync(recursive: true);
  return integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      File('${dir.path}/$name.png').writeAsBytesSync(bytes);
      stdout.writeln('screenshot ${dir.path}/$name.png');
      return true;
    },
  );
}
