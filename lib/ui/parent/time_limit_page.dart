import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';

/// Дневной лимит просмотра.
///
/// Лимит считается только во время воспроизведения видео: если ребёнок
/// просто листает карточки, время не тратится.
class TimeLimitPage extends StatelessWidget {
  const TimeLimitPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const TimeLimitPage());

  /// Допустимые значения лимита в минутах. Первое — «без ограничений».
  static const List<int> options = [0, 15, 20, 30, 45, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;

    final currentIndex = !options.contains(settings.dailyLimitMinutes)
        ? 0
        : options.indexOf(settings.dailyLimitMinutes);
    final limitSeconds = settings.dailyLimitMinutes * 60;
    final progress = limitSeconds == 0
        ? 0.0
        : (settings.watchedSecondsToday / limitSeconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(strings.timeLimitTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.hasDailyLimit
                      ? strings.timeLimitMinutes(settings.dailyLimitMinutes)
                      : strings.timeLimitUnlimited,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Slider(
                  value: currentIndex.toDouble(),
                  min: 0,
                  max: (options.length - 1).toDouble(),
                  divisions: options.length - 1,
                  label: options[currentIndex] == 0
                      ? strings.timeLimitUnlimited
                      : strings.timeLimitMinutes(options[currentIndex]),
                  onChanged: (value) =>
                      controller.setDailyLimit(options[value.round()]),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < options.length; index++)
                      ChoiceChip(
                        label: Text(
                          options[index] == 0 ? '∞' : '${options[index]} мин',
                        ),
                        selected: index == currentIndex,
                        onSelected: (_) =>
                            controller.setDailyLimit(options[index]),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.timeLimitTodayUsed,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: settings.isLimitReached
                        ? theme.colorScheme.error
                        : AppColors.mint,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  settings.hasDailyLimit
                      ? '${(settings.watchedSecondsToday / 60).floor()} / '
                            '${settings.dailyLimitMinutes} мин'
                      : '${(settings.watchedSecondsToday / 60).floor()} мин',
                  style: theme.textTheme.bodyMedium,
                ),
                if (settings.isLimitReached) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.nightlight_round,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.timeLimitExhausted,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await controller.resetTodayCounter();
                    if (!context.mounted) return;
                    showAppSnack(
                      context,
                      strings.timeLimitReset,
                      icon: Icons.refresh_rounded,
                    );
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(strings.timeLimitResetToday),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.timeLimitNote,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
