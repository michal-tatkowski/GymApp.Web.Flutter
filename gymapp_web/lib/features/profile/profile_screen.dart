import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/failure_messages.dart';
import '../../core/validation/validators.dart';
import '../../l10n/app_localizations.dart';
import 'data/models/update_profile_request.dart';
import 'data/models/user_profile.dart';
import 'presentation/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  Gender _gender = Gender.notSpecified;
  DateTime? _dateOfBirth;
  bool _editing = false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _populate(UserProfile p) {
    _nicknameCtrl.text = p.nickname ?? '';
    _firstNameCtrl.text = p.firstName ?? '';
    _lastNameCtrl.text = p.lastName ?? '';
    _heightCtrl.text = p.height != null ? _fmt(p.height!) : '';
    _weightCtrl.text = p.weight != null ? _fmt(p.weight!) : '';
    _gender = p.gender ?? Gender.notSpecified;
    _dateOfBirth = p.dateOfBirth;
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Text fields always sent ("" clears them on the server); empty number = unchanged.
    final req = UpdateProfileRequest(
      nickname: _nicknameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      gender: _gender,
      height: parseDecimal(_heightCtrl.text),
      weight: parseDecimal(_weightCtrl.text),
      dateOfBirth: _dateOfBirth,
    );

    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(profileControllerProvider.notifier).save(req);
    if (!mounted) return;
    if (error == null) setState(() => _editing = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error == null ? t.profileSaved : describeError(t, error))));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileControllerProvider);
    final isLoading = profileAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile),
        actions: [
          if (profileAsync.hasValue) ...[
            if (_editing) ...[
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => setState(() {
                          _populate(profileAsync.value!);
                          _editing = false;
                        }),
                child: Text(t.cancel),
              ),
              TextButton(
                onPressed: isLoading ? null : _save,
                child: Text(t.save),
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: t.edit,
                onPressed: () {
                  _populate(profileAsync.value!);
                  setState(() => _editing = true);
                },
              ),
          ],
        ],
      ),
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
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(
                message: describeError(t, err),
                onRetry: () => ref.read(profileControllerProvider.notifier).load(),
              ),
              data: (profile) {
                return _editing
                    ? _EditForm(
                        formKey: _formKey,
                        nicknameCtrl: _nicknameCtrl,
                        firstNameCtrl: _firstNameCtrl,
                        lastNameCtrl: _lastNameCtrl,
                        heightCtrl: _heightCtrl,
                        weightCtrl: _weightCtrl,
                        gender: _gender,
                        dateOfBirth: _dateOfBirth,
                        onGenderChanged: (g) => setState(() => _gender = g),
                        onPickDate: _pickDate,
                        isLoading: isLoading,
                      )
                    : _ProfileView(profile: profile);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Read-only view ──────────────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
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
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    _initials(profile),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _InfoTile(label: t.nickname, value: profile.nickname),
              _InfoTile(label: t.firstName, value: profile.firstName),
              _InfoTile(label: t.lastName, value: profile.lastName),
              _InfoTile(
                label: t.gender,
                value: profile.gender != null && profile.gender != Gender.notSpecified
                    ? _genderLabel(context, profile.gender!)
                    : null,
              ),
              _InfoTile(
                label: t.height,
                value: profile.height != null ? '${profile.height} cm' : null,
              ),
              _InfoTile(
                label: t.weight,
                value: profile.weight != null ? '${profile.weight} kg' : null,
              ),
              _InfoTile(
                label: t.dateOfBirth,
                value: profile.dateOfBirth != null
                    ? DateFormat.yMMMd().format(profile.dateOfBirth!)
                    : null,
              ),
              _InfoTile(
                label: t.bmi,
                value: profile.bmi != null ? profile.bmi!.toStringAsFixed(1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(UserProfile p) {
    final parts = [p.firstName, p.lastName, p.nickname]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit form ───────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.formKey,
    required this.nicknameCtrl,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.heightCtrl,
    required this.weightCtrl,
    required this.gender,
    required this.dateOfBirth,
    required this.onGenderChanged,
    required this.onPickDate,
    required this.isLoading,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nicknameCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final Gender gender;
  final DateTime? dateOfBirth;
  final ValueChanged<Gender> onGenderChanged;
  final VoidCallback onPickDate;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nicknameCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: t.nickname,
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: firstNameCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: t.firstName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: t.lastName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Gender>(
                  initialValue: gender,
                  decoration: InputDecoration(
                    labelText: t.gender,
                    prefixIcon: const Icon(Icons.wc),
                  ),
                  items: [
                    DropdownMenuItem(value: Gender.notSpecified, child: Text(t.notSpecified)),
                    DropdownMenuItem(value: Gender.male, child: Text(t.male)),
                    DropdownMenuItem(value: Gender.female, child: Text(t.female)),
                    DropdownMenuItem(value: Gender.other, child: Text(t.other)),
                  ],
                  onChanged: isLoading ? null : (v) => onGenderChanged(v ?? Gender.notSpecified),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: heightCtrl,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: t.heightWithUnit,
                    prefixIcon: const Icon(Icons.height),
                  ),
                  validator: (v) => validateOptionalNumber(t, v, min: 50, max: 272),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightCtrl,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: t.weightWithUnit,
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (v) => validateOptionalNumber(t, v, min: 20, max: 500),
                ),
                const SizedBox(height: 12),
                // Key = date: the field is rebuilt with the new value instead of
                // creating a new TextEditingController on every build (leak).
                TextFormField(
                  key: ValueKey(dateOfBirth),
                  readOnly: true,
                  enabled: !isLoading,
                  onTap: onPickDate,
                  decoration: InputDecoration(
                    labelText: t.dateOfBirth,
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  initialValue: dateOfBirth != null
                      ? DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(dateOfBirth!)
                      : '',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(t.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _genderLabel(BuildContext context, Gender gender) {
  final t = AppLocalizations.of(context)!;
  return switch (gender) {
    Gender.notSpecified => t.notSpecified,
    Gender.male => t.male,
    Gender.female => t.female,
    Gender.other => t.other,
  };
}
