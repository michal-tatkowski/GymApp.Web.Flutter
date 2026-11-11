import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Extended FAB that shrinks to its icon while the user scrolls down a list
/// and grows back when scrolling up (Material 3 pattern), so it does not sit
/// on top of the last rows. Wrap the scrollable in [ScrollAwareFab.listener].
class ScrollAwareFab extends StatelessWidget {
  const ScrollAwareFab({
    super.key,
    required this.extended,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final ValueNotifier<bool> extended;
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  /// Updates [extended] from scroll direction of the wrapped scrollable.
  static Widget listener({required ValueNotifier<bool> extended, required Widget child}) =>
      NotificationListener<UserScrollNotification>(
        onNotification: (n) {
          if (n.depth != 0) return false;
          if (n.direction == ScrollDirection.reverse) extended.value = false;
          if (n.direction == ScrollDirection.forward) extended.value = true;
          return false;
        },
        child: child,
      );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: extended,
    builder: (_, isExtended, __) => FloatingActionButton.extended(
      onPressed: onPressed,
      isExtended: isExtended,
      tooltip: isExtended ? null : label,
      icon: icon,
      label: Text(label),
    ),
  );
}
