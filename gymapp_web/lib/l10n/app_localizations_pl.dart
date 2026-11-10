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
  String get myWorkouts => 'Moje treningi';

  @override
  String get today => 'Dziś';

  @override
  String get metricVolume => 'Objętość';

  @override
  String get metricOneRepMax => '1RM';

  @override
  String get metricMaxWeight => 'Maks.';

  @override
  String get metricReps => 'Powt.';

  @override
  String get range1M => '1M';

  @override
  String get range3M => '3M';

  @override
  String get range1Y => '1R';

  @override
  String get rangeAll => 'Wszystko';

  @override
  String get personalRecord => '🏆 Rekord';

  @override
  String get newRecordVolume => '🏆 Nowy rekord: największa objętość!';

  @override
  String get newRecordOneRepMax =>
      '🏆 Nowy rekord: najsilniej do tej pory (szac. 1RM)!';

  @override
  String chartSemantics(String metric, String first, String last, int days) {
    return 'Wykres $metric: od $first do $last, $days dni treningowych';
  }

  @override
  String get undo => 'Cofnij';

  @override
  String get close => 'Zamknij';

  @override
  String get off => 'Wył.';

  @override
  String repeatLast(String sets) {
    return 'Powtórz ostatni: $sets';
  }

  @override
  String get repeatLastShort => 'Powtórz ostatni trening';

  @override
  String decreaseBy(String step) {
    return 'Zmniejsz o $step';
  }

  @override
  String increaseBy(String step) {
    return 'Zwiększ o $step';
  }

  @override
  String get restTimer => 'Timer przerwy';

  @override
  String get restTimerHint => 'Startuje sam po zapisaniu treningu.';

  @override
  String restRemaining(String time) {
    return 'Przerwa $time';
  }

  @override
  String get restOver => 'Koniec przerwy — następna seria!';

  @override
  String get quickLog => 'Szybki zapis';

  @override
  String get doneToday => 'Zrobione dzisiaj';

  @override
  String get noFavoritesYet =>
      'Oznacz ćwiczenia gwiazdką (★), żeby zapisywać je tutaj jednym dotknięciem.';

  @override
  String get browseExercises => 'Przeglądaj ćwiczenia';

  @override
  String get notTrainedYet => 'Jeszcze nie trenowane';

  @override
  String get logWorkout => 'Zapisz trening';

  @override
  String get editWorkout => 'Edytuj trening';

  @override
  String get workoutHistory => 'Historia';

  @override
  String get noWorkoutsYet =>
      'Nie masz jeszcze treningów. Otwórz ćwiczenie i wybierz „Zapisz trening”.';

  @override
  String get noEntriesForExercise => 'Brak treningów dla tego ćwiczenia.';

  @override
  String get progress => 'Postęp';

  @override
  String get progressNeedsMoreDays =>
      'Zapisz co najmniej dwa dni treningowe, żeby zobaczyć trend.';

  @override
  String setNumber(int number) {
    return 'Seria $number';
  }

  @override
  String get reps => 'Powtórzenia';

  @override
  String get weightKgShort => 'kg';

  @override
  String get addSet => 'Dodaj serię';

  @override
  String get removeSet => 'Usuń serię';

  @override
  String get notesOptional => 'Notatka (opcjonalnie)';

  @override
  String get date => 'Data';

  @override
  String get workoutSaved => 'Trening zapisany';

  @override
  String get entryDeleted => 'Trening usunięty';

  @override
  String get delete => 'Usuń';

  @override
  String lastWorkout(String date) {
    return 'Ostatnio: $date';
  }

  @override
  String trainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni treningowych',
      many: '$count dni treningowych',
      few: '$count dni treningowe',
      one: '1 dzień treningowy',
    );
    return '$_temp0';
  }

  @override
  String volumeValue(String value) {
    return '$value kg';
  }

  @override
  String bestValue(String value) {
    return 'rekord $value';
  }

  @override
  String repsValue(int count) {
    return '$count powt.';
  }

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
