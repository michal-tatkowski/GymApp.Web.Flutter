import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/core/errors/failure_messages.dart';
import 'package:gymapp_web/features/settings/presentation/settings_providers.dart';
import 'package:gymapp_web/l10n/app_localizations_en.dart';
import 'package:gymapp_web/l10n/app_localizations_pl.dart';

void main() {
  final en = AppLocalizationsEn();
  final pl = AppLocalizationsPl();

  test('server message wins over the default text', () {
    expect(describeError(pl, const ValidationFailure('Wzrost musi wynosić od 50 do 272 cm.')),
        'Wzrost musi wynosić od 50 do 272 cm.');
  });

  test('defaults follow the app language', () {
    expect(describeError(en, const NetworkFailure()), 'No internet connection.');
    expect(describeError(pl, const NetworkFailure()), 'Brak połączenia z internetem.');
    expect(describeError(pl, const UnauthorizedFailure()), pl.errSessionExpired);
    expect(describeError(en, const ServerFailure(null, 503)), 'Server error (503).');
  });

  test('blank server message falls back to the default', () {
    expect(describeError(en, const ValidationFailure('  ')), en.errValidation);
  });

  test('non-Failure errors never leak technical details', () {
    expect(describeError(en, Exception('SocketException: secret host')), en.errUnknown);
    expect(describeError(en, const ServerFailure()), en.errUnknown);
  });

  test('device language is used when supported, English otherwise', () {
    expect(deviceLocale('pl').languageCode, 'pl');
    expect(deviceLocale('en').languageCode, 'en');
    expect(deviceLocale('de').languageCode, 'en');
  });
}
