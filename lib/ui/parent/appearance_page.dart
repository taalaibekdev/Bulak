import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/models/app_settings.dart';
import '../../state/settings_controller.dart';

/// Внешний вид и язык: тема, язык интерфейса, режим воспроизведения.
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const AppearancePage());

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.appearanceTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _Section(
            title: strings.appearanceTheme,
            child: RadioGroup<AppThemeChoice>(
              groupValue: settings.themeChoice,
              onChanged: (value) {
                if (value != null) controller.setThemeChoice(value);
              },
              child: Column(
                children: [
                  for (final choice in AppThemeChoice.values)
                    RadioListTile<AppThemeChoice>(
                      value: choice,
                      title: Text(_themeLabel(strings, choice)),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: strings.appearanceLanguage,
            child: RadioGroup<String?>(
              groupValue: settings.localeCode,
              onChanged: controller.setLocaleCode,
              child: Column(
                children: [
                  RadioListTile<String?>(
                    value: null,
                    title: Text(strings.languageSystem),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String?>(
                    value: 'ru',
                    title: Text(strings.languageRussian),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String?>(
                    value: 'en',
                    title: Text(strings.languageEnglish),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: strings.playbackTitle,
            child: RadioGroup<PlaybackMode>(
              groupValue: settings.playbackMode,
              onChanged: (value) {
                if (value != null) controller.setPlaybackMode(value);
              },
              child: Column(
                children: [
                  for (final mode in PlaybackMode.values)
                    RadioListTile<PlaybackMode>(
                      value: mode,
                      title: Text(_playbackLabel(strings, mode)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 8,
                      left: 4,
                      right: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.playbackNote,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(AppStrings strings, AppThemeChoice choice) {
    switch (choice) {
      case AppThemeChoice.system:
        return strings.themeSystem;
      case AppThemeChoice.light:
        return strings.themeLight;
      case AppThemeChoice.dark:
        return strings.themeDark;
    }
  }

  static String _playbackLabel(AppStrings strings, PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.auto:
        return strings.playbackAuto;
      case PlaybackMode.direct:
        return strings.playbackDirect;
      case PlaybackMode.embed:
        return strings.playbackEmbed;
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
