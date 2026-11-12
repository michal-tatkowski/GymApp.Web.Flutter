import 'package:flutter/material.dart';

import '../../../../core/units/weight_unit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/user_profile.dart';
import '../profile_format.dart';
import 'body_weight_card.dart';

/// Read-only profile: avatar with initials and a label/value list ("—" when empty).
class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.profile, this.weights = WeightFormat.kg});

  final UserProfile profile;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final gender = profile.gender;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // pull-to-refresh also when the content is short
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    profileInitials(profile),
                    style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              InfoTile(label: t.nickname, value: profile.nickname),
              InfoTile(label: t.firstName, value: profile.firstName),
              InfoTile(label: t.lastName, value: profile.lastName),
              InfoTile(
                label: t.gender,
                value: gender != null && gender != Gender.notSpecified ? genderLabel(t, gender) : null,
              ),
              InfoTile(
                label: t.height,
                value: profile.height != null ? '${formatNumber(profile.height!)} cm' : null,
              ),
              InfoTile(
                label: t.weight,
                value: profile.weight != null ? weights.withUnit(profile.weight!) : null,
              ),
              InfoTile(
                label: t.dateOfBirth,
                value: profile.dateOfBirth != null ? formatDate(context, profile.dateOfBirth!) : null,
              ),
              InfoTile(label: t.bmi, value: profile.bmi?.toStringAsFixed(1)),
              const SizedBox(height: 16),
              const BodyWeightCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value == null || value!.trim().isEmpty ? '—' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
