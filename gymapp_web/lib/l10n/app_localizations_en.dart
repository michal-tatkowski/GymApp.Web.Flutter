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
  String get metricTotalTime => 'Time';

  @override
  String get metricLongestSet => 'Longest';

  @override
  String get metricDistance => 'Distance';

  @override
  String get durationLabel => 'Time (m:ss)';

  @override
  String get invalidDuration => 'Enter the time as m:ss, e.g. 1:30';

  @override
  String get distanceKm => 'km';

  @override
  String get trackingLabel => 'Measured by';

  @override
  String get trackingWeight => 'Reps × weight';

  @override
  String get trackingTime => 'Time';

  @override
  String get trackingDistance => 'Distance + time';

  @override
  String get plateCalculator => 'Plates';

  @override
  String get platesPerSide => 'On each side';

  @override
  String platesBar(String weight) {
    return 'Bar $weight';
  }

  @override
  String platesRemainder(String weight) {
    return '$weight short — not possible exactly with standard plates';
  }

  @override
  String get platesJustBar => 'Just the empty bar';

  @override
  String get platesBelowBar =>
      'Lighter than the bar — use dumbbells or a lighter bar';

  @override
  String get barWeight => 'Barbell';

  @override
  String get barWeightHint =>
      'For the plate calculator in a workout (tap the weight)';

  @override
  String get plateCalculatorHint => 'Tap the weight to see the plates';

  @override
  String get exerciseNote => 'Note for this exercise';

  @override
  String get exerciseNoteHint => 'Seat height, grip, cues: shown every workout';

  @override
  String get addExerciseNote => 'Add a note';

  @override
  String get editExerciseNote => 'Edit note';

  @override
  String get swapExercise => 'Swap exercise';

  @override
  String swapExerciseTitle(String name) {
    return 'Instead of $name';
  }

  @override
  String get swapNotAfterSets =>
      'Done sets stay with this exercise: swap before the first set.';

  @override
  String swapped(String name) {
    return 'Swapped for $name';
  }

  @override
  String get timedSetStart => 'Start the timer';

  @override
  String get timedSetTitle => 'Hold it';

  @override
  String get getReady => 'Get ready';

  @override
  String get timedSetPause => 'Pause';

  @override
  String get timedSetResume => 'Resume';

  @override
  String get timedSetFinishNow => 'Finish now';

  @override
  String get warmUpRoutineTitle => 'Warm up first (5 min)';

  @override
  String get coolDownTitle => 'Stretch to finish (5 min)';

  @override
  String routineProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get routinesSetting => 'Warm-up and stretching';

  @override
  String get routinesSettingHint =>
      'Short checklists at the start and end of a workout';

  @override
  String get wuCardio => '5 min of light cardio (bike, rower, brisk walk)';

  @override
  String get wuArmCircles => 'Arm circles, 10 each way';

  @override
  String get wuBandPullApart => 'Band pull-aparts, 15';

  @override
  String get wuCatCow => 'Cat-cow, 8';

  @override
  String get wuHipCircles => 'Hip circles, 10 each way';

  @override
  String get wuLegSwings => 'Leg swings, 10 per leg';

  @override
  String get wuSquats => 'Bodyweight squats, 10';

  @override
  String get cdChest => 'Chest stretch in a doorway, 30 s';

  @override
  String get cdLat => 'Lat stretch, 30 s per side';

  @override
  String get cdShoulder => 'Cross-body shoulder stretch, 30 s per side';

  @override
  String get cdQuad => 'Standing quad stretch, 30 s per leg';

  @override
  String get cdHamstring => 'Hamstring stretch, 30 s per leg';

  @override
  String get cdHipFlexor => 'Kneeling hip flexor stretch, 30 s per side';

  @override
  String get cdChildPose => 'Child\'s pose, 30 s';

  @override
  String get cdBreathing => 'Slow breathing, 1 min';

  @override
  String get compareTitle => 'Compared with before';

  @override
  String get compareWeek => 'Week';

  @override
  String get compareMonth => 'Month';

  @override
  String get compareHintWeek => 'This week so far vs. the same days last week';

  @override
  String get compareHintMonth =>
      'This month so far vs. the same days last month';

  @override
  String get compareNew => 'new';

  @override
  String goalForecastWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'At this pace: about $weeks weeks',
      one: 'At this pace: about a week',
    );
    return '$_temp0';
  }

  @override
  String get goalForecastSoon => 'At this pace: any day now';

  @override
  String get goalForecastNoTrend => 'No trend towards it yet: keep logging';

  @override
  String get goalForecastLate => 'At this pace: a bit after the deadline';

  @override
  String challengesTitle(String month) {
    return 'Challenges · $month';
  }

  @override
  String challengeSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Do $count sets',
      one: 'Do 1 set',
    );
    return '$_temp0';
  }

  @override
  String get challengeDone => 'Done!';

  @override
  String challengesCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count challenges completed so far',
      one: '1 challenge completed so far',
      zero: 'No challenge completed yet',
    );
    return '$_temp0';
  }

  @override
  String challengeDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get pureBlack => 'Pure black (OLED)';

  @override
  String get pureBlackHint =>
      'Dark theme on a black background: saves battery on OLED screens';

  @override
  String get largeSessionControls => 'Large buttons during a workout';

  @override
  String get largeSessionControlsHint =>
      'Easier to hit with one hand at the gym';

  @override
  String get moodQuestion => 'How did it go?';

  @override
  String get mood1 => 'Very bad';

  @override
  String get mood2 => 'Bad';

  @override
  String get mood3 => 'Okay';

  @override
  String get mood4 => 'Good';

  @override
  String get mood5 => 'Great';

  @override
  String get workoutNote => 'Workout note';

  @override
  String get workoutNoteHint => 'What went well, what to change next time';

  @override
  String get sessionFeedback => 'Mood and note';

  @override
  String get lifetimeTitle => 'All time';

  @override
  String lifetimeSince(String date) {
    return 'Since $date';
  }

  @override
  String get lifetimeDays => 'Training days';

  @override
  String get lifetimeSets => 'Sets';

  @override
  String get lifetimeReps => 'Reps';

  @override
  String get lifetimeVolume => 'Lifted';

  @override
  String get lifetimeTime => 'Workout time';

  @override
  String get lifetimeDistance => 'Distance';

  @override
  String get lifetimeRecords => 'Records';

  @override
  String get lifetimeExercises => 'Exercises';

  @override
  String hoursShort(int hours) {
    return '$hours h';
  }

  @override
  String get badgeWorkouts250 => 'Dedicated';

  @override
  String get badgeWorkouts500 => 'Lifer';

  @override
  String get badgeStreak26 => 'Half a year';

  @override
  String get badgeStreak52 => 'Whole year';

  @override
  String get badgeRecord50 => 'Record machine';

  @override
  String get badgeVolume1000t => 'Thousand tonnes';

  @override
  String get badgeVariety25 => 'Collector';

  @override
  String get musclesTitle => 'Sets per muscle group';

  @override
  String get musclesThisWeek => 'This week';

  @override
  String get musclesAverage => '4-week average';

  @override
  String get musclesEmpty => 'No sets in this period yet.';

  @override
  String get musclesMorePush =>
      'More pushing than pulling: add a row or a pull-up.';

  @override
  String get musclesMorePull => 'More pulling than pushing: add a press.';

  @override
  String get musclesNoLegs => 'No leg work in this period.';

  @override
  String get onboardingTitle => 'Let\'s set you up';

  @override
  String get skip => 'Skip';

  @override
  String get onboardingGoal => 'What\'s your main goal?';

  @override
  String get goalStrength => 'Get stronger';

  @override
  String get goalMuscle => 'Build muscle';

  @override
  String get goalFitness => 'General fitness';

  @override
  String get goalFatLoss => 'Lose fat';

  @override
  String get onboardingPlace => 'Where do you train?';

  @override
  String get placeGym => 'At a gym';

  @override
  String get placeHome => 'At home, no equipment';

  @override
  String get onboardingDays => 'How many days a week?';

  @override
  String get onboardingPlanTitle => 'Your plan';

  @override
  String get onboardingPlanHint =>
      'A proven plan to start with — change anything later in Plans.';

  @override
  String onboardingSplitHint(int count) {
    return '$count plans to rotate, one per workout — change anything later in Plans.';
  }

  @override
  String get onboardingReminders => 'Remind me on training days';

  @override
  String onboardingRemindersHint(int count) {
    return '$count days a week, at 18:00 — adjust in Settings';
  }

  @override
  String get onboardingAccept => 'Add plan and weekly goal';

  @override
  String get onboardingReady => 'All set — start your first workout from Plans';

  @override
  String shareTitle(String name) {
    return 'Share \"$name\"';
  }

  @override
  String get shareHint =>
      'Anyone with this code can add a copy in GymApp (New plan → From a code).';

  @override
  String shareMessage(String name, String code) {
    return 'My \"$name\" in GymApp — add it with the code $code (New plan → From a code).';
  }

  @override
  String get codeCopied => 'Code copied';

  @override
  String get copy => 'Copy';

  @override
  String get importFromCode => 'From a code';

  @override
  String get importFromCodeHint => 'A plan or exercise someone shared with you';

  @override
  String get shareCode => 'Share code';

  @override
  String get showShared => 'Show';

  @override
  String get addToMyPlans => 'Add to my plans';

  @override
  String get addToMyExercises => 'Add to my exercises';

  @override
  String planImported(String name) {
    return 'Plan \"$name\" added';
  }

  @override
  String exerciseImported(String name) {
    return 'Exercise \"$name\" added';
  }

  @override
  String get rir => 'RIR';

  @override
  String get rirExplained =>
      'Reps in reserve: how many more you could have done. Feeds the next hint.';

  @override
  String get rirZero => '0 — nothing left, to failure';

  @override
  String rirValue(String count) {
    return '$count more in reserve';
  }

  @override
  String get setNote => 'Note to this set';

  @override
  String get setNoteHint => 'e.g. elbow hurt, slow negative';

  @override
  String get exportData => 'Export my data';

  @override
  String get exportDataHint =>
      'Everything as JSON, workouts as CSV (Excel, Sheets)';

  @override
  String get sessionChannel => 'Workout in progress';

  @override
  String sessionNotificationSet(int set, int total) {
    return 'Set $set of $total';
  }

  @override
  String get sessionNotificationDone =>
      'All sets done — on to the next exercise';

  @override
  String get measurements => 'Measurements';

  @override
  String get addMeasurement => 'Today\'s measurements';

  @override
  String get measurementsEmpty =>
      'Waist, chest, hips, arm, thigh, neck — track what you like.';

  @override
  String get measurementsHint => 'Fill in only what you measured (cm).';

  @override
  String get measurementsNeedOne => 'Enter at least one measurement.';

  @override
  String get partWaist => 'Waist';

  @override
  String get partChest => 'Chest';

  @override
  String get partHips => 'Hips';

  @override
  String get partArm => 'Arm';

  @override
  String get partThigh => 'Thigh';

  @override
  String get partNeck => 'Neck';

  @override
  String get progressPhotos => 'Progress photos';

  @override
  String get progressPhotosPrivate =>
      'Stay only on this phone — never uploaded. Deleted when you log out.';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get photoCamera => 'Take a photo';

  @override
  String get photoGallery => 'Choose from gallery';

  @override
  String photoOf(String date) {
    return 'Photo of $date';
  }

  @override
  String get comparePhotos => 'Compare with the first';

  @override
  String get deletePhoto => 'Delete this photo?';

  @override
  String get records => 'Records';

  @override
  String get recordOneRepMax => 'Best 1RM (estimated)';

  @override
  String get recordHeaviest => 'Heaviest set';

  @override
  String get recordDayVolume => 'Best day (volume)';

  @override
  String get recordMostReps => 'Most reps in a set';

  @override
  String get recordLongest => 'Longest set';

  @override
  String get recordDistance => 'Longest distance';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryMonth => 'Month';

  @override
  String get summaryYear => 'Year';

  @override
  String get summaryEmpty => 'No workouts in this period.';

  @override
  String get summaryWorkouts => 'workouts';

  @override
  String get summarySets => 'sets';

  @override
  String get summaryVolume => 'lifted';

  @override
  String get summaryTime => 'training time';

  @override
  String get summaryRecords => 'records';

  @override
  String get summarySetsPerWorkout => 'sets / workout';

  @override
  String get summaryTopExercises => 'Most trained';

  @override
  String get share => 'Share';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get more => 'More';

  @override
  String get goals => 'Goals';

  @override
  String get addGoal => 'New goal';

  @override
  String get noGoalsYet =>
      'Set a goal: a weight to lift, workouts per week or a body weight.';

  @override
  String get goalKindExercise => 'Lift';

  @override
  String get goalKindWeekly => 'Per week';

  @override
  String get goalKindBodyWeight => 'Body weight';

  @override
  String get goalPickExercise => 'Choose the exercise';

  @override
  String get goalTargetWeight => 'Target weight';

  @override
  String get goalTargetWorkouts => 'Workouts per week';

  @override
  String get goalNoDeadline => 'No deadline (optional)';

  @override
  String goalBy(String date) {
    return 'by $date';
  }

  @override
  String goalExerciseTitle(String exercise, String weight) {
    return '$exercise: $weight';
  }

  @override
  String goalWeeklyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts a week',
      one: '1 workout a week',
    );
    return '$_temp0';
  }

  @override
  String goalBodyWeightTitle(String weight) {
    return 'Body weight $weight';
  }

  @override
  String goalNow(String value) {
    return 'now $value';
  }

  @override
  String goalThisWeek(int count) {
    return '$count this week';
  }

  @override
  String get goalNoData => 'no data yet';

  @override
  String goalReached(String goal) {
    return 'Goal reached: $goal 🎉';
  }

  @override
  String get history => 'History';

  @override
  String get historyEmpty => 'No workouts yet.';

  @override
  String get historyEnd => 'That\'s everything.';

  @override
  String get historyLoadMore => 'Older workouts';

  @override
  String get repeatWorkout => 'Repeat';

  @override
  String get repeatLastWorkout => 'Repeat last workout';

  @override
  String workoutOfDay(String date) {
    return 'Workout of $date';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get planTemplates => 'Ready-made plans';

  @override
  String get fromTemplate => 'From a ready-made plan';

  @override
  String get fromTemplateHint =>
      'FBW, 5×5, Push/Pull/Legs, Upper/Lower, home circuit';

  @override
  String get emptyPlan => 'Empty plan';

  @override
  String get useTemplate => 'Use';

  @override
  String daysPerWeek(int count) {
    return '$count× a week';
  }

  @override
  String get hintBeatLastTime => 'Try to beat last time';

  @override
  String sessionTargetSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Target: $count sets',
      one: 'Target: 1 set',
    );
    return '$_temp0';
  }

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

  @override
  String get supersetWithNext => 'Superset with next';

  @override
  String get supersetHint =>
      'Done in turns with the next exercise, rest only after the round. Link 3+ for a circuit.';

  @override
  String get superset => 'Superset';

  @override
  String get circuit => 'Circuit';

  @override
  String get supersetNoRest =>
      'Ticking a set moves on to the next exercise, rest after the round.';

  @override
  String get warmUp => 'Warm-up';

  @override
  String warmUpHint(String weight) {
    return 'Before $weight — not logged';
  }

  @override
  String get activityTitle => 'Activity';

  @override
  String activitySummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts in the last 12 months',
      one: '1 workout in the last 12 months',
      zero: 'No workouts in the last 12 months',
    );
    return '$_temp0';
  }

  @override
  String get activityTapHint => 'Tap a day to see it';

  @override
  String activityRestDay(String date) {
    return '$date: rest day';
  }

  @override
  String activityDay(String date, int exercises, int sets) {
    String _temp0 = intl.Intl.pluralLogic(
      exercises,
      locale: localeName,
      other: '$exercises exercises',
      one: '1 exercise',
    );
    return '$date: $_temp0 · $sets sets';
  }

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgesCount(int earned, int total) {
    return '$earned of $total earned';
  }

  @override
  String badgeUnlocked(String name) {
    return 'New badge: $name 🏅';
  }

  @override
  String get badgeEarned => 'Earned';

  @override
  String badgeEarnedOn(String date) {
    return 'Earned $date';
  }

  @override
  String get badgeWorkouts1 => 'First step';

  @override
  String get badgeWorkouts10 => 'Getting going';

  @override
  String get badgeWorkouts50 => 'Regular';

  @override
  String get badgeWorkouts100 => 'Centurion';

  @override
  String get badgeStreak4 => 'Month strong';

  @override
  String get badgeStreak12 => 'Unstoppable';

  @override
  String get badgeBusyWeek => 'Busy week';

  @override
  String get badgeRecord1 => 'New best';

  @override
  String get badgeRecord10 => 'Record breaker';

  @override
  String get badgeVolume10t => 'Heavy lifter';

  @override
  String get badgeVolume100t => 'Iron mover';

  @override
  String get badgeVariety => 'Explorer';

  @override
  String badgeGoalWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Train on $count days',
      one: 'Log your first workout',
    );
    return '$_temp0';
  }

  @override
  String badgeGoalStreak(int count) {
    return 'Train $count weeks in a row';
  }

  @override
  String badgeGoalBusyWeek(int count) {
    return 'Train $count times in one week';
  }

  @override
  String badgeGoalRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Set $count personal records',
      one: 'Set a personal record',
    );
    return '$_temp0';
  }

  @override
  String badgeGoalVolume(String weight) {
    return 'Lift $weight in total';
  }

  @override
  String badgeGoalVariety(int count) {
    return 'Train $count different exercises';
  }

  @override
  String offlineData(String time) {
    return 'Offline · showing data saved $time. Pull down to refresh.';
  }
}
