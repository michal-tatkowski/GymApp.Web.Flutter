import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gym;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get profileLoadError;

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @weeklyPlan.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan'**
  String get weeklyPlan;

  /// No description provided for @charts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// No description provided for @workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @searchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get searchExercises;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get exerciseName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get noExercisesFound;

  /// No description provided for @exerciseAdded.
  ///
  /// In en, this message translates to:
  /// **'Exercise added'**
  String get exerciseAdded;

  /// No description provided for @customExercise.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customExercise;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @aboutExercise.
  ///
  /// In en, this message translates to:
  /// **'About this exercise'**
  String get aboutExercise;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @catPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get catPush;

  /// No description provided for @catPull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get catPull;

  /// No description provided for @catLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get catLegs;

  /// No description provided for @catCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get catCore;

  /// No description provided for @catCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get catCardio;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @myWorkouts.
  ///
  /// In en, this message translates to:
  /// **'My workouts'**
  String get myWorkouts;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @metricVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get metricVolume;

  /// No description provided for @metricOneRepMax.
  ///
  /// In en, this message translates to:
  /// **'1RM'**
  String get metricOneRepMax;

  /// No description provided for @metricMaxWeight.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get metricMaxWeight;

  /// No description provided for @metricReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get metricReps;

  /// No description provided for @range1M.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get range1M;

  /// No description provided for @range3M.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get range3M;

  /// No description provided for @range1Y.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get range1Y;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @personalRecord.
  ///
  /// In en, this message translates to:
  /// **'🏆 Personal record'**
  String get personalRecord;

  /// No description provided for @newRecordVolume.
  ///
  /// In en, this message translates to:
  /// **'🏆 New record: best volume so far!'**
  String get newRecordVolume;

  /// No description provided for @newRecordOneRepMax.
  ///
  /// In en, this message translates to:
  /// **'🏆 New record: strongest so far (est. 1RM)!'**
  String get newRecordOneRepMax;

  /// No description provided for @chartSemantics.
  ///
  /// In en, this message translates to:
  /// **'{metric} chart: from {first} to {last} over {days} training days'**
  String chartSemantics(String metric, String first, String last, int days);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @repeatLast.
  ///
  /// In en, this message translates to:
  /// **'Repeat last: {sets}'**
  String repeatLast(String sets);

  /// No description provided for @repeatLastShort.
  ///
  /// In en, this message translates to:
  /// **'Repeat last workout'**
  String get repeatLastShort;

  /// No description provided for @decreaseBy.
  ///
  /// In en, this message translates to:
  /// **'Decrease by {step}'**
  String decreaseBy(String step);

  /// No description provided for @increaseBy.
  ///
  /// In en, this message translates to:
  /// **'Increase by {step}'**
  String increaseBy(String step);

  /// No description provided for @restTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get restTimer;

  /// No description provided for @restTimerHint.
  ///
  /// In en, this message translates to:
  /// **'Starts automatically after you log a workout.'**
  String get restTimerHint;

  /// No description provided for @restRemaining.
  ///
  /// In en, this message translates to:
  /// **'Rest {time}'**
  String restRemaining(String time);

  /// No description provided for @restOver.
  ///
  /// In en, this message translates to:
  /// **'Rest is over — next set!'**
  String get restOver;

  /// No description provided for @restNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restNotificationTitle;

  /// No description provided for @restNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Next set when the countdown ends'**
  String get restNotificationBody;

  /// No description provided for @restCountdownChannel.
  ///
  /// In en, this message translates to:
  /// **'Rest countdown'**
  String get restCountdownChannel;

  /// No description provided for @restOverChannel.
  ///
  /// In en, this message translates to:
  /// **'End of rest'**
  String get restOverChannel;

  /// No description provided for @restExactAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alert exactly on time'**
  String get restExactAlarm;

  /// No description provided for @restExactAlarmHint.
  ///
  /// In en, this message translates to:
  /// **'Allow alarms so the end-of-rest alert is not delayed when the phone is locked'**
  String get restExactAlarmHint;

  /// No description provided for @quickLog.
  ///
  /// In en, this message translates to:
  /// **'Quick log'**
  String get quickLog;

  /// No description provided for @doneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get doneToday;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'Star exercises (★) to log them here with one tap.'**
  String get noFavoritesYet;

  /// No description provided for @browseExercises.
  ///
  /// In en, this message translates to:
  /// **'Browse exercises'**
  String get browseExercises;

  /// No description provided for @notTrainedYet.
  ///
  /// In en, this message translates to:
  /// **'Not trained yet'**
  String get notTrainedYet;

  /// No description provided for @logWorkout.
  ///
  /// In en, this message translates to:
  /// **'Log workout'**
  String get logWorkout;

  /// No description provided for @editWorkout.
  ///
  /// In en, this message translates to:
  /// **'Edit workout'**
  String get editWorkout;

  /// No description provided for @workoutHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get workoutHistory;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet. Open an exercise and tap \"Log workout\".'**
  String get noWorkoutsYet;

  /// No description provided for @noEntriesForExercise.
  ///
  /// In en, this message translates to:
  /// **'No workouts for this exercise yet.'**
  String get noEntriesForExercise;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @progressNeedsMoreDays.
  ///
  /// In en, this message translates to:
  /// **'Log at least two training days to see the trend.'**
  String get progressNeedsMoreDays;

  /// No description provided for @setNumber.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String setNumber(int number);

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSet;

  /// No description provided for @removeSet.
  ///
  /// In en, this message translates to:
  /// **'Remove set'**
  String get removeSet;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @workoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout saved'**
  String get workoutSaved;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on the phone — it will be sent when you\'re online'**
  String get savedOffline;

  /// No description provided for @waitingToSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get waitingToSync;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineTitle;

  /// No description provided for @offlineLogHint.
  ///
  /// In en, this message translates to:
  /// **'You can still log workouts — they\'re kept on the phone and sent later.'**
  String get offlineLogHint;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout waiting to sync} other{{count} workouts waiting to sync}}'**
  String pendingCount(int count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @logoutPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Workouts not sent yet'**
  String get logoutPendingTitle;

  /// No description provided for @logoutPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Workouts saved offline that have not been sent yet will be lost. Log out anyway?'**
  String get logoutPendingBody;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Workout deleted'**
  String get entryDeleted;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @lastWorkout.
  ///
  /// In en, this message translates to:
  /// **'Last: {date}'**
  String lastWorkout(String date);

  /// No description provided for @trainingDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 training day} other{{count} training days}}'**
  String trainingDays(int count);

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'best {value}'**
  String bestValue(String value);

  /// No description provided for @repsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} reps'**
  String repsValue(int count);

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters long'**
  String passwordTooShort(int min);

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registering.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get registering;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created. You can log in now.'**
  String get accountCreated;

  /// No description provided for @weightUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight unit'**
  String get weightUnit;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Workout reminders'**
  String get reminders;

  /// No description provided for @remindersHint.
  ///
  /// In en, this message translates to:
  /// **'A notification on the days you train'**
  String get remindersHint;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderTime;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to train 💪'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready — tap to start.'**
  String get reminderBody;

  /// No description provided for @reminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Workout reminders'**
  String get reminderChannel;

  /// No description provided for @reminderPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for GymApp in the system settings to get reminders.'**
  String get reminderPermissionDenied;

  /// No description provided for @bodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get bodyWeight;

  /// No description provided for @bodyWeightLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get bodyWeightLog;

  /// No description provided for @bodyWeightToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weight'**
  String get bodyWeightToday;

  /// No description provided for @bodyWeightEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log your weight now and then to see the trend.'**
  String get bodyWeightEmpty;

  /// No description provided for @bodyWeightChange.
  ///
  /// In en, this message translates to:
  /// **'{change} in 30 days'**
  String bodyWeightChange(String change);

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @weekNothingYet.
  ///
  /// In en, this message translates to:
  /// **'No workout yet this week'**
  String get weekNothingYet;

  /// No description provided for @weekWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout} other{{count} workouts}}'**
  String weekWorkouts(int count);

  /// No description provided for @weekSets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String weekSets(int count);

  /// No description provided for @weekStreak.
  ///
  /// In en, this message translates to:
  /// **'{count}-week streak'**
  String weekStreak(int count);

  /// No description provided for @weekRecords.
  ///
  /// In en, this message translates to:
  /// **'Records: {names}'**
  String weekRecords(String names);

  /// No description provided for @sessionInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get sessionInProgressTitle;

  /// No description provided for @sessionInProgressBody.
  ///
  /// In en, this message translates to:
  /// **'\"{plan}\" is not finished yet. Resume it or start the new one (sets not saved yet in the old one are dropped)?'**
  String sessionInProgressBody(String plan);

  /// No description provided for @sessionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get sessionResume;

  /// No description provided for @sessionStartNew.
  ///
  /// In en, this message translates to:
  /// **'Start new'**
  String get sessionStartNew;

  /// No description provided for @sessionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard workout'**
  String get sessionDiscard;

  /// No description provided for @sessionDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this workout?'**
  String get sessionDiscardTitle;

  /// No description provided for @sessionDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Sets not saved yet are dropped. Exercises already saved stay in your history.'**
  String get sessionDiscardBody;

  /// No description provided for @sessionNone.
  ///
  /// In en, this message translates to:
  /// **'No workout in progress.'**
  String get sessionNone;

  /// No description provided for @sessionFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get sessionFinish;

  /// No description provided for @sessionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get sessionNext;

  /// No description provided for @sessionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get sessionPrevious;

  /// No description provided for @sessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your history'**
  String get sessionSaved;

  /// No description provided for @sessionTarget.
  ///
  /// In en, this message translates to:
  /// **'Target: {target} reps'**
  String sessionTarget(String target);

  /// No description provided for @sessionLastTime.
  ///
  /// In en, this message translates to:
  /// **'Last time: {sets}'**
  String sessionLastTime(String sets);

  /// No description provided for @hintAddWeight.
  ///
  /// In en, this message translates to:
  /// **'You hit the top of the range — today {weight} × {reps}'**
  String hintAddWeight(String weight, int reps);

  /// No description provided for @hintAddReps.
  ///
  /// In en, this message translates to:
  /// **'You hit the top of the range — one more rep per set today'**
  String get hintAddReps;

  /// No description provided for @hintRepeat.
  ///
  /// In en, this message translates to:
  /// **'Same weight — aim for {reps} reps in every set'**
  String hintRepeat(int reps);

  /// No description provided for @hintFirstTime.
  ///
  /// In en, this message translates to:
  /// **'First time — pick a weight you can do with good form'**
  String get hintFirstTime;

  /// No description provided for @repsShort.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsShort;

  /// No description provided for @sessionDoneSet.
  ///
  /// In en, this message translates to:
  /// **'Set done'**
  String get sessionDoneSet;

  /// No description provided for @sessionUndoSet.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get sessionUndoSet;

  /// No description provided for @sessionSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout done!'**
  String get sessionSummaryTitle;

  /// No description provided for @sessionSummaryStats.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {exercises} exercises · {sets} sets'**
  String sessionSummaryStats(int minutes, int exercises, int sets);

  /// No description provided for @sessionSummaryVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume: {volume}'**
  String sessionSummaryVolume(String volume);

  /// No description provided for @sessionSummaryRecords.
  ///
  /// In en, this message translates to:
  /// **'New records: {names}'**
  String sessionSummaryRecords(String names);

  /// No description provided for @sessionActive.
  ///
  /// In en, this message translates to:
  /// **'{plan} in progress · {done}/{total}'**
  String sessionActive(String plan, int done, int total);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @newPlan.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get newPlan;

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get editPlan;

  /// No description provided for @planName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get planName;

  /// No description provided for @planNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push, FBW A'**
  String get planNameHint;

  /// No description provided for @planNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a plan name'**
  String get planNameRequired;

  /// No description provided for @planNeedsExercise.
  ///
  /// In en, this message translates to:
  /// **'Add at least one exercise'**
  String get planNeedsExercise;

  /// No description provided for @planEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add the exercises in the order you do them. Set the target for each: sets × reps.'**
  String get planEmptyHint;

  /// No description provided for @deletePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete plan?'**
  String get deletePlanTitle;

  /// No description provided for @deletePlanBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be deleted. Your workout history stays.'**
  String deletePlanBody(String name);

  /// No description provided for @noPlansYet.
  ///
  /// In en, this message translates to:
  /// **'Create a plan (e.g. Push / Pull / Legs) to start a guided workout with one tap.'**
  String get noPlansYet;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @repsFrom.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsFrom;

  /// No description provided for @repsTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get repsTo;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startWorkout;

  /// No description provided for @planExercises.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String planExercises(int count);

  /// No description provided for @weightUnitHint.
  ///
  /// In en, this message translates to:
  /// **'History and charts are converted too.'**
  String get weightUnitHint;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @numberOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a value between {min} and {max}'**
  String numberOutOfRange(int min, int max);

  /// No description provided for @heightWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightWithUnit;

  /// No description provided for @weightWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightWithUnit;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errNetwork;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server is not responding.'**
  String get errTimeout;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired, please log in again.'**
  String get errSessionExpired;

  /// No description provided for @errBadCertificate.
  ///
  /// In en, this message translates to:
  /// **'Invalid server certificate.'**
  String get errBadCertificate;

  /// No description provided for @errCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled.'**
  String get errCancelled;

  /// No description provided for @errValidation.
  ///
  /// In en, this message translates to:
  /// **'Invalid data.'**
  String get errValidation;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'Server error ({status}).'**
  String errServer(int status);

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get errForbidden;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errNotFound;

  /// No description provided for @errConflict.
  ///
  /// In en, this message translates to:
  /// **'This already exists.'**
  String get errConflict;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get errTooManyRequests;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errUnknown;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String privacyUpdated(String date);

  /// No description provided for @privacyAgree.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you accept the privacy policy.'**
  String get privacyAgree;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently, with all your data'**
  String get deleteAccountHint;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile, workouts, plans, custom exercises and body weight will be deleted from the server. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password to confirm'**
  String get deleteAccountPassword;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteAccountConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
