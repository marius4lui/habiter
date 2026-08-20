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
  String get navAnalytics => 'Analyse';

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
  String get startMomentum => 'Starte klein.';

  @override
  String get startMomentumDescription =>
      'Wähle eine Gewohnheit, die heute in deinen Alltag passt.';

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
  String get icon => 'Symbol';

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
    return '$count× pro Woche';
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
  String get testNotification => 'Testbenachrichtigung';

  @override
  String get testNotificationDesc => 'Sendet eine Testbenachrichtigung';

  @override
  String get testNotificationSent => 'Testbenachrichtigung gesendet!';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get theme => 'Darstellung';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get aiFeatures => 'KI-Funktionen';

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
  String get english => 'Englisch';

  @override
  String get advanced => 'Erweitert';

  @override
  String version(String version) {
    return 'Habiter v$version';
  }

  @override
  String get analytics => 'Analyse';

  @override
  String get analyticsSubtitle =>
      'Entwicklungen erkennen, ohne daraus Druck zu machen.';

  @override
  String get liveOverview => 'Übersicht';

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
      'Erfasse ein Habit, um den Wochenfortschritt zu sehen.';

  @override
  String get streak => 'Serie';

  @override
  String get success => 'Erfolg';

  @override
  String get total => 'Gesamt';

  @override
  String get aiInsightsTitle => 'KI-Einblicke';

  @override
  String get insightsAppearHere =>
      'Einblicke erscheinen hier, nachdem du einige Tage erfasst hast.';

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
  String get reminderDiagnostics => 'Erinnerungsdiagnose';

  @override
  String get reminderDiagnosticsDescription =>
      'Berechtigung und ausstehende Erinnerungen sicher prüfen';

  @override
  String get reminderPermissionGranted => 'Benachrichtigungen sind erlaubt';

  @override
  String get reminderPermissionMissing =>
      'Benachrichtigungen sind nicht verfügbar';

  @override
  String pendingReminders(int count) {
    return 'Ausstehende Erinnerungen: $count';
  }

  @override
  String get noPendingReminders => 'Keine ausstehenden Erinnerungen';

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

  @override
  String get categoryHealth => 'Gesundheit';

  @override
  String get categoryLearning => 'Lernen';

  @override
  String get categoryProductivity => 'Produktivität';

  @override
  String get categorySocial => 'Soziales';

  @override
  String get categoryCreative => 'Kreativität';

  @override
  String get categoryFitness => 'Fitness';

  @override
  String get categoryMindfulness => 'Achtsamkeit';

  @override
  String get categoryFinance => 'Finanzen';

  @override
  String get categoryHome => 'Zuhause';

  @override
  String get templateGroupPopular => 'Beliebt';

  @override
  String get templateWater => 'Wasser trinken';

  @override
  String get templateWorkout => 'Training';

  @override
  String get templateRead => 'Lesen';

  @override
  String get templateMeditate => 'Meditieren';

  @override
  String get templateWalk => 'Spazieren';

  @override
  String get templateSleep => 'Schlafroutine';

  @override
  String get templateWrite => 'Schreiben';

  @override
  String get templateTidy => 'Aufräumen';

  @override
  String get templateHealthyMeal => 'Gesund essen';

  @override
  String get templateMedicine => 'Medikamente nehmen';

  @override
  String get templateFloss => 'Zahnseide';

  @override
  String get templateScreenFree => 'Bildschirmfreie Zeit';

  @override
  String get templateFinances => 'Finanzen prüfen';

  @override
  String get templateInstrument => 'Instrument üben';

  @override
  String get templateLanguage => 'Sprache lernen';

  @override
  String get templateRun => 'Laufen';

  @override
  String get creationQuestion => 'Was möchtest du regelmäßig tun?';

  @override
  String get starterTemplates => 'Für dich als Start';

  @override
  String get searchTemplates => 'Gewohnheiten durchsuchen';

  @override
  String get customHabitAction => 'Eigenes Habit erstellen';

  @override
  String customHabitFromSearch(String name) {
    return 'Eigenes Habit \"$name\" erstellen';
  }

  @override
  String get habitIdentityQuestion => 'Was möchtest du tun?';

  @override
  String get habitIdentityHint =>
      'Ein kurzer Name lässt sich im Alltag leichter erkennen.';

  @override
  String get chooseAnotherTemplate => 'Andere Vorlage wählen';

  @override
  String get rhythmQuestion => 'Wie oft?';

  @override
  String get rhythmHint =>
      'Wähle einen Rhythmus, der wirklich in deine Woche passt.';

  @override
  String get dailyOptionBody => 'Einmal täglich';

  @override
  String get weeklyOptionBody => 'Zum Beispiel dreimal pro Woche';

  @override
  String get customOptionBody => 'Wähle passende Wochentage';

  @override
  String get reminderQuestion => 'Möchtest du erinnert werden?';

  @override
  String get habitReminderToggle => 'Erinnerung';

  @override
  String get reminderSupportBody =>
      'Habiter kann dich zu einer Zeit deiner Wahl sanft erinnern.';

  @override
  String get reviewHabit => 'Dein Habit';

  @override
  String get ready => 'Bereit.';

  @override
  String get detailsOptional => 'Notiz hinzufügen';

  @override
  String weeklyUnits(int completed, int scheduled) {
    return '$completed von $scheduled geplanten Einheiten';
  }

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get lastThirtyDays => 'Letzte 30 Tage';

  @override
  String consistencyValue(int percent) {
    return '$percent % Konsistenz';
  }

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get notEnoughHistory => 'Noch nicht genug Verlauf';

  @override
  String get notEnoughHistoryBody =>
      'Nach ein paar geplanten Einheiten wird hier dein Rhythmus sichtbar.';

  @override
  String get trendImproving =>
      'Dein jüngster Rhythmus entwickelt sich positiv.';

  @override
  String get trendDeclining =>
      'Dein jüngster Rhythmus ist etwas ruhiger geworden.';

  @override
  String get trendSteady => 'Dein jüngster Rhythmus bleibt stabil.';

  @override
  String get dayCompleted => 'erledigt';

  @override
  String get dayMissed => 'geplant, nicht erledigt';

  @override
  String get dayFuture => 'steht noch an';

  @override
  String get dayNotScheduled => 'nicht geplant';

  @override
  String pausedArchivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pausierte oder archivierte Habits',
      one: '1 pausiertes oder archiviertes Habit',
    );
    return '$_temp0';
  }

  @override
  String get chooseHabit => 'Habit auswählen';

  @override
  String get emptyStarterExamples => 'Wasser · Lesen · Spazieren · Meditieren';

  @override
  String get onboardingWelcomeTitle => 'Kleine Schritte.\nEchte Veränderung.';

  @override
  String get onboardingWelcomeBody =>
      'Habiter hält fest, was dir wichtig ist – klar, ruhig und Tag für Tag.';

  @override
  String get onboardingGetStarted => 'Loslegen';

  @override
  String get onboardingIntentTitle => 'Was soll\nwachsen?';

  @override
  String get onboardingIntentBody =>
      'Wähle eine Richtung. Du kannst später alles ändern.';

  @override
  String get onboardingIntentOther => 'Etwas anderes';

  @override
  String get onboardingFirstHabitTitle => 'Dein erster\nkleiner Schritt.';

  @override
  String get onboardingFirstHabitBody =>
      'Wähle eine Idee oder gib deinem Habit einen eigenen Namen.';

  @override
  String get onboardingCustomHabitName => 'Gib deinem Habit einen Namen';

  @override
  String get onboardingRhythmTitle => 'Wie oft passt das in deinen Alltag?';

  @override
  String get onboardingEveryDay => 'Jeden Tag';

  @override
  String get onboardingEveryDayBody => 'Ein klarer täglicher Rhythmus';

  @override
  String get onboardingSeveralTimes => 'Mehrmals pro Woche';

  @override
  String get onboardingSeveralTimesBody => 'Wähle dein Wochenziel';

  @override
  String get onboardingSpecificDays => 'Bestimmte Tage';

  @override
  String get onboardingSpecificDaysBody => 'Wähle passende Wochentage';

  @override
  String onboardingTimesPerWeek(int count) {
    return '$count× pro Woche';
  }

  @override
  String get onboardingRhythmExplainerDailyTitle =>
      'Jeder Tag kann einmal zählen.';

  @override
  String onboardingRhythmExplainerFlexibleTitle(int count) {
    return '$count× pro Woche heißt: $count verschiedene Tage.';
  }

  @override
  String get onboardingRhythmExplainerFixedTitle =>
      'Nur deine gewählten Wochentage zählen.';

  @override
  String get onboardingRhythmExplainerDailyBody =>
      'Ein Abschluss zählt pro Kalendertag einmal. Deine Woche läuft von Montag bis Sonntag.';

  @override
  String get onboardingRhythmExplainerFlexibleBody =>
      'Du brauchst keine festen Wochentage. Beliebige verschiedene Tage von Montag bis Sonntag zählen – auch direkt hintereinander.';

  @override
  String get onboardingRhythmExplainerFixedBody =>
      'Die hervorgehobenen Wochentage sind deine Habit-Tage. Jedes Datum kann einmal zählen.';

  @override
  String get onboardingRhythmWeekLabel => 'DIESE WOCHE';

  @override
  String onboardingRhythmProgress(int completed, int target) {
    return '$completed / $target';
  }

  @override
  String onboardingRhythmProgressSemantics(int completed, int target) {
    return '$completed von $target Tagen ausgewählt';
  }

  @override
  String get onboardingRhythmDaySelected => 'ausgewählt';

  @override
  String get onboardingRhythmDayNotSelected => 'nicht ausgewählt';

  @override
  String get onboardingRhythmDayUnavailable => 'nicht Teil dieses Rhythmus';

  @override
  String get onboardingRhythmTryPrompt =>
      'Tippe einen Tag an und sieh, wie sich diese Woche verändert.';

  @override
  String get onboardingRhythmFactDifferentDays => 'Ein Datum zählt einmal';

  @override
  String get onboardingRhythmFactMondayReset => 'Montag bis Sonntag';

  @override
  String get onboardingRhythmFactConsecutive =>
      'Aufeinanderfolgende Tage zählen';

  @override
  String get onboardingRhythmInvalid =>
      'Dieser Rhythmus konnte nicht angezeigt werden. Gehe zurück und wähle ihn erneut.';

  @override
  String get onboardingReminderTitle => 'Wann soll Habiter helfen?';

  @override
  String get onboardingReminderBody =>
      'Smart-Reminder sind optional. Wir erklären alles, bevor wir nach der Notification-Berechtigung fragen.';

  @override
  String get onboardingNoReminder => 'Ohne Erinnerung';

  @override
  String get onboardingAddReminder => 'Smart-Reminder verwenden';

  @override
  String get onboardingSmartCalibrationTitle => 'Siebentägige Kalibrierung';

  @override
  String get onboardingSmartCalibrationBody =>
      'Ein paar kurze Fragen zeigen Habiter, welche Momente wirklich passen. Ignorierte Hinweise bleiben neutral.';

  @override
  String get onboardingSmartFrequencyTitle => 'Hartnäckig, aber begrenzt';

  @override
  String get onboardingSmartFrequencyBody =>
      'Bis zu drei Versuche pro Habit-Tag, aber insgesamt nie mehr als acht Hinweise und mindestens 90 Minuten Abstand.';

  @override
  String get onboardingSmartPrivacyTitle => 'Nur auf diesem Gerät';

  @override
  String get onboardingSmartPrivacyBody =>
      'Keine Cloudübertragung, Standort-, Kontakt-, Kalender-, Sensor- oder App-Nutzungsdaten.';

  @override
  String get onboardingSmartControlTitle => 'Du behältst die Kontrolle';

  @override
  String get onboardingSmartControlBody =>
      'Die Wachzeit ist zunächst 08:00–22:00 Uhr. Du kannst jederzeit pausieren, jeden Plan ändern oder alle Lerndaten löschen.';

  @override
  String get onboardingHabitReadyTitle => 'Dein erstes Habit steht.';

  @override
  String get onboardingHabitReadyBody =>
      'Jetzt bringen wir es dorthin, wo du es wirklich siehst.';

  @override
  String get onboardingSaving => 'Dein Habit wird eingerichtet…';

  @override
  String onboardingStepProgress(int step, int total) {
    return 'Einrichtungsschritt $step von $total';
  }

  @override
  String get onboardingWidgetIntroTitle =>
      'Habiter gehört auf deinen Homescreen.';

  @override
  String get onboardingWidgetIntroBody =>
      'Sieh deinen nächsten Schritt und hake ihn ab, ohne die App zu öffnen.';

  @override
  String get onboardingWidgetResponsive =>
      'Passt in kompakte, breite und große Homescreen-Flächen.';

  @override
  String get onboardingWidgetAdd => 'Widget hinzufügen';

  @override
  String get onboardingWidgetLater => 'Später';

  @override
  String get onboardingWidgetPinTitle => 'Habiter zum Homescreen hinzufügen';

  @override
  String get onboardingWidgetPinBody =>
      'Android fragt dich, wo du das Widget platzieren möchtest.';

  @override
  String get onboardingWidgetReadyTitle => 'Bereit.';

  @override
  String get onboardingWidgetReadyBody =>
      'Dein nächster Schritt ist jetzt direkt auf deinem Homescreen.';

  @override
  String get onboardingWidgetDeclinedBody =>
      'Du kannst das Widget jederzeit später in Habiter hinzufügen.';

  @override
  String get onboardingWidgetManualTitle => 'Widget manuell hinzufügen';

  @override
  String get onboardingWidgetManualOne => 'Homescreen gedrückt halten';

  @override
  String get onboardingWidgetManualTwo => 'Widgets öffnen';

  @override
  String get onboardingWidgetManualThree => 'Habiter auswählen';

  @override
  String get onboardingWidgetManualFour => 'Widget platzieren';

  @override
  String get onboardingWidgetLetsGo => 'Los geht\'s';

  @override
  String get onboardingWidgetUnderstood => 'Verstanden';

  @override
  String get widgetPromotionTitle => 'Habiter auf deinem Homescreen';

  @override
  String get widgetPromotionBody => 'Habits abhaken, ohne die App zu öffnen.';

  @override
  String get widgetSettingsTitle => 'Homescreen / Widget';

  @override
  String get widgetStatusAdded => 'Widget hinzugefügt';

  @override
  String get widgetStatusNotAdded => 'Noch nicht hinzugefügt';

  @override
  String get widgetPreviewSemantics =>
      'Vorschau des responsiven Habiter-Homescreen-Widgets';

  @override
  String widgetPreviewNext(String name) {
    return 'Als Nächstes: $name';
  }

  @override
  String get updateCenterTitle => 'Update-Center';

  @override
  String get updateSettingsEntry => 'App-Updates';

  @override
  String get updateSettingsBody => 'Kanal, Zeitplan, Status und Update-Verlauf';

  @override
  String get updateStatusTitle => 'Update-Status';

  @override
  String get updateStatusIdle => 'Bereit zur Prüfung';

  @override
  String get updateStatusChecking => 'Sichere Prüfung läuft…';

  @override
  String get updateStatusCurrent => 'Habiter ist aktuell';

  @override
  String updateStatusAvailable(String version) {
    return 'Habiter $version ist verfügbar';
  }

  @override
  String updateStatusDownloading(int percent) {
    return 'Download · $percent%';
  }

  @override
  String get updateStatusVerifying => 'Download wird geprüft…';

  @override
  String get updateStatusReady => 'Bereit zur Installation';

  @override
  String get updateStatusInstalling => 'Android-Installer geöffnet';

  @override
  String get updateStatusMandatory => 'Dieses Update ist jetzt erforderlich';

  @override
  String get updateStatusError => 'Update-Prüfung nicht verfügbar';

  @override
  String get updateAvailableBadge => 'Update verfügbar';

  @override
  String get updateCheckNow => 'Jetzt prüfen';

  @override
  String updateLastChecked(String date) {
    return 'Zuletzt geprüft: $date';
  }

  @override
  String get updateNeverChecked => 'Noch nicht geprüft';

  @override
  String get updateTrackTitle => 'Release-Kanal';

  @override
  String get updateTrackStable => 'Stable';

  @override
  String get updateTrackStableBody => 'Nur getestete Stable-Releases';

  @override
  String get updateTrackBeta => 'Beta';

  @override
  String get updateTrackBetaBody => 'Höchster Build aus Stable und Beta';

  @override
  String get updateProfileTitle => 'Update-Profil';

  @override
  String get updateProfileImmediate => 'Sofort';

  @override
  String get updateProfileImmediateBody =>
      'Bei Start/Fortsetzen und stündlich · Download über jedes Netz';

  @override
  String get updateProfileBalanced => 'Ausgewogen';

  @override
  String get updateProfileBalancedBody =>
      'Alle 24 Stunden · Auto-Download über ungetaktete Netze';

  @override
  String get updateProfileSaver => 'Sparsam';

  @override
  String get updateProfileSaverBody =>
      'Alle sieben Tage · kein automatischer Download';

  @override
  String get updateViewWhatsNew => 'Was ist neu?';

  @override
  String get updateDownload => 'Update herunterladen';

  @override
  String get updateInstall => 'Installieren';

  @override
  String get updateOpenDownload => 'Download öffnen';

  @override
  String get updateNotNow => 'Später';

  @override
  String get updateInstallerPermissionTitle =>
      'Habiter darf dieses Update installieren';

  @override
  String get updateInstallerPermissionBody =>
      'Android fragt einmal, ob Habiter geprüfte APK-Updates öffnen darf. Du kannst diese Freigabe jederzeit entziehen.';

  @override
  String get updateOpenSettings => 'Android-Einstellungen öffnen';

  @override
  String get updateHistoryTitle => 'Release-Verlauf';

  @override
  String get updateStorageTitle => 'Update-Speicher';

  @override
  String updateStorageUsage(String metadata, String downloads) {
    return 'Metadaten: $metadata · Downloads: $downloads';
  }

  @override
  String get updateClearDownloads => 'Downloads löschen';

  @override
  String get updateClearCache => 'Manifest-Cache leeren';

  @override
  String get updatePrivacyNote =>
      'Prüfungen enthalten keine Nutzerkennung und erzeugen keine Analytics.';

  @override
  String get updateOfflineMandatoryWarning =>
      'Ein Pflichtupdate wartet. Habiter bleibt offline nutzbar und prüft erneut, sobald du online bist.';

  @override
  String get updateMandatoryTitle => 'Update erforderlich';

  @override
  String get updateMandatoryBody =>
      'Eine verifizierte Frist ist abgelaufen. Installiere das Update, um Habiter online weiterzuverwenden.';

  @override
  String updateMandatoryCountdown(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'In $hours Stunden erforderlich',
      one: 'In 1 Stunde erforderlich',
    );
    return '$_temp0';
  }

  @override
  String get releaseStorySuccessTitle => 'Update installiert';

  @override
  String get releaseStorySuccessBody =>
      'Habiter ist mit den neuesten Verbesserungen bereit.';

  @override
  String get releaseStoryContinue => 'Weiter zu Habiter';

  @override
  String get releaseStoryDetails => 'Details nach Version';

  @override
  String get releaseStoryAdded => 'Neu';

  @override
  String get releaseStoryChanged => 'Geändert';

  @override
  String get releaseStoryFixed => 'Behoben';

  @override
  String get releaseStorySecurity => 'Sicherheit';

  @override
  String releaseStoryFallbackHeadline(String version) {
    return 'Habiter $version';
  }

  @override
  String get releaseStoryFallbackSummary =>
      'Eine neue Habiter-Version ist bereit.';

  @override
  String get updateUnsupported =>
      'Updates sind auf dieser Plattform noch nicht verfügbar.';
}
