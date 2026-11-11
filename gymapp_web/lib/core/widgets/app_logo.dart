import 'package:flutter/material.dart';

/// App mark: dumbbell in a rounded square + optional "GymApp" wordmark.
/// Same motif as the launcher icon, so login and splash feel like the same app.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(size * 0.28)),
          child: Icon(Icons.fitness_center, size: size * 0.55, color: colors.onPrimary),
        ),
        if (showName) ...[
          SizedBox(height: size * 0.2),
          Text('GymApp', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }
}
