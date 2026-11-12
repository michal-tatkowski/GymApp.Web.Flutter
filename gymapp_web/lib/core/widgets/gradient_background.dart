import 'package:flutter/material.dart';

/// The soft primary → secondary gradient used behind the app's content screens.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Pure black (OLED): no tint, the pixels stay off.
    if (theme.scaffoldBackgroundColor == Colors.black) return SizedBox.expand(child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.secondary.withValues(alpha: 0.10),
          ],
        ),
      ),
      // Fill the whole body even when the content is short (e.g. the profile),
      // otherwise the gradient stops where the content ends.
      child: SizedBox.expand(child: child),
    );
  }
}
