// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get login => 'Zaloguj';

  @override
  String get logout => 'Wyloguj';

  @override
  String get register => 'Zarejestruj';

  @override
  String get email => 'Email';

  @override
  String get password => 'Hasło';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Zarejestruj';

  @override
  String get forgotPassword => 'Zapomniałeś hasła?';

  @override
  String get or => 'albo';

  @override
  String get rememberMe => 'Zapamiętaj mnie';

  @override
  String get gym => 'Siłownia';

  @override
  String get settings => 'Ustawienia';

  @override
  String get home => 'Centrum';

  @override
  String get profile => 'Profil';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get info => 'Informacje';

  @override
  String get social => 'Społeczne';

  @override
  String get nickname => 'Nazwa użytkownika';

  @override
  String get firstName => 'Imię';

  @override
  String get lastName => 'Nazwisko';

  @override
  String get gender => 'Płeć';

  @override
  String get height => 'Wzrost';

  @override
  String get weight => 'Waga';

  @override
  String get dateOfBirth => 'Data urodzenia';

  @override
  String get save => 'Zapisz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get edit => 'Edytuj';

  @override
  String get male => 'Mężczyzna';

  @override
  String get female => 'Kobieta';

  @override
  String get other => 'Inne';

  @override
  String get notSpecified => 'Nie podano';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get profileSaved => 'Profil został zapisany';

  @override
  String get profileLoadError => 'Nie udało się załadować profilu';

  @override
  String get bmi => 'BMI';

  @override
  String get weeklyPlan => 'Plan tygodniowy';

  @override
  String get charts => 'Wykresy';

  @override
  String get workouts => 'Treningi';

  @override
  String get exercises => 'Ćwiczenia';

  @override
  String get searchExercises => 'Szukaj ćwiczeń';

  @override
  String get addExercise => 'Dodaj ćwiczenie';

  @override
  String get exerciseName => 'Nazwa ćwiczenia';

  @override
  String get category => 'Kategoria';

  @override
  String get description => 'Opis';

  @override
  String get descriptionOptional => 'Opis (opcjonalnie)';

  @override
  String get noExercisesFound => 'Nie znaleziono ćwiczeń';

  @override
  String get exerciseAdded => 'Ćwiczenie dodane';

  @override
  String get customExercise => 'Własne';

  @override
  String get noDescription => 'Brak opisu';

  @override
  String get allCategories => 'Wszystkie';

  @override
  String get fieldRequired => 'To pole jest wymagane';

  @override
  String get catPush => 'Pchające';

  @override
  String get catPull => 'Ciągnące';

  @override
  String get catLegs => 'Nogi';

  @override
  String get catCore => 'Core';

  @override
  String get catCardio => 'Cardio';

  @override
  String get catOther => 'Inne';

  @override
  String get favorites => 'Ulubione';

  @override
  String get addToFavorites => 'Dodaj do ulubionych';

  @override
  String get removeFromFavorites => 'Usuń z ulubionych';

  @override
  String get emailRequired => 'Podaj e-mail';

  @override
  String get emailInvalid => 'Nieprawidłowy format e-mail';

  @override
  String get passwordRequired => 'Podaj hasło';

  @override
  String passwordTooShort(int min) {
    return 'Hasło musi mieć co najmniej $min znaków';
  }

  @override
  String get registerTitle => 'Rejestracja';

  @override
  String get registering => 'Rejestrowanie…';

  @override
  String get accountCreated => 'Konto utworzone. Zaloguj się.';

  @override
  String get darkTheme => 'Ciemny motyw';

  @override
  String get language => 'Język';

  @override
  String get previousWeek => 'Poprzedni tydzień';

  @override
  String get nextWeek => 'Następny tydzień';

  @override
  String get invalidNumber => 'Nieprawidłowa liczba';

  @override
  String numberOutOfRange(int min, int max) {
    return 'Podaj wartość od $min do $max';
  }

  @override
  String get heightWithUnit => 'Wzrost (cm)';

  @override
  String get weightWithUnit => 'Waga (kg)';

  @override
  String get errNetwork => 'Brak połączenia z internetem.';

  @override
  String get errTimeout => 'Serwer nie odpowiada.';

  @override
  String get errSessionExpired => 'Sesja wygasła, zaloguj się ponownie.';

  @override
  String get errBadCertificate => 'Nieprawidłowy certyfikat serwera.';

  @override
  String get errCancelled => 'Żądanie zostało anulowane.';

  @override
  String get errValidation => 'Nieprawidłowe dane.';

  @override
  String errServer(int status) {
    return 'Błąd serwera ($status).';
  }

  @override
  String get errForbidden => 'Nie masz do tego dostępu.';

  @override
  String get errNotFound => 'Nie znaleziono.';

  @override
  String get errConflict => 'To już istnieje.';

  @override
  String get errTooManyRequests =>
      'Zbyt wiele prób. Odczekaj minutę i spróbuj ponownie.';

  @override
  String get errUnknown => 'Wystąpił nieoczekiwany błąd.';
}
