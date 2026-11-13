import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../core/errors/exceptions.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/failure_messages.dart';
import '../../core/providers/retry.dart';
import '../../core/widgets/error_view.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/auth_providers.dart';
import '../gym/workouts/data/workout_models.dart' show fromApiDate;

// ─── Data ──────────────────────────────────────────────────────────────────

class AdminDay {
  const AdminDay({required this.date, this.newUsers = 0, this.activeUsers = 0, this.trainingUsers = 0, this.workouts = 0});

  final DateTime date;
  final int newUsers;
  final int activeUsers;
  final int trainingUsers;
  final int workouts;

  factory AdminDay.fromJson(Map<String, dynamic> j) => AdminDay(
        date: fromApiDate(j['date'] as String),
        newUsers: (j['newUsers'] as num? ?? 0).toInt(),
        activeUsers: (j['activeUsers'] as num? ?? 0).toInt(),
        trainingUsers: (j['trainingUsers'] as num? ?? 0).toInt(),
        workouts: (j['workouts'] as num? ?? 0).toInt(),
      );
}

/// GET Admin/stats: counts only, no data of single users.
class AdminStats {
  const AdminStats({required this.generatedAt, required this.values, required this.days});

  final DateTime generatedAt;

  /// The API's counters by name: totalUsers, active24h, trained7d, …
  final Map<String, int> values;
  final List<AdminDay> days;

  int operator [](String key) => values[key] ?? 0;

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        generatedAt: DateTime.parse(j['generatedAt'] as String).toLocal(),
        values: {
          for (final MapEntry(:key, :value) in j.entries)
            if (value is num) key: value.toInt(),
        },
        days: [for (final d in j['days'] as List? ?? const []) AdminDay.fromJson(d as Map<String, dynamic>)],
      );
}

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  /// False for everyone else — and when the API does not know the panel yet.
  Future<bool> isAdmin() async {
    try {
      final res = await _dio.get<dynamic>('Admin/access');
      return (res.data as Map<String, dynamic>)['isAdmin'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<AdminStats> stats({int days = 30}) async {
    try {
      final res = await _dio.get<dynamic>('Admin/stats', queryParameters: {'days': days});
      return AdminStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on TypeError {
      throw const ServerFailure();
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref.watch(dioProvider)));

/// Shows the panel's entry in Settings.
final adminAccessProvider = FutureProvider.autoDispose<bool>((ref) => ref.watch(adminRepositoryProvider).isAdmin(), retry: noRetry);

final adminStatsProvider =
    FutureProvider.autoDispose<AdminStats>((ref) => ref.watch(adminRepositoryProvider).stats(), retry: noRetry);

// ─── Screen ────────────────────────────────────────────────────────────────

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final stats = ref.watch(adminStatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.adminPanel)),
      body: SafeArea(
        child: switch (stats) {
          AsyncValue(:final value?) => RefreshIndicator(
              onRefresh: () => ref.refresh(adminStatsProvider.future),
              child: _AdminBody(stats: value),
            ),
          AsyncValue(:final error?) => ErrorView(message: describeError(t, error), onRetry: () => ref.invalidate(adminStatsProvider)),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _AdminBody extends StatelessWidget {
  const _AdminBody({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return ListView(
      key: const Key('admin.list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.adminUpdated(DateFormat.Hm(locale).format(stats.generatedAt)), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        _Section(title: t.adminUsers, tiles: [
          (t.adminTotal, stats['totalUsers']),
          (t.adminConfirmed, stats['confirmedUsers']),
          (t.adminNew24h, stats['newUsers24h']),
          (t.adminNew7d, stats['newUsers7d']),
          (t.adminNew30d, stats['newUsers30d']),
        ]),
        _Section(title: t.adminActive, tiles: [
          (t.adminActive24h, stats['active24h']),
          (t.adminActive48h, stats['active48h']),
          (t.adminActive7d, stats['active7d']),
          (t.adminActive30d, stats['active30d']),
        ]),
        _Section(title: t.adminTraining, tiles: [
          (t.adminTrainedToday, stats['trainedToday']),
          (t.adminTrained7d, stats['trained7d']),
          (t.adminTrained30d, stats['trained30d']),
          (t.adminWorkouts7d, stats['workouts7d']),
          (t.adminSessions7d, stats['sessions7d']),
        ]),
        if (stats.days.isNotEmpty) _DailyChart(days: stats.days),
      ],
    );
  }
}

/// Title + a grid of "number over label" tiles.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});

  final String title;
  final List<(String, int)> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                final columns = (box.maxWidth / 150).floor().clamp(2, 5);
                final width = (box.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (label, value) in tiles)
                      SizedBox(
                        width: width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(count.format(value), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Text(label, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _Series { active, newUsers, training }

/// Bars per day for one series (active / new / training users), the highest value on top.
class _DailyChart extends StatefulWidget {
  const _DailyChart({required this.days});

  final List<AdminDay> days;

  @override
  State<_DailyChart> createState() => _DailyChartState();
}

class _DailyChartState extends State<_DailyChart> {
  _Series _series = _Series.active;

  int _value(AdminDay d) => switch (_series) {
        _Series.active => d.activeUsers,
        _Series.newUsers => d.newUsers,
        _Series.training => d.trainingUsers,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final values = widget.days.map(_value).toList();
    final max = values.fold(0, (m, v) => v > m ? v : m);
    const height = 120.0;
    return Card(
      key: const Key('admin.daily'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.adminDaily, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<_Series>(
              key: const Key('admin.series'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: _Series.active, label: Text(t.adminSeriesActive)),
                ButtonSegment(value: _Series.newUsers, label: Text(t.adminSeriesNew)),
                ButtonSegment(value: _Series.training, label: Text(t.adminSeriesTraining)),
              ],
              selected: {_series},
              onSelectionChanged: (v) => setState(() => _series = v.single),
            ),
            const SizedBox(height: 12),
            Text('max $max', style: theme.textTheme.labelSmall),
            Semantics(
              label: '${t.adminDaily}: ${values.join(', ')}',
              child: SizedBox(
                height: height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: Tooltip(
                          message: '${DateFormat.MMMd(locale).format(widget.days[i].date)}: ${values[i]}',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: max == 0 ? 2 : 2 + (height - 2) * values[i] / max,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: values[i] == 0 ? 0.2 : 0.85),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat.MMMd(locale).format(widget.days.first.date), style: theme.textTheme.labelSmall),
                Text(DateFormat.MMMd(locale).format(widget.days.last.date), style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
