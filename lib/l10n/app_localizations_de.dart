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

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockSubtitle => 'Sperre Apps bis deine Habits erledigt sind';

  @override
  String get locked => 'Gesperrt';

  @override
  String get status => 'Status';

  @override
  String get statusActive => 'Aktiv';

  @override
  String get statusInactive => 'Inaktiv';

  @override
  String get permissionsRequired => 'Berechtigungen erforderlich';

  @override
  String get usageAccess => 'Usage Access';

  @override
  String get usageAccessDesc => 'Erkennen welche App geöffnet ist';

  @override
  String get overlayPermission => 'Über anderen Apps anzeigen';

  @override
  String get overlayPermissionDesc => 'Sperrbildschirm anzeigen';

  @override
  String get loadingApps => 'Apps werden geladen...';

  @override
  String get noAppsFound => 'Keine Apps gefunden';

  @override
  String selectAppsToLock(int count) {
    return 'Apps zum Sperren auswählen ($count)';
  }

  @override
  String get androidOnly => 'Nur für Android';

  @override
  String get androidOnlyDesc =>
      'App Lock ist nur auf Android Geräten verfügbar.';

  @override
  String get yourDailyFlow => 'Dein Tages-Flow';

  @override
  String get keepMomentum => 'Bleib am Ball!';

  @override
  String get onTrack => 'Auf Kurs';

  @override
  String habitsCompleted(int done, int total) {
    return '$done von $total Habits erledigt';
  }

  @override
  String get pending => 'Ausstehend';

  @override
  String get done => 'Erledigt';

  @override
  String get classlyInstance => 'Classly-Instanz';

  @override
  String get loginWithClassly => 'Mit Classly anmelden';

  @override
  String get autoSync => 'Auto-Sync';

  @override
  String get syncInterval => 'Sync-Intervall';

  @override
  String newTasksImported(int count) {
    return '$count neue Aufgaben importiert';
  }

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncComplete => 'Sync abgeschlossen';

  @override
  String todayCompleted(int count) {
    return 'Heute erledigt ($count)';
  }

  @override
  String get allHabitsCompleted => '🎉 Alle Habits für heute erledigt!';

  @override
  String get markAsComplete => 'Als erledigt markieren';

  @override
  String get undoComplete => 'Rückgängig machen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get archive => 'Archivieren';

  @override
  String get pauseHabit => 'Habit pausieren';

  @override
  String get resumeHabit => 'Habit fortsetzen';

  @override
  String get restoreHabit => 'Habit wiederherstellen';

  @override
  String get manageHabitLifecycle => 'Pausierte und archivierte Habits';

  @override
  String get noPausedOrArchivedHabits =>
      'Keine pausierten oder archivierten Habits';

  @override
  String inactiveHabitCount(int count) => switch (count) {
    1 => '1 Habit',
    _ => '$count Habits',
  };

  @override
  String get habitPaused =>
      'Pausiert – geplante Tage zählen nicht gegen dich';

  @override
  String get habitArchived =>
      'Archiviert – kann wiederhergestellt werden';

  @override
  String get recoveryTitle => 'Dein Tempo, ohne Druck';

  @override
  String get recoveryNewStart =>
      'Beginne bei der nächsten kleinen Gelegenheit, wenn es für dich passt.';

  @override
  String get recoveryGentleReturn =>
      'Ein ausgelassener Tag löscht frühere Schritte nicht. Der nächste geplante Tag genügt.';

  @override
  String get recoveryRebuilding =>
      'Du findest deinen Rhythmus wieder – einen geplanten Tag nach dem anderen.';

  @override
  String get recoverySteady =>
      'Dein aktueller Rhythmus ist stabil. Pausen bleiben neutral.';

  @override
  String get recoveryHide => 'Unterstützenden Wert ausblenden';

  @override
  String recoveryFormula(int completed, int scheduled, int score) =>
      '$completed von $scheduled berücksichtigten Plänen erledigt = $score%';

  @override
  String get reminderDiagnostics => 'Reminder-Diagnose';

  @override
  String get reminderDiagnosticsDescription =>
      'Berechtigung und ausstehende Reminder sicher prüfen';

  @override
  String get reminderPermissionGranted => 'Benachrichtigungen sind erlaubt';

  @override
  String get reminderPermissionMissing =>
      'Benachrichtigungen sind nicht verfügbar';

  @override
  String pendingReminders(int count) => 'Ausstehende Reminder: $count';

  @override
  String get noPendingReminders => 'Keine ausstehenden Reminder';

  @override
  String get osManagedReminderTime =>
      'Zustellzeit wird vom Betriebssystem verwaltet';

  @override
  String get rescheduleReminders => 'Neu planen';

  @override
  String get goal => 'Ziel';

  @override
  String get createdAt => 'Erstellt am';

  @override
  String get todayDone => 'Heute erledigt ✓';

  @override
  String get notCompleted => 'Noch nicht erledigt';

  @override
  String get noHabitsYet => 'Noch keine Habits. Füge ein neues hinzu!';

  @override
  String perDayTarget(int count) {
    return '${count}x pro Tag';
  }
}
