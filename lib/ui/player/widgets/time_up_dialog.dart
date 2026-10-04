import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';

/// Диалог «На сегодня всё» — показывается, когда исчерпан дневной лимит.
///
/// Формулировка намеренно добрая: ребёнок не должен чувствовать, что его
/// наказывают, — ограничение поставили родители.
Future<void> showTimeUpDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const TimeUpDialog(),
  );
}

class TimeUpDialog extends StatelessWidget {
  const TimeUpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌙', style: TextStyle(fontSize: 62)),
            const SizedBox(height: 18),
            Text(
              strings.timeUpTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              strings.timeUpBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(strings.timeUpButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
