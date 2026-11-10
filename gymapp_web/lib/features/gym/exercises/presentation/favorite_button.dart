import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Star toggle used on the exercise list and the exercise details.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return IconButton(
      onPressed: onPressed,
      tooltip: isFavorite ? t.removeFromFavorites : t.addToFavorites,
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber.shade700 : null,
      ),
    );
  }
}
