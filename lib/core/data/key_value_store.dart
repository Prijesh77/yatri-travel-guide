import 'package:shared_preferences/shared_preferences.dart';

/// Minimal persistent key/value store used for offline caches and user
/// preferences. Backed by SharedPreferences in the app and by an in-memory
/// map in tests.
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? initial]) : _map = {...?initial};
  final Map<String, String> _map;

  @override
  String? getString(String key) => _map[key];

  @override
  Future<void> setString(String key, String value) async => _map[key] = value;

  @override
  Future<void> remove(String key) async => _map.remove(key);
}
