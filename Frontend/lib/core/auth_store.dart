import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Persists the JWT and current user, and exposes auth state to the app.
///
/// A single instance is provided at the top of the widget tree (see main.dart).
/// The Dio interceptor reads/clears the token through the same instance.
class AuthStore extends ChangeNotifier {
  static const _tokenKey = 'washly_token';
  static const _userKey = 'washly_user';

  String? _token;
  User? _user;
  bool _initialized = false;

  String? get token => _token;
  User? get currentUser => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isInitialized => _initialized;

  /// Load any persisted session from disk. Call once at app start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  /// Persist a fresh session after login/registration.
  Future<void> setSession(String token, User user) async {
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  /// Update the cached user (e.g. after editing profile) without touching the token.
  Future<void> updateUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  /// Clear the session (logout, or 401 from the server).
  Future<void> clear() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }
}
