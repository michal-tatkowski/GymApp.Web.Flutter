// Contact sheet of every exercise movement (start | end) for visual checks:
//   flutter test tool/render_motions.dart   → build/motions.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motion.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motions.dart';

void main() {
  testWidgets('render motions', (tester) async {
    await tester.runAsync(() async {
      const cell = 140.0, cols = 6;
      final entries = motionsByKey.entries.toList();
      final rows = (entries.length / (cols / 2)).ceil();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..drawRect(Rect.fromLTWH(0, 0, cell * cols, cell * rows), Paint()..color = Colors.white);
      for (var i = 0; i < entries.length; i++) {
        for (final (j, t) in [(0, 0.0), (1, 1.0)]) {
          final x = ((i % (cols ~/ 2)) * 2 + j) * cell, y = (i ~/ (cols ~/ 2)) * cell;
          canvas
            ..save()
            ..translate(x, y)
            ..drawRect(const Rect.fromLTWH(0, 0, cell, cell), Paint()..color = j == 0 ? const Color(0xFFF7F7F7) : Colors.white);
          MotionPainter(motion: entries[i].value, t: t, body: Colors.black87, weight: Colors.deepOrange, prop: Colors.grey)
              .paint(canvas, const Size(cell, cell - 14));
          final label = TextPainter(
            text: TextSpan(text: j == 0 ? entries[i].key : '', style: const TextStyle(fontSize: 10, color: Colors.black)),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: cell * 2);
          label.paint(canvas, Offset(4, cell - 13));
          canvas.restore();
        }
      }
      final image = await recorder.endRecording().toImage((cell * cols).toInt(), (cell * rows).toInt());
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/motions.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
