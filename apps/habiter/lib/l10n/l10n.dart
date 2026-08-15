import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Extension for easy access to localized strings
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
