import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
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
];
