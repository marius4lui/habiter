// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Habiter';

  @override
  String get navHabits => 'Habits';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Nachmittag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get newHabit => 'Neues Habit';

  @override
  String get editHabit => 'Habit bearbeiten';

  @override
  String get createHabit => 'Habit erstellen';

  @override
  String get updateHabit => 'Habit aktualisieren';

  @override
  String get deleteHabit => 'Habit löschen';

  @override
  String get deleteHabitConfirm =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get startMomentum => 'Starte dein Momentum';

  @override
  String get startMomentumDescription =>
      'Lege dein erstes Habit an und schau zu, wie die Routine wachsen kann.';

  @override
  String get completion => 'Abschluss';

  @override
  String get active => 'Aktiv';

  @override
  String get todaysMomentum => 'Heutiges Momentum';

  @override
  String get completed => 'ERLEDIGT';

  @override
  String get slideToComplete => 'Wischen >>';

  @override
  String get name => 'Name';

  @override
  String get namePlaceholder => 'z.B. 20 Minuten lesen';

  @override
  String get nameRequired => 'Name ist erforderlich';

  @override
  String get description => 'Beschreibung';

  @override
  String get descriptionPlaceholder => 'Optionale Beschreibung';

  @override
  String get category => 'Kategorie';

  @override
  String get icon => 'Icon';

  @override
  String get tapToSelect => 'Tippen zum Auswählen';

  @override
  String get color => 'Farbe';

  @override
  String get frequency => 'Frequenz';

  @override
  String get selectDays => 'Tage auswählen';

  @override
  String get targetPerDay => 'Ziel pro Tag';

  @override
  String get daily => 'Täglich';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String perDay(int count) {
    return '$count/Tag';
  }

  @override
  String perWeek(int count) {
    return '$count/Woche';
  }

  @override
  String onDays(int count, int days) {
    return '$count an $days Tagen';
  }

  @override
  String completedCount(int count) {
    return 'Erledigt ($count)';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get dailyReminder => 'Tägliche Erinnerung';

  @override
  String get dailyReminderDesc => 'Erinnert dich an offene Habits';

  @override
  String get reminderTime => 'Erinnerungszeit';

  @override
  String get permissionRequired => 'Berechtigung erforderlich';

  @override
  String get permissionRequiredDesc =>
      'Erlaube Benachrichtigungen für Erinnerungen';

  @override
  String get allow => 'Erlauben';

  @override
  String get notificationsEnabled => 'Benachrichtigungen aktiviert! 🔔';

  @override
  String get testNotification => 'Test-Benachrichtigung';

  @override
  String get testNotificationDesc => 'Sendet eine Test-Notification';

  @override
  String get testNotificationSent => 'Test-Benachrichtigung gesendet!';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get aiFeatures => 'KI-Features';

  @override
  String get aiInsights => 'AI Insights';

  @override
  String get aiInsightsDesc => 'Intelligente Analyse deiner Habits';

  @override
  String get language => 'Sprache';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'English';

  @override
  String get advanced => 'Erweitert';

  @override
  String version(String version) {
    return 'Habiter v$version';
  }

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsSubtitle =>
      'Trends live verfolgen, Peaks feiern, früh korrigieren.';

  @override
  String get liveOverview => 'Live-Übersicht';

  @override
  String get activeHabits => 'Aktive Habits';

  @override
  String get totalWins => 'Gesamt-Erfolge';

  @override
  String get avgSuccess => 'Durchschn. Erfolg';

  @override
  String get weeklyProgress => 'Wöchentlicher Fortschritt';

  @override
  String get trackToSeeProgress =>
      'Tracke ein Habit, um den Wochenfortschritt zu sehen.';

  @override
  String get streak => 'Serie';

  @override
  String get success => 'Erfolg';

  @override
  String get total => 'Gesamt';

  @override
  String get aiInsightsTitle => 'AI Insights';

  @override
  String get insightsAppearHere =>
      'Insights erscheinen hier, nachdem du einige Tage getrackt und AI-Vorschläge generiert hast.';

  @override
  String confidence(int percent) {
    return 'Konfidenz $percent%';
  }

  @override
  String get habit => 'Habit';

  @override
  String get retry => 'Wiederholen';
}
