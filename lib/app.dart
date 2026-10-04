import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'data/models/app_settings.dart';
import 'data/services/download_service.dart';
import 'data/services/youtube_service.dart';
import 'state/download_controller.dart';
import 'state/library_controller.dart';
import 'state/settings_controller.dart';
import 'ui/onboarding/onboarding_page.dart';
import 'ui/shell/app_shell.dart';

/// Корневой виджет приложения.
class BulakApp extends StatelessWidget {
  const BulakApp({
    super.key,
    required this.settings,
    required this.library,
    required this.youtube,
    this.downloads,
    this.downloadController,
  });

  final SettingsController settings;
  final LibraryController library;
  final YouTubeService youtube;

  /// Сервис загрузок. Необязателен: в тестах интерфейса он не нужен.
  final DownloadService? downloads;

  /// Очередь загрузок. Необязательна по той же причине.
  final DownloadController? downloadController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<LibraryController>.value(value: library),
        Provider<YouTubeService>.value(value: youtube),
        if (downloads != null)
          Provider<DownloadService>.value(value: downloads!),
        if (downloadController != null)
          ChangeNotifierProvider<DownloadController>.value(
            value: downloadController!,
          ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settingsController, _) {
          final state = settingsController.settings;
          return MaterialApp(
            title: AppConfig.displayName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeMode(state.themeChoice),
            locale: _locale(state.localeCode),
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // Ограничиваем системный масштаб шрифта: при «гигантском»
              // размере текста интерфейс для ребёнка разваливается.
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.3,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _RootGate(),
          );
        },
      ),
    );
  }

  static ThemeMode _themeMode(AppThemeChoice choice) {
    switch (choice) {
      case AppThemeChoice.light:
        return ThemeMode.light;
      case AppThemeChoice.dark:
        return ThemeMode.dark;
      case AppThemeChoice.system:
        return ThemeMode.system;
    }
  }

  static Locale? _locale(String? code) {
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }
}

/// Первый запуск показывает мастер настройки, дальше — обычный интерфейс.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final completed = context.select<SettingsController, bool>(
      (controller) => controller.settings.onboardingCompleted,
    );
    if (!completed) return const OnboardingPage();
    return const AppShell();
  }
}
