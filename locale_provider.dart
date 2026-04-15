import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings_model.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  String _language = 'English';

  List<Locale> get supportedLocales => const [Locale('en'), Locale('es')];

  Locale get locale => _locale;
  String get language => _language;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isNotEmpty) {
      final settings = settingsBox.getAt(0);
      if (settings != null && settings.language.isNotEmpty) {
        _setLocaleFromString(settings.language);
      }
    }
  }

  void _setLocaleFromString(String language) {
    // Change detection: only notify if actually changed
    final oldLocale = _locale;
    final oldLanguage = _language;

    // Fallback logic: validate against supported locales
    Locale? targetLocale;
    String targetLanguage = 'English';

    switch (language) {
      case 'English':
        targetLocale = const Locale('en');
        targetLanguage = 'English';
        break;
      case 'Spanish':
        targetLocale = const Locale('es');
        targetLanguage = 'Spanish';
        break;
      case 'Runyankole':
        targetLocale = const Locale('en');
        targetLanguage = 'Runyankole';
        break;
    }

    // Explicit fallback to English if invalid/missing
    if (targetLocale == null) {
      targetLocale = const Locale('en');
      targetLanguage = 'English';
    }

    // Only update and notify if changed - IMMEDIATE notifyListeners (FIXES MaterialLocalizations error)
    if (oldLocale != targetLocale || oldLanguage != targetLanguage) {
      _locale = targetLocale;
      _language = targetLanguage;
      notifyListeners(); // 🔥 IMMEDIATE - eliminates 250ms race condition
    }
  }

  String get languageString {
    return _language;
  }

  void setLocale(String language) {
    _setLocaleFromString(language);

    // FIXED: Safe Hive settings save - prevents "object not in box" crash
    final settingsBox = Hive.box<SettingsModel>('settings');
    try {
      if (settingsBox.isNotEmpty) {
        final settings = settingsBox.getAt(0);
        if (settings != null) {
          settings.language = language;
          settings.save(); // Safe - object already in box
        }
      } else {
        // Create & properly add new settings
        final newSettings = SettingsModel(
          darkMode: false,
          notifications: true,
          language: language, // Use requested language
        );
        settingsBox.add(newSettings); // Properly add to box FIRST
      }
    } catch (e) {
      // Fallback: create new settings if box corrupted
      debugPrint('Settings save error: $e');
      final newSettings = SettingsModel(
        darkMode: false,
        notifications: true,
        language: language,
      );
      settingsBox.clear();
      settingsBox.add(newSettings);
    }
  }
}
