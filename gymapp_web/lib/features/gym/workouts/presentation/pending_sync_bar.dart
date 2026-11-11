import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import 'pending_workouts.dart';

/// "2 workouts waiting to sync · Sync now" above the tabs while something saved
/// offline has not reached the server. Hidden otherwise. Watching the queue here
/// also keeps it alive (and retrying) for the whole logged-in session.
class PendingSyncBar extends ConsumerStatefulWidget {
  const PendingSyncBar({super.key});

  @override
  ConsumerState<PendingSyncBar> createState() => _PendingSyncBarState();
}

class _PendingSyncBarState extends ConsumerState<PendingSyncBar> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await ref.read(pendingWorkoutsProvider.notifier).sync();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(pendingWorkoutsProvider).length;
    if (count == 0) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Material(
      key: const Key('pending.bar'),
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
        child: Row(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(t.pendingCount(count), style: Theme.of(context).textTheme.bodyMedium)),
            _syncing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : TextButton(onPressed: _syncNow, child: Text(t.syncNow)),
          ],
        ),
      ),
    );
  }
}
