import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'logging/app_logger.dart';

/// Texts for the Android home screen widget ("This week"); the native side
/// (WeekWidgetProvider.kt) only draws them.
abstract class HomeWidgetSync {
  Future<void> update({required String title, required String days, required String line, required String streak});

  /// Logout: back to the neutral "open the app" texts.
  Future<void> clear();
}

class AndroidHomeWidgetSync implements HomeWidgetSync {
  const AndroidHomeWidgetSync();

  static const _provider = 'pl.tatkowski.gymapp.WeekWidgetProvider';
  static String? _last;

  @override
  Future<void> update({required String title, required String days, required String line, required String streak}) async {
    final key = '$title|$days|$line|$streak';
    if (key == _last) return; // the card rebuilds often; the widget only needs real changes
    _last = key;
    try {
      await HomeWidget.saveWidgetData('week_title', title);
      await HomeWidget.saveWidgetData('week_days', days);
      await HomeWidget.saveWidgetData('week_line', line);
      await HomeWidget.saveWidgetData('week_streak', streak);
      await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    } catch (e) {
      _last = null;
      log.w('Home widget not updated: $e');
    }
  }

  @override
  Future<void> clear() async {
    _last = null;
    try {
      for (final key in ['week_title', 'week_days', 'week_line', 'week_streak']) {
        await HomeWidget.saveWidgetData<String>(key, null);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    } catch (e) {
      log.w('Home widget not cleared: $e');
    }
  }
}

class NoHomeWidgetSync implements HomeWidgetSync {
  const NoHomeWidgetSync();

  @override
  Future<void> update({required String title, required String days, required String line, required String streak}) async {}

  @override
  Future<void> clear() async {}
}

final homeWidgetSyncProvider = Provider<HomeWidgetSync>(
  (ref) => !kIsWeb && Platform.isAndroid ? const AndroidHomeWidgetSync() : const NoHomeWidgetSync(),
);
