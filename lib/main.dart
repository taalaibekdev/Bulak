import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'data/repositories/library_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/download_service.dart';
import 'data/services/youtube_service.dart';
import 'data/storage/key_value_store.dart';
import 'state/download_controller.dart';
import 'state/library_controller.dart';
import 'state/settings_controller.dart';

/// Точка входа приложения «Булак».
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Портрет — основной режим, но плеер должен уметь разворачиваться.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Хранилище: если плагин по какой-то причине недоступен, приложение всё
  // равно должно открыться — тогда работаем в памяти.
  KeyValueStore store;
  try {
    store = await SharedPreferencesStore.open();
  } catch (_) {
    store = InMemoryStore();
  }

  final settings = SettingsController(repository: SettingsRepository(store));
  final youtube = YouTubeService();
  final downloads = DownloadService(source: youtube);
  final library = LibraryController(
    repository: LibraryRepository(store),
    youtube: youtube,
  );
  final downloadController = DownloadController(
    service: downloads,
    library: library,
  );

  await settings.load();
  await library.load();
  // Если файлы загрузок пропали (например, очистили данные приложения),
  // снимаем отметки «скачано», иначе плеер будет искать несуществующий файл.
  await downloadController.reconcileWithDisk();

  runApp(
    BulakApp(
      settings: settings,
      library: library,
      youtube: youtube,
      downloads: downloads,
      downloadController: downloadController,
    ),
  );
}

/// Имя приложения для системных диалогов.
const String kAppTitle = AppConfig.displayName;

/// Стиль системных панелей под текущую тему.
SystemUiOverlayStyle systemOverlayStyleFor(Brightness brightness) {
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
    statusBarBrightness: brightness == Brightness.dark
        ? Brightness.dark
        : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
  );
}
