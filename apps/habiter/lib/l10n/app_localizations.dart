import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Habiter'**
  String get appTitle;

  /// No description provided for @navHabits.
  ///
  /// In de, this message translates to:
  /// **'Habits'**
  String get navHabits;

  /// No description provided for @navAnalytics.
  ///
  /// In de, this message translates to:
  /// **'Analyse'**
  String get navAnalytics;

  /// No description provided for @goodMorning.
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In de, this message translates to:
  /// **'Guten Nachmittag'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In de, this message translates to:
  /// **'Guten Abend'**
  String get goodEvening;

  /// No description provided for @newHabit.
  ///
  /// In de, this message translates to:
  /// **'Neues Habit'**
  String get newHabit;

  /// No description provided for @editHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit bearbeiten'**
  String get editHabit;

  /// No description provided for @createHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit erstellen'**
  String get createHabit;

  /// No description provided for @updateHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit aktualisieren'**
  String get updateHabit;

  /// No description provided for @deleteHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit löschen'**
  String get deleteHabit;

  /// No description provided for @deleteHabitConfirm.
  ///
  /// In de, this message translates to:
  /// **'Diese Aktion kann nicht rückgängig gemacht werden.'**
  String get deleteHabitConfirm;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @startMomentum.
  ///
  /// In de, this message translates to:
  /// **'Starte klein.'**
  String get startMomentum;

  /// No description provided for @startMomentumDescription.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Gewohnheit, die heute in deinen Alltag passt.'**
  String get startMomentumDescription;

  /// No description provided for @completion.
  ///
  /// In de, this message translates to:
  /// **'Abschluss'**
  String get completion;

  /// No description provided for @active.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get active;

  /// No description provided for @todaysMomentum.
  ///
  /// In de, this message translates to:
  /// **'Heutiges Momentum'**
  String get todaysMomentum;

  /// No description provided for @completed.
  ///
  /// In de, this message translates to:
  /// **'ERLEDIGT'**
  String get completed;

  /// No description provided for @slideToComplete.
  ///
  /// In de, this message translates to:
  /// **'Wischen >>'**
  String get slideToComplete;

  /// No description provided for @name.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @namePlaceholder.
  ///
  /// In de, this message translates to:
  /// **'z.B. 20 Minuten lesen'**
  String get namePlaceholder;

  /// No description provided for @nameRequired.
  ///
  /// In de, this message translates to:
  /// **'Name ist erforderlich'**
  String get nameRequired;

  /// No description provided for @description.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get description;

  /// No description provided for @descriptionPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Optionale Beschreibung'**
  String get descriptionPlaceholder;

  /// No description provided for @category.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get category;

  /// No description provided for @icon.
  ///
  /// In de, this message translates to:
  /// **'Symbol'**
  String get icon;

  /// No description provided for @tapToSelect.
  ///
  /// In de, this message translates to:
  /// **'Tippen zum Auswählen'**
  String get tapToSelect;

  /// No description provided for @color.
  ///
  /// In de, this message translates to:
  /// **'Farbe'**
  String get color;

  /// No description provided for @frequency.
  ///
  /// In de, this message translates to:
  /// **'Frequenz'**
  String get frequency;

  /// No description provided for @selectDays.
  ///
  /// In de, this message translates to:
  /// **'Tage auswählen'**
  String get selectDays;

  /// No description provided for @targetPerDay.
  ///
  /// In de, this message translates to:
  /// **'Ziel pro Tag'**
  String get targetPerDay;

  /// No description provided for @targetPerWeek.
  ///
  /// In de, this message translates to:
  /// **'Ziel pro Woche'**
  String get targetPerWeek;

  /// No description provided for @daily.
  ///
  /// In de, this message translates to:
  /// **'Täglich'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In de, this message translates to:
  /// **'Wöchentlich'**
  String get weekly;

  /// No description provided for @custom.
  ///
  /// In de, this message translates to:
  /// **'Benutzerdefiniert'**
  String get custom;

  /// No description provided for @perDay.
  ///
  /// In de, this message translates to:
  /// **'{count}/Tag'**
  String perDay(int count);

  /// No description provided for @perWeek.
  ///
  /// In de, this message translates to:
  /// **'{count}× pro Woche'**
  String perWeek(int count);

  /// No description provided for @onDays.
  ///
  /// In de, this message translates to:
  /// **'{count} an {days} Tagen'**
  String onDays(int count, int days);

  /// No description provided for @completedCount.
  ///
  /// In de, this message translates to:
  /// **'Erledigt ({count})'**
  String completedCount(int count);

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notifications;

  /// No description provided for @dailyReminder.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Erinnerung'**
  String get dailyReminder;

  /// No description provided for @dailyReminderDesc.
  ///
  /// In de, this message translates to:
  /// **'Erinnert dich an offene Habits'**
  String get dailyReminderDesc;

  /// No description provided for @reminderTime.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungszeit'**
  String get reminderTime;

  /// No description provided for @permissionRequired.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung erforderlich'**
  String get permissionRequired;

  /// No description provided for @permissionRequiredDesc.
  ///
  /// In de, this message translates to:
  /// **'Erlaube Benachrichtigungen für Erinnerungen'**
  String get permissionRequiredDesc;

  /// No description provided for @allow.
  ///
  /// In de, this message translates to:
  /// **'Erlauben'**
  String get allow;

  /// No description provided for @notificationsEnabled.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen aktiviert! 🔔'**
  String get notificationsEnabled;

  /// No description provided for @testNotification.
  ///
  /// In de, this message translates to:
  /// **'Testbenachrichtigung'**
  String get testNotification;

  /// No description provided for @testNotificationDesc.
  ///
  /// In de, this message translates to:
  /// **'Sendet eine Testbenachrichtigung'**
  String get testNotificationDesc;

  /// No description provided for @testNotificationSent.
  ///
  /// In de, this message translates to:
  /// **'Testbenachrichtigung gesendet!'**
  String get testNotificationSent;

  /// No description provided for @appearance.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @aiFeatures.
  ///
  /// In de, this message translates to:
  /// **'KI-Funktionen'**
  String get aiFeatures;

  /// No description provided for @aiInsights.
  ///
  /// In de, this message translates to:
  /// **'Lokales Coaching'**
  String get aiInsights;

  /// No description provided for @aiInsightsDesc.
  ///
  /// In de, this message translates to:
  /// **'Deterministische Vorschläge, die auf diesem Gerät berechnet werden'**
  String get aiInsightsDesc;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @appLanguage.
  ///
  /// In de, this message translates to:
  /// **'App-Sprache'**
  String get appLanguage;

  /// No description provided for @german.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @english.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get english;

  /// No description provided for @advanced.
  ///
  /// In de, this message translates to:
  /// **'Erweitert'**
  String get advanced;

  /// No description provided for @version.
  ///
  /// In de, this message translates to:
  /// **'Habiter v{version}'**
  String version(String version);

  /// No description provided for @analytics.
  ///
  /// In de, this message translates to:
  /// **'Analyse'**
  String get analytics;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Entwicklungen erkennen, ohne daraus Druck zu machen.'**
  String get analyticsSubtitle;

  /// No description provided for @liveOverview.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get liveOverview;

  /// No description provided for @activeHabits.
  ///
  /// In de, this message translates to:
  /// **'Aktive Habits'**
  String get activeHabits;

  /// No description provided for @totalWins.
  ///
  /// In de, this message translates to:
  /// **'Gesamt-Erfolge'**
  String get totalWins;

  /// No description provided for @avgSuccess.
  ///
  /// In de, this message translates to:
  /// **'Durchschn. Erfolg'**
  String get avgSuccess;

  /// No description provided for @weeklyProgress.
  ///
  /// In de, this message translates to:
  /// **'Wöchentlicher Fortschritt'**
  String get weeklyProgress;

  /// No description provided for @trackToSeeProgress.
  ///
  /// In de, this message translates to:
  /// **'Erfasse ein Habit, um den Wochenfortschritt zu sehen.'**
  String get trackToSeeProgress;

  /// No description provided for @streak.
  ///
  /// In de, this message translates to:
  /// **'Serie'**
  String get streak;

  /// No description provided for @success.
  ///
  /// In de, this message translates to:
  /// **'Erfolg'**
  String get success;

  /// No description provided for @total.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get total;

  /// No description provided for @aiInsightsTitle.
  ///
  /// In de, this message translates to:
  /// **'KI-Einblicke'**
  String get aiInsightsTitle;

  /// No description provided for @insightsAppearHere.
  ///
  /// In de, this message translates to:
  /// **'Einblicke erscheinen hier, nachdem du einige Tage erfasst hast.'**
  String get insightsAppearHere;

  /// No description provided for @confidence.
  ///
  /// In de, this message translates to:
  /// **'Konfidenz {percent}%'**
  String confidence(int percent);

  /// No description provided for @habit.
  ///
  /// In de, this message translates to:
  /// **'Habit'**
  String get habit;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen'**
  String get retry;

  /// No description provided for @appLock.
  ///
  /// In de, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Sperre Apps bis deine Habits erledigt sind'**
  String get appLockSubtitle;

  /// No description provided for @locked.
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get locked;

  /// No description provided for @status.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In de, this message translates to:
  /// **'Inaktiv'**
  String get statusInactive;

  /// No description provided for @permissionsRequired.
  ///
  /// In de, this message translates to:
  /// **'Berechtigungen erforderlich'**
  String get permissionsRequired;

  /// No description provided for @usageAccess.
  ///
  /// In de, this message translates to:
  /// **'Usage Access'**
  String get usageAccess;

  /// No description provided for @usageAccessDesc.
  ///
  /// In de, this message translates to:
  /// **'Erkennen welche App geöffnet ist'**
  String get usageAccessDesc;

  /// No description provided for @overlayPermission.
  ///
  /// In de, this message translates to:
  /// **'Über anderen Apps anzeigen'**
  String get overlayPermission;

  /// No description provided for @overlayPermissionDesc.
  ///
  /// In de, this message translates to:
  /// **'Sperrbildschirm anzeigen'**
  String get overlayPermissionDesc;

  /// No description provided for @loadingApps.
  ///
  /// In de, this message translates to:
  /// **'Apps werden geladen...'**
  String get loadingApps;

  /// No description provided for @noAppsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine sichtbaren Launcher-Apps gefunden. Die Sichtbarkeit hängt von Android-Regeln ab.'**
  String get noAppsFound;

  /// No description provided for @selectAppsToLock.
  ///
  /// In de, this message translates to:
  /// **'Apps zum Sperren auswählen ({count})'**
  String selectAppsToLock(int count);

  /// No description provided for @androidOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur für Android'**
  String get androidOnly;

  /// No description provided for @androidOnlyDesc.
  ///
  /// In de, this message translates to:
  /// **'App Lock ist nur auf Android Geräten verfügbar.'**
  String get androidOnlyDesc;

  /// No description provided for @appLockRecovery.
  ///
  /// In de, this message translates to:
  /// **'App Lock ist sicher ausgeschaltet'**
  String get appLockRecovery;

  /// No description provided for @appLockReliability.
  ///
  /// In de, this message translates to:
  /// **'Gerätezuverlässigkeit'**
  String get appLockReliability;

  /// No description provided for @appLockReliabilityDescription.
  ///
  /// In de, this message translates to:
  /// **'Android- und Hersteller-Energiesparregeln können die Überwachung stoppen. Habiter schaltet App Lock aus, wenn erforderliche Zugriffe fehlen.'**
  String get appLockReliabilityDescription;

  /// No description provided for @disableAppLock.
  ///
  /// In de, this message translates to:
  /// **'App Lock jetzt ausschalten'**
  String get disableAppLock;

  /// No description provided for @batterySettings.
  ///
  /// In de, this message translates to:
  /// **'Akku-Einstellungen öffnen'**
  String get batterySettings;

  /// No description provided for @refreshPermissions.
  ///
  /// In de, this message translates to:
  /// **'Berechtigungen erneut prüfen'**
  String get refreshPermissions;

  /// No description provided for @grant.
  ///
  /// In de, this message translates to:
  /// **'Erlauben'**
  String get grant;

  /// No description provided for @yourDailyFlow.
  ///
  /// In de, this message translates to:
  /// **'Dein Tages-Flow'**
  String get yourDailyFlow;

  /// No description provided for @keepMomentum.
  ///
  /// In de, this message translates to:
  /// **'Bleib am Ball!'**
  String get keepMomentum;

  /// No description provided for @onTrack.
  ///
  /// In de, this message translates to:
  /// **'Auf Kurs'**
  String get onTrack;

  /// No description provided for @habitsCompleted.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total} Habits erledigt'**
  String habitsCompleted(int done, int total);

  /// No description provided for @pending.
  ///
  /// In de, this message translates to:
  /// **'Ausstehend'**
  String get pending;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get done;

  /// No description provided for @classlyInstance.
  ///
  /// In de, this message translates to:
  /// **'Classly-Instanz'**
  String get classlyInstance;

  /// No description provided for @loginWithClassly.
  ///
  /// In de, this message translates to:
  /// **'Mit Classly anmelden'**
  String get loginWithClassly;

  /// No description provided for @autoSync.
  ///
  /// In de, this message translates to:
  /// **'Auto-Sync'**
  String get autoSync;

  /// No description provided for @syncInterval.
  ///
  /// In de, this message translates to:
  /// **'Sync-Intervall'**
  String get syncInterval;

  /// No description provided for @newTasksImported.
  ///
  /// In de, this message translates to:
  /// **'{count} neue Aufgaben importiert'**
  String newTasksImported(int count);

  /// No description provided for @syncNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt synchronisieren'**
  String get syncNow;

  /// No description provided for @syncComplete.
  ///
  /// In de, this message translates to:
  /// **'Sync abgeschlossen'**
  String get syncComplete;

  /// No description provided for @todayCompleted.
  ///
  /// In de, this message translates to:
  /// **'Heute erledigt ({count})'**
  String todayCompleted(int count);

  /// No description provided for @allHabitsCompleted.
  ///
  /// In de, this message translates to:
  /// **'🎉 Alle Habits für heute erledigt!'**
  String get allHabitsCompleted;

  /// No description provided for @markAsComplete.
  ///
  /// In de, this message translates to:
  /// **'Als erledigt markieren'**
  String get markAsComplete;

  /// No description provided for @undoComplete.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig machen'**
  String get undoComplete;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @archive.
  ///
  /// In de, this message translates to:
  /// **'Archivieren'**
  String get archive;

  /// No description provided for @pauseHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit pausieren'**
  String get pauseHabit;

  /// No description provided for @resumeHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit fortsetzen'**
  String get resumeHabit;

  /// No description provided for @restoreHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit wiederherstellen'**
  String get restoreHabit;

  /// No description provided for @manageHabitLifecycle.
  ///
  /// In de, this message translates to:
  /// **'Pausierte und archivierte Habits'**
  String get manageHabitLifecycle;

  /// No description provided for @noPausedOrArchivedHabits.
  ///
  /// In de, this message translates to:
  /// **'Keine pausierten oder archivierten Habits'**
  String get noPausedOrArchivedHabits;

  /// No description provided for @inactiveHabitCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Habit} other{{count} Habits}}'**
  String inactiveHabitCount(int count);

  /// No description provided for @habitPaused.
  ///
  /// In de, this message translates to:
  /// **'Pausiert – geplante Tage zählen nicht gegen dich'**
  String get habitPaused;

  /// No description provided for @habitArchived.
  ///
  /// In de, this message translates to:
  /// **'Archiviert – kann wiederhergestellt werden'**
  String get habitArchived;

  /// No description provided for @recoveryTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Tempo, ohne Druck'**
  String get recoveryTitle;

  /// No description provided for @recoveryNewStart.
  ///
  /// In de, this message translates to:
  /// **'Beginne bei der nächsten kleinen Gelegenheit, wenn es für dich passt.'**
  String get recoveryNewStart;

  /// No description provided for @recoveryGentleReturn.
  ///
  /// In de, this message translates to:
  /// **'Ein ausgelassener Tag löscht frühere Schritte nicht. Der nächste geplante Tag genügt.'**
  String get recoveryGentleReturn;

  /// No description provided for @recoveryRebuilding.
  ///
  /// In de, this message translates to:
  /// **'Du findest deinen Rhythmus wieder – einen geplanten Tag nach dem anderen.'**
  String get recoveryRebuilding;

  /// No description provided for @recoverySteady.
  ///
  /// In de, this message translates to:
  /// **'Dein aktueller Rhythmus ist stabil. Pausen bleiben neutral.'**
  String get recoverySteady;

  /// No description provided for @recoveryHide.
  ///
  /// In de, this message translates to:
  /// **'Unterstützenden Wert ausblenden'**
  String get recoveryHide;

  /// No description provided for @recoveryFormula.
  ///
  /// In de, this message translates to:
  /// **'{completed} von {scheduled} berücksichtigten Plänen erledigt = {score}%'**
  String recoveryFormula(int completed, int scheduled, int score);

  /// No description provided for @reminderDiagnostics.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungsdiagnose'**
  String get reminderDiagnostics;

  /// No description provided for @reminderDiagnosticsDescription.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung und ausstehende Erinnerungen sicher prüfen'**
  String get reminderDiagnosticsDescription;

  /// No description provided for @reminderPermissionGranted.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen sind erlaubt'**
  String get reminderPermissionGranted;

  /// No description provided for @reminderPermissionMissing.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen sind nicht verfügbar'**
  String get reminderPermissionMissing;

  /// No description provided for @pendingReminders.
  ///
  /// In de, this message translates to:
  /// **'Ausstehende Erinnerungen: {count}'**
  String pendingReminders(int count);

  /// No description provided for @noPendingReminders.
  ///
  /// In de, this message translates to:
  /// **'Keine ausstehenden Erinnerungen'**
  String get noPendingReminders;

  /// No description provided for @osManagedReminderTime.
  ///
  /// In de, this message translates to:
  /// **'Zustellzeit wird vom Betriebssystem verwaltet'**
  String get osManagedReminderTime;

  /// No description provided for @rescheduleReminders.
  ///
  /// In de, this message translates to:
  /// **'Neu planen'**
  String get rescheduleReminders;

  /// No description provided for @goal.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get goal;

  /// No description provided for @createdAt.
  ///
  /// In de, this message translates to:
  /// **'Erstellt am'**
  String get createdAt;

  /// No description provided for @todayDone.
  ///
  /// In de, this message translates to:
  /// **'Heute erledigt ✓'**
  String get todayDone;

  /// No description provided for @notCompleted.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht erledigt'**
  String get notCompleted;

  /// No description provided for @noHabitsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Habits. Füge ein neues hinzu!'**
  String get noHabitsYet;

  /// No description provided for @perDayTarget.
  ///
  /// In de, this message translates to:
  /// **'{count}x pro Tag'**
  String perDayTarget(int count);

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @todaySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Ein klarer nächster Schritt, in deinem Tempo.'**
  String get todaySubtitle;

  /// No description provided for @nextUp.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes'**
  String get nextUp;

  /// No description provided for @nextUpDescription.
  ///
  /// In de, this message translates to:
  /// **'Eine kleine Handlung reicht.'**
  String get nextUpDescription;

  /// No description provided for @remainingToday.
  ///
  /// In de, this message translates to:
  /// **'Noch für heute'**
  String get remainingToday;

  /// No description provided for @remainingCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Nichts mehr offen} =1{Noch 1 Habit} other{Noch {count} Habits}}'**
  String remainingCount(int count);

  /// No description provided for @dailyProgress.
  ///
  /// In de, this message translates to:
  /// **'Tagesfortschritt'**
  String get dailyProgress;

  /// No description provided for @completeHabit.
  ///
  /// In de, this message translates to:
  /// **'{name} abschließen'**
  String completeHabit(String name);

  /// No description provided for @openHabit.
  ///
  /// In de, this message translates to:
  /// **'{name} öffnen'**
  String openHabit(String name);

  /// No description provided for @completedToday.
  ///
  /// In de, this message translates to:
  /// **'Heute erledigt'**
  String get completedToday;

  /// No description provided for @completedQuietly.
  ///
  /// In de, this message translates to:
  /// **'Alles Geplante ist erledigt. Genieß den Freiraum.'**
  String get completedQuietly;

  /// No description provided for @addHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit hinzufügen'**
  String get addHabit;

  /// No description provided for @habitBasics.
  ///
  /// In de, this message translates to:
  /// **'Der Habit'**
  String get habitBasics;

  /// No description provided for @habitBasicsHint.
  ///
  /// In de, this message translates to:
  /// **'Gib der Handlung eine klare, freundliche Identität.'**
  String get habitBasicsHint;

  /// No description provided for @habitSchedule.
  ///
  /// In de, this message translates to:
  /// **'Rhythmus'**
  String get habitSchedule;

  /// No description provided for @habitScheduleHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle, wann der Habit erscheint. Pausierte Tage bleiben neutral.'**
  String get habitScheduleHint;

  /// No description provided for @habitReminder.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung'**
  String get habitReminder;

  /// No description provided for @habitReminderHint.
  ///
  /// In de, this message translates to:
  /// **'Optional und vollständig unter deiner Kontrolle.'**
  String get habitReminderHint;

  /// No description provided for @continueLabel.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueLabel;

  /// No description provided for @backLabel.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get backLabel;

  /// No description provided for @saveHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit speichern'**
  String get saveHabit;

  /// No description provided for @stepOf.
  ///
  /// In de, this message translates to:
  /// **'Schritt {step} von {total}'**
  String stepOf(int step, int total);

  /// No description provided for @scheduleRequired.
  ///
  /// In de, this message translates to:
  /// **'Wähle mindestens einen Tag.'**
  String get scheduleRequired;

  /// No description provided for @reminderTimeRequired.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Uhrzeit oder schalte Erinnerungen aus.'**
  String get reminderTimeRequired;

  /// No description provided for @optional.
  ///
  /// In de, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @analyticsTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Rhythmus'**
  String get analyticsTitle;

  /// No description provided for @analyticsBody.
  ///
  /// In de, this message translates to:
  /// **'Erkenne Muster, ohne Fortschritt in Druck zu verwandeln.'**
  String get analyticsBody;

  /// No description provided for @activeHabitsLabel.
  ///
  /// In de, this message translates to:
  /// **'Aktive Habits'**
  String get activeHabitsLabel;

  /// No description provided for @totalWinsLabel.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get totalWinsLabel;

  /// No description provided for @averageSuccessLabel.
  ///
  /// In de, this message translates to:
  /// **'Drangeblieben'**
  String get averageSuccessLabel;

  /// No description provided for @noAnalyticsTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Muster erscheinen hier'**
  String get noAnalyticsTitle;

  /// No description provided for @noAnalyticsBody.
  ///
  /// In de, this message translates to:
  /// **'Schließe Habits einige Male ab, um eine hilfreiche, private Historie aufzubauen.'**
  String get noAnalyticsBody;

  /// No description provided for @streakLabel.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Rhythmus'**
  String get streakLabel;

  /// No description provided for @bestStreakLabel.
  ///
  /// In de, this message translates to:
  /// **'Bester Rhythmus'**
  String get bestStreakLabel;

  /// No description provided for @successLabel.
  ///
  /// In de, this message translates to:
  /// **'Drangeblieben'**
  String get successLabel;

  /// No description provided for @appLockTitle.
  ///
  /// In de, this message translates to:
  /// **'Fokus mit App Lock'**
  String get appLockTitle;

  /// No description provided for @appLockBody.
  ///
  /// In de, this message translates to:
  /// **'Halte ausgewählte Apps zurück, bis deine heutigen Habits erledigt sind.'**
  String get appLockBody;

  /// No description provided for @appLockStatusOn.
  ///
  /// In de, this message translates to:
  /// **'App Lock ist aktiv'**
  String get appLockStatusOn;

  /// No description provided for @appLockStatusOff.
  ///
  /// In de, this message translates to:
  /// **'App Lock ist aus'**
  String get appLockStatusOff;

  /// No description provided for @appLockPermissionIntro.
  ///
  /// In de, this message translates to:
  /// **'Zwei Android-Berechtigungen ermöglichen die Sperre. Du kannst beide jederzeit entziehen.'**
  String get appLockPermissionIntro;

  /// No description provided for @searchApps.
  ///
  /// In de, this message translates to:
  /// **'Apps suchen'**
  String get searchApps;

  /// No description provided for @selectedApps.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählte Apps'**
  String get selectedApps;

  /// No description provided for @availableApps.
  ///
  /// In de, this message translates to:
  /// **'Verfügbare Apps'**
  String get availableApps;

  /// No description provided for @noMatchingApps.
  ///
  /// In de, this message translates to:
  /// **'Keine passenden Apps'**
  String get noMatchingApps;

  /// No description provided for @appSelected.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählt'**
  String get appSelected;

  /// No description provided for @appNotSelected.
  ///
  /// In de, this message translates to:
  /// **'Nicht ausgewählt'**
  String get appNotSelected;

  /// No description provided for @permissionsReady.
  ///
  /// In de, this message translates to:
  /// **'Berechtigungen bereit'**
  String get permissionsReady;

  /// No description provided for @permissionsNeedAttention.
  ///
  /// In de, this message translates to:
  /// **'Einrichtung benötigt Aufmerksamkeit'**
  String get permissionsNeedAttention;

  /// No description provided for @recoveryAndReliability.
  ///
  /// In de, this message translates to:
  /// **'Zuverlässigkeit & Wiederherstellung'**
  String get recoveryAndReliability;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingsBody.
  ///
  /// In de, this message translates to:
  /// **'Passe Habiter an deinen Alltag an. Deine Habit-Daten bleiben auf diesem Gerät.'**
  String get settingsBody;

  /// No description provided for @focusAndAppLock.
  ///
  /// In de, this message translates to:
  /// **'Fokus & App Lock'**
  String get focusAndAppLock;

  /// No description provided for @privacyAndData.
  ///
  /// In de, this message translates to:
  /// **'Daten & Datenschutz'**
  String get privacyAndData;

  /// No description provided for @localFirstTitle.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät gespeichert'**
  String get localFirstTitle;

  /// No description provided for @localFirstBody.
  ///
  /// In de, this message translates to:
  /// **'Habits bleiben lokal, außer du exportierst sie bewusst oder verbindest eine Integration.'**
  String get localFirstBody;

  /// No description provided for @configureAppLock.
  ///
  /// In de, this message translates to:
  /// **'App Lock einrichten'**
  String get configureAppLock;

  /// No description provided for @configureAppLockBody.
  ///
  /// In de, this message translates to:
  /// **'Nur Android · Berechtigungen und Ausschalten mit einem Tipp'**
  String get configureAppLockBody;

  /// No description provided for @recoverySupport.
  ///
  /// In de, this message translates to:
  /// **'Sanfte Neustart-Hilfe'**
  String get recoverySupport;

  /// No description provided for @recoverySupportBody.
  ///
  /// In de, this message translates to:
  /// **'Zeigt wertfreie Vorschläge nach ausgelassenen Tagen.'**
  String get recoverySupportBody;

  /// No description provided for @advancedIntegrations.
  ///
  /// In de, this message translates to:
  /// **'Erweitert & Integrationen'**
  String get advancedIntegrations;

  /// No description provided for @advancedIntegrationsBody.
  ///
  /// In de, this message translates to:
  /// **'Optionale Werkzeuge, standardmäßig aus'**
  String get advancedIntegrationsBody;

  /// No description provided for @classlyImport.
  ///
  /// In de, this message translates to:
  /// **'Classly-kompatibler Import'**
  String get classlyImport;

  /// No description provided for @experimentalAi.
  ///
  /// In de, this message translates to:
  /// **'Experimentelle Remote-KI'**
  String get experimentalAi;

  /// No description provided for @dailyReminderOff.
  ///
  /// In de, this message translates to:
  /// **'Aus — die Berechtigung wird erst beim Einschalten angefragt.'**
  String get dailyReminderOff;

  /// No description provided for @dailyReminderAt.
  ///
  /// In de, this message translates to:
  /// **'Geplant für {time}'**
  String dailyReminderAt(String time);

  /// No description provided for @bootstrapErrorTitle.
  ///
  /// In de, this message translates to:
  /// **'Habiter konnte nicht sicher starten'**
  String get bootstrapErrorTitle;

  /// No description provided for @exportData.
  ///
  /// In de, this message translates to:
  /// **'Backup exportieren'**
  String get exportData;

  /// No description provided for @exportDataBody.
  ///
  /// In de, this message translates to:
  /// **'Kopiert ein JSON-Backup für deine sichere Ablage in die Zwischenablage.'**
  String get exportDataBody;

  /// No description provided for @importData.
  ///
  /// In de, this message translates to:
  /// **'Backup importieren'**
  String get importData;

  /// No description provided for @importDataBody.
  ///
  /// In de, this message translates to:
  /// **'Prüfe ein Habiter-JSON-Backup, bevor Daten hinzugefügt werden.'**
  String get importDataBody;

  /// No description provided for @backupCopied.
  ///
  /// In de, this message translates to:
  /// **'Backup wurde in die Zwischenablage kopiert'**
  String get backupCopied;

  /// No description provided for @pasteBackup.
  ///
  /// In de, this message translates to:
  /// **'Backup-JSON einfügen'**
  String get pasteBackup;

  /// No description provided for @reviewImport.
  ///
  /// In de, this message translates to:
  /// **'Import prüfen'**
  String get reviewImport;

  /// No description provided for @importSummary.
  ///
  /// In de, this message translates to:
  /// **'{habits} Habits · {entries} Einträge · {collisions} bereits vorhanden'**
  String importSummary(int habits, int entries, int collisions);

  /// No description provided for @importComplete.
  ///
  /// In de, this message translates to:
  /// **'Import abgeschlossen. Bestehende Habits wurden behalten und das Backup vor dem Import wurde kopiert.'**
  String get importComplete;

  /// No description provided for @invalidBackup.
  ///
  /// In de, this message translates to:
  /// **'Dieses Backup konnte nicht gelesen werden.'**
  String get invalidBackup;

  /// No description provided for @disconnect.
  ///
  /// In de, this message translates to:
  /// **'Trennen'**
  String get disconnect;

  /// No description provided for @connectWithOauth.
  ///
  /// In de, this message translates to:
  /// **'Mit OAuth verbinden'**
  String get connectWithOauth;

  /// No description provided for @useToken.
  ///
  /// In de, this message translates to:
  /// **'Token verwenden'**
  String get useToken;

  /// No description provided for @trustedHttpsOnly.
  ///
  /// In de, this message translates to:
  /// **'Verbinde nur einen vertrauenswürdigen öffentlichen HTTPS-Server. Beim Trennen werden Zugangsdaten gelöscht.'**
  String get trustedHttpsOnly;

  /// No description provided for @httpsEndpoint.
  ///
  /// In de, this message translates to:
  /// **'HTTPS-Endpunkt'**
  String get httpsEndpoint;

  /// No description provided for @optionalAccessToken.
  ///
  /// In de, this message translates to:
  /// **'Optionales Zugriffs-Token'**
  String get optionalAccessToken;

  /// No description provided for @remoteAiOn.
  ///
  /// In de, this message translates to:
  /// **'Aktiv. Anbieter-Anfragen können Daten teilen und Kosten verursachen.'**
  String get remoteAiOn;

  /// No description provided for @remoteAiOff.
  ///
  /// In de, this message translates to:
  /// **'Aus. Lokales Coaching benötigt keinen API-Key.'**
  String get remoteAiOff;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @providerLabel.
  ///
  /// In de, this message translates to:
  /// **'Anbieter'**
  String get providerLabel;

  /// No description provided for @apiKeyLabel.
  ///
  /// In de, this message translates to:
  /// **'API-Key'**
  String get apiKeyLabel;

  /// No description provided for @increaseTarget.
  ///
  /// In de, this message translates to:
  /// **'Tagesziel erhöhen'**
  String get increaseTarget;

  /// No description provided for @decreaseTarget.
  ///
  /// In de, this message translates to:
  /// **'Tagesziel verringern'**
  String get decreaseTarget;

  /// No description provided for @bootstrapErrorBody.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten wurden nicht verändert. Versuche Habiter erneut zu starten.'**
  String get bootstrapErrorBody;

  /// No description provided for @remoteAiDisclosure.
  ///
  /// In de, this message translates to:
  /// **'Optional und standardmäßig aus. Der Schlüssel bleibt im sicheren Gerätespeicher. Anbieter-Anfragen können Kosten verursachen und Habit-Daten teilen.'**
  String get remoteAiDisclosure;

  /// No description provided for @apiKeyRequired.
  ///
  /// In de, this message translates to:
  /// **'Gib einen API-Key ein, um Remote-KI zu aktivieren.'**
  String get apiKeyRequired;

  /// No description provided for @unlockRule.
  ///
  /// In de, this message translates to:
  /// **'Freigaberegel'**
  String get unlockRule;

  /// No description provided for @allHabitsRequired.
  ///
  /// In de, this message translates to:
  /// **'Alle heutigen Habits abschließen'**
  String get allHabitsRequired;

  /// No description provided for @allHabitsRequiredBody.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählte Apps werden verfügbar, sobald die heutige Liste erledigt ist.'**
  String get allHabitsRequiredBody;

  /// No description provided for @specificHabitsRequired.
  ///
  /// In de, this message translates to:
  /// **'Nur ausgewählte Habits verwenden'**
  String get specificHabitsRequired;

  /// No description provided for @specificHabitsRequiredBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle, welche Habits App Lock steuern.'**
  String get specificHabitsRequiredBody;

  /// No description provided for @requiredHabits.
  ///
  /// In de, this message translates to:
  /// **'Zum Freigeben erforderliche Habits'**
  String get requiredHabits;

  /// No description provided for @nothingScheduledTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute ist nichts geplant'**
  String get nothingScheduledTitle;

  /// No description provided for @nothingScheduledBody.
  ///
  /// In de, this message translates to:
  /// **'Dein nächster Habit erscheint hier, sobald sein Rhythmus wieder dran ist.'**
  String get nothingScheduledBody;

  /// No description provided for @categoryHealth.
  ///
  /// In de, this message translates to:
  /// **'Gesundheit'**
  String get categoryHealth;

  /// No description provided for @categoryLearning.
  ///
  /// In de, this message translates to:
  /// **'Lernen'**
  String get categoryLearning;

  /// No description provided for @categoryProductivity.
  ///
  /// In de, this message translates to:
  /// **'Produktivität'**
  String get categoryProductivity;

  /// No description provided for @categorySocial.
  ///
  /// In de, this message translates to:
  /// **'Soziales'**
  String get categorySocial;

  /// No description provided for @categoryCreative.
  ///
  /// In de, this message translates to:
  /// **'Kreativität'**
  String get categoryCreative;

  /// No description provided for @categoryFitness.
  ///
  /// In de, this message translates to:
  /// **'Fitness'**
  String get categoryFitness;

  /// No description provided for @categoryMindfulness.
  ///
  /// In de, this message translates to:
  /// **'Achtsamkeit'**
  String get categoryMindfulness;

  /// No description provided for @categoryFinance.
  ///
  /// In de, this message translates to:
  /// **'Finanzen'**
  String get categoryFinance;

  /// No description provided for @categoryHome.
  ///
  /// In de, this message translates to:
  /// **'Zuhause'**
  String get categoryHome;

  /// No description provided for @templateGroupPopular.
  ///
  /// In de, this message translates to:
  /// **'Beliebt'**
  String get templateGroupPopular;

  /// No description provided for @templateWater.
  ///
  /// In de, this message translates to:
  /// **'Wasser trinken'**
  String get templateWater;

  /// No description provided for @templateWorkout.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get templateWorkout;

  /// No description provided for @templateRead.
  ///
  /// In de, this message translates to:
  /// **'Lesen'**
  String get templateRead;

  /// No description provided for @templateMeditate.
  ///
  /// In de, this message translates to:
  /// **'Meditieren'**
  String get templateMeditate;

  /// No description provided for @templateWalk.
  ///
  /// In de, this message translates to:
  /// **'Spazieren'**
  String get templateWalk;

  /// No description provided for @templateSleep.
  ///
  /// In de, this message translates to:
  /// **'Schlafroutine'**
  String get templateSleep;

  /// No description provided for @templateWrite.
  ///
  /// In de, this message translates to:
  /// **'Schreiben'**
  String get templateWrite;

  /// No description provided for @templateTidy.
  ///
  /// In de, this message translates to:
  /// **'Aufräumen'**
  String get templateTidy;

  /// No description provided for @templateHealthyMeal.
  ///
  /// In de, this message translates to:
  /// **'Gesund essen'**
  String get templateHealthyMeal;

  /// No description provided for @templateMedicine.
  ///
  /// In de, this message translates to:
  /// **'Medikamente nehmen'**
  String get templateMedicine;

  /// No description provided for @templateFloss.
  ///
  /// In de, this message translates to:
  /// **'Zahnseide'**
  String get templateFloss;

  /// No description provided for @templateScreenFree.
  ///
  /// In de, this message translates to:
  /// **'Bildschirmfreie Zeit'**
  String get templateScreenFree;

  /// No description provided for @templateFinances.
  ///
  /// In de, this message translates to:
  /// **'Finanzen prüfen'**
  String get templateFinances;

  /// No description provided for @templateInstrument.
  ///
  /// In de, this message translates to:
  /// **'Instrument üben'**
  String get templateInstrument;

  /// No description provided for @templateLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache lernen'**
  String get templateLanguage;

  /// No description provided for @templateRun.
  ///
  /// In de, this message translates to:
  /// **'Laufen'**
  String get templateRun;

  /// No description provided for @creationQuestion.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du regelmäßig tun?'**
  String get creationQuestion;

  /// No description provided for @starterTemplates.
  ///
  /// In de, this message translates to:
  /// **'Für dich als Start'**
  String get starterTemplates;

  /// No description provided for @searchTemplates.
  ///
  /// In de, this message translates to:
  /// **'Gewohnheiten durchsuchen'**
  String get searchTemplates;

  /// No description provided for @customHabitAction.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Habit erstellen'**
  String get customHabitAction;

  /// No description provided for @customHabitFromSearch.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Habit \"{name}\" erstellen'**
  String customHabitFromSearch(String name);

  /// No description provided for @habitIdentityQuestion.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du tun?'**
  String get habitIdentityQuestion;

  /// No description provided for @habitIdentityHint.
  ///
  /// In de, this message translates to:
  /// **'Ein kurzer Name lässt sich im Alltag leichter erkennen.'**
  String get habitIdentityHint;

  /// No description provided for @chooseAnotherTemplate.
  ///
  /// In de, this message translates to:
  /// **'Andere Vorlage wählen'**
  String get chooseAnotherTemplate;

  /// No description provided for @rhythmQuestion.
  ///
  /// In de, this message translates to:
  /// **'Wie oft?'**
  String get rhythmQuestion;

  /// No description provided for @rhythmHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen Rhythmus, der wirklich in deine Woche passt.'**
  String get rhythmHint;

  /// No description provided for @dailyOptionBody.
  ///
  /// In de, this message translates to:
  /// **'Einmal täglich'**
  String get dailyOptionBody;

  /// No description provided for @weeklyOptionBody.
  ///
  /// In de, this message translates to:
  /// **'Zum Beispiel dreimal pro Woche'**
  String get weeklyOptionBody;

  /// No description provided for @customOptionBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle passende Wochentage'**
  String get customOptionBody;

  /// No description provided for @reminderQuestion.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du erinnert werden?'**
  String get reminderQuestion;

  /// No description provided for @habitReminderToggle.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung'**
  String get habitReminderToggle;

  /// No description provided for @reminderSupportBody.
  ///
  /// In de, this message translates to:
  /// **'Habiter kann dich zu einer Zeit deiner Wahl sanft erinnern.'**
  String get reminderSupportBody;

  /// No description provided for @reviewHabit.
  ///
  /// In de, this message translates to:
  /// **'Dein Habit'**
  String get reviewHabit;

  /// No description provided for @ready.
  ///
  /// In de, this message translates to:
  /// **'Bereit.'**
  String get ready;

  /// No description provided for @detailsOptional.
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen'**
  String get detailsOptional;

  /// No description provided for @weeklyUnits.
  ///
  /// In de, this message translates to:
  /// **'{completed} von {scheduled} geplanten Einheiten'**
  String weeklyUnits(int completed, int scheduled);

  /// No description provided for @thisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get thisWeek;

  /// No description provided for @lastThirtyDays.
  ///
  /// In de, this message translates to:
  /// **'Letzte 30 Tage'**
  String get lastThirtyDays;

  /// No description provided for @consistencyValue.
  ///
  /// In de, this message translates to:
  /// **'{percent} % Konsistenz'**
  String consistencyValue(int percent);

  /// No description provided for @historyTitle.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get historyTitle;

  /// No description provided for @notEnoughHistory.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht genug Verlauf'**
  String get notEnoughHistory;

  /// No description provided for @notEnoughHistoryBody.
  ///
  /// In de, this message translates to:
  /// **'Nach ein paar geplanten Einheiten wird hier dein Rhythmus sichtbar.'**
  String get notEnoughHistoryBody;

  /// No description provided for @trendImproving.
  ///
  /// In de, this message translates to:
  /// **'Dein jüngster Rhythmus entwickelt sich positiv.'**
  String get trendImproving;

  /// No description provided for @trendDeclining.
  ///
  /// In de, this message translates to:
  /// **'Dein jüngster Rhythmus ist etwas ruhiger geworden.'**
  String get trendDeclining;

  /// No description provided for @trendSteady.
  ///
  /// In de, this message translates to:
  /// **'Dein jüngster Rhythmus bleibt stabil.'**
  String get trendSteady;

  /// No description provided for @dayCompleted.
  ///
  /// In de, this message translates to:
  /// **'erledigt'**
  String get dayCompleted;

  /// No description provided for @dayMissed.
  ///
  /// In de, this message translates to:
  /// **'geplant, nicht erledigt'**
  String get dayMissed;

  /// No description provided for @dayFuture.
  ///
  /// In de, this message translates to:
  /// **'steht noch an'**
  String get dayFuture;

  /// No description provided for @dayNotScheduled.
  ///
  /// In de, this message translates to:
  /// **'nicht geplant'**
  String get dayNotScheduled;

  /// No description provided for @pausedArchivedCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 pausiertes oder archiviertes Habit} other{{count} pausierte oder archivierte Habits}}'**
  String pausedArchivedCount(int count);

  /// No description provided for @chooseHabit.
  ///
  /// In de, this message translates to:
  /// **'Habit auswählen'**
  String get chooseHabit;

  /// No description provided for @emptyStarterExamples.
  ///
  /// In de, this message translates to:
  /// **'Wasser · Lesen · Spazieren · Meditieren'**
  String get emptyStarterExamples;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Kleine Schritte.\nEchte Veränderung.'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In de, this message translates to:
  /// **'Habiter hält fest, was dir wichtig ist – klar, ruhig und Tag für Tag.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In de, this message translates to:
  /// **'Loslegen'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingIntentTitle.
  ///
  /// In de, this message translates to:
  /// **'Was soll\nwachsen?'**
  String get onboardingIntentTitle;

  /// No description provided for @onboardingIntentBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Richtung. Du kannst später alles ändern.'**
  String get onboardingIntentBody;

  /// No description provided for @onboardingIntentOther.
  ///
  /// In de, this message translates to:
  /// **'Etwas anderes'**
  String get onboardingIntentOther;

  /// No description provided for @onboardingFirstHabitTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein erster\nkleiner Schritt.'**
  String get onboardingFirstHabitTitle;

  /// No description provided for @onboardingFirstHabitBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Idee oder gib deinem Habit einen eigenen Namen.'**
  String get onboardingFirstHabitBody;

  /// No description provided for @onboardingCustomHabitName.
  ///
  /// In de, this message translates to:
  /// **'Gib deinem Habit einen Namen'**
  String get onboardingCustomHabitName;

  /// No description provided for @onboardingRhythmTitle.
  ///
  /// In de, this message translates to:
  /// **'Finde deinen\nRhythmus.'**
  String get onboardingRhythmTitle;

  /// No description provided for @onboardingEveryDay.
  ///
  /// In de, this message translates to:
  /// **'Jeden Tag'**
  String get onboardingEveryDay;

  /// No description provided for @onboardingEveryDayBody.
  ///
  /// In de, this message translates to:
  /// **'Ein klarer täglicher Rhythmus'**
  String get onboardingEveryDayBody;

  /// No description provided for @onboardingSeveralTimes.
  ///
  /// In de, this message translates to:
  /// **'Mehrmals pro Woche'**
  String get onboardingSeveralTimes;

  /// No description provided for @onboardingSeveralTimesBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle dein Wochenziel'**
  String get onboardingSeveralTimesBody;

  /// No description provided for @onboardingSpecificDays.
  ///
  /// In de, this message translates to:
  /// **'Bestimmte Tage'**
  String get onboardingSpecificDays;

  /// No description provided for @onboardingSpecificDaysBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle passende Wochentage'**
  String get onboardingSpecificDaysBody;

  /// No description provided for @onboardingTimesPerWeek.
  ///
  /// In de, this message translates to:
  /// **'{count}× pro Woche'**
  String onboardingTimesPerWeek(int count);

  /// No description provided for @onboardingRhythmExplainerDailyTitle.
  ///
  /// In de, this message translates to:
  /// **'Jeder Tag kann einmal zählen.'**
  String get onboardingRhythmExplainerDailyTitle;

  /// No description provided for @onboardingRhythmExplainerFlexibleTitle.
  ///
  /// In de, this message translates to:
  /// **'{count}× pro Woche heißt: {count} verschiedene Tage.'**
  String onboardingRhythmExplainerFlexibleTitle(int count);

  /// No description provided for @onboardingRhythmExplainerFixedTitle.
  ///
  /// In de, this message translates to:
  /// **'Nur deine gewählten Wochentage zählen.'**
  String get onboardingRhythmExplainerFixedTitle;

  /// No description provided for @onboardingRhythmExplainerDailyBody.
  ///
  /// In de, this message translates to:
  /// **'Ein Abschluss zählt pro Kalendertag einmal. Deine Woche läuft von Montag bis Sonntag.'**
  String get onboardingRhythmExplainerDailyBody;

  /// No description provided for @onboardingRhythmExplainerFlexibleBody.
  ///
  /// In de, this message translates to:
  /// **'Du brauchst keine festen Wochentage. Beliebige verschiedene Tage von Montag bis Sonntag zählen – auch direkt hintereinander.'**
  String get onboardingRhythmExplainerFlexibleBody;

  /// No description provided for @onboardingRhythmExplainerFixedBody.
  ///
  /// In de, this message translates to:
  /// **'Die hervorgehobenen Wochentage sind deine Habit-Tage. Jedes Datum kann einmal zählen.'**
  String get onboardingRhythmExplainerFixedBody;

  /// No description provided for @onboardingRhythmWeekLabel.
  ///
  /// In de, this message translates to:
  /// **'DIESE WOCHE'**
  String get onboardingRhythmWeekLabel;

  /// No description provided for @onboardingRhythmProgress.
  ///
  /// In de, this message translates to:
  /// **'{completed} / {target}'**
  String onboardingRhythmProgress(int completed, int target);

  /// No description provided for @onboardingRhythmProgressSemantics.
  ///
  /// In de, this message translates to:
  /// **'{completed} von {target} Tagen ausgewählt'**
  String onboardingRhythmProgressSemantics(int completed, int target);

  /// No description provided for @onboardingRhythmDaySelected.
  ///
  /// In de, this message translates to:
  /// **'ausgewählt'**
  String get onboardingRhythmDaySelected;

  /// No description provided for @onboardingRhythmDayNotSelected.
  ///
  /// In de, this message translates to:
  /// **'nicht ausgewählt'**
  String get onboardingRhythmDayNotSelected;

  /// No description provided for @onboardingRhythmDayUnavailable.
  ///
  /// In de, this message translates to:
  /// **'nicht Teil dieses Rhythmus'**
  String get onboardingRhythmDayUnavailable;

  /// No description provided for @onboardingRhythmTryPrompt.
  ///
  /// In de, this message translates to:
  /// **'Tippe einen Tag an und sieh, wie sich diese Woche verändert.'**
  String get onboardingRhythmTryPrompt;

  /// No description provided for @onboardingRhythmFactDifferentDays.
  ///
  /// In de, this message translates to:
  /// **'Ein Datum zählt einmal'**
  String get onboardingRhythmFactDifferentDays;

  /// No description provided for @onboardingRhythmFactMondayReset.
  ///
  /// In de, this message translates to:
  /// **'Montag bis Sonntag'**
  String get onboardingRhythmFactMondayReset;

  /// No description provided for @onboardingRhythmFactConsecutive.
  ///
  /// In de, this message translates to:
  /// **'Aufeinanderfolgende Tage zählen'**
  String get onboardingRhythmFactConsecutive;

  /// No description provided for @onboardingRhythmInvalid.
  ///
  /// In de, this message translates to:
  /// **'Dieser Rhythmus konnte nicht angezeigt werden. Gehe zurück und wähle ihn erneut.'**
  String get onboardingRhythmInvalid;

  /// No description provided for @onboardingReminderEducationTitle.
  ///
  /// In de, this message translates to:
  /// **'Ein Hinweis.\nZwei Wege.'**
  String get onboardingReminderEducationTitle;

  /// No description provided for @onboardingReminderEducationBody.
  ///
  /// In de, this message translates to:
  /// **'Teste, wie Erledigt und Später deinen Fortschritt verändern.'**
  String get onboardingReminderEducationBody;

  /// No description provided for @onboardingReminderQuestion.
  ///
  /// In de, this message translates to:
  /// **'Passt es gerade?'**
  String get onboardingReminderQuestion;

  /// No description provided for @onboardingReminderResetDemo.
  ///
  /// In de, this message translates to:
  /// **'Noch einmal testen'**
  String get onboardingReminderResetDemo;

  /// No description provided for @onboardingReminderDoneExplanation.
  ///
  /// In de, this message translates to:
  /// **'Als erledigt markiert. Dein Fortschritt steigt sofort.'**
  String get onboardingReminderDoneExplanation;

  /// No description provided for @onboardingReminderLaterExplanation.
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt bleibt gleich. Die Demo springt 30 Minuten weiter.'**
  String get onboardingReminderLaterExplanation;

  /// No description provided for @onboardingReminderProgressSemantics.
  ///
  /// In de, this message translates to:
  /// **'{completed} von {target} Habit-Tagen erledigt'**
  String onboardingReminderProgressSemantics(int completed, int target);

  /// No description provided for @onboardingReminderTitle.
  ///
  /// In de, this message translates to:
  /// **'Erinnern.\nNur wenn du willst.'**
  String get onboardingReminderTitle;

  /// No description provided for @onboardingReminderBody.
  ///
  /// In de, this message translates to:
  /// **'Smart-Reminder sind optional. Erst nach deiner Wahl fragen wir nach der Berechtigung.'**
  String get onboardingReminderBody;

  /// No description provided for @onboardingNoReminder.
  ///
  /// In de, this message translates to:
  /// **'Ohne Erinnerung'**
  String get onboardingNoReminder;

  /// No description provided for @onboardingAddReminder.
  ///
  /// In de, this message translates to:
  /// **'Smart-Reminder verwenden'**
  String get onboardingAddReminder;

  /// No description provided for @onboardingSmartCalibrationTitle.
  ///
  /// In de, this message translates to:
  /// **'Siebentägige Kalibrierung'**
  String get onboardingSmartCalibrationTitle;

  /// No description provided for @onboardingSmartCalibrationBody.
  ///
  /// In de, this message translates to:
  /// **'Ein paar kurze Fragen zeigen Habiter, welche Momente wirklich passen. Ignorierte Hinweise bleiben neutral.'**
  String get onboardingSmartCalibrationBody;

  /// No description provided for @onboardingSmartFrequencyTitle.
  ///
  /// In de, this message translates to:
  /// **'Hartnäckig, aber begrenzt'**
  String get onboardingSmartFrequencyTitle;

  /// No description provided for @onboardingSmartFrequencyBody.
  ///
  /// In de, this message translates to:
  /// **'Bis zu drei Versuche pro Habit-Tag, aber insgesamt nie mehr als acht Hinweise und mindestens 90 Minuten Abstand.'**
  String get onboardingSmartFrequencyBody;

  /// No description provided for @onboardingSmartPrivacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Nur auf diesem Gerät'**
  String get onboardingSmartPrivacyTitle;

  /// No description provided for @onboardingSmartPrivacyBody.
  ///
  /// In de, this message translates to:
  /// **'Keine Cloudübertragung, Standort-, Kontakt-, Kalender-, Sensor- oder App-Nutzungsdaten.'**
  String get onboardingSmartPrivacyBody;

  /// No description provided for @onboardingSmartControlTitle.
  ///
  /// In de, this message translates to:
  /// **'Du behältst die Kontrolle'**
  String get onboardingSmartControlTitle;

  /// No description provided for @onboardingSmartControlBody.
  ///
  /// In de, this message translates to:
  /// **'Die Wachzeit ist zunächst 08:00–22:00 Uhr. Du kannst jederzeit pausieren, jeden Plan ändern oder alle Lerndaten löschen.'**
  String get onboardingSmartControlBody;

  /// No description provided for @onboardingHabitReadyTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein erstes\nHabit steht.'**
  String get onboardingHabitReadyTitle;

  /// No description provided for @onboardingHabitReadyBody.
  ///
  /// In de, this message translates to:
  /// **'Jetzt bringen wir es dorthin, wo du es wirklich siehst.'**
  String get onboardingHabitReadyBody;

  /// No description provided for @onboardingSaving.
  ///
  /// In de, this message translates to:
  /// **'Dein Habit wird eingerichtet…'**
  String get onboardingSaving;

  /// No description provided for @onboardingStepProgress.
  ///
  /// In de, this message translates to:
  /// **'Einrichtungsschritt {step} von {total}'**
  String onboardingStepProgress(int step, int total);

  /// No description provided for @onboardingWidgetIntroTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Habit.\nDirekt im Blick.'**
  String get onboardingWidgetIntroTitle;

  /// No description provided for @onboardingWidgetIntroBody.
  ///
  /// In de, this message translates to:
  /// **'Sieh deinen nächsten Schritt und hake ihn ab, ohne die App zu öffnen.'**
  String get onboardingWidgetIntroBody;

  /// No description provided for @onboardingWidgetResponsive.
  ///
  /// In de, this message translates to:
  /// **'Passt in kompakte, breite und große Homescreen-Flächen.'**
  String get onboardingWidgetResponsive;

  /// No description provided for @onboardingWidgetAdd.
  ///
  /// In de, this message translates to:
  /// **'Widget hinzufügen'**
  String get onboardingWidgetAdd;

  /// No description provided for @onboardingWidgetLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get onboardingWidgetLater;

  /// No description provided for @onboardingWidgetPinTitle.
  ///
  /// In de, this message translates to:
  /// **'Habiter zum Homescreen hinzufügen'**
  String get onboardingWidgetPinTitle;

  /// No description provided for @onboardingWidgetPinBody.
  ///
  /// In de, this message translates to:
  /// **'Android fragt dich, wo du das Widget platzieren möchtest.'**
  String get onboardingWidgetPinBody;

  /// No description provided for @onboardingWidgetRequestingTitle.
  ///
  /// In de, this message translates to:
  /// **'Fast da.'**
  String get onboardingWidgetRequestingTitle;

  /// No description provided for @onboardingWidgetRequestingBody.
  ///
  /// In de, this message translates to:
  /// **'Android bereitet die Platzierung vor…'**
  String get onboardingWidgetRequestingBody;

  /// No description provided for @onboardingWidgetReadyTitle.
  ///
  /// In de, this message translates to:
  /// **'Bereit.'**
  String get onboardingWidgetReadyTitle;

  /// No description provided for @onboardingWidgetReadyBody.
  ///
  /// In de, this message translates to:
  /// **'Dein nächster Schritt ist jetzt direkt auf deinem Homescreen.'**
  String get onboardingWidgetReadyBody;

  /// No description provided for @onboardingWidgetDeclinedTitle.
  ///
  /// In de, this message translates to:
  /// **'Kein Problem.'**
  String get onboardingWidgetDeclinedTitle;

  /// No description provided for @onboardingWidgetDeclinedBody.
  ///
  /// In de, this message translates to:
  /// **'Du kannst das Widget jederzeit später in Habiter hinzufügen.'**
  String get onboardingWidgetDeclinedBody;

  /// No description provided for @onboardingWidgetManualTitle.
  ///
  /// In de, this message translates to:
  /// **'Widget manuell hinzufügen'**
  String get onboardingWidgetManualTitle;

  /// No description provided for @onboardingWidgetUnsupportedBody.
  ///
  /// In de, this message translates to:
  /// **'Automatisches Anheften wird hier nicht unterstützt. Manuell klappt es trotzdem.'**
  String get onboardingWidgetUnsupportedBody;

  /// No description provided for @onboardingWidgetFailedBody.
  ///
  /// In de, this message translates to:
  /// **'Die Android-Anfrage hat nicht geklappt. Du kannst das Widget manuell hinzufügen.'**
  String get onboardingWidgetFailedBody;

  /// No description provided for @onboardingWidgetManualOne.
  ///
  /// In de, this message translates to:
  /// **'Homescreen gedrückt halten'**
  String get onboardingWidgetManualOne;

  /// No description provided for @onboardingWidgetManualTwo.
  ///
  /// In de, this message translates to:
  /// **'Widgets öffnen'**
  String get onboardingWidgetManualTwo;

  /// No description provided for @onboardingWidgetManualThree.
  ///
  /// In de, this message translates to:
  /// **'Habiter auswählen'**
  String get onboardingWidgetManualThree;

  /// No description provided for @onboardingWidgetManualFour.
  ///
  /// In de, this message translates to:
  /// **'Widget platzieren'**
  String get onboardingWidgetManualFour;

  /// No description provided for @onboardingWidgetLetsGo.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get onboardingWidgetLetsGo;

  /// No description provided for @onboardingWidgetUnderstood.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get onboardingWidgetUnderstood;

  /// No description provided for @widgetPromotionTitle.
  ///
  /// In de, this message translates to:
  /// **'Habiter auf deinem Homescreen'**
  String get widgetPromotionTitle;

  /// No description provided for @widgetPromotionBody.
  ///
  /// In de, this message translates to:
  /// **'Habits abhaken, ohne die App zu öffnen.'**
  String get widgetPromotionBody;

  /// No description provided for @widgetSettingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Homescreen / Widget'**
  String get widgetSettingsTitle;

  /// No description provided for @widgetStatusAdded.
  ///
  /// In de, this message translates to:
  /// **'Widget hinzugefügt'**
  String get widgetStatusAdded;

  /// No description provided for @widgetStatusNotAdded.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht hinzugefügt'**
  String get widgetStatusNotAdded;

  /// No description provided for @widgetPreviewSemantics.
  ///
  /// In de, this message translates to:
  /// **'Vorschau des responsiven Habiter-Homescreen-Widgets'**
  String get widgetPreviewSemantics;

  /// No description provided for @widgetPreviewNext.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes: {name}'**
  String widgetPreviewNext(String name);

  /// No description provided for @updateCenterTitle.
  ///
  /// In de, this message translates to:
  /// **'Update-Center'**
  String get updateCenterTitle;

  /// No description provided for @updateSettingsEntry.
  ///
  /// In de, this message translates to:
  /// **'App-Updates'**
  String get updateSettingsEntry;

  /// No description provided for @updateSettingsBody.
  ///
  /// In de, this message translates to:
  /// **'Kanal, Zeitplan, Status und Update-Verlauf'**
  String get updateSettingsBody;

  /// No description provided for @updateStatusTitle.
  ///
  /// In de, this message translates to:
  /// **'Update-Status'**
  String get updateStatusTitle;

  /// No description provided for @updateStatusIdle.
  ///
  /// In de, this message translates to:
  /// **'Bereit zur Prüfung'**
  String get updateStatusIdle;

  /// No description provided for @updateStatusChecking.
  ///
  /// In de, this message translates to:
  /// **'Sichere Prüfung läuft…'**
  String get updateStatusChecking;

  /// No description provided for @updateStatusCurrent.
  ///
  /// In de, this message translates to:
  /// **'Habiter ist aktuell'**
  String get updateStatusCurrent;

  /// No description provided for @updateStatusAvailable.
  ///
  /// In de, this message translates to:
  /// **'Habiter {version} ist verfügbar'**
  String updateStatusAvailable(String version);

  /// No description provided for @updateStatusDownloading.
  ///
  /// In de, this message translates to:
  /// **'Download · {percent}%'**
  String updateStatusDownloading(int percent);

  /// No description provided for @updateStatusVerifying.
  ///
  /// In de, this message translates to:
  /// **'Download wird geprüft…'**
  String get updateStatusVerifying;

  /// No description provided for @updateStatusReady.
  ///
  /// In de, this message translates to:
  /// **'Bereit zur Installation'**
  String get updateStatusReady;

  /// No description provided for @updateStatusInstalling.
  ///
  /// In de, this message translates to:
  /// **'Android-Installer geöffnet'**
  String get updateStatusInstalling;

  /// No description provided for @updateStatusMandatory.
  ///
  /// In de, this message translates to:
  /// **'Dieses Update ist jetzt erforderlich'**
  String get updateStatusMandatory;

  /// No description provided for @updateStatusError.
  ///
  /// In de, this message translates to:
  /// **'Update-Prüfung nicht verfügbar'**
  String get updateStatusError;

  /// No description provided for @updateAvailableBadge.
  ///
  /// In de, this message translates to:
  /// **'Update verfügbar'**
  String get updateAvailableBadge;

  /// No description provided for @updateCheckNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt prüfen'**
  String get updateCheckNow;

  /// No description provided for @updateLastChecked.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt geprüft: {date}'**
  String updateLastChecked(String date);

  /// No description provided for @updateNeverChecked.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht geprüft'**
  String get updateNeverChecked;

  /// No description provided for @updateTrackTitle.
  ///
  /// In de, this message translates to:
  /// **'Release-Kanal'**
  String get updateTrackTitle;

  /// No description provided for @updateTrackStable.
  ///
  /// In de, this message translates to:
  /// **'Stable'**
  String get updateTrackStable;

  /// No description provided for @updateTrackStableBody.
  ///
  /// In de, this message translates to:
  /// **'Nur getestete Stable-Releases'**
  String get updateTrackStableBody;

  /// No description provided for @updateTrackBeta.
  ///
  /// In de, this message translates to:
  /// **'Beta'**
  String get updateTrackBeta;

  /// No description provided for @updateTrackBetaBody.
  ///
  /// In de, this message translates to:
  /// **'Höchster Build aus Stable und Beta'**
  String get updateTrackBetaBody;

  /// No description provided for @updateProfileTitle.
  ///
  /// In de, this message translates to:
  /// **'Update-Profil'**
  String get updateProfileTitle;

  /// No description provided for @updateProfileImmediate.
  ///
  /// In de, this message translates to:
  /// **'Sofort'**
  String get updateProfileImmediate;

  /// No description provided for @updateProfileImmediateBody.
  ///
  /// In de, this message translates to:
  /// **'Bei Start/Fortsetzen und stündlich · Download über jedes Netz'**
  String get updateProfileImmediateBody;

  /// No description provided for @updateProfileBalanced.
  ///
  /// In de, this message translates to:
  /// **'Ausgewogen'**
  String get updateProfileBalanced;

  /// No description provided for @updateProfileBalancedBody.
  ///
  /// In de, this message translates to:
  /// **'Alle 24 Stunden · Auto-Download über ungetaktete Netze'**
  String get updateProfileBalancedBody;

  /// No description provided for @updateProfileSaver.
  ///
  /// In de, this message translates to:
  /// **'Sparsam'**
  String get updateProfileSaver;

  /// No description provided for @updateProfileSaverBody.
  ///
  /// In de, this message translates to:
  /// **'Alle sieben Tage · kein automatischer Download'**
  String get updateProfileSaverBody;

  /// No description provided for @updateViewWhatsNew.
  ///
  /// In de, this message translates to:
  /// **'Was ist neu?'**
  String get updateViewWhatsNew;

  /// No description provided for @updateDownload.
  ///
  /// In de, this message translates to:
  /// **'Update herunterladen'**
  String get updateDownload;

  /// No description provided for @updateInstall.
  ///
  /// In de, this message translates to:
  /// **'Installieren'**
  String get updateInstall;

  /// No description provided for @updateOpenDownload.
  ///
  /// In de, this message translates to:
  /// **'Download öffnen'**
  String get updateOpenDownload;

  /// No description provided for @updateNotNow.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get updateNotNow;

  /// No description provided for @updateInstallerPermissionTitle.
  ///
  /// In de, this message translates to:
  /// **'Habiter darf dieses Update installieren'**
  String get updateInstallerPermissionTitle;

  /// No description provided for @updateInstallerPermissionBody.
  ///
  /// In de, this message translates to:
  /// **'Android fragt einmal, ob Habiter geprüfte APK-Updates öffnen darf. Du kannst diese Freigabe jederzeit entziehen.'**
  String get updateInstallerPermissionBody;

  /// No description provided for @updateOpenSettings.
  ///
  /// In de, this message translates to:
  /// **'Android-Einstellungen öffnen'**
  String get updateOpenSettings;

  /// No description provided for @updateHistoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Release-Verlauf'**
  String get updateHistoryTitle;

  /// No description provided for @updateStorageTitle.
  ///
  /// In de, this message translates to:
  /// **'Update-Speicher'**
  String get updateStorageTitle;

  /// No description provided for @updateStorageUsage.
  ///
  /// In de, this message translates to:
  /// **'Metadaten: {metadata} · Downloads: {downloads}'**
  String updateStorageUsage(String metadata, String downloads);

  /// No description provided for @updateClearDownloads.
  ///
  /// In de, this message translates to:
  /// **'Downloads löschen'**
  String get updateClearDownloads;

  /// No description provided for @updateClearCache.
  ///
  /// In de, this message translates to:
  /// **'Manifest-Cache leeren'**
  String get updateClearCache;

  /// No description provided for @updatePrivacyNote.
  ///
  /// In de, this message translates to:
  /// **'Prüfungen enthalten keine Nutzerkennung und erzeugen keine Analytics.'**
  String get updatePrivacyNote;

  /// No description provided for @updateOfflineMandatoryWarning.
  ///
  /// In de, this message translates to:
  /// **'Ein Pflichtupdate wartet. Habiter bleibt offline nutzbar und prüft erneut, sobald du online bist.'**
  String get updateOfflineMandatoryWarning;

  /// No description provided for @updateMandatoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Update erforderlich'**
  String get updateMandatoryTitle;

  /// No description provided for @updateMandatoryBody.
  ///
  /// In de, this message translates to:
  /// **'Eine verifizierte Frist ist abgelaufen. Installiere das Update, um Habiter online weiterzuverwenden.'**
  String get updateMandatoryBody;

  /// No description provided for @updateMandatoryCountdown.
  ///
  /// In de, this message translates to:
  /// **'{hours, plural, =1{In 1 Stunde erforderlich} other{In {hours} Stunden erforderlich}}'**
  String updateMandatoryCountdown(int hours);

  /// No description provided for @releaseStorySuccessTitle.
  ///
  /// In de, this message translates to:
  /// **'Update installiert'**
  String get releaseStorySuccessTitle;

  /// No description provided for @releaseStorySuccessBody.
  ///
  /// In de, this message translates to:
  /// **'Habiter ist mit den neuesten Verbesserungen bereit.'**
  String get releaseStorySuccessBody;

  /// No description provided for @releaseStoryContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter zu Habiter'**
  String get releaseStoryContinue;

  /// No description provided for @releaseStoryDetails.
  ///
  /// In de, this message translates to:
  /// **'Details nach Version'**
  String get releaseStoryDetails;

  /// No description provided for @releaseStoryAdded.
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get releaseStoryAdded;

  /// No description provided for @releaseStoryChanged.
  ///
  /// In de, this message translates to:
  /// **'Geändert'**
  String get releaseStoryChanged;

  /// No description provided for @releaseStoryFixed.
  ///
  /// In de, this message translates to:
  /// **'Behoben'**
  String get releaseStoryFixed;

  /// No description provided for @releaseStorySecurity.
  ///
  /// In de, this message translates to:
  /// **'Sicherheit'**
  String get releaseStorySecurity;

  /// No description provided for @releaseStoryFallbackHeadline.
  ///
  /// In de, this message translates to:
  /// **'Habiter {version}'**
  String releaseStoryFallbackHeadline(String version);

  /// No description provided for @releaseStoryFallbackSummary.
  ///
  /// In de, this message translates to:
  /// **'Eine neue Habiter-Version ist bereit.'**
  String get releaseStoryFallbackSummary;

  /// No description provided for @updateUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Updates sind auf dieser Plattform noch nicht verfügbar.'**
  String get updateUnsupported;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
