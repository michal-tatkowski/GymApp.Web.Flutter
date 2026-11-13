import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/units/measures.dart';
import '../../../l10n/app_localizations.dart';

/// Countdown for a timed set (plank, hang): 3 s to get into position, then [seconds]
/// counted down with a buzz at the end. Returns the seconds actually held — all of them
/// at the end, fewer with "Finish now" — or null when cancelled.
Future<int?> runTimedSet(BuildContext context, int seconds) => showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TimedSetDialog(seconds: seconds),
    );

class TimedSetDialog extends StatefulWidget {
  const TimedSetDialog({super.key, required this.seconds});

  static const getReadySeconds = 3;

  final int seconds;

  @override
  State<TimedSetDialog> createState() => _TimedSetDialogState();
}

class _TimedSetDialogState extends State<TimedSetDialog> {
  Timer? _timer;
  int _ready = TimedSetDialog.getReadySeconds;
  int _held = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_paused || !mounted) return;
    setState(() {
      if (_ready > 0) {
        _ready--;
        if (_ready == 0) HapticFeedback.mediumImpact(); // go
        return;
      }
      _held++;
    });
    if (_ready == 0 && _held >= widget.seconds) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      _close(widget.seconds);
    } else if (_ready == 0 && widget.seconds - _held <= 3) {
      HapticFeedback.selectionClick(); // last three seconds
    }
  }

  void _close(int? result) {
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ready = _ready > 0;
    final left = widget.seconds - _held;
    return AlertDialog(
      key: const Key('timedSet'),
      title: Text(ready ? t.getReady : t.timedSetTitle, textAlign: TextAlign.center),
      content: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: ready ? 1 : left / widget.seconds,
                strokeWidth: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            Text(
              ready ? '$_ready' : formatDuration(left),
              key: const Key('timedSet.left'),
              style: theme.textTheme.displayMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(key: const Key('timedSet.cancel'), onPressed: () => _close(null), child: Text(t.cancel)),
        IconButton.filledTonal(
          key: const Key('timedSet.pause'),
          tooltip: _paused ? t.timedSetResume : t.timedSetPause,
          iconSize: 32,
          onPressed: () => setState(() => _paused = !_paused),
          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
        ),
        FilledButton(
          key: const Key('timedSet.finish'),
          onPressed: ready || _held == 0 ? null : () => _close(_held),
          child: Text(t.timedSetFinishNow),
        ),
      ],
    );
  }
}
