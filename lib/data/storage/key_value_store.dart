import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Минимальный интерфейс хранилища «ключ → строка».
///
/// Благодаря ему репозитории можно тестировать без платформенных плагинов:
/// в тестах подставляется [InMemoryStore].
abstract class KeyValueStore {
  String? read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);

  /// Полное удаление всех данных приложения.
  Future<void> clear();
}

/// Хранилище поверх `shared_preferences` — то, что используется в приложении.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesStore> open() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  @override
  String? read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> clear() => _preferences.clear();
}

/// Хранилище в памяти: используется в тестах.
class InMemoryStore implements KeyValueStore {
  InMemoryStore([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }

  /// Показать содержимое — удобно в отладочных тестах.
  Map<String, String> get values => Map.unmodifiable(_values);
}

/// Помощники для чтения и записи JSON в хранилище.
extension KeyValueStoreJson on KeyValueStore {
  Map<String, dynamic>? readMap(String key) {
    final raw = read(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  List<dynamic> readList(String key) {
    final raw = read(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> writeJson(String key, Object value) =>
      write(key, jsonEncode(value));
}
