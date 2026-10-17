import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The user's light/dark/system preference, light by default (mobile only - main.dart never
// applies it on web). Loaded from SharedPreferences before runApp so the first
// frame already has the right theme.
class ThemeModeProvider extends ChangeNotifier {
  static const _prefsKey = 'themeMode';

  ThemeModeProvider([this._mode = ThemeMode.light]);

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  static Future<ThemeModeProvider> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      return ThemeModeProvider(
        ThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => ThemeMode.light,
        ),
      );
    } catch (e) {
      debugPrint('theme mode load error: $e');
      return ThemeModeProvider();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (e) {
      debugPrint('theme mode save error: $e');
    }
  }

  // Flips between light and dark based on what's currently showing, so the
  // header toggle behaves sensibly when the mode is still "system".
  Future<void> toggle(BuildContext context) => setMode(
        Theme.of(context).brightness == Brightness.dark
            ? ThemeMode.light
            : ThemeMode.dark,
      );
}
