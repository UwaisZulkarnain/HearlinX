import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_text.dart';

class LanguageProvider extends ChangeNotifier {
  static const _storageKey = 'hearlinx_lang';

  Locale _locale = const Locale('ms');

  Locale get locale => _locale;
  String get lang => _locale.languageCode;
  AppText get text => AppText(lang);

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_storageKey) ?? 'ms';

    if (savedLang == 'en' || savedLang == 'ms') {
      _locale = Locale(savedLang);
      notifyListeners();
    }
  }

  Future<void> setLang(String lang) async {
    if (lang != 'en' && lang != 'ms') {
      return;
    }

    if (_locale.languageCode == lang) {
      return;
    }

    _locale = Locale(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, lang);
    notifyListeners();
  }

  Future<void> toggleLang() async {
    await setLang(lang == 'en' ? 'ms' : 'en');
  }
}
