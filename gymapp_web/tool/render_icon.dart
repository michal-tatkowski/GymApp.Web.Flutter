// Renders the app icon PNGs into assets/icon/ (source for flutter_launcher_icons
// and flutter_native_splash). Run after changing the design:
//
//   flutter test tool/render_icon.dart
//   dart run flutter_launcher_icons && dart run flutter_native_splash:create
//
// Drawn with plain shapes (no icon font), so the output is the same everywhere.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Brand orange — the seed of the app's color scheme (AppTheme).
const brand = Color(0xFFEF6C00);
const ink = Colors.white;

void main() {
  testWidgets('render app icon', (tester) async {
    await tester.runAsync(() async {
      // Legacy / iOS icon: full square, dumbbell fills ~62 %.
      await _write('assets/icon/icon.png', 1024, background: brand, scale: 0.62);
      // Android adaptive foreground: transparent; the generated XML insets it by 16 %,
      // which lands the dumbbell inside the 66 % safe zone.
      await _write('assets/icon/foreground.png', 1024, scale: 0.62);
      // Splash: dumbbell only, the splash background is brand.
      await _write('assets/icon/splash.png', 768, scale: 0.42);
    });
  });
}

Future<void> _write(String path, int size, {Color? background, required double scale}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (background != null) canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = background);
  _dumbbell(canvas, Offset(s / 2, s / 2), s * scale);
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

/// Dumbbell at 45°: bar + two plates and a smaller collar on each side.
void _dumbbell(Canvas canvas, Offset center, double length) {
  final paint = Paint()..color = ink;
  canvas
    ..save()
    ..translate(center.dx, center.dy)
    ..rotate(-math.pi / 4);
  final u = length / 100; // design grid: 100 units long
  RRect r(double x, double w, double h, double radius) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x * u, 0), width: w * u, height: h * u), Radius.circular(radius * u));
  canvas.drawRRect(r(0, 50, 10, 3), paint); // bar
  for (final side in [-1, 1]) {
    canvas
      ..drawRRect(r(side * 27, 14, 50, 4), paint) // plate
      ..drawRRect(r(side * 39.5, 8, 28, 3), paint); // smaller outer plate
  }
  canvas.restore();
}
