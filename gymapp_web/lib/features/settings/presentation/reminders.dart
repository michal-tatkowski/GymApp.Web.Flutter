import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/logging/app_logger.dart';
import '../../../core/storage/secure_storage_keys.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_providers.dart';

/// Weekly workout reminders: chosen days ([DateTime.monday] … [DateTime.sunday]) at one time.
@immutable
class ReminderSettings {
  const ReminderSettings({this.enabled = false, this.weekdays = const {1, 3, 5}, this.time = const TimeOfDay(hour: 18, minute: 0)});

  final bool enabled;
  final Set<int> weekdays;
  final TimeOfDay time;

  ReminderSettings copyWith({bool? enabled, Set<int>? weekdays, TimeOfDay? time}) => ReminderSettings(
        enabled: enabled ?? this.enabled,
        weekdays: weekdays ?? this.weekdays,
        time: time ?? this.time,
      );

  Map<String, dynamic> toJson() =>
      {'enabled': enabled, 'weekdays': weekdays.toList()..sort(), 'hour': time.hour, 'minute': time.minute};

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
        enabled: j['enabled'] as bool? ?? false,
        weekdays: {...(j['weekdays'] as List? ?? const []).cast<int>()},
        time: TimeOfDay(hour: (j['hour'] as num?)?.toInt() ?? 18, minute: (j['minute'] as num?)?.toInt() ?? 0),
      );
}

/// Puts the reminders into the system (or removes them). Swapped out in tests.
abstract class ReminderScheduler {
  /// Returns false when the user did not allow notifications.
  Future<bool> requestPermission();
  Future<void> apply(ReminderSettings settings, AppLocalizations t);
}

final reminderSchedulerProvider =
    Provider<ReminderScheduler>((ref) => kIsWeb ? const NoReminderScheduler() : LocalReminderScheduler());

class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> apply(ReminderSettings settings, AppLocalizations t) async {}
}

class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  static const _baseId = 2000; // + weekday (1–7)

  /// Local time zone, so "Monday 18:00" stays 18:00 across daylight saving changes.
  Future<bool> _init() => _ready ??= () async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_gymapp'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return true;
    } catch (e) {
      log.w('Workout reminders unavailable: $e');
      return false;
    }
  }();

  @override
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    try {
      final android = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      final ios = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
      return (android ?? ios) ?? true;
    } catch (e) {
      log.w('Notification permission request failed: $e');
      return false;
    }
  }

  @override
  Future<void> apply(ReminderSettings settings, AppLocalizations t) async {
    if (!await _init()) return;
    try {
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
        await _plugin.cancel(id: _baseId + day);
      }
      if (!settings.enabled) return;
      final now = tz.TZDateTime.now(tz.local);
      for (final day in settings.weekdays) {
        // Next such weekday at the chosen time; then the system repeats it weekly.
        var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, settings.time.hour, settings.time.minute);
        while (at.weekday != day || !at.isAfter(now)) {
          at = at.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          id: _baseId + day,
          title: t.reminderTitle,
          body: t.reminderBody,
          scheduledDate: at,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // a few minutes late is fine
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'workout_reminders',
              t.reminderChannel,
              importance: Importance.defaultImportance,
              color: const Color(0xFFEF6C00),
            ),
          ),
        );
      }
    } catch (e) {
      log.w('Scheduling workout reminders failed: $e');
    }
  }
}

/// Persisted reminder settings; every change is applied to the system at once.
final remindersProvider = NotifierProvider<RemindersNotifier, ReminderSettings>(RemindersNotifier.new);

class RemindersNotifier extends Notifier<ReminderSettings> {
  bool _changedByUser = false;

  @override
  ReminderSettings build() {
    _restore();
    return const ReminderSettings();
  }

  Future<void> _restore() async {
    final raw = (await SharedPreferences.getInstance()).getString(StorageKeys.reminders);
    if (!ref.mounted || _changedByUser || raw == null) return;
    try {
      state = ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  /// Turning on asks for the notification permission; refused → stays off (returns false).
  Future<bool> update(ReminderSettings next) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    if (next.enabled && !state.enabled && !await scheduler.requestPermission()) return false;
    _changedByUser = true;
    state = next;
    await (await SharedPreferences.getInstance()).setString(StorageKeys.reminders, jsonEncode(next.toJson()));
    await scheduler.apply(next, lookupAppLocalizations(ref.read(localeProvider)));
    return true;
  }
}
