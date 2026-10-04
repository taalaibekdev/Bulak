import 'package:bulak/core/l10n/app_strings.dart';
import 'package:bulak/core/theme/app_theme.dart';
import 'package:bulak/data/repositories/library_repository.dart';
import 'package:bulak/data/services/youtube_service.dart';
import 'package:bulak/data/storage/key_value_store.dart';
import 'package:bulak/state/library_controller.dart';
import 'package:bulak/ui/parent/add_video_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Заглушка вместо сети: сведения о видео не нужны, проверяем интерфейс.
class _OfflineYoutube implements VideoMetadataSource {
  @override
  Future<VideoMetadata?> fetchMetadata(String videoId) async => null;
}

void main() {
  late InMemoryStore store;
  late LibraryController library;

  setUp(() {
    store = InMemoryStore();
    library = LibraryController(
      repository: LibraryRepository(store),
      youtube: _OfflineYoutube(),
    );
  });

  tearDown(() => library.dispose());

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(420, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await library.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<LibraryController>.value(
        value: library,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ru'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AddVideoPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('пустая страница показывает подсказку и кнопку «Вставить»', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Добавить видео'), findsOneWidget);
    expect(find.text('Вставить'), findsWidgets);
    expect(find.textContaining('Instance of'), findsNothing);
  });

  testWidgets(
    'после вставки ссылки появляется предпросмотр и кнопка добавления',
    (tester) async {
      // Экран повыше, чтобы кнопка внизу списка была построена без прокрутки:
      // именно её подпись мы и проверяем.
      await pumpPage(tester, size: const Size(420, 1600));

      await tester.enterText(
        find.byType(TextField),
        'https://youtu.be/aaaaaaaaaaa',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Главная проверка: в интерфейс не попадает текст вида
      // «Instance of 'AppStrings'» — так выглядит ошибка в интерполяции строк.
      expect(find.textContaining('Instance of'), findsNothing);
      expect(find.text('Так увидит ребёнок'), findsOneWidget);
      expect(find.text('1 видео'), findsOneWidget);

      // Кнопка добавления подписана «Добавить · 1».
      expect(find.textContaining('Добавить · 1'), findsOneWidget);
      expect(find.textContaining('Instance of'), findsNothing);
    },
  );

  testWidgets('непонятный текст помечается как некорректная ссылка', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'просто текст');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Это не похоже на ссылку YouTube'),
      findsOneWidget,
    );
  });

  testWidgets('повторная ссылка помечается как уже добавленная', (
    tester,
  ) async {
    await library.addVideos([
      const VideoDraft(id: 'aaaaaaaaaaa', title: 'Уже в библиотеке'),
    ]);
    await pumpPage(tester);

    await tester.enterText(
      find.byType(TextField),
      'https://youtu.be/aaaaaaaaaaa',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('уже есть в библиотеке'), findsOneWidget);
  });
}
