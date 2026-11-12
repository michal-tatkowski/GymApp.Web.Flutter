// Contact sheet of every exercise movement in four phases, for visual checks:
//   flutter test tool/render_motions.dart   → build/motions.png
// A pair (start ⇄ end) is shown at 0, ⅓, ⅔, 1; a sequence at the start of each phase.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motion.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motions.dart';

void main() {
  testWidgets('render motions', (tester) async {
    await tester.runAsync(() async {
      const cell = 110.0, perMotion = 4, perRow = 2;
      final only = Platform.environment['MOTIONS']?.split(',');
      final entries = motionsByKey.entries.where((e) => only == null || only.contains(e.key)).toList();
      final rows = (entries.length / perRow).ceil();
      final width = cell * perMotion * perRow, height = cell * rows;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);
      for (var i = 0; i < entries.length; i++) {
        final m = entries[i].value;
        final ts = m.isSequence
            ? [for (var k = 0; k < perMotion; k++) k * (m.frames!.length / perMotion).floor() / m.frames!.length]
            : [0.0, 1 / 3, 2 / 3, 1.0];
        for (var j = 0; j < perMotion; j++) {
          final x = ((i % perRow) * perMotion + j) * cell, y = (i ~/ perRow) * cell;
          canvas
            ..save()
            ..translate(x, y)
            ..drawRect(const Rect.fromLTWH(0, 0, cell, cell), Paint()..color = j.isEven ? const Color(0xFFF7F7F7) : Colors.white);
          MotionPainter(motion: m, t: ts[j], body: Colors.black87, weight: Colors.deepOrange, prop: Colors.grey)
              .paint(canvas, const Size(cell, cell));
          canvas.restore();
        }
      }
      final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/motions.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
      File('build/motions.txt').writeAsStringSync(entries.map((e) => e.key).join('\n'));
    });
  });
}
