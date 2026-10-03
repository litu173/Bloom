import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny JSON persistence layer over SharedPreferences.
/// Mirrors the web app's storage.ts so state shape/behavior stays familiar.
class StorageService {
  static const _prefix = 'bloom-alarm:';
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  T load<T>(String key, T fallback, T Function(dynamic json) fromJson) {
    try {
      final raw = _prefs.getString(_prefix + key);
      if (raw == null) return fallback;
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return fallback;
    }
  }

  Future<void> save<T>(String key, dynamic value) async {
    try {
      await _prefs.setString(_prefix + key, jsonEncode(value));
    } catch (_) {
      /* ignore quota/availability errors */
    }
  }

  Set<String> loadSet(String key, Set<String> Function() fallback) {
    final list = load<List<dynamic>?>(key, null, (j) => j as List<dynamic>?);
    return list != null ? list.map((e) => e as String).toSet() : fallback();
  }

  Future<void> saveSet(String key, Set<String> value) => save(key, value.toList());
}
