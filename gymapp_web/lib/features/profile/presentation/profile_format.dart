import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../data/models/user_profile.dart';

String genderLabel(AppLocalizations t, Gender gender) => switch (gender) {
      Gender.notSpecified => t.notSpecified,
      Gender.male => t.male,
      Gender.female => t.female,
      Gender.other => t.other,
    };

/// 180.0 → "180", 80.5 → "80.5".
String formatNumber(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

/// Date in the app's language, e.g. "1 maj 1990" / "May 1, 1990".
String formatDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);

/// Up to two letters from first name / last name / nickname, "?" when none.
String profileInitials(UserProfile p) {
  final parts = [p.firstName, p.lastName, p.nickname]
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
