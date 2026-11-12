// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Register';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get or => 'or';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get gym => 'Gym';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get info => 'Info';

  @override
  String get social => 'Social';

  @override
  String get nickname => 'Nickname';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get gender => 'Gender';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get retry => 'Try again';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileLoadError => 'Failed to load profile';

  @override
  String get bmi => 'BMI';

  @override
  String get weeklyPlan => 'Weekly plan';

  @override
  String get charts => 'Charts';

  @override
  String get workouts => 'Workouts';

  @override
  String get exercises => 'Exercises';

  @override
  String get searchExercises => 'Search exercises';

  @override
  String get addExercise => 'Add exercise';

  @override
  String get exerciseName => 'Exercise name';

  @override
  String get category => 'Category';

  @override
  String get description => 'Description';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get noExercisesFound => 'No exercises found';

  @override
  String get exerciseAdded => 'Exercise added';

  @override
  String get customExercise => 'Custom';

  @override
  String get noDescription => 'No description';

  @override
  String get aboutExercise => 'About this exercise';

  @override
  String get allCategories => 'All';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get catPush => 'Push';

  @override
  String get catPull => 'Pull';

  @override
  String get catLegs => 'Legs';

  @override
  String get catCore => 'Core';

  @override
  String get catCardio => 'Cardio';

  @override
  String get catOther => 'Other';

  @override
  String get favorites => 'Favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get myWorkouts => 'My workouts';

  @override
  String get today => 'Today';

  @override
  String get metricVolume => 'Volume';

  @override
  String get metricOneRepMax => '1RM';

  @override
  String get metricMaxWeight => 'Max';

  @override
  String get metricReps => 'Reps';

  @override
  String get range1M => '1M';

  @override
  String get range3M => '3M';

  @override
  String get range1Y => '1Y';

  @override
  String get rangeAll => 'All';

  @override
  String get personalRecord => '🏆 Personal record';

  @override
  String get newRecordVolume => '🏆 New record: best volume so far!';

  @override
  String get newRecordOneRepMax =>
      '🏆 New record: strongest so far (est. 1RM)!';

  @override
  String chartSemantics(String metric, String first, String last, int days) {
    return '$metric chart: from $first to $last over $days training days';
  }

  @override
  String get undo => 'Undo';

  @override
  String get close => 'Close';

  @override
  String get off => 'Off';

  @override
  String repeatLast(String sets) {
    return 'Repeat last: $sets';
  }

  @override
  String get repeatLastShort => 'Repeat last workout';

  @override
  String decreaseBy(String step) {
    return 'Decrease by $step';
  }

  @override
  String increaseBy(String step) {
    return 'Increase by $step';
  }

  @override
  String get restTimer => 'Rest timer';

  @override
  String get restTimerHint => 'Starts automatically after you log a workout.';

  @override
  String restRemaining(String time) {
    return 'Rest $time';
  }

  @override
  String get restOver => 'Rest is over — next set!';

  @override
  String get restNotificationTitle => 'Rest';

  @override
  String get restNotificationBody => 'Next set when the countdown ends';

  @override
  String get restCountdownChannel => 'Rest countdown';

  @override
  String get restOverChannel => 'End of rest';

  @override
  String get restExactAlarm => 'Alert exactly on time';

  @override
  String get restExactAlarmHint =>
      'Allow alarms so the end-of-rest alert is not delayed when the phone is locked';

  @override
  String get quickLog => 'Quick log';

  @override
  String get doneToday => 'Done today';

  @override
  String get noFavoritesYet =>
      'Star exercises (★) to log them here with one tap.';

  @override
  String get browseExercises => 'Browse exercises';

  @override
  String get notTrainedYet => 'Not trained yet';

  @override
  String get logWorkout => 'Log workout';

  @override
  String get editWorkout => 'Edit workout';

  @override
  String get workoutHistory => 'History';

  @override
  String get noWorkoutsYet =>
      'No workouts yet. Open an exercise and tap \"Log workout\".';

  @override
  String get noEntriesForExercise => 'No workouts for this exercise yet.';

  @override
  String get progress => 'Progress';

  @override
  String get progressNeedsMoreDays =>
      'Log at least two training days to see the trend.';

  @override
  String setNumber(int number) {
    return 'Set $number';
  }

  @override
  String get reps => 'Reps';

  @override
  String get addSet => 'Add set';

  @override
  String get removeSet => 'Remove set';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get date => 'Date';

  @override
  String get workoutSaved => 'Workout saved';

  @override
  String get savedOffline =>
      'Saved on the phone — it will be sent when you\'re online';

  @override
  String get waitingToSync => 'Waiting to sync';

  @override
  String get offlineTitle => 'You\'re offline';

  @override
  String get offlineLogHint =>
      'You can still log workouts — they\'re kept on the phone and sent later.';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts waiting to sync',
      one: '1 workout waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get logoutPendingTitle => 'Workouts not sent yet';

  @override
  String get logoutPendingBody =>
      'Workouts saved offline that have not been sent yet will be lost. Log out anyway?';

  @override
  String get entryDeleted => 'Workout deleted';

  @override
  String get delete => 'Delete';

  @override
  String lastWorkout(String date) {
    return 'Last: $date';
  }

  @override
  String trainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count training days',
      one: '1 training day',
    );
    return '$_temp0';
  }

  @override
  String bestValue(String value) {
    return 'best $value';
  }

  @override
  String repsValue(int count) {
    return '$count reps';
  }

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get emailInvalid => 'Invalid email format';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String passwordTooShort(int min) {
    return 'Password must be at least $min characters long';
  }

  @override
  String get registerTitle => 'Create account';

  @override
  String get registering => 'Creating account…';

  @override
  String get weightUnit => 'Weight unit';

  @override
  String get reminders => 'Workout reminders';

  @override
  String get remindersHint => 'A notification on the days you train';

  @override
  String get reminderTime => 'Time';

  @override
  String get reminderTitle => 'Time to train 💪';

  @override
  String get reminderBody => 'Your plan is ready — tap to start.';

  @override
  String get reminderChannel => 'Workout reminders';

  @override
  String get reminderPermissionDenied =>
      'Allow notifications for GymApp in the system settings to get reminders.';

  @override
  String get bodyWeight => 'Body weight';

  @override
  String get bodyWeightLog => 'Log';

  @override
  String get bodyWeightToday => 'Today\'s weight';

  @override
  String get bodyWeightEmpty =>
      'Log your weight now and then to see the trend.';

  @override
  String bodyWeightChange(String change) {
    return '$change in 30 days';
  }

  @override
  String get thisWeek => 'This week';

  @override
  String get weekNothingYet => 'No workout yet this week';

  @override
  String weekWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String weekSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String weekStreak(int count) {
    return '$count-week streak';
  }

  @override
  String weekRecords(String names) {
    return 'Records: $names';
  }

  @override
  String get sessionInProgressTitle => 'Workout in progress';

  @override
  String sessionInProgressBody(String plan) {
    return '\"$plan\" is not finished yet. Resume it or start the new one (sets not saved yet in the old one are dropped)?';
  }

  @override
  String get sessionResume => 'Resume';

  @override
  String get sessionStartNew => 'Start new';

  @override
  String get sessionDiscard => 'Discard workout';

  @override
  String get sessionDiscardTitle => 'Discard this workout?';

  @override
  String get sessionDiscardBody =>
      'Sets not saved yet are dropped. Exercises already saved stay in your history.';

  @override
  String get sessionNone => 'No workout in progress.';

  @override
  String get sessionFinish => 'Finish';

  @override
  String get sessionNext => 'Next';

  @override
  String get sessionPrevious => 'Back';

  @override
  String get sessionSaved => 'Saved to your history';

  @override
  String sessionTarget(String target) {
    return 'Target: $target reps';
  }

  @override
  String sessionLastTime(String sets) {
    return 'Last time: $sets';
  }

  @override
  String hintAddWeight(String weight, int reps) {
    return 'You hit the top of the range — today $weight × $reps';
  }

  @override
  String get hintAddReps =>
      'You hit the top of the range — one more rep per set today';

  @override
  String hintRepeat(int reps) {
    return 'Same weight — aim for $reps reps in every set';
  }

  @override
  String get hintFirstTime =>
      'First time — pick a weight you can do with good form';

  @override
  String get repsShort => 'reps';

  @override
  String get sessionDoneSet => 'Set done';

  @override
  String get sessionUndoSet => 'Not done';

  @override
  String get sessionSummaryTitle => 'Workout done!';

  @override
  String sessionSummaryStats(int minutes, int exercises, int sets) {
    return '$minutes min · $exercises exercises · $sets sets';
  }

  @override
  String sessionSummaryVolume(String volume) {
    return 'Volume: $volume';
  }

  @override
  String sessionSummaryRecords(String names) {
    return 'New records: $names';
  }

  @override
  String sessionActive(String plan, int done, int total) {
    return '$plan in progress · $done/$total';
  }

  @override
  String get done => 'Done';

  @override
  String get plans => 'Plans';

  @override
  String get newPlan => 'New plan';

  @override
  String get editPlan => 'Edit plan';

  @override
  String get planName => 'Plan name';

  @override
  String get planNameHint => 'e.g. Push, FBW A';

  @override
  String get planNameRequired => 'Enter a plan name';

  @override
  String get planNeedsExercise => 'Add at least one exercise';

  @override
  String get planEmptyHint =>
      'Add the exercises in the order you do them. Set the target for each: sets × reps.';

  @override
  String get deletePlanTitle => 'Delete plan?';

  @override
  String deletePlanBody(String name) {
    return '\"$name\" will be deleted. Your workout history stays.';
  }

  @override
  String get noPlansYet =>
      'Create a plan (e.g. Push / Pull / Legs) to start a guided workout with one tap.';

  @override
  String get remove => 'Remove';

  @override
  String get sets => 'Sets';

  @override
  String get repsFrom => 'Reps';

  @override
  String get repsTo => 'to';

  @override
  String get startWorkout => 'Start';

  @override
  String planExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get weightUnitHint => 'History and charts are converted too.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String numberOutOfRange(int min, int max) {
    return 'Enter a value between $min and $max';
  }

  @override
  String get heightWithUnit => 'Height (cm)';

  @override
  String get weightWithUnit => 'Weight (kg)';

  @override
  String get errNetwork => 'No internet connection.';

  @override
  String get errTimeout => 'The server is not responding.';

  @override
  String get errSessionExpired =>
      'Your session has expired, please log in again.';

  @override
  String get errBadCertificate => 'Invalid server certificate.';

  @override
  String get errCancelled => 'The request was cancelled.';

  @override
  String get errValidation => 'Invalid data.';

  @override
  String errServer(int status) {
    return 'Server error ($status).';
  }

  @override
  String get errForbidden => 'You don\'t have access to this.';

  @override
  String get errNotFound => 'Not found.';

  @override
  String get errConflict => 'This already exists.';

  @override
  String get errTooManyRequests =>
      'Too many attempts. Wait a minute and try again.';

  @override
  String get errUnknown => 'An unexpected error occurred.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String privacyUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get privacyAgree =>
      'By creating an account you accept the privacy policy.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountHint => 'Permanently, with all your data';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Your profile, workouts, plans, custom exercises and body weight will be deleted from the server. This cannot be undone.';

  @override
  String get deleteAccountPassword => 'Password to confirm';

  @override
  String get deleteAccountConfirm => 'Delete forever';

  @override
  String get verifyEmailTitle => 'Confirm your email';

  @override
  String verifyEmailBody(String email) {
    return 'We sent a 6-digit code to $email. Enter it to finish creating your account.';
  }

  @override
  String get codeLabel => 'Code';

  @override
  String get confirmCode => 'Confirm';

  @override
  String get resendCode => 'Send a new code';

  @override
  String resendIn(int seconds) {
    return 'New code in $seconds s';
  }

  @override
  String get codeSent => 'New code sent. Check your inbox (and spam).';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get forgotTitle => 'Reset password';

  @override
  String get forgotBody =>
      'Enter your account email. We will send you a code to set a new password.';

  @override
  String get sendCode => 'Send code';

  @override
  String resetBody(String email) {
    return 'If $email has an account, we sent it a code. Enter it with your new password.';
  }

  @override
  String get newPassword => 'New password';

  @override
  String get setNewPassword => 'Set new password';

  @override
  String get passwordChanged => 'Password changed. Log in with the new one.';
}
