import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/logging/app_logger.dart';
import '../../../../l10n/app_localizations.dart';

/// System notifications for the rest timer while the app is in the background
/// (phone in the pocket between sets):
/// - an ongoing notification with a live countdown (Android chronometer), also
///   on the lock screen,
/// - an alert scheduled for the end of the rest.
/// In the foreground the in-app bar does the job, so both are cleared then.
abstract class RestAlarm {
  /// Asks for the notification permission (Android 13+, iOS). Called when the
  /// timer is first used — in context, not on app start.
  Future<void> requestPermission();

  Future<void> showInBackground({required DateTime endsAt, required AppLocalizations t});

  Future<void> clear();

  /// Android 12+: exact alarms are needed for the end alert to come on time;
  /// on Android 14 the user grants them in system settings. Always true elsewhere.
  Future<bool> canAlertOnTime();

  Future<void> openExactAlarmSettings();
}

final restAlarmProvider = Provider<RestAlarm>(
  (ref) => kIsWeb ? const NoRestAlarm() : LocalNotificationsRestAlarm(),
);

class NoRestAlarm implements RestAlarm {
  const NoRestAlarm();

  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> showInBackground({required DateTime endsAt, required AppLocalizations t}) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<bool> canAlertOnTime() async => true;
  @override
  Future<void> openExactAlarmSettings() async {}
}

class LocalNotificationsRestAlarm implements RestAlarm {
  LocalNotificationsRestAlarm([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _ready;

  static const _countdownId = 1001;
  static const _endId = 1002;
  static const _brand = Color(0xFFEF6C00);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Initialized lazily; false when the platform has no implementation (tests,
  /// desktop) — then every call is a no-op instead of an exception.
  Future<bool> _init() => _ready ??= () async {
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          // Monochrome silhouette — Android draws small icons as a single color.
          android: AndroidInitializationSettings('ic_stat_gymapp'),
          // Permission is requested later, when the timer is first used.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return true;
    } catch (e) {
      log.w('Rest timer notifications unavailable: $e');
      return false;
    }
  }();

  Future<void> _guard(Future<void> Function() action) async {
    if (!await _init()) return;
    try {
      await action();
    } catch (e) {
      log.w('Rest timer notification failed: $e');
    }
  }

  @override
  Future<void> requestPermission() => _guard(() async {
    await _android?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
  });

  @override
  Future<void> showInBackground({required DateTime endsAt, required AppLocalizations t}) => _guard(() async {
    final left = endsAt.difference(clock.now());
    if (left <= Duration.zero) return;

    // Live countdown, silent; disappears by itself when the rest is over.
    await _plugin.show(
      id: _countdownId,
      title: t.restNotificationTitle,
      body: t.restNotificationBody,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_countdown',
          t.restCountdownChannel,
          importance: Importance.low,
          color: _brand,
          priority: Priority.low,
          ongoing: true,
          onlyAlertOnce: true,
          silent: true,
          showWhen: true,
          when: endsAt.millisecondsSinceEpoch,
          usesChronometer: true,
          chronometerCountDown: true,
          timeoutAfter: left.inMilliseconds,
          category: AndroidNotificationCategory.stopwatch,
          visibility: NotificationVisibility.public,
        ),
      ),
    );

    final exact = await canAlertOnTime();
    await _plugin.zonedSchedule(
      id: _endId,
      title: t.restOver,
      scheduledDate: tz.TZDateTime.from(endsAt, tz.UTC),
      androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_over',
          t.restOverChannel,
          importance: Importance.high,
          color: _brand,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          timeoutAfter: const Duration(minutes: 5).inMilliseconds,
        ),
        iOS: const DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
      ),
    );
  });

  @override
  Future<void> clear() => _guard(() async {
    await _plugin.cancel(id: _countdownId);
    await _plugin.cancel(id: _endId);
  });

  @override
  Future<bool> canAlertOnTime() async {
    final android = _android;
    if (android == null || !await _init()) return true;
    try {
      return await android.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> openExactAlarmSettings() => _guard(() async {
    await _android?.requestExactAlarmsPermission();
  });
}
