import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's profile photo locally on the device as a data URI.
///
/// The backend User model has no photo field yet, so this keeps the chosen
/// avatar on-device (keyed per user id) and broadcasts changes to the UI.
/// Server-side persistence is a future follow-up.
class ProfilePhotoStore extends ChangeNotifier {
  static String _key(int userId) => 'washly_profile_photo_$userId';

  String? _dataUri;
  int? _userId;

  /// The current photo as a data URI (e.g. 'data:image/jpeg;base64,...'), or
  /// null if none set.
  String? get dataUri => _dataUri;

  /// Load the stored photo for a given user. Call after login / on profile open.
  Future<void> loadFor(int userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    _dataUri = prefs.getString(_key(userId));
    notifyListeners();
  }

  Future<void> setPhoto(String dataUri) async {
    if (_userId == null) return;
    _dataUri = dataUri;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_userId!), dataUri);
    notifyListeners();
  }

  Future<void> clear() async {
    if (_userId == null) return;
    _dataUri = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(_userId!));
    notifyListeners();
  }
}
