import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin synchronous wrapper around SharedPreferences.
/// Initialised once in main() before the widget tree is created.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;
  static StorageService? _instance;
  static const String stateKey = 'instagram_clone_state_v1';

  static Future<void> init() async {
    _instance ??= StorageService._(await SharedPreferences.getInstance());
  }

  static StorageService get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('StorageService.init() must be called in main() first.');
    }
    return instance;
  }

  Map<String, dynamic>? readState() {
    final raw = _prefs.getString(stateKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeState(Map<String, dynamic> data) =>
      _prefs.setString(stateKey, jsonEncode(data));

  Future<void> clear() => _prefs.remove(stateKey);
}
