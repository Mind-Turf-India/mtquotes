import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
export 'package:flutter_gen/gen_l10n/app_localizations.dart';

// This makes it easy to access localization throughout your app
extension LocalizationExtension on BuildContext {
 AppLocalizations get loc => AppLocalizations.of(this)!;
}

// The localization delegates for your app
List<LocalizationsDelegate> get localizationDelegates => [
 AppLocalizations.delegate,
 GlobalMaterialLocalizations.delegate,
 GlobalWidgetsLocalizations.delegate,
 GlobalCupertinoLocalizations.delegate,
];

// The languages your app supports
List<Locale> get supportedLocales => [
 const Locale('en'),
 const Locale('hi'),
 const Locale('bn'),
 const Locale('te'),
 const Locale('gu'),
 const Locale('or'),
 const Locale('mr'),
];


extension AppLocalizationsExtensions on AppLocalizations {
 String get filters => 'Filters';
 String get selectMinimumRating => 'Select Minimum Rating';
 String get selectLanguage => 'Select Language';
 String get allLanguages => 'All Languages';
 String get allRatings => 'All Ratings';
 String get discard => 'Discard';
 String get apply => 'Apply';
 String get clearAll => 'Clear All';
 String get noResultsFound => 'No results found';
 String get tryRemovingFilters => 'Try removing some filters';
}
