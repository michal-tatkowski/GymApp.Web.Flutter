import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_routes.dart';

class GymScreen extends ConsumerWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    final items = [
      _GymTile(
        icon: Icons.calendar_month,
        label: t.weeklyPlan,
        route: AppRoutes.gymWeeklyPlan,
      ),
      _GymTile(
        icon: Icons.fitness_center,
        label: t.exercises,
        route: AppRoutes.gymExercises,
      ),
      _GymTile(
        icon: Icons.bar_chart,
        label: t.charts,
        route: null, 
      ),
      _GymTile(
        icon: Icons.sports_gymnastics,
        label: t.workouts,
        route: AppRoutes.gymWorkouts,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.gym)),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.10),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: items
                    .map((item) => _GymTileWidget(item: item))
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymTile {
  const _GymTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String? route;
}

class _GymTileWidget extends StatelessWidget {
  const _GymTileWidget({required this.item});

  final _GymTile item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = item.route != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        elevation: enabled ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: enabled ? () => context.push(item.route!) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(item.label, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
