import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  
  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar'); // Default to Arabic

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isRTL => _locale.languageCode == 'ar';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
    _loadLanguage();
  }

  void _loadTheme() {
    final themeIndex = _prefs?.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
  }

  void _loadLanguage() {
    final languageCode = _prefs?.getString(_languageKey) ?? 'ar';
    _locale = Locale(languageCode);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _prefs?.setInt(_themeKey, themeMode.index);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs?.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
    }
  }

  Future<void> toggleLanguage() async {
    final newLocale = _locale.languageCode == 'ar' 
        ? const Locale('en') 
        : const Locale('ar');
    await setLocale(newLocale);
  }

  String getThemeModeDisplayName() {
    switch (_themeMode) {
      case ThemeMode.system:
        return isRTL ? 'تلقائي' : 'System';
      case ThemeMode.light:
        return isRTL ? 'فاتح' : 'Light';
      case ThemeMode.dark:
        return isRTL ? 'داكن' : 'Dark';
    }
  }
}