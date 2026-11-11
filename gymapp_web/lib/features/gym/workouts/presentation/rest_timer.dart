import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/secure_storage_keys.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/settings_providers.dart';
import 'rest_alarm.dart';

/// Rest durations offered in Settings; 0 = timer off.
const restTimerOptions = [0, 60, 90, 120, 180];
const defaultRestSeconds = 90;

/// Rest length chosen in Settings (persisted).
final restDurationProvider = NotifierProvider<RestDurationNotifier, int>(RestDurationNotifier.new);

class RestDurationNotifier extends Notifier<int> {
  bool _changedByUser = false;

  @override
  int build() {
    _restore();
    return defaultRestSeconds;
  }

  Future<void> _restore() async {
    final stored = (await SharedPreferences.getInstance()).getInt(StorageKeys.restTimerSeconds);
    if (ref.mounted && !_changedByUser && stored != null) state = stored;
  }

  Future<void> set(int seconds) async {
    _changedByUser = true;
    state = seconds;
    await (await SharedPreferences.getInstance()).setInt(StorageKeys.restTimerSeconds, seconds);
  }
}

class RestTimerState {
  const RestTimerState({this.remaining = Duration.zero, this.total = Duration.zero, this.finished = false});

  final Duration remaining;
  final Duration total;

  /// Just reached zero — the bar shows "Rest over" until dismissed.
  final bool finished;

  bool get running => remaining > Duration.zero;
  bool get visible => running || finished;
}

/// Countdown started after a set is saved; shown above the bottom navigation
/// on every tab, so the user can check it from anywhere.
final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(RestTimerNotifier.new);

/// Counts toward a fixed end time (not tick by tick), so the countdown is right
/// after the app was in the background — Android freezes background apps and
/// their timers. While in the background, [RestAlarm] shows the countdown and
/// the end alert as system notifications.
class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _ticker;
  DateTime? _endsAt;
  AppLifecycleListener? _lifecycle;
  bool _askedPermission = false;

  RestAlarm get _alarm => ref.read(restAlarmProvider);

  @override
  RestTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _lifecycle?.dispose();
    });
    return const RestTimerState();
  }

  /// Starts (or restarts) with the duration from Settings; does nothing when it is "off".
  void startAfterSet() {
    final seconds = ref.read(restDurationProvider);
    if (seconds > 0) start(Duration(seconds: seconds));
  }

  void start(Duration duration) {
    _ticker?.cancel();
    _endsAt = clock.now().add(duration);
    state = RestTimerState(remaining: duration, total: duration);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _lifecycle ??= AppLifecycleListener(onHide: _onBackground, onShow: _onForeground);
    if (!_askedPermission) {
      _askedPermission = true;
      _alarm.requestPermission();
    }
  }

  void adjust(Duration delta) {
    final endsAt = _endsAt;
    if (!state.running || endsAt == null) return;
    _endsAt = endsAt.add(delta);
    final total = state.total + delta;
    if (_remaining() <= Duration.zero) return _finish();
    state = RestTimerState(remaining: _remaining(), total: total);
  }

  void stop() {
    _ticker?.cancel();
    _endsAt = null;
    state = const RestTimerState();
    _alarm.clear();
  }

  /// Whole seconds left, rounded up — "0:01" until it is really over.
  Duration _remaining() {
    final left = _endsAt!.difference(clock.now());
    return Duration(seconds: (left.inMilliseconds / 1000).ceil());
  }

  void _tick() {
    if (_endsAt == null) return;
    final remaining = _remaining();
    if (remaining <= Duration.zero) return _finish();
    state = RestTimerState(remaining: remaining, total: state.total);
  }

  void _finish() {
    _ticker?.cancel();
    _endsAt = null;
    state = RestTimerState(total: state.total, finished: true);
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  void _onBackground() {
    final endsAt = _endsAt;
    if (endsAt == null || !state.running) return;
    final t = lookupAppLocalizations(ref.read(localeProvider));
    _alarm.showInBackground(endsAt: endsAt, t: t);
  }

  void _onForeground() {
    _alarm.clear();
    _tick(); // catch up at once instead of on the next tick
  }
}

String formatRest(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Slim bar with the countdown, ±15 s and stop. Hidden when no timer runs.
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final timer = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);
    final theme = Theme.of(context);
    if (!timer.visible) return const SizedBox.shrink();

    final progress = timer.total.inSeconds == 0 ? 0.0 : timer.remaining.inSeconds / timer.total.inSeconds;

    return Material(
      key: const Key('rest.bar'),
      color: timer.finished ? theme.colorScheme.tertiaryContainer : theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: timer.finished ? 1 : progress, minHeight: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(timer.finished ? Icons.notifications_active : Icons.timer_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timer.finished ? t.restOver : t.restRemaining(formatRest(timer.remaining)),
                      key: const Key('rest.label'),
                      style: theme.textTheme.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                  if (timer.running) ...[
                    TextButton(
                      onPressed: () => notifier.adjust(const Duration(seconds: -15)),
                      child: const Text('−15 s'),
                    ),
                    TextButton(
                      onPressed: () => notifier.adjust(const Duration(seconds: 15)),
                      child: const Text('+15 s'),
                    ),
                  ],
                  IconButton(tooltip: t.close, icon: const Icon(Icons.close), onPressed: notifier.stop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
