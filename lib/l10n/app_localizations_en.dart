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
  String get createHabit => 'Create Habit';

  @override
  String get updateHabit => 'Update Habit';

  @override
  String get deleteHabit => 'Delete Habit?';

  @override
  String get deleteHabitConfirm => 'This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get startMomentum => 'Start your momentum';

  @override
  String get startMomentumDescription =>
      'Create your first habit and watch your routine grow.';

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
    return '$count/week';
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
  String get aiInsights => 'AI Insights';

  @override
  String get aiInsightsDesc => 'Intelligent analysis of your habits';

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
}
