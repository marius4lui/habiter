// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Habiter';

  @override
  String get navHabits => 'Habits';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get newHabit => 'New Habit';

  @override
  String get editHabit => 'Edit Habit';

  @override
  String get createHabit => 'Create habit';

  @override
  String get updateHabit => 'Update habit';

  @override
  String get deleteHabit => 'Delete Habit?';

  @override
  String get deleteHabitConfirm => 'This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get startMomentum => 'Start small.';

  @override
  String get startMomentumDescription =>
      'Choose one habit that fits into your day right now.';

  @override
  String get completion => 'Completion';

  @override
  String get active => 'Active';

  @override
  String get todaysMomentum => 'Today\'s momentum';

  @override
  String get completed => 'COMPLETED';

  @override
  String get slideToComplete => 'Slide >>';

  @override
  String get name => 'Name';

  @override
  String get namePlaceholder => 'e.g. Read 20 minutes';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get description => 'Description';

  @override
  String get descriptionPlaceholder => 'Optional description';

  @override
  String get category => 'Category';

  @override
  String get icon => 'Icon';

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get color => 'Color';

  @override
  String get frequency => 'Frequency';

  @override
  String get selectDays => 'Select Days';

  @override
  String get targetPerDay => 'Target per day';

  @override
  String get targetPerWeek => 'Target per week';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get custom => 'Custom';

  @override
  String perDay(int count) {
    return '$count/day';
  }

  @override
  String perWeek(int count) {
    return '$count× per week';
  }

  @override
  String onDays(int count, int days) {
    return '$count on $days days';
  }

  @override
  String completedCount(int count) {
    return 'Completed ($count)';
  }

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get dailyReminderDesc => 'Reminds you about open habits';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionRequiredDesc => 'Allow notifications for reminders';

  @override
  String get allow => 'Allow';

  @override
  String get notificationsEnabled => 'Notifications enabled! 🔔';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get testNotificationDesc => 'Sends a test notification';

  @override
  String get testNotificationSent => 'Test notification sent!';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get aiFeatures => 'AI Features';

  @override
  String get aiInsights => 'Local coaching';

  @override
  String get aiInsightsDesc =>
      'Deterministic suggestions calculated on this device';

  @override
  String get language => 'Language';

  @override
  String get appLanguage => 'App Language';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'English';

  @override
  String get advanced => 'Advanced';

  @override
  String version(String version) {
    return 'Habiter v$version';
  }

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsSubtitle =>
      'Track trends live, celebrate peaks, correct early.';

  @override
  String get liveOverview => 'Live overview';

  @override
  String get activeHabits => 'Active habits';

  @override
  String get totalWins => 'Total wins';

  @override
  String get avgSuccess => 'Avg success';

  @override
  String get weeklyProgress => 'Weekly progress';

  @override
  String get trackToSeeProgress => 'Track a habit to see weekly performance.';

  @override
  String get streak => 'Streak';

  @override
  String get success => 'Success';

  @override
  String get total => 'Total';

  @override
  String get aiInsightsTitle => 'AI Insights';

  @override
  String get insightsAppearHere =>
      'Insights will appear here after you track a few days and generate AI suggestions.';

  @override
  String confidence(int percent) {
    return 'Confidence $percent%';
  }

  @override
  String get habit => 'Habit';

  @override
  String get retry => 'Retry';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockSubtitle => 'Lock apps until your habits are completed';

  @override
  String get locked => 'Locked';

  @override
  String get status => 'Status';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get permissionsRequired => 'Permissions required';

  @override
  String get usageAccess => 'Usage Access';

  @override
  String get usageAccessDesc => 'Detect which app is open';

  @override
  String get overlayPermission => 'Display over other apps';

  @override
  String get overlayPermissionDesc => 'Show lock screen';

  @override
  String get loadingApps => 'Loading apps...';

  @override
  String get noAppsFound =>
      'No visible launcher apps were found. App visibility depends on Android policy.';

  @override
  String selectAppsToLock(int count) {
    return 'Select apps to lock ($count)';
  }

  @override
  String get androidOnly => 'Android Only';

  @override
  String get androidOnlyDesc =>
      'App Lock is only available on Android devices.';

  @override
  String get appLockRecovery => 'App Lock is safely off';

  @override
  String get appLockReliability => 'Device reliability';

  @override
  String get appLockReliabilityDescription =>
      'Android and manufacturer power policies can stop monitoring. Habiter turns App Lock off when required access is missing.';

  @override
  String get disableAppLock => 'Disable App Lock now';

  @override
  String get batterySettings => 'Open battery settings';

  @override
  String get refreshPermissions => 'Check permissions again';

  @override
  String get grant => 'Grant';

  @override
  String get yourDailyFlow => 'Your Daily Flow';

  @override
  String get keepMomentum => 'Keep the momentum going!';

  @override
  String get onTrack => 'On Track';

  @override
  String habitsCompleted(int done, int total) {
    return '$done of $total habits completed';
  }

  @override
  String get pending => 'Pending';

  @override
  String get done => 'Done';

  @override
  String get classlyInstance => 'Classly Instance';

  @override
  String get loginWithClassly => 'Login with Classly';

  @override
  String get autoSync => 'Auto-Sync';

  @override
  String get syncInterval => 'Sync Interval';

  @override
  String newTasksImported(int count) {
    return '$count new tasks imported';
  }

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String todayCompleted(int count) {
    return 'Completed today ($count)';
  }

  @override
  String get allHabitsCompleted => '🎉 All habits completed for today!';

  @override
  String get markAsComplete => 'Mark as complete';

  @override
  String get undoComplete => 'Undo';

  @override
  String get edit => 'Edit';

  @override
  String get archive => 'Archive';

  @override
  String get pauseHabit => 'Pause habit';

  @override
  String get resumeHabit => 'Resume habit';

  @override
  String get restoreHabit => 'Restore habit';

  @override
  String get manageHabitLifecycle => 'Paused and archived habits';

  @override
  String get noPausedOrArchivedHabits => 'No paused or archived habits';

  @override
  String inactiveHabitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits',
      one: '1 habit',
    );
    return '$_temp0';
  }

  @override
  String get habitPaused => 'Paused — planned days do not count against you';

  @override
  String get habitArchived => 'Archived — available to restore';

  @override
  String get recoveryTitle => 'Your pace, without pressure';

  @override
  String get recoveryNewStart =>
      'Start with the next small opportunity when it suits you.';

  @override
  String get recoveryGentleReturn =>
      'A missed day does not erase earlier effort. The next planned day is enough.';

  @override
  String get recoveryRebuilding =>
      'You are finding your rhythm again, one planned day at a time.';

  @override
  String get recoverySteady =>
      'Your recent rhythm is steady. Pauses remain neutral.';

  @override
  String get recoveryHide => 'Hide supportive score';

  @override
  String recoveryFormula(int completed, int scheduled, int score) {
    return '$completed of $scheduled eligible plans completed = $score%';
  }

  @override
  String get reminderDiagnostics => 'Reminder diagnostics';

  @override
  String get reminderDiagnosticsDescription =>
      'Review permissions and pending reminders safely';

  @override
  String get reminderPermissionGranted => 'Notification permission is granted';

  @override
  String get reminderPermissionMissing =>
      'Notification permission is not available';

  @override
  String pendingReminders(int count) {
    return 'Pending reminders: $count';
  }

  @override
  String get noPendingReminders => 'No pending reminders';

  @override
  String get osManagedReminderTime =>
      'Delivery time managed by the operating system';

  @override
  String get rescheduleReminders => 'Reschedule';

  @override
  String get goal => 'Goal';

  @override
  String get createdAt => 'Created';

  @override
  String get todayDone => 'Done today ✓';

  @override
  String get notCompleted => 'Not completed yet';

  @override
  String get noHabitsYet => 'No habits yet. Start by adding one!';

  @override
  String perDayTarget(int count) {
    return '${count}x per day';
  }

  @override
  String get today => 'Today';

  @override
  String get todaySubtitle => 'One clear next step, at your pace.';

  @override
  String get nextUp => 'Next up';

  @override
  String get nextUpDescription => 'A small action is enough.';

  @override
  String get remainingToday => 'Still for today';

  @override
  String remainingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits left',
      one: '1 habit left',
      zero: 'Nothing left',
    );
    return '$_temp0';
  }

  @override
  String get dailyProgress => 'Daily progress';

  @override
  String completeHabit(String name) {
    return 'Complete $name';
  }

  @override
  String openHabit(String name) {
    return 'Open $name';
  }

  @override
  String get habitHubLatestHabit => 'Latest habit';

  @override
  String get habitHubTodayOpen => 'Open today';

  @override
  String get habitHubNotPlanned => 'Not planned today';

  @override
  String get habitHubEmptyTitle => 'Make space for a new habit';

  @override
  String get habitHubEmptyBody =>
      'Start with one small action that belongs to you.';

  @override
  String habitHubWheelPosition(String name, int position, int total) {
    return '$name, option $position of $total';
  }

  @override
  String habitHubOpenDestination(String name) {
    return 'Open $name';
  }

  @override
  String get completedToday => 'Completed today';

  @override
  String get completedQuietly =>
      'Everything planned is done. Enjoy the space you made.';

  @override
  String get addHabit => 'Add habit';

  @override
  String get habitBasics => 'The habit';

  @override
  String get habitBasicsHint => 'Give this action a clear, friendly identity.';

  @override
  String get habitSchedule => 'Rhythm';

  @override
  String get habitScheduleHint =>
      'Choose when this habit should appear. Paused days stay neutral.';

  @override
  String get habitReminder => 'Reminder';

  @override
  String get habitReminderHint => 'Optional and fully controlled by you.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get backLabel => 'Back';

  @override
  String get saveHabit => 'Save habit';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get scheduleRequired => 'Choose at least one day.';

  @override
  String get reminderTimeRequired =>
      'Choose a reminder time or turn reminders off.';

  @override
  String get optional => 'Optional';

  @override
  String get analyticsTitle => 'Your rhythm';

  @override
  String get analyticsBody =>
      'Notice patterns without turning progress into pressure.';

  @override
  String get activeHabitsLabel => 'Active habits';

  @override
  String get totalWinsLabel => 'Completed';

  @override
  String get averageSuccessLabel => 'Follow-through';

  @override
  String get noAnalyticsTitle => 'Your patterns will appear here';

  @override
  String get noAnalyticsBody =>
      'Complete a habit a few times to build a useful, private history.';

  @override
  String get streakLabel => 'Current rhythm';

  @override
  String get bestStreakLabel => 'Best rhythm';

  @override
  String get successLabel => 'Follow-through';

  @override
  String get appLockTitle => 'Focus with App Lock';

  @override
  String get appLockBody =>
      'Keep selected apps out of reach until today\'s habits are complete.';

  @override
  String get appLockStatusOn => 'App Lock is on';

  @override
  String get appLockStatusOff => 'App Lock is off';

  @override
  String get appLockPermissionIntro =>
      'Two Android permissions make blocking possible. You can revoke either one at any time.';

  @override
  String get searchApps => 'Search apps';

  @override
  String get selectedApps => 'Selected apps';

  @override
  String get availableApps => 'Available apps';

  @override
  String get noMatchingApps => 'No matching apps';

  @override
  String get appSelected => 'Selected';

  @override
  String get appNotSelected => 'Not selected';

  @override
  String get permissionsReady => 'Permissions ready';

  @override
  String get permissionsNeedAttention => 'Setup needs attention';

  @override
  String get recoveryAndReliability => 'Reliability & recovery';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBody =>
      'Shape Habiter around your routine. Your habit data stays on this device.';

  @override
  String get focusAndAppLock => 'Focus & App Lock';

  @override
  String get privacyAndData => 'Data & privacy';

  @override
  String get localFirstTitle => 'Stored on this device';

  @override
  String get localFirstBody =>
      'Habits stay local unless you explicitly export them or connect an integration.';

  @override
  String get configureAppLock => 'Configure App Lock';

  @override
  String get configureAppLockBody =>
      'Android only · permissions and a one-tap recovery switch';

  @override
  String get recoverySupport => 'Gentle recovery support';

  @override
  String get recoverySupportBody =>
      'Show non-punitive suggestions after a missed day.';

  @override
  String get advancedIntegrations => 'Advanced & integrations';

  @override
  String get advancedIntegrationsBody => 'Optional tools, off by default';

  @override
  String get classlyImport => 'Classly-compatible import';

  @override
  String get experimentalAi => 'Experimental remote AI';

  @override
  String get dailyReminderOff =>
      'Off — permission is requested only when you enable it.';

  @override
  String dailyReminderAt(String time) {
    return 'Scheduled for $time';
  }

  @override
  String get bootstrapErrorTitle => 'Habiter could not start safely';

  @override
  String get exportData => 'Export a backup';

  @override
  String get exportDataBody =>
      'Copy a JSON backup to the clipboard for your secure storage.';

  @override
  String get importData => 'Import a backup';

  @override
  String get importDataBody =>
      'Review a Habiter JSON backup before adding its data.';

  @override
  String get backupCopied => 'Backup copied to the clipboard';

  @override
  String get pasteBackup => 'Paste backup JSON';

  @override
  String get reviewImport => 'Review import';

  @override
  String importSummary(int habits, int entries, int collisions) {
    return '$habits habits · $entries entries · $collisions already exist';
  }

  @override
  String get importComplete =>
      'Import complete. Existing habits were kept and the pre-import backup was copied.';

  @override
  String get invalidBackup => 'This backup could not be read.';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connectWithOauth => 'Connect with OAuth';

  @override
  String get useToken => 'Use token';

  @override
  String get trustedHttpsOnly =>
      'Connect only a trusted public HTTPS server. Disconnecting clears stored credentials.';

  @override
  String get httpsEndpoint => 'HTTPS endpoint';

  @override
  String get optionalAccessToken => 'Optional access token';

  @override
  String get remoteAiOn =>
      'Enabled. Provider requests may share data and incur costs.';

  @override
  String get remoteAiOff => 'Off. Local coaching does not require an API key.';

  @override
  String get save => 'Save';

  @override
  String get providerLabel => 'Provider';

  @override
  String get apiKeyLabel => 'API key';

  @override
  String get increaseTarget => 'Increase daily target';

  @override
  String get decreaseTarget => 'Decrease daily target';

  @override
  String get bootstrapErrorBody =>
      'Your data was left untouched. Try starting Habiter again.';

  @override
  String get remoteAiDisclosure =>
      'Optional and off by default. The key stays in secure device storage. Provider requests may cost money and share habit data.';

  @override
  String get apiKeyRequired => 'Enter an API key to enable remote AI.';

  @override
  String get unlockRule => 'Unlock rule';

  @override
  String get allHabitsRequired => 'Finish all of today\'s habits';

  @override
  String get allHabitsRequiredBody =>
      'Selected apps become available when today\'s list is complete.';

  @override
  String get specificHabitsRequired => 'Use selected habits only';

  @override
  String get specificHabitsRequiredBody =>
      'Choose which habits control App Lock.';

  @override
  String get requiredHabits => 'Habits required to unlock';

  @override
  String get nothingScheduledTitle => 'Nothing is scheduled today';

  @override
  String get nothingScheduledBody =>
      'Your next habit will appear here when its rhythm comes around.';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryLearning => 'Learning';

  @override
  String get categoryProductivity => 'Productivity';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryCreative => 'Creative';

  @override
  String get categoryFitness => 'Fitness';

  @override
  String get categoryMindfulness => 'Mindfulness';

  @override
  String get categoryFinance => 'Finance';

  @override
  String get categoryHome => 'Home';

  @override
  String get templateGroupPopular => 'Popular';

  @override
  String get templateWater => 'Drink water';

  @override
  String get templateWorkout => 'Workout';

  @override
  String get templateRead => 'Read';

  @override
  String get templateMeditate => 'Meditate';

  @override
  String get templateWalk => 'Take a walk';

  @override
  String get templateSleep => 'Sleep routine';

  @override
  String get templateWrite => 'Write';

  @override
  String get templateTidy => 'Tidy up';

  @override
  String get templateHealthyMeal => 'Healthy meal';

  @override
  String get templateMedicine => 'Take medicine';

  @override
  String get templateFloss => 'Floss';

  @override
  String get templateScreenFree => 'Screen-free time';

  @override
  String get templateFinances => 'Review finances';

  @override
  String get templateInstrument => 'Practice an instrument';

  @override
  String get templateLanguage => 'Learn a language';

  @override
  String get templateRun => 'Go running';

  @override
  String get creationQuestion => 'What would you like to do regularly?';

  @override
  String get starterTemplates => 'A few good places to start';

  @override
  String get searchTemplates => 'Search habits';

  @override
  String get customHabitAction => 'Create your own habit';

  @override
  String customHabitFromSearch(String name) {
    return 'Create your own habit \"$name\"';
  }

  @override
  String get habitIdentityQuestion => 'What would you like to do?';

  @override
  String get habitIdentityHint =>
      'A short name is easier to recognize in your day.';

  @override
  String get chooseAnotherTemplate => 'Choose another template';

  @override
  String get rhythmQuestion => 'How often?';

  @override
  String get rhythmHint => 'Choose a rhythm that genuinely fits your week.';

  @override
  String get dailyOptionBody => 'Once every day';

  @override
  String get weeklyOptionBody => 'For example, three times a week';

  @override
  String get customOptionBody => 'Choose the days that fit';

  @override
  String get reminderQuestion => 'Would you like a reminder?';

  @override
  String get habitReminderToggle => 'Reminder';

  @override
  String get reminderSupportBody =>
      'Habiter can give you a gentle nudge at a time you choose.';

  @override
  String get reviewHabit => 'Your habit';

  @override
  String get ready => 'Ready.';

  @override
  String get detailsOptional => 'Add a note';

  @override
  String weeklyUnits(int completed, int scheduled) {
    return '$completed of $scheduled planned this week';
  }

  @override
  String get thisWeek => 'This week';

  @override
  String get lastThirtyDays => 'Last 30 days';

  @override
  String consistencyValue(int percent) {
    return '$percent% consistency';
  }

  @override
  String get historyTitle => 'History';

  @override
  String get notEnoughHistory => 'Not enough history yet';

  @override
  String get notEnoughHistoryBody =>
      'After a few planned sessions, your rhythm will become visible here.';

  @override
  String get trendImproving => 'Your recent rhythm is improving.';

  @override
  String get trendDeclining => 'Your recent rhythm has become quieter.';

  @override
  String get trendSteady => 'Your recent rhythm is steady.';

  @override
  String get dayCompleted => 'completed';

  @override
  String get dayMissed => 'scheduled, not completed';

  @override
  String get dayFuture => 'upcoming';

  @override
  String get dayNotScheduled => 'not scheduled';

  @override
  String pausedArchivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paused or archived habits',
      one: '1 paused or archived habit',
    );
    return '$_temp0';
  }

  @override
  String get chooseHabit => 'Choose a habit';

  @override
  String get emptyStarterExamples => 'Water · Read · Walk · Meditate';

  @override
  String get onboardingWelcomeTitle => 'Small steps.\nReal change.';

  @override
  String get onboardingWelcomeBody =>
      'Habiter keeps what matters in view — clearly, calmly, one day at a time.';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingIntentTitle => 'What should\ngrow?';

  @override
  String get onboardingIntentBody =>
      'Choose a direction. You can change everything later.';

  @override
  String get onboardingIntentOther => 'Something else';

  @override
  String get onboardingFirstHabitTitle => 'Your first\nsmall step.';

  @override
  String get onboardingFirstHabitBody =>
      'Choose an idea or give your habit a name of its own.';

  @override
  String get onboardingCustomHabitName => 'Name your habit';

  @override
  String get onboardingRhythmTitle => 'Find your\nrhythm.';

  @override
  String get onboardingEveryDay => 'Every day';

  @override
  String get onboardingEveryDayBody => 'A clear daily rhythm';

  @override
  String get onboardingSeveralTimes => 'Several times per week';

  @override
  String get onboardingSeveralTimesBody => 'Choose a weekly target';

  @override
  String get onboardingSpecificDays => 'Specific days';

  @override
  String get onboardingSpecificDaysBody => 'Choose the days that fit';

  @override
  String onboardingTimesPerWeek(int count) {
    return '$count× per week';
  }

  @override
  String get onboardingRhythmExplainerDailyTitle => 'Every day can count once.';

  @override
  String onboardingRhythmExplainerFlexibleTitle(int count) {
    return '$count× per week means $count different days.';
  }

  @override
  String get onboardingRhythmExplainerFixedTitle =>
      'Only your chosen weekdays count.';

  @override
  String get onboardingRhythmExplainerDailyBody =>
      'A completion counts once per calendar day. Your week runs Monday–Sunday.';

  @override
  String get onboardingRhythmExplainerFlexibleBody =>
      'You do not need fixed weekdays. Any different days from Monday–Sunday count—even consecutive days.';

  @override
  String get onboardingRhythmExplainerFixedBody =>
      'The highlighted weekdays are your habit days. Each date can count once.';

  @override
  String get onboardingRhythmWeekLabel => 'THIS WEEK';

  @override
  String onboardingRhythmProgress(int completed, int target) {
    return '$completed / $target';
  }

  @override
  String onboardingRhythmProgressSemantics(int completed, int target) {
    return '$completed of $target days selected';
  }

  @override
  String get onboardingRhythmDaySelected => 'selected';

  @override
  String get onboardingRhythmDayNotSelected => 'not selected';

  @override
  String get onboardingRhythmDayUnavailable => 'not part of this schedule';

  @override
  String get onboardingRhythmTryPrompt =>
      'Tap a day to see how it changes this week.';

  @override
  String get onboardingRhythmFactDifferentDays => 'One date counts once';

  @override
  String get onboardingRhythmFactMondayReset => 'Monday–Sunday';

  @override
  String get onboardingRhythmFactConsecutive => 'Consecutive days count';

  @override
  String get onboardingRhythmInvalid =>
      'This rhythm could not be displayed. Go back and choose it again.';

  @override
  String get onboardingReminderEducationTitle => 'One nudge.\nTwo choices.';

  @override
  String get onboardingReminderEducationBody =>
      'Try how Done and Later change your progress.';

  @override
  String get onboardingReminderQuestion => 'Does now work for you?';

  @override
  String get onboardingReminderResetDemo => 'Try it again';

  @override
  String get onboardingReminderDoneExplanation =>
      'Marked done. Your progress changes immediately.';

  @override
  String get onboardingReminderLaterExplanation =>
      'Your progress stays the same. The demo moves 30 minutes ahead.';

  @override
  String onboardingReminderProgressSemantics(int completed, int target) {
    return '$completed of $target habit days completed';
  }

  @override
  String get onboardingReminderTitle => 'Reminders.\nOnly if you want.';

  @override
  String get onboardingReminderBody =>
      'Smart reminders are optional. We only ask for permission after your choice.';

  @override
  String get onboardingNoReminder => 'Without a reminder';

  @override
  String get onboardingAddReminder => 'Use Smart reminders';

  @override
  String get onboardingSmartCalibrationTitle => 'Seven-day calibration';

  @override
  String get onboardingSmartCalibrationBody =>
      'A few short questions teach Habiter which moments actually fit. Ignored alerts stay neutral.';

  @override
  String get onboardingSmartFrequencyTitle => 'Persistent, within limits';

  @override
  String get onboardingSmartFrequencyBody =>
      'Up to three attempts per habit day, but never more than eight alerts in total and at least 90 minutes apart.';

  @override
  String get onboardingSmartPrivacyTitle => 'Only on this device';

  @override
  String get onboardingSmartPrivacyBody =>
      'No cloud transfer, location, contacts, calendar, sensors, or app-usage monitoring.';

  @override
  String get onboardingSmartControlTitle => 'You stay in control';

  @override
  String get onboardingSmartControlBody =>
      'Active hours default to 08:00–22:00. You can pause, change every plan, or delete all learning data anytime.';

  @override
  String get onboardingHabitReadyTitle => 'Your first\nhabit is ready.';

  @override
  String get onboardingHabitReadyBody =>
      'Now we\'ll bring it to where you actually see it.';

  @override
  String get onboardingSaving => 'Setting up your habit…';

  @override
  String onboardingStepProgress(int step, int total) {
    return 'Setup step $step of $total';
  }

  @override
  String get onboardingStateUnavailableTitle => 'One step back.';

  @override
  String get onboardingStateUnavailableBody =>
      'This step could not be loaded. Go back and try it again.';

  @override
  String get onboardingWidgetIntroTitle => 'Your habit.\nRight in view.';

  @override
  String get onboardingWidgetIntroBody =>
      'See your next step and check it off without opening the app.';

  @override
  String get onboardingWidgetResponsive =>
      'Fits compact, wide, and large home screen spaces.';

  @override
  String get onboardingWidgetAdd => 'Add widget';

  @override
  String get onboardingWidgetLater => 'Later';

  @override
  String get onboardingWidgetPinTitle => 'Add Habiter to your home screen';

  @override
  String get onboardingWidgetPinBody =>
      'Android will ask where you want to place the widget.';

  @override
  String get onboardingWidgetRequestingTitle => 'Almost there.';

  @override
  String get onboardingWidgetRequestingBody =>
      'Android is preparing placement…';

  @override
  String get onboardingWidgetReadyTitle => 'Ready.';

  @override
  String get onboardingWidgetReadyBody =>
      'Your next step is now directly on your home screen.';

  @override
  String get onboardingWidgetDeclinedTitle => 'No problem.';

  @override
  String get onboardingWidgetDeclinedBody =>
      'You can add the widget later from Habiter at any time.';

  @override
  String get onboardingWidgetManualTitle => 'Add the widget manually';

  @override
  String get onboardingWidgetUnsupportedBody =>
      'Automatic pinning is not supported here. You can still add it manually.';

  @override
  String get onboardingWidgetFailedBody =>
      'The Android request did not work. You can add the widget manually instead.';

  @override
  String get onboardingWidgetManualOne => 'Touch and hold your home screen';

  @override
  String get onboardingWidgetManualTwo => 'Open Widgets';

  @override
  String get onboardingWidgetManualThree => 'Choose Habiter';

  @override
  String get onboardingWidgetManualFour => 'Place the widget';

  @override
  String get onboardingWidgetLetsGo => 'Let\'s go';

  @override
  String get onboardingWidgetUnderstood => 'Got it';

  @override
  String get widgetPromotionTitle => 'Habiter on your home screen';

  @override
  String get widgetPromotionBody => 'Check off habits without opening the app.';

  @override
  String get widgetSettingsTitle => 'Home screen / Widget';

  @override
  String get widgetStatusAdded => 'Widget added';

  @override
  String get widgetStatusNotAdded => 'Not added yet';

  @override
  String get widgetPreviewSemantics =>
      'Preview of the responsive Habiter home screen widget';

  @override
  String widgetPreviewNext(String name) {
    return 'Next: $name';
  }

  @override
  String get updateCenterTitle => 'Update Center';

  @override
  String get updateSettingsEntry => 'App updates';

  @override
  String get updateSettingsBody =>
      'Channel, schedule, status and update history';

  @override
  String get updateStatusTitle => 'Update status';

  @override
  String get updateStatusIdle => 'Ready to check';

  @override
  String get updateStatusChecking => 'Checking securely…';

  @override
  String get updateStatusCurrent => 'Habiter is up to date';

  @override
  String updateStatusAvailable(String version) {
    return 'Habiter $version is available';
  }

  @override
  String updateStatusDownloading(int percent) {
    return 'Downloading · $percent%';
  }

  @override
  String get updateStatusVerifying => 'Verifying download…';

  @override
  String get updateStatusReady => 'Ready to install';

  @override
  String get updateStatusInstalling => 'Android installer opened';

  @override
  String get updateStatusMandatory => 'This update is now required';

  @override
  String get updateStatusError => 'Update check unavailable';

  @override
  String get updateAvailableBadge => 'Update available';

  @override
  String get updateCheckNow => 'Check now';

  @override
  String updateLastChecked(String date) {
    return 'Last checked: $date';
  }

  @override
  String get updateNeverChecked => 'Not checked yet';

  @override
  String get updateTrackTitle => 'Release channel';

  @override
  String get updateTrackStable => 'Stable';

  @override
  String get updateTrackStableBody => 'Only tested stable releases';

  @override
  String get updateTrackBeta => 'Beta';

  @override
  String get updateTrackBetaBody => 'Newest build across Stable and Beta';

  @override
  String get updateProfileTitle => 'Update profile';

  @override
  String get updateProfileImmediate => 'Immediate';

  @override
  String get updateProfileImmediateBody =>
      'Start/resume and hourly checks · download on any network';

  @override
  String get updateProfileBalanced => 'Balanced';

  @override
  String get updateProfileBalancedBody =>
      'Every 24 hours · auto-download on unmetered networks';

  @override
  String get updateProfileSaver => 'Saver';

  @override
  String get updateProfileSaverBody =>
      'Every seven days · no automatic downloads';

  @override
  String get updateViewWhatsNew => 'What’s new';

  @override
  String get updateDownload => 'Download update';

  @override
  String get updateInstall => 'Install';

  @override
  String get updateOpenDownload => 'Open download';

  @override
  String get updateNotNow => 'Not now';

  @override
  String get updateInstallerPermissionTitle =>
      'Allow Habiter to install this update';

  @override
  String get updateInstallerPermissionBody =>
      'Android asks once whether Habiter may open verified APK updates. You can revoke this permission anytime.';

  @override
  String get updateOpenSettings => 'Open Android settings';

  @override
  String get updateHistoryTitle => 'Release history';

  @override
  String get updateStorageTitle => 'Update storage';

  @override
  String updateStorageUsage(String metadata, String downloads) {
    return 'Metadata: $metadata · downloads: $downloads';
  }

  @override
  String get updateClearDownloads => 'Delete downloads';

  @override
  String get updateClearCache => 'Clear manifest cache';

  @override
  String get updatePrivacyNote =>
      'Checks contain no user identifier and create no analytics.';

  @override
  String get updateOfflineMandatoryWarning =>
      'A required update is pending. Habiter stays usable offline and will verify again when you reconnect.';

  @override
  String get updateMandatoryTitle => 'Update required';

  @override
  String get updateMandatoryBody =>
      'A verified deadline has passed. Install the update to continue online with Habiter.';

  @override
  String updateMandatoryCountdown(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Required in $hours hours',
      one: 'Required in 1 hour',
    );
    return '$_temp0';
  }

  @override
  String get releaseStorySuccessTitle => 'Update installed';

  @override
  String get releaseStorySuccessBody =>
      'Habiter is ready with the latest improvements.';

  @override
  String get releaseStoryContinue => 'Continue to Habiter';

  @override
  String get releaseStoryDetails => 'Details by version';

  @override
  String get releaseStoryAdded => 'Added';

  @override
  String get releaseStoryChanged => 'Changed';

  @override
  String get releaseStoryFixed => 'Fixed';

  @override
  String get releaseStorySecurity => 'Security';

  @override
  String releaseStoryFallbackHeadline(String version) {
    return 'Habiter $version';
  }

  @override
  String get releaseStoryFallbackSummary => 'A new Habiter release is ready.';

  @override
  String get updateUnsupported =>
      'Updates are not available on this platform yet.';

  @override
  String get widgetInstancesTitle => 'Widgets';

  @override
  String get widgetInstancesBody =>
      'Each home-screen widget keeps its own content, layout, colors and actions.';

  @override
  String get widgetInstancesEmpty =>
      'No Habiter widgets are currently placed on your home screen.';

  @override
  String get widgetInstancesLoadFailed =>
      'Your widget instances could not be loaded.';

  @override
  String get widgetAddAnother => 'Add widget';

  @override
  String widgetDefaultName(int id) {
    return 'Widget $id';
  }

  @override
  String get widgetBreakpointCompact => 'Compact';

  @override
  String get widgetBreakpointCompactSquare => 'Compact Square';

  @override
  String get widgetBreakpointWide => 'Wide';

  @override
  String get widgetBreakpointMediumHero => 'Medium Hero';

  @override
  String get widgetBreakpointLarge => 'Large';

  @override
  String get widgetBreakpointExtraLarge => 'Extra Large';

  @override
  String get widgetBasicTitle => 'Widget settings';

  @override
  String get widgetBasicBody =>
      'Simple by default. These settings only affect this widget instance.';

  @override
  String get widgetSectionIdentity => 'This widget';

  @override
  String get widgetSectionContent => 'Content';

  @override
  String get widgetSectionMode => 'Widget mode';

  @override
  String get widgetSectionAppearance => 'Appearance';

  @override
  String get widgetSectionBehavior => 'Behavior';

  @override
  String get widgetDisplayName => 'Name (optional)';

  @override
  String get widgetDisplayNameHint => 'Morning, Training, Dashboard…';

  @override
  String get widgetHabitSelection => 'Habits to show';

  @override
  String get widgetHabitsAllToday => 'All today\'s habits';

  @override
  String get widgetHabitsOpenOnly => 'Open habits only';

  @override
  String get widgetHabitsSelected => 'Selected habits';

  @override
  String get widgetNoSelectableHabits =>
      'There are no active habits to select.';

  @override
  String get widgetSort => 'Sort order';

  @override
  String get widgetSortHabiter => 'As in Habiter';

  @override
  String get widgetSortOpenFirst => 'Open habits first';

  @override
  String get widgetSortCustom => 'Custom order';

  @override
  String get widgetSortCustomBody =>
      'Drag habits into the order this widget should use.';

  @override
  String get widgetMode => 'Mode';

  @override
  String get widgetModeAuto => 'Auto';

  @override
  String get widgetModeFocus => 'Focus';

  @override
  String get widgetModeList => 'List';

  @override
  String get widgetModeMinimal => 'Minimal';

  @override
  String get widgetTheme => 'Theme';

  @override
  String get widgetAccent => 'Accent';

  @override
  String get widgetAccentHabiter => 'Habiter';

  @override
  String get widgetAccentDynamic => 'Android Dynamic Color';

  @override
  String get widgetAccentCustom => 'Custom';

  @override
  String get widgetShowProgress => 'Show progress';

  @override
  String get widgetShowSchedule => 'Show schedule label';

  @override
  String get widgetShowCompleted => 'Show completed habits';

  @override
  String get widgetDensity => 'Density';

  @override
  String get widgetDensityCompact => 'Compact';

  @override
  String get widgetDensityComfortable => 'Comfortable';

  @override
  String get widgetBackgroundTap => 'Tap widget background';

  @override
  String get widgetBackgroundToday => 'Open Today';

  @override
  String get widgetBackgroundNext => 'Open next habit';

  @override
  String get widgetBackgroundApp => 'Open Habiter';

  @override
  String get widgetOneTapCompletion => 'One-tap completion';

  @override
  String get widgetOneTapCompletionBody =>
      'When off, the completion control opens the habit instead.';

  @override
  String get widgetShowUndo => 'Show Undo after completion';

  @override
  String get widgetCompletionFeedback => 'Show completion feedback';

  @override
  String get widgetSaveFailed => 'This widget\'s settings could not be saved.';

  @override
  String get widgetAdvancedTitle => 'Advanced';

  @override
  String get widgetAdvancedBody =>
      'Cracked customization · collapsed by default';

  @override
  String get widgetAdvancedBreakpoints => 'Per-breakpoint overrides';

  @override
  String get widgetAdvancedVisibleElements => 'Visible elements';

  @override
  String get widgetAdvancedHabitList => 'Habit list';

  @override
  String get widgetAdvancedProgress => 'Progress';

  @override
  String get widgetAdvancedCompletion => 'Completion controls';

  @override
  String get widgetAdvancedThemeTokens => 'Theme tokens';

  @override
  String get widgetAdvancedGeometry => 'Geometry';

  @override
  String get widgetAdvancedTypography => 'Typography';

  @override
  String get widgetAdvancedStates => 'State-specific UI';

  @override
  String get widgetAdvancedInteractions => 'Interaction mapping';

  @override
  String get widgetUseGlobalSettings => 'Use global settings';

  @override
  String get widgetOverrideThisSize => 'Override this size';

  @override
  String get widgetMaximumHabits => 'Maximum visible habits';

  @override
  String get widgetCompletedPlacement => 'Completed habit placement';

  @override
  String get widgetCompletedAsHabiter => 'As in Habiter';

  @override
  String get widgetCompletedAtEnd => 'Move to end';

  @override
  String get widgetOverflow => 'When space runs out';

  @override
  String get widgetOverflowTruncate => 'Truncate list';

  @override
  String get widgetOverflowOpenOnly => 'Show open habits only';

  @override
  String get widgetOverflowFocus => 'Switch to Focus';

  @override
  String get widgetPinnedHabits => 'Pinned habits';

  @override
  String get widgetProgressMode => 'Progress display';

  @override
  String get widgetProgressAutomatic => 'Automatic';

  @override
  String get widgetProgressHidden => 'Hidden';

  @override
  String get widgetProgressSegments => 'Segments';

  @override
  String get widgetProgressCounter => 'Counter';

  @override
  String get widgetProgressBoth => 'Segments + counter';

  @override
  String get widgetSegmentHeight => 'Segment height';

  @override
  String get widgetSegmentGap => 'Segment gap';

  @override
  String get widgetMaximumSegments => 'Maximum segments';

  @override
  String get widgetCompletedSegments => 'Completed segments';

  @override
  String get widgetRemainingSegments => 'Remaining segments';

  @override
  String get widgetCompletionButtonStyle => 'Button style';

  @override
  String get widgetFocusNextHabit => 'Focus next open habit after completion';

  @override
  String get widgetCompletionFeedbackLevel => 'Feedback detail';

  @override
  String get widgetFeedbackMinimal => 'Minimal';

  @override
  String get widgetFeedbackNormal => 'Normal';

  @override
  String get widgetFeedbackDetailed => 'Detailed';

  @override
  String get widgetThemeTokenMode => 'Theme token mode';

  @override
  String get widgetColorSurface => 'Surface';

  @override
  String get widgetColorSurfaceAccent => 'Surface accent';

  @override
  String get widgetColorPrimary => 'Primary';

  @override
  String get widgetColorText => 'Text';

  @override
  String get widgetColorMutedText => 'Muted text';

  @override
  String get widgetColorSuccess => 'Success';

  @override
  String get widgetResetToken => 'Reset this token';

  @override
  String get widgetChooseColor => 'Choose color';

  @override
  String get widgetSurfaceTransparency => 'Surface transparency';

  @override
  String get widgetCornerRadius => 'Widget corner radius';

  @override
  String get widgetHabitRowRadius => 'Habit row radius';

  @override
  String get widgetButtonRadius => 'Button radius';

  @override
  String get widgetOuterPadding => 'Outer padding';

  @override
  String get widgetHorizontalPadding => 'Horizontal padding';

  @override
  String get widgetVerticalPadding => 'Vertical padding';

  @override
  String get widgetRowGap => 'Row gap';

  @override
  String get widgetSectionGap => 'Section gap';

  @override
  String get widgetTextScale => 'Text scale';

  @override
  String get widgetHabitTitleSize => 'Habit title size';

  @override
  String get widgetSecondaryTextSize => 'Secondary text size';

  @override
  String get widgetCounterSize => 'Counter size';

  @override
  String get widgetFontWeight => 'Font weight';

  @override
  String get widgetFontSystem => 'System';

  @override
  String get widgetFontRegular => 'Regular';

  @override
  String get widgetFontMedium => 'Medium';

  @override
  String get widgetFontBold => 'Bold';

  @override
  String get widgetStateJustCompleted => 'Just completed';

  @override
  String get widgetStateAllComplete => 'All complete';

  @override
  String get widgetStateFreeToday => 'Free today';

  @override
  String get widgetStateNoHabits => 'No habits';

  @override
  String get widgetStateMissingStale => 'Missing / stale';

  @override
  String get widgetInteractionBackground => 'Widget background';

  @override
  String get widgetInteractionHabitRow => 'Habit row';

  @override
  String get widgetInteractionCompletion => 'Completion control';

  @override
  String get widgetActionOpenHabit => 'Open habit';

  @override
  String get widgetActionComplete => 'Complete';

  @override
  String get widgetActionNone => 'No action';

  @override
  String get widgetElementHabitIcon => 'Habit icon';

  @override
  String get widgetElementHabitName => 'Habit name';

  @override
  String get widgetElementSchedule => 'Schedule label';

  @override
  String get widgetElementSegments => 'Progress segments';

  @override
  String get widgetElementCounter => 'x / y counter';

  @override
  String get widgetElementTodayHeader => 'Today header';

  @override
  String get widgetElementCompletionButton => 'Completion button';

  @override
  String get widgetElementCompletedHabits => 'Completed habits';

  @override
  String get widgetElementCheckmark => 'Completion checkmark';

  @override
  String get widgetElementUndo => 'Undo button';

  @override
  String get widgetElementEmptyText => 'Empty-state text';

  @override
  String get widgetElementDoneText => 'Done-state text';

  @override
  String get widgetStyleAutomatic => 'Automatic';

  @override
  String get widgetStyleSolid => 'Solid';

  @override
  String get widgetStyleMuted => 'Muted';

  @override
  String get widgetStyleTrack => 'Track';

  @override
  String get widgetStyleOutline => 'Outline';

  @override
  String get widgetStyleCheckOnly => 'Check only';

  @override
  String get widgetStyleTextOnly => 'Text only';

  @override
  String get widgetStyleCheckAndText => 'Check + text';

  @override
  String get widgetStyleWholeRow => 'Whole habit row';

  @override
  String get widgetStyleFull => 'Full feedback';

  @override
  String get widgetStyleCompact => 'Compact';

  @override
  String get widgetStyleNextHabit => 'Show next habit';

  @override
  String get widgetStyleCard => 'Done card';

  @override
  String get widgetStyleMessage => 'Done message';

  @override
  String get widgetStyleIconOnly => 'Icon only';

  @override
  String get widgetStyleTextAndIcon => 'Text + icon';

  @override
  String get widgetStyleDefault => 'Default state';

  @override
  String get widgetStyleSyncMessage => 'Sync message';

  @override
  String get widgetLivePreview => 'Live preview';

  @override
  String widgetLivePreviewSemantics(String size) {
    return 'Live widget preview at $size size';
  }

  @override
  String get widgetPreviewEmpty => 'No matching habits for this widget.';

  @override
  String get widgetScheduleCustom => 'Specific days';

  @override
  String get widgetPresets => 'Presets and reuse';

  @override
  String get widgetPreset => 'Preset';

  @override
  String get widgetPresetDefault => 'Default';

  @override
  String get widgetPresetMinimal => 'Minimal';

  @override
  String get widgetPresetFocus => 'Focus';

  @override
  String get widgetPresetDenseList => 'Dense List';

  @override
  String get widgetPresetDashboard => 'Dashboard';

  @override
  String get widgetResetDefault => 'Reset to Default';

  @override
  String get widgetCopySettings => 'Copy settings from widget';

  @override
  String get widgetDuplicateConfiguration => 'Duplicate configuration';

  @override
  String get widgetCopyFrom => 'Copy settings from…';

  @override
  String get widgetDuplicateTo => 'Duplicate configuration to…';

  @override
  String get widgetDuplicated => 'The configuration was duplicated.';
}
