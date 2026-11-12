import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'core/providers/retry.dart';

/// Crash reporting is off unless the build sets a DSN:
/// `flutter build appbundle --dart-define=SENTRY_DSN=https://…@….ingest.sentry.io/…`
/// (see README). Local runs and tests send nothing.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  if (_sentryDsn.isEmpty) return _run();

  await SentryFlutter.init(
    (options) {
      options
        ..dsn = _sentryDsn
        ..environment = kReleaseMode ? 'production' : 'development'
        // Matches the privacy policy: no IP, user or request bodies — only the error and device/app info.
        ..sendDefaultPii = false
        ..tracesSampleRate = 0
        ..attachScreenshot = false
        ..attachViewHierarchy = false;
    },
    appRunner: _run,
  );
}

void _run() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(retry: noRetry, child: GymApp()));
}
