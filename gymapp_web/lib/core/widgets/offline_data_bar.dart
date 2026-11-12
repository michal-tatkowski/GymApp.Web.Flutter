import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/app_localizations.dart';
import '../network/offline_cache.dart';

/// "Offline · data from 14:05" above the tabs while screens show saved replies.
/// Gone with the first reply from the server.
class OfflineDataBar extends ConsumerWidget {
  const OfflineDataBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAt = ref.watch(offlineDataProvider);
    if (savedAt == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final today = DateUtils.isSameDay(savedAt, DateTime.now());
    final when = today ? DateFormat.Hm(locale).format(savedAt) : DateFormat.MMMd(locale).add_Hm().format(savedAt);

    return Semantics(
      liveRegion: true,
      child: Material(
        key: const Key('offline.bar'),
        color: colors.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 20, color: colors.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.offlineData(when),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onTertiaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
