import '../../l10n/app_localizations.dart';

/// Must match the API (RegisterUserCommandHandler.MinPasswordLength).
const kMinPasswordLength = 8;

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(AppLocalizations t, String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return t.emailRequired;
  if (!_emailRe.hasMatch(value)) return t.emailInvalid;
  return null;
}

/// Login: only "not empty". Registration: also the minimum length.
String? validatePassword(AppLocalizations t, String? v, {bool checkLength = false}) {
  if (v == null || v.isEmpty) return t.passwordRequired;
  if (checkLength && v.length < kMinPasswordLength) return t.passwordTooShort(kMinPasswordLength);
  return null;
}

/// Optional number (comma or dot as decimal separator) within [min]–[max].
String? validateOptionalNumber(AppLocalizations t, String? v, {required int min, required int max}) {
  if (v == null || v.trim().isEmpty) return null;
  final n = parseDecimal(v);
  if (n == null) return t.invalidNumber;
  if (n < min || n > max) return t.numberOutOfRange(min, max);
  return null;
}

double? parseDecimal(String v) => double.tryParse(v.trim().replaceAll(',', '.'));
