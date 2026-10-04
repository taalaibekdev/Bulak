import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../state/settings_controller.dart';
import '../../widgets/pin_pad.dart';

/// Спрашивает PIN-код родителя перед «взрослым» действием.
///
/// Возвращает `true`, только если код верный. Если PIN ещё не настроен,
/// сразу возвращает `false`: значит, приложение не настроено.
Future<bool> askParentPin(
  BuildContext context, {
  String? title,
  String? subtitle,
  String emoji = '🔒',
}) async {
  final settings = context.read<SettingsController>();
  if (!settings.hasPin) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _PinDialog(title: title, subtitle: subtitle, emoji: emoji),
  );
  return result ?? false;
}

/// Проверяет код без диалога — для случаев, когда нужен только факт.
bool verifyParentPin(BuildContext context, String code) =>
    context.read<SettingsController>().verifyPin(code);

class _PinDialog extends StatefulWidget {
  const _PinDialog({this.title, this.subtitle, this.emoji = '🔒'});

  final String? title;
  final String? subtitle;
  final String emoji;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PinPad(
                emoji: widget.emoji,
                title: widget.title ?? strings.parentGateTitle,
                subtitle: widget.subtitle ?? strings.parentGateBody,
                errorText: _error,
                onCompleted: (code) {
                  final controller = context.read<SettingsController>();
                  if (controller.verifyPin(code)) {
                    Navigator.of(context).pop(true);
                    return;
                  }
                  setState(() => _error = strings.parentGateWrong);
                },
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.actionCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
