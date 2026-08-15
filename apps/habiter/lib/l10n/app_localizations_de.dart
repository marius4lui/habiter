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
  String get targetPerWeek => 'Ziel pro Woche';

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
  String get aiInsights => 'Lokales Coaching';

  @override
  String get aiInsightsDesc =>
      'Deterministische Vorschläge, die auf diesem Gerät berechnet werden';

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
  String get noAppsFound =>
      'Keine sichtbaren Launcher-Apps gefunden. Die Sichtbarkeit hängt von Android-Regeln ab.';

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
  String get appLockRecovery => 'App Lock ist sicher ausgeschaltet';

  @override
  String get appLockReliability => 'Gerätezuverlässigkeit';

  @override
  String get appLockReliabilityDescription =>
      'Android- und Hersteller-Energiesparregeln können die Überwachung stoppen. Habiter schaltet App Lock aus, wenn erforderliche Zugriffe fehlen.';

  @override
  String get disableAppLock => 'App Lock jetzt ausschalten';

  @override
  String get batterySettings => 'Akku-Einstellungen öffnen';

  @override
  String get refreshPermissions => 'Berechtigungen erneut prüfen';

  @override
  String get grant => 'Erlauben';

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
  String inactiveHabitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Habits',
      one: '1 Habit',
    );
    return '$_temp0';
  }

  @override
  String get habitPaused => 'Pausiert – geplante Tage zählen nicht gegen dich';

  @override
  String get habitArchived => 'Archiviert – kann wiederhergestellt werden';

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
  String recoveryFormula(int completed, int scheduled, int score) {
    return '$completed von $scheduled berücksichtigten Plänen erledigt = $score%';
  }

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
  String pendingReminders(int count) {
    return 'Ausstehende Reminder: $count';
  }

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

  @override
  String get today => 'Heute';

  @override
  String get todaySubtitle => 'Ein klarer nächster Schritt, in deinem Tempo.';

  @override
  String get nextUp => 'Als Nächstes';

  @override
  String get nextUpDescription => 'Eine kleine Handlung reicht.';

  @override
  String get remainingToday => 'Noch für heute';

  @override
  String remainingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Habits',
      one: 'Noch 1 Habit',
      zero: 'Nichts mehr offen',
    );
    return '$_temp0';
  }

  @override
  String get dailyProgress => 'Tagesfortschritt';

  @override
  String completeHabit(String name) {
    return '$name abschließen';
  }

  @override
  String openHabit(String name) {
    return '$name öffnen';
  }

  @override
  String get completedToday => 'Heute erledigt';

  @override
  String get completedQuietly =>
      'Alles Geplante ist erledigt. Genieß den Freiraum.';

  @override
  String get addHabit => 'Habit hinzufügen';

  @override
  String get habitBasics => 'Der Habit';

  @override
  String get habitBasicsHint =>
      'Gib der Handlung eine klare, freundliche Identität.';

  @override
  String get habitSchedule => 'Rhythmus';

  @override
  String get habitScheduleHint =>
      'Wähle, wann der Habit erscheint. Pausierte Tage bleiben neutral.';

  @override
  String get habitReminder => 'Erinnerung';

  @override
  String get habitReminderHint =>
      'Optional und vollständig unter deiner Kontrolle.';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get backLabel => 'Zurück';

  @override
  String get saveHabit => 'Habit speichern';

  @override
  String stepOf(int step, int total) {
    return 'Schritt $step von $total';
  }

  @override
  String get scheduleRequired => 'Wähle mindestens einen Tag.';

  @override
  String get reminderTimeRequired =>
      'Wähle eine Uhrzeit oder schalte Erinnerungen aus.';

  @override
  String get optional => 'Optional';

  @override
  String get analyticsTitle => 'Dein Rhythmus';

  @override
  String get analyticsBody =>
      'Erkenne Muster, ohne Fortschritt in Druck zu verwandeln.';

  @override
  String get activeHabitsLabel => 'Aktive Habits';

  @override
  String get totalWinsLabel => 'Erledigt';

  @override
  String get averageSuccessLabel => 'Drangeblieben';

  @override
  String get noAnalyticsTitle => 'Deine Muster erscheinen hier';

  @override
  String get noAnalyticsBody =>
      'Schließe Habits einige Male ab, um eine hilfreiche, private Historie aufzubauen.';

  @override
  String get streakLabel => 'Aktueller Rhythmus';

  @override
  String get bestStreakLabel => 'Bester Rhythmus';

  @override
  String get successLabel => 'Drangeblieben';

  @override
  String get appLockTitle => 'Fokus mit App Lock';

  @override
  String get appLockBody =>
      'Halte ausgewählte Apps zurück, bis deine heutigen Habits erledigt sind.';

  @override
  String get appLockStatusOn => 'App Lock ist aktiv';

  @override
  String get appLockStatusOff => 'App Lock ist aus';

  @override
  String get appLockPermissionIntro =>
      'Zwei Android-Berechtigungen ermöglichen die Sperre. Du kannst beide jederzeit entziehen.';

  @override
  String get searchApps => 'Apps suchen';

  @override
  String get selectedApps => 'Ausgewählte Apps';

  @override
  String get availableApps => 'Verfügbare Apps';

  @override
  String get noMatchingApps => 'Keine passenden Apps';

  @override
  String get appSelected => 'Ausgewählt';

  @override
  String get appNotSelected => 'Nicht ausgewählt';

  @override
  String get permissionsReady => 'Berechtigungen bereit';

  @override
  String get permissionsNeedAttention => 'Einrichtung benötigt Aufmerksamkeit';

  @override
  String get recoveryAndReliability => 'Zuverlässigkeit & Wiederherstellung';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsBody =>
      'Passe Habiter an deinen Alltag an. Deine Habit-Daten bleiben auf diesem Gerät.';

  @override
  String get focusAndAppLock => 'Fokus & App Lock';

  @override
  String get privacyAndData => 'Daten & Datenschutz';

  @override
  String get localFirstTitle => 'Auf diesem Gerät gespeichert';

  @override
  String get localFirstBody =>
      'Habits bleiben lokal, außer du exportierst sie bewusst oder verbindest eine Integration.';

  @override
  String get configureAppLock => 'App Lock einrichten';

  @override
  String get configureAppLockBody =>
      'Nur Android · Berechtigungen und Ausschalten mit einem Tipp';

  @override
  String get recoverySupport => 'Sanfte Neustart-Hilfe';

  @override
  String get recoverySupportBody =>
      'Zeigt wertfreie Vorschläge nach ausgelassenen Tagen.';

  @override
  String get advancedIntegrations => 'Erweitert & Integrationen';

  @override
  String get advancedIntegrationsBody =>
      'Optionale Werkzeuge, standardmäßig aus';

  @override
  String get classlyImport => 'Classly-kompatibler Import';

  @override
  String get experimentalAi => 'Experimentelle Remote-KI';

  @override
  String get dailyReminderOff =>
      'Aus — die Berechtigung wird erst beim Einschalten angefragt.';

  @override
  String dailyReminderAt(String time) {
    return 'Geplant für $time';
  }

  @override
  String get bootstrapErrorTitle => 'Habiter konnte nicht sicher starten';

  @override
  String get exportData => 'Backup exportieren';

  @override
  String get exportDataBody =>
      'Kopiert ein JSON-Backup für deine sichere Ablage in die Zwischenablage.';

  @override
  String get importData => 'Backup importieren';

  @override
  String get importDataBody =>
      'Prüfe ein Habiter-JSON-Backup, bevor Daten hinzugefügt werden.';

  @override
  String get backupCopied => 'Backup wurde in die Zwischenablage kopiert';

  @override
  String get pasteBackup => 'Backup-JSON einfügen';

  @override
  String get reviewImport => 'Import prüfen';

  @override
  String importSummary(int habits, int entries, int collisions) {
    return '$habits Habits · $entries Einträge · $collisions bereits vorhanden';
  }

  @override
  String get importComplete =>
      'Import abgeschlossen. Bestehende Habits wurden behalten und das Backup vor dem Import wurde kopiert.';

  @override
  String get invalidBackup => 'Dieses Backup konnte nicht gelesen werden.';

  @override
  String get disconnect => 'Trennen';

  @override
  String get connectWithOauth => 'Mit OAuth verbinden';

  @override
  String get useToken => 'Token verwenden';

  @override
  String get trustedHttpsOnly =>
      'Verbinde nur einen vertrauenswürdigen öffentlichen HTTPS-Server. Beim Trennen werden Zugangsdaten gelöscht.';

  @override
  String get httpsEndpoint => 'HTTPS-Endpunkt';

  @override
  String get optionalAccessToken => 'Optionales Zugriffs-Token';

  @override
  String get remoteAiOn =>
      'Aktiv. Anbieter-Anfragen können Daten teilen und Kosten verursachen.';

  @override
  String get remoteAiOff => 'Aus. Lokales Coaching benötigt keinen API-Key.';

  @override
  String get save => 'Speichern';

  @override
  String get providerLabel => 'Anbieter';

  @override
  String get apiKeyLabel => 'API-Key';

  @override
  String get increaseTarget => 'Tagesziel erhöhen';

  @override
  String get decreaseTarget => 'Tagesziel verringern';

  @override
  String get bootstrapErrorBody =>
      'Deine Daten wurden nicht verändert. Versuche Habiter erneut zu starten.';

  @override
  String get remoteAiDisclosure =>
      'Optional und standardmäßig aus. Der Schlüssel bleibt im sicheren Gerätespeicher. Anbieter-Anfragen können Kosten verursachen und Habit-Daten teilen.';

  @override
  String get apiKeyRequired =>
      'Gib einen API-Key ein, um Remote-KI zu aktivieren.';

  @override
  String get unlockRule => 'Freigaberegel';

  @override
  String get allHabitsRequired => 'Alle heutigen Habits abschließen';

  @override
  String get allHabitsRequiredBody =>
      'Ausgewählte Apps werden verfügbar, sobald die heutige Liste erledigt ist.';

  @override
  String get specificHabitsRequired => 'Nur ausgewählte Habits verwenden';

  @override
  String get specificHabitsRequiredBody =>
      'Wähle, welche Habits App Lock steuern.';

  @override
  String get requiredHabits => 'Zum Freigeben erforderliche Habits';

  @override
  String get nothingScheduledTitle => 'Heute ist nichts geplant';

  @override
  String get nothingScheduledBody =>
      'Dein nächster Habit erscheint hier, sobald sein Rhythmus wieder dran ist.';
}
