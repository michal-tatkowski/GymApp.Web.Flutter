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
  String get accountCreated => 'Account created. You can log in now.';

  @override
  String get darkTheme => 'Dark theme';

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
}
