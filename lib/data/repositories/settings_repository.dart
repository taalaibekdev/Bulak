import '../models/app_settings.dart';
import '../storage/key_value_store.dart';

/// Чтение и запись настроек приложения.
class SettingsRepository {
  SettingsRepository(this._store);

  final KeyValueStore _store;

  static const String storageKey = 'bulak.settings.v1';

  /// Загружает настройки и сразу обнуляет дневной счётчик, если наступил
  /// новый день.
  Future<AppSettings> load() async {
    final settings = AppSettings.fromJson(_store.readMap(storageKey))
        .normalized();
    // Если день сменился, сохраняем обнулённый счётчик, чтобы он не
    // «переехал» на следующие сутки.
    final stored = _store.readMap(storageKey);
    if (stored != null && stored['dayKey'] != settings.dayKey) {
      await save(settings);
    }
    return settings;
  }

  Future<void> save(AppSettings settings) =>
      _store.writeJson(storageKey, settings.toJson());

  Future<void> clear() => _store.remove(storageKey);
}
