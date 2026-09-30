import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen app language and exposes it to the widget tree.
///
/// Note: this stores and broadcasts the preference. Translating every screen's
/// copy is a separate localization effort (ARB files + flutter_localizations);
/// wiring the locale here is the foundation for that.
class LocaleStore extends ChangeNotifier {
  static const _key = 'washly_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  /// Supported languages, in menu order.
  static const supported = <(Locale, String)>[
    (Locale('en'), 'English'),
    (Locale('id'), 'Indonesian'),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    notifyListeners();
  }
}
