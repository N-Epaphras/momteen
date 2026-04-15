import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings_model.dart';

class ThemeProvider extends ChangeNotifier {
  final Box<SettingsModel> _box;
  bool _isDarkMode = false;

  ThemeProvider(this._box) {
    _loadTheme();
    // Setup watcher after init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupWatcher();
    });
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  static final ThemeData _lightTheme = ThemeData(
    primarySwatch: Colors.purple,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[200],
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.pink[200]),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.pink[200],
      foregroundColor: Colors.white,
    ),
  );

  static final ThemeData _darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.purple,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.purple),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
    ),
  );

  void _loadTheme() {
    if (_box.isNotEmpty) {
      final settings = _box.getAt(0);
      if (settings != null) {
        _isDarkMode = settings.darkMode;
      }
    }
    // Default to light mode if no settings
    notifyListeners();
  }

  void _setupWatcher() {
    _box.watch().listen((event) {
      if (event.value is SettingsModel) {
        final settings = event.value as SettingsModel;
        _isDarkMode = settings.darkMode;
        notifyListeners();
      }
    });
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;

    // Save to settings
    if (_box.isNotEmpty) {
      final settings = _box.getAt(0)!;
      settings.darkMode = value;
      await settings.save();
    } else {
      // Create default settings if none exist
      final newSettings = SettingsModel(
        darkMode: value,
        notifications: true,
        language: 'English',
        offlineModeEnabled: false,
        modelDownloaded: false,
      );
      await _box.add(newSettings);
    }

    notifyListeners();
  }
}
