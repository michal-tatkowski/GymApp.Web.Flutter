import 'package:flutter/material.dart';

import '../../../../core/validation/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/update_profile_request.dart';
import '../../data/models/user_profile.dart';
import '../profile_format.dart';

/// Must match the API (UpdateUserDetailsCommandHandler).
const kMinHeightCm = 50, kMaxHeightCm = 272;
const kMinWeightKg = 20, kMaxWeightKg = 500;

/// Edit form prefilled from [initial]. Owns its controllers; the screen asks for
/// the result through a `GlobalKey<ProfileEditFormState>`:
/// `formKey.currentState!.buildRequest()` (null when validation fails).
class ProfileEditForm extends StatefulWidget {
  const ProfileEditForm({super.key, required this.initial, this.enabled = true});

  final UserProfile initial;
  final bool enabled;

  @override
  State<ProfileEditForm> createState() => ProfileEditFormState();
}

class ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nickname = TextEditingController(text: widget.initial.nickname ?? '');
  late final _firstName = TextEditingController(text: widget.initial.firstName ?? '');
  late final _lastName = TextEditingController(text: widget.initial.lastName ?? '');
  late final _height = TextEditingController(
      text: widget.initial.height != null ? formatNumber(widget.initial.height!) : '');
  late final _weight = TextEditingController(
      text: widget.initial.weight != null ? formatNumber(widget.initial.weight!) : '');
  late Gender _gender = widget.initial.gender ?? Gender.notSpecified;
  late DateTime? _dateOfBirth = widget.initial.dateOfBirth;

  @override
  void dispose() {
    for (final c in [_nickname, _firstName, _lastName, _height, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Validates and returns the PUT body, or null when a field is invalid.
  /// Text fields are always sent ("" clears them on the server); an empty
  /// number is omitted (= unchanged).
  UpdateProfileRequest? buildRequest() {
    if (!_formKey.currentState!.validate()) return null;
    return UpdateProfileRequest(
      nickname: _nickname.text.trim(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      gender: _gender,
      height: parseDecimal(_height.text),
      weight: parseDecimal(_weight.text),
      dateOfBirth: _dateOfBirth,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final enabled = widget.enabled;

    Widget text(TextEditingController c, String label, IconData icon, {Key? key}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            key: key,
            controller: c,
            enabled: enabled,
            decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          ),
        );

    Widget number(TextEditingController c, String label, IconData icon, int min, int max, {Key? key}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            key: key,
            controller: c,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
            validator: (v) => validateOptionalNumber(t, v, min: min, max: max),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                text(_nickname, t.nickname, Icons.alternate_email, key: const Key('profile.nickname')),
                text(_firstName, t.firstName, Icons.person_outline, key: const Key('profile.firstName')),
                text(_lastName, t.lastName, Icons.person_outline, key: const Key('profile.lastName')),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<Gender>(
                    initialValue: _gender,
                    decoration: InputDecoration(labelText: t.gender, prefixIcon: const Icon(Icons.wc)),
                    items: [
                      for (final g in Gender.values) DropdownMenuItem(value: g, child: Text(genderLabel(t, g))),
                    ],
                    onChanged: enabled ? (v) => setState(() => _gender = v ?? Gender.notSpecified) : null,
                  ),
                ),
                number(_height, t.heightWithUnit, Icons.height, kMinHeightCm, kMaxHeightCm,
                    key: const Key('profile.height')),
                number(_weight, t.weightWithUnit, Icons.monitor_weight_outlined, kMinWeightKg, kMaxWeightKg,
                    key: const Key('profile.weight')),
                // Key = date: the field is rebuilt with the new value instead of
                // creating a new TextEditingController on every build.
                TextFormField(
                  key: ValueKey(('profile.dateOfBirth', _dateOfBirth)),
                  readOnly: true,
                  enabled: enabled,
                  onTap: _pickDate,
                  decoration: InputDecoration(
                    labelText: t.dateOfBirth,
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  initialValue: _dateOfBirth != null ? formatDate(context, _dateOfBirth!) : '',
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
