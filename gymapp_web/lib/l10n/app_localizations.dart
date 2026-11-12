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

  /// No description provided for @metricTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get metricTotalTime;

  /// No description provided for @metricLongestSet.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get metricLongestSet;

  /// No description provided for @metricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get metricDistance;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Time (m:ss)'**
  String get durationLabel;

  /// No description provided for @invalidDuration.
  ///
  /// In en, this message translates to:
  /// **'Enter the time as m:ss, e.g. 1:30'**
  String get invalidDuration;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get distanceKm;

  /// No description provided for @trackingLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured by'**
  String get trackingLabel;

  /// No description provided for @trackingWeight.
  ///
  /// In en, this message translates to:
  /// **'Reps × weight'**
  String get trackingWeight;

  /// No description provided for @trackingTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get trackingTime;

  /// No description provided for @trackingDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance + time'**
  String get trackingDistance;

  /// No description provided for @plateCalculator.
  ///
  /// In en, this message translates to:
  /// **'Plates'**
  String get plateCalculator;

  /// No description provided for @platesPerSide.
  ///
  /// In en, this message translates to:
  /// **'On each side'**
  String get platesPerSide;

  /// No description provided for @platesBar.
  ///
  /// In en, this message translates to:
  /// **'Bar {weight}'**
  String platesBar(String weight);

  /// No description provided for @platesRemainder.
  ///
  /// In en, this message translates to:
  /// **'{weight} short — not possible exactly with standard plates'**
  String platesRemainder(String weight);

  /// No description provided for @platesJustBar.
  ///
  /// In en, this message translates to:
  /// **'Just the empty bar'**
  String get platesJustBar;

  /// No description provided for @platesBelowBar.
  ///
  /// In en, this message translates to:
  /// **'Lighter than the bar — use dumbbells or a lighter bar'**
  String get platesBelowBar;

  /// No description provided for @barWeight.
  ///
  /// In en, this message translates to:
  /// **'Barbell'**
  String get barWeight;

  /// No description provided for @barWeightHint.
  ///
  /// In en, this message translates to:
  /// **'For the plate calculator in a workout (tap the weight)'**
  String get barWeightHint;

  /// No description provided for @plateCalculatorHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the weight to see the plates'**
  String get plateCalculatorHint;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set you up'**
  String get onboardingTitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboardingGoal.
  ///
  /// In en, this message translates to:
  /// **'What\'s your main goal?'**
  String get onboardingGoal;

  /// No description provided for @goalStrength.
  ///
  /// In en, this message translates to:
  /// **'Get stronger'**
  String get goalStrength;

  /// No description provided for @goalMuscle.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get goalMuscle;

  /// No description provided for @goalFitness.
  ///
  /// In en, this message translates to:
  /// **'General fitness'**
  String get goalFitness;

  /// No description provided for @goalFatLoss.
  ///
  /// In en, this message translates to:
  /// **'Lose fat'**
  String get goalFatLoss;

  /// No description provided for @onboardingPlace.
  ///
  /// In en, this message translates to:
  /// **'Where do you train?'**
  String get onboardingPlace;

  /// No description provided for @placeGym.
  ///
  /// In en, this message translates to:
  /// **'At a gym'**
  String get placeGym;

  /// No description provided for @placeHome.
  ///
  /// In en, this message translates to:
  /// **'At home, no equipment'**
  String get placeHome;

  /// No description provided for @onboardingDays.
  ///
  /// In en, this message translates to:
  /// **'How many days a week?'**
  String get onboardingDays;

  /// No description provided for @onboardingPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get onboardingPlanTitle;

  /// No description provided for @onboardingPlanHint.
  ///
  /// In en, this message translates to:
  /// **'A proven plan to start with — change anything later in Plans.'**
  String get onboardingPlanHint;

  /// No description provided for @onboardingSplitHint.
  ///
  /// In en, this message translates to:
  /// **'{count} plans to rotate, one per workout — change anything later in Plans.'**
  String onboardingSplitHint(int count);

  /// No description provided for @onboardingReminders.
  ///
  /// In en, this message translates to:
  /// **'Remind me on training days'**
  String get onboardingReminders;

  /// No description provided for @onboardingRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'{count} days a week, at 18:00 — adjust in Settings'**
  String onboardingRemindersHint(int count);

  /// No description provided for @onboardingAccept.
  ///
  /// In en, this message translates to:
  /// **'Add plan and weekly goal'**
  String get onboardingAccept;

  /// No description provided for @onboardingReady.
  ///
  /// In en, this message translates to:
  /// **'All set — start your first workout from Plans'**
  String get onboardingReady;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share \"{name}\"'**
  String shareTitle(String name);

  /// No description provided for @shareHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this code can add a copy in GymApp (New plan → From a code).'**
  String get shareHint;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'My \"{name}\" in GymApp — add it with the code {code} (New plan → From a code).'**
  String shareMessage(String name, String code);

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @importFromCode.
  ///
  /// In en, this message translates to:
  /// **'From a code'**
  String get importFromCode;

  /// No description provided for @importFromCodeHint.
  ///
  /// In en, this message translates to:
  /// **'A plan or exercise someone shared with you'**
  String get importFromCodeHint;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get shareCode;

  /// No description provided for @showShared.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showShared;

  /// No description provided for @addToMyPlans.
  ///
  /// In en, this message translates to:
  /// **'Add to my plans'**
  String get addToMyPlans;

  /// No description provided for @addToMyExercises.
  ///
  /// In en, this message translates to:
  /// **'Add to my exercises'**
  String get addToMyExercises;

  /// No description provided for @planImported.
  ///
  /// In en, this message translates to:
  /// **'Plan \"{name}\" added'**
  String planImported(String name);

  /// No description provided for @exerciseImported.
  ///
  /// In en, this message translates to:
  /// **'Exercise \"{name}\" added'**
  String exerciseImported(String name);

  /// No description provided for @rir.
  ///
  /// In en, this message translates to:
  /// **'RIR'**
  String get rir;

  /// No description provided for @rirExplained.
  ///
  /// In en, this message translates to:
  /// **'Reps in reserve: how many more you could have done. Feeds the next hint.'**
  String get rirExplained;

  /// No description provided for @rirZero.
  ///
  /// In en, this message translates to:
  /// **'0 — nothing left, to failure'**
  String get rirZero;

  /// No description provided for @rirValue.
  ///
  /// In en, this message translates to:
  /// **'{count} more in reserve'**
  String rirValue(String count);

  /// No description provided for @setNote.
  ///
  /// In en, this message translates to:
  /// **'Note to this set'**
  String get setNote;

  /// No description provided for @setNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. elbow hurt, slow negative'**
  String get setNoteHint;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportData;

  /// No description provided for @exportDataHint.
  ///
  /// In en, this message translates to:
  /// **'Everything as JSON, workouts as CSV (Excel, Sheets)'**
  String get exportDataHint;

  /// No description provided for @sessionChannel.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get sessionChannel;

  /// No description provided for @sessionNotificationSet.
  ///
  /// In en, this message translates to:
  /// **'Set {set} of {total}'**
  String sessionNotificationSet(int set, int total);

  /// No description provided for @sessionNotificationDone.
  ///
  /// In en, this message translates to:
  /// **'All sets done — on to the next exercise'**
  String get sessionNotificationDone;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @addMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Today\'s measurements'**
  String get addMeasurement;

  /// No description provided for @measurementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Waist, chest, hips, arm, thigh, neck — track what you like.'**
  String get measurementsEmpty;

  /// No description provided for @measurementsHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in only what you measured (cm).'**
  String get measurementsHint;

  /// No description provided for @measurementsNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one measurement.'**
  String get measurementsNeedOne;

  /// No description provided for @partWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get partWaist;

  /// No description provided for @partChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get partChest;

  /// No description provided for @partHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get partHips;

  /// No description provided for @partArm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get partArm;

  /// No description provided for @partThigh.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get partThigh;

  /// No description provided for @partNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get partNeck;

  /// No description provided for @progressPhotos.
  ///
  /// In en, this message translates to:
  /// **'Progress photos'**
  String get progressPhotos;

  /// No description provided for @progressPhotosPrivate.
  ///
  /// In en, this message translates to:
  /// **'Stay only on this phone — never uploaded. Deleted when you log out.'**
  String get progressPhotosPrivate;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @photoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoCamera;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoGallery;

  /// No description provided for @photoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo of {date}'**
  String photoOf(String date);

  /// No description provided for @comparePhotos.
  ///
  /// In en, this message translates to:
  /// **'Compare with the first'**
  String get comparePhotos;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get deletePhoto;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @recordOneRepMax.
  ///
  /// In en, this message translates to:
  /// **'Best 1RM (estimated)'**
  String get recordOneRepMax;

  /// No description provided for @recordHeaviest.
  ///
  /// In en, this message translates to:
  /// **'Heaviest set'**
  String get recordHeaviest;

  /// No description provided for @recordDayVolume.
  ///
  /// In en, this message translates to:
  /// **'Best day (volume)'**
  String get recordDayVolume;

  /// No description provided for @recordMostReps.
  ///
  /// In en, this message translates to:
  /// **'Most reps in a set'**
  String get recordMostReps;

  /// No description provided for @recordLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest set'**
  String get recordLongest;

  /// No description provided for @recordDistance.
  ///
  /// In en, this message translates to:
  /// **'Longest distance'**
  String get recordDistance;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// No description provided for @summaryMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get summaryMonth;

  /// No description provided for @summaryYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get summaryYear;

  /// No description provided for @summaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts in this period.'**
  String get summaryEmpty;

  /// No description provided for @summaryWorkouts.
  ///
  /// In en, this message translates to:
  /// **'workouts'**
  String get summaryWorkouts;

  /// No description provided for @summarySets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get summarySets;

  /// No description provided for @summaryVolume.
  ///
  /// In en, this message translates to:
  /// **'lifted'**
  String get summaryVolume;

  /// No description provided for @summaryTime.
  ///
  /// In en, this message translates to:
  /// **'training time'**
  String get summaryTime;

  /// No description provided for @summaryRecords.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get summaryRecords;

  /// No description provided for @summarySetsPerWorkout.
  ///
  /// In en, this message translates to:
  /// **'sets / workout'**
  String get summarySetsPerWorkout;

  /// No description provided for @summaryTopExercises.
  ///
  /// In en, this message translates to:
  /// **'Most trained'**
  String get summaryTopExercises;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get addGoal;

  /// No description provided for @noGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'Set a goal: a weight to lift, workouts per week or a body weight.'**
  String get noGoalsYet;

  /// No description provided for @goalKindExercise.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get goalKindExercise;

  /// No description provided for @goalKindWeekly.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get goalKindWeekly;

  /// No description provided for @goalKindBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get goalKindBodyWeight;

  /// No description provided for @goalPickExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose the exercise'**
  String get goalPickExercise;

  /// No description provided for @goalTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get goalTargetWeight;

  /// No description provided for @goalTargetWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts per week'**
  String get goalTargetWorkouts;

  /// No description provided for @goalNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline (optional)'**
  String get goalNoDeadline;

  /// No description provided for @goalBy.
  ///
  /// In en, this message translates to:
  /// **'by {date}'**
  String goalBy(String date);

  /// No description provided for @goalExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'{exercise}: {weight}'**
  String goalExerciseTitle(String exercise, String weight);

  /// No description provided for @goalWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout a week} other{{count} workouts a week}}'**
  String goalWeeklyTitle(int count);

  /// No description provided for @goalBodyWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Body weight {weight}'**
  String goalBodyWeightTitle(String weight);

  /// No description provided for @goalNow.
  ///
  /// In en, this message translates to:
  /// **'now {value}'**
  String goalNow(String value);

  /// No description provided for @goalThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} this week'**
  String goalThisWeek(int count);

  /// No description provided for @goalNoData.
  ///
  /// In en, this message translates to:
  /// **'no data yet'**
  String get goalNoData;

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached: {goal} 🎉'**
  String goalReached(String goal);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet.'**
  String get historyEmpty;

  /// No description provided for @historyEnd.
  ///
  /// In en, this message translates to:
  /// **'That\'s everything.'**
  String get historyEnd;

  /// No description provided for @historyLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Older workouts'**
  String get historyLoadMore;

  /// No description provided for @repeatWorkout.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatWorkout;

  /// No description provided for @repeatLastWorkout.
  ///
  /// In en, this message translates to:
  /// **'Repeat last workout'**
  String get repeatLastWorkout;

  /// No description provided for @workoutOfDay.
  ///
  /// In en, this message translates to:
  /// **'Workout of {date}'**
  String workoutOfDay(String date);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String setsCount(int count);

  /// No description provided for @planTemplates.
  ///
  /// In en, this message translates to:
  /// **'Ready-made plans'**
  String get planTemplates;

  /// No description provided for @fromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From a ready-made plan'**
  String get fromTemplate;

  /// No description provided for @fromTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'FBW, 5×5, Push/Pull/Legs, Upper/Lower, home circuit'**
  String get fromTemplateHint;

  /// No description provided for @emptyPlan.
  ///
  /// In en, this message translates to:
  /// **'Empty plan'**
  String get emptyPlan;

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useTemplate;

  /// No description provided for @daysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count}× a week'**
  String daysPerWeek(int count);

  /// No description provided for @hintBeatLastTime.
  ///
  /// In en, this message translates to:
  /// **'Try to beat last time'**
  String get hintBeatLastTime;

  /// No description provided for @sessionTargetSets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Target: 1 set} other{Target: {count} sets}}'**
  String sessionTargetSets(int count);

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

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. Enter it to finish creating your account.'**
  String verifyEmailBody(String email);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @confirmCode.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'New code in {seconds} s'**
  String resendIn(int seconds);

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'New code sent. Check your inbox (and spam).'**
  String get codeSent;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotTitle;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email. We will send you a code to set a new password.'**
  String get forgotBody;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'If {email} has an account, we sent it a code. Enter it with your new password.'**
  String resetBody(String email);

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Log in with the new one.'**
  String get passwordChanged;

  /// No description provided for @supersetWithNext.
  ///
  /// In en, this message translates to:
  /// **'Superset with next'**
  String get supersetWithNext;

  /// No description provided for @supersetHint.
  ///
  /// In en, this message translates to:
  /// **'Done in turns with the next exercise, rest only after the round. Link 3+ for a circuit.'**
  String get supersetHint;

  /// No description provided for @superset.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get superset;

  /// No description provided for @circuit.
  ///
  /// In en, this message translates to:
  /// **'Circuit'**
  String get circuit;

  /// No description provided for @supersetNoRest.
  ///
  /// In en, this message translates to:
  /// **'Ticking a set moves on to the next exercise, rest after the round.'**
  String get supersetNoRest;

  /// No description provided for @warmUp.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get warmUp;

  /// No description provided for @warmUpHint.
  ///
  /// In en, this message translates to:
  /// **'Before {weight} — not logged'**
  String warmUpHint(String weight);

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activitySummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No workouts in the last 12 months} =1{1 workout in the last 12 months} other{{count} workouts in the last 12 months}}'**
  String activitySummary(int count);

  /// No description provided for @activityTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to see it'**
  String get activityTapHint;

  /// No description provided for @activityRestDay.
  ///
  /// In en, this message translates to:
  /// **'{date}: rest day'**
  String activityRestDay(String date);

  /// No description provided for @activityDay.
  ///
  /// In en, this message translates to:
  /// **'{date}: {exercises, plural, =1{1 exercise} other{{exercises} exercises}} · {sets} sets'**
  String activityDay(String date, int exercises, int sets);

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesTitle;

  /// No description provided for @badgesCount.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} earned'**
  String badgesCount(int earned, int total);

  /// No description provided for @badgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'New badge: {name} 🏅'**
  String badgeUnlocked(String name);

  /// No description provided for @badgeEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get badgeEarned;

  /// No description provided for @badgeEarnedOn.
  ///
  /// In en, this message translates to:
  /// **'Earned {date}'**
  String badgeEarnedOn(String date);

  /// No description provided for @badgeWorkouts1.
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get badgeWorkouts1;

  /// No description provided for @badgeWorkouts10.
  ///
  /// In en, this message translates to:
  /// **'Getting going'**
  String get badgeWorkouts10;

  /// No description provided for @badgeWorkouts50.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get badgeWorkouts50;

  /// No description provided for @badgeWorkouts100.
  ///
  /// In en, this message translates to:
  /// **'Centurion'**
  String get badgeWorkouts100;

  /// No description provided for @badgeStreak4.
  ///
  /// In en, this message translates to:
  /// **'Month strong'**
  String get badgeStreak4;

  /// No description provided for @badgeStreak12.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get badgeStreak12;

  /// No description provided for @badgeBusyWeek.
  ///
  /// In en, this message translates to:
  /// **'Busy week'**
  String get badgeBusyWeek;

  /// No description provided for @badgeRecord1.
  ///
  /// In en, this message translates to:
  /// **'New best'**
  String get badgeRecord1;

  /// No description provided for @badgeRecord10.
  ///
  /// In en, this message translates to:
  /// **'Record breaker'**
  String get badgeRecord10;

  /// No description provided for @badgeVolume10t.
  ///
  /// In en, this message translates to:
  /// **'Heavy lifter'**
  String get badgeVolume10t;

  /// No description provided for @badgeVolume100t.
  ///
  /// In en, this message translates to:
  /// **'Iron mover'**
  String get badgeVolume100t;

  /// No description provided for @badgeVariety.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get badgeVariety;

  /// No description provided for @badgeGoalWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Log your first workout} other{Train on {count} days}}'**
  String badgeGoalWorkouts(int count);

  /// No description provided for @badgeGoalStreak.
  ///
  /// In en, this message translates to:
  /// **'Train {count} weeks in a row'**
  String badgeGoalStreak(int count);

  /// No description provided for @badgeGoalBusyWeek.
  ///
  /// In en, this message translates to:
  /// **'Train {count} times in one week'**
  String badgeGoalBusyWeek(int count);

  /// No description provided for @badgeGoalRecords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Set a personal record} other{Set {count} personal records}}'**
  String badgeGoalRecords(int count);

  /// No description provided for @badgeGoalVolume.
  ///
  /// In en, this message translates to:
  /// **'Lift {weight} in total'**
  String badgeGoalVolume(String weight);

  /// No description provided for @badgeGoalVariety.
  ///
  /// In en, this message translates to:
  /// **'Train {count} different exercises'**
  String badgeGoalVariety(int count);

  /// No description provided for @offlineData.
  ///
  /// In en, this message translates to:
  /// **'Offline · showing data saved {time}. Pull down to refresh.'**
  String offlineData(String time);
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
