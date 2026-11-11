import 'dart:async';

import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motion.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  MotionView.animate = false; // endless illustration loops would block pumpAndSettle
  await testMain();
}
