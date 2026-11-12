import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors/exceptions.dart';
import '../auth/presentation/auth_providers.dart';

/// Everything about the account (api/Account/export) — GDPR data portability.
class DataExport {
  DataExport(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetch() async {
    try {
      final res = await _dio.get<dynamic>('Account/export');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    }
  }

  /// One row per set — opens in Excel / Google Sheets.
  static String workoutsCsv(Map<String, dynamic> export) {
    String cell(Object? v) {
      final s = v?.toString() ?? '';
      return s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    const header = ['date', 'exercise', 'set', 'reps', 'weight_kg', 'duration_s', 'distance_m', 'notes'];
    final rows = <List<Object?>>[];
    for (final log in (export['workouts'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      for (final entry in (log['entries'] as List).cast<Map<String, dynamic>>().reversed) {
        final sets = (entry['sets'] as List).cast<Map<String, dynamic>>();
        for (var i = 0; i < sets.length; i++) {
          rows.add([
            entry['date'],
            log['exerciseName'],
            i + 1,
            sets[i]['reps'],
            sets[i]['weight'],
            sets[i]['durationSeconds'],
            sets[i]['distanceMeters'],
            i == 0 ? entry['notes'] : null,
          ]);
        }
      }
    }
    // By date (yyyy-MM-dd sorts as text); Dart's sort is stable, so sets keep their order.
    rows.sort((a, b) => (a[0] as String).compareTo(b[0] as String));
    return [header, ...rows].map((r) => r.map(cell).join(',')).join('\n');
  }

  /// Fetches the export and hands two files to the system share sheet (save to
  /// Files / Drive, e-mail…): the full JSON and the workouts as CSV.
  Future<void> shareFiles() async {
    final data = await fetch();
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await SharePlus.instance.share(ShareParams(
      files: [
        XFile.fromData(Uint8List.fromList(utf8.encode(json)), mimeType: 'application/json', name: 'gymapp-$day.json'),
        XFile.fromData(Uint8List.fromList(utf8.encode(workoutsCsv(data))), mimeType: 'text/csv', name: 'gymapp-workouts-$day.csv'),
      ],
      subject: 'GymApp $day',
    ));
  }
}

final dataExportProvider = Provider((ref) => DataExport(ref.watch(dioProvider)));
