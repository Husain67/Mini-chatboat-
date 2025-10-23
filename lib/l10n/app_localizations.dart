import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('hi')];

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static final Map<String, Map<String, String>> _values = {
    'en': {
      'title': 'VokAI',
      'today': 'Today',
      'type_message': 'Type a message...',
      'history': 'History',
      'new_chat': 'New Chat',
      'about': 'About',
      'privacy_policy': 'Privacy Policy',
      'app_language': 'App Language',
      'app_version': 'App Version',
      'dark_mode': 'Dark Mode',
      'eye_mode': 'Eye Mode',
      'system_mode': 'System Mode',
      'english': 'English',
      'hindi': 'Hindi',
      'ok': 'OK',
      'version_value': 'Version 1.0.0',
    },
    'hi': {
      'title': 'VokAI',
      'today': 'आज',
      'type_message': 'संदेश लिखें...',
      'history': 'इतिहास',
      'new_chat': 'नई चैट',
      'about': 'जानकारी',
      'privacy_policy': 'गोपनीयता नीति',
      'app_language': 'एप की भाषा',
      'app_version': 'एप संस्करण',
      'dark_mode': 'डार्क मोड',
      'eye_mode': 'आई मोड',
      'system_mode': 'सिस्टम मोड',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिंदी',
      'ok': 'ठीक',
      'version_value': 'संस्करण 1.0.0',
    }
  };

  String t(String key) => _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
