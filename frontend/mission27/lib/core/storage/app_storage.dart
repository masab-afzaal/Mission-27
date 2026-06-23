import 'package:shared_preferences/shared_preferences.dart';

/// Platform-safe key-value storage.
/// Uses SharedPreferences (localStorage on web, file on desktop, native on mobile).
/// Drop-in replacement for flutter_secure_storage on web.
class AppStorage {
  AppStorage(this._prefs);

  final SharedPreferences _prefs;

  Future<String?> read({required String key}) async {
    return _prefs.getString(key);
  }

  Future<void> write({required String key, required String value}) async {
    await _prefs.setString(key, value);
  }

  Future<void> delete({required String key}) async {
    await _prefs.remove(key);
  }

  Future<void> deleteAll() async {
    await _prefs.clear();
  }
}
