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
  String get forgotPassword => 'Nie pamiętasz hasła?';

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
  String get aboutExercise => 'O ćwiczeniu';

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
  String get restNotificationTitle => 'Przerwa';

  @override
  String get restNotificationBody => 'Następna seria po końcu odliczania';

  @override
  String get restCountdownChannel => 'Odliczanie przerwy';

  @override
  String get restOverChannel => 'Koniec przerwy';

  @override
  String get restExactAlarm => 'Powiadomienie dokładnie na czas';

  @override
  String get restExactAlarmHint =>
      'Zezwól na alarmy, żeby powiadomienie o końcu przerwy nie spóźniało się przy zablokowanym telefonie';

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
  String get savedOffline =>
      'Zapisano w telefonie — wyślemy, gdy wróci internet';

  @override
  String get waitingToSync => 'Czeka na wysłanie';

  @override
  String get offlineTitle => 'Brak połączenia';

  @override
  String get offlineLogHint =>
      'Nadal możesz zapisywać treningi — zostaną w telefonie i wyślemy je później.';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treningów czeka na wysłanie',
      few: '$count treningi czekają na wysłanie',
      one: '1 trening czeka na wysłanie',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Wyślij teraz';

  @override
  String get logoutPendingTitle => 'Niewysłane treningi';

  @override
  String get logoutPendingBody =>
      'Treningi zapisane offline, które nie zostały jeszcze wysłane, przepadną. Wylogować mimo to?';

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
  String get weightUnit => 'Jednostka ciężaru';

  @override
  String get reminders => 'Przypomnienia o treningu';

  @override
  String get remindersHint => 'Powiadomienie w dni, w które trenujesz';

  @override
  String get reminderTime => 'Godzina';

  @override
  String get reminderTitle => 'Czas na trening 💪';

  @override
  String get reminderBody => 'Plan czeka — stuknij, żeby zacząć.';

  @override
  String get reminderChannel => 'Przypomnienia o treningu';

  @override
  String get reminderPermissionDenied =>
      'Zezwól GymApp na powiadomienia w ustawieniach systemu, żeby dostawać przypomnienia.';

  @override
  String get bodyWeight => 'Masa ciała';

  @override
  String get bodyWeightLog => 'Zapisz';

  @override
  String get bodyWeightToday => 'Dzisiejsza waga';

  @override
  String get bodyWeightEmpty =>
      'Zapisuj wagę od czasu do czasu, żeby zobaczyć trend.';

  @override
  String bodyWeightChange(String change) {
    return '$change w 30 dni';
  }

  @override
  String get thisWeek => 'Ten tydzień';

  @override
  String get weekNothingYet => 'W tym tygodniu jeszcze bez treningu';

  @override
  String weekWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treningów',
      few: '$count treningi',
      one: '1 trening',
    );
    return '$_temp0';
  }

  @override
  String weekSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serii',
      few: '$count serie',
      one: '1 seria',
    );
    return '$_temp0';
  }

  @override
  String weekStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tygodni z rzędu',
      few: '$count tygodnie z rzędu',
    );
    return '$_temp0';
  }

  @override
  String weekRecords(String names) {
    return 'Rekordy: $names';
  }

  @override
  String get sessionInProgressTitle => 'Trening w toku';

  @override
  String sessionInProgressBody(String plan) {
    return '„$plan” nie jest jeszcze zakończony. Wrócić do niego czy zacząć nowy (niezapisane serie starego przepadną)?';
  }

  @override
  String get sessionResume => 'Wróć';

  @override
  String get sessionStartNew => 'Zacznij nowy';

  @override
  String get sessionDiscard => 'Porzuć trening';

  @override
  String get sessionDiscardTitle => 'Porzucić ten trening?';

  @override
  String get sessionDiscardBody =>
      'Niezapisane serie przepadną. Ćwiczenia już zapisane zostają w historii.';

  @override
  String get sessionNone => 'Brak trwającego treningu.';

  @override
  String get sessionFinish => 'Zakończ';

  @override
  String get sessionNext => 'Dalej';

  @override
  String get sessionPrevious => 'Wstecz';

  @override
  String get sessionSaved => 'Zapisane w historii';

  @override
  String sessionTarget(String target) {
    return 'Cel: $target powt.';
  }

  @override
  String sessionLastTime(String sets) {
    return 'Ostatnio: $sets';
  }

  @override
  String hintAddWeight(String weight, int reps) {
    return 'Górna granica zakresu osiągnięta — dziś $weight × $reps';
  }

  @override
  String get hintAddReps =>
      'Górna granica zakresu osiągnięta — dziś jedno powtórzenie więcej w serii';

  @override
  String hintRepeat(int reps) {
    return 'Ten sam ciężar — celuj w $reps powt. w każdej serii';
  }

  @override
  String get hintFirstTime =>
      'Pierwszy raz — wybierz ciężar, z którym zachowasz dobrą technikę';

  @override
  String get repsShort => 'powt.';

  @override
  String get sessionDoneSet => 'Seria zrobiona';

  @override
  String get sessionUndoSet => 'Cofnij serię';

  @override
  String get sessionSummaryTitle => 'Trening zrobiony!';

  @override
  String sessionSummaryStats(int minutes, int exercises, int sets) {
    return '$minutes min · ćwiczenia: $exercises · serie: $sets';
  }

  @override
  String sessionSummaryVolume(String volume) {
    return 'Objętość: $volume';
  }

  @override
  String sessionSummaryRecords(String names) {
    return 'Nowe rekordy: $names';
  }

  @override
  String sessionActive(String plan, int done, int total) {
    return '$plan w toku · $done/$total';
  }

  @override
  String get done => 'Gotowe';

  @override
  String get plans => 'Plany';

  @override
  String get newPlan => 'Nowy plan';

  @override
  String get editPlan => 'Edytuj plan';

  @override
  String get planName => 'Nazwa planu';

  @override
  String get planNameHint => 'np. Push, FBW A';

  @override
  String get planNameRequired => 'Podaj nazwę planu';

  @override
  String get planNeedsExercise => 'Dodaj co najmniej jedno ćwiczenie';

  @override
  String get planEmptyHint =>
      'Dodaj ćwiczenia w kolejności wykonywania. Ustaw każdemu cel: serie × powtórzenia.';

  @override
  String get deletePlanTitle => 'Usunąć plan?';

  @override
  String deletePlanBody(String name) {
    return 'Plan „$name” zostanie usunięty. Historia treningów zostaje.';
  }

  @override
  String get noPlansYet =>
      'Utwórz plan (np. Push / Pull / Legs), żeby jednym stuknięciem zacząć prowadzony trening.';

  @override
  String get remove => 'Usuń';

  @override
  String get sets => 'Serie';

  @override
  String get repsFrom => 'Powt.';

  @override
  String get repsTo => 'do';

  @override
  String get startWorkout => 'Start';

  @override
  String planExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ćwiczeń',
      few: '$count ćwiczenia',
      one: '1 ćwiczenie',
    );
    return '$_temp0';
  }

  @override
  String get weightUnitHint => 'Historia i wykresy też zostaną przeliczone.';

  @override
  String get theme => 'Motyw';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

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

  @override
  String get privacyPolicy => 'Polityka prywatności';

  @override
  String privacyUpdated(String date) {
    return 'Ostatnia aktualizacja: $date';
  }

  @override
  String get privacyAgree =>
      'Zakładając konto, akceptujesz politykę prywatności.';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteAccountHint => 'Trwale, razem ze wszystkimi danymi';

  @override
  String get deleteAccountTitle => 'Usunąć konto?';

  @override
  String get deleteAccountBody =>
      'Profil, treningi, plany, własne ćwiczenia i pomiary wagi zostaną usunięte z serwera. Tego nie da się cofnąć.';

  @override
  String get deleteAccountPassword => 'Hasło dla potwierdzenia';

  @override
  String get deleteAccountConfirm => 'Usuń na zawsze';

  @override
  String get verifyEmailTitle => 'Potwierdź e-mail';

  @override
  String verifyEmailBody(String email) {
    return 'Wysłaliśmy 6-cyfrowy kod na $email. Wpisz go, aby dokończyć zakładanie konta.';
  }

  @override
  String get codeLabel => 'Kod';

  @override
  String get confirmCode => 'Potwierdź';

  @override
  String get resendCode => 'Wyślij nowy kod';

  @override
  String resendIn(int seconds) {
    return 'Nowy kod za $seconds s';
  }

  @override
  String get codeSent => 'Wysłaliśmy nowy kod. Sprawdź skrzynkę (i spam).';

  @override
  String get backToLogin => 'Wróć do logowania';

  @override
  String get forgotTitle => 'Reset hasła';

  @override
  String get forgotBody =>
      'Podaj e-mail konta. Wyślemy kod do ustawienia nowego hasła.';

  @override
  String get sendCode => 'Wyślij kod';

  @override
  String resetBody(String email) {
    return 'Jeśli $email ma konto, wysłaliśmy na niego kod. Wpisz go razem z nowym hasłem.';
  }

  @override
  String get newPassword => 'Nowe hasło';

  @override
  String get setNewPassword => 'Ustaw nowe hasło';

  @override
  String get passwordChanged => 'Hasło zmienione. Zaloguj się nowym.';
}
