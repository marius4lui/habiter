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
    Locale('en')
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
  /// **'Analytics'**
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
  /// **'Starte dein Momentum'**
  String get startMomentum;

  /// No description provided for @startMomentumDescription.
  ///
  /// In de, this message translates to:
  /// **'Lege dein erstes Habit an und schau zu, wie die Routine wachsen kann.'**
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
  /// **'Icon'**
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
  /// **'{count}/Woche'**
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
  /// **'Test-Benachrichtigung'**
  String get testNotification;

  /// No description provided for @testNotificationDesc.
  ///
  /// In de, this message translates to:
  /// **'Sendet eine Test-Notification'**
  String get testNotificationDesc;

  /// No description provided for @testNotificationSent.
  ///
  /// In de, this message translates to:
  /// **'Test-Benachrichtigung gesendet!'**
  String get testNotificationSent;

  /// No description provided for @appearance.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In de, this message translates to:
  /// **'Theme'**
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
  /// **'KI-Features'**
  String get aiFeatures;

  /// No description provided for @aiInsights.
  ///
  /// In de, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @aiInsightsDesc.
  ///
  /// In de, this message translates to:
  /// **'Intelligente Analyse deiner Habits'**
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
  /// **'English'**
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
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Trends live verfolgen, Peaks feiern, früh korrigieren.'**
  String get analyticsSubtitle;

  /// No description provided for @liveOverview.
  ///
  /// In de, this message translates to:
  /// **'Live-Übersicht'**
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
  /// **'Tracke ein Habit, um den Wochenfortschritt zu sehen.'**
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
  /// **'AI Insights'**
  String get aiInsightsTitle;

  /// No description provided for @insightsAppearHere.
  ///
  /// In de, this message translates to:
  /// **'Insights erscheinen hier, nachdem du einige Tage getrackt und AI-Vorschläge generiert hast.'**
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
      'that was used.');
}
