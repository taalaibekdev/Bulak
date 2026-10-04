import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/pin_code.dart';
import '../../state/settings_controller.dart';
import '../widgets/common.dart';
import '../widgets/pin_pad.dart';

/// Безопасность: PIN-код, замочек в плеере, видимость разделов.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const SecurityPage());

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.securityTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _Card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.password_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(strings.securityChangePin),
              subtitle: Text(
                '${AppConfig.pinLength} · ${strings.parentSetupBody}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(ChangePinPage.route()),
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.kidLockEnabled,
                  onChanged: controller.setKidLock,
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.securityKidLock),
                  subtitle: Text(strings.securityKidLockBody),
                  secondary: Icon(
                    Icons.lock_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.showFavorites,
                  onChanged: controller.setShowFavorites,
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.securityHideFavorites),
                  secondary: Icon(
                    Icons.favorite_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.showHistory,
                  onChanged: controller.setShowHistory,
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.securityHideHistory),
                  secondary: Icon(
                    Icons.history_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

/// Смена PIN-кода: текущий → новый → подтверждение.
class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ChangePinPage());

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

enum _Step { current, fresh, repeat }

class _ChangePinPageState extends State<ChangePinPage> {
  _Step _step = _Step.current;
  String? _newCode;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    final (emoji, title, subtitle) = switch (_step) {
      _Step.current => ('🔒', strings.securityCurrentPin, null),
      _Step.fresh => ('🔐', strings.securityNewPin, strings.parentSetupBody),
      _Step.repeat => ('🔁', strings.parentSetupRepeat, null),
    };

    return Scaffold(
      appBar: AppBar(title: Text(strings.securityChangePin)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PinPad(
              // Каждый шаг смены PIN-кода начинается с чистого ввода.
              key: ValueKey<_Step>(_step),
              emoji: emoji,
              title: title,
              subtitle: subtitle,
              errorText: _error,
              length: AppConfig.pinLength,
              onCompleted: _handle,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handle(String code) async {
    final strings = AppStrings.of(context);
    final controller = context.read<SettingsController>();

    switch (_step) {
      case _Step.current:
        if (!controller.verifyPin(code)) {
          setState(() => _error = strings.parentGateWrong);
          return;
        }
        setState(() {
          _step = _Step.fresh;
          _error = null;
        });
      case _Step.fresh:
        if (PinCode.isWeak(code)) {
          setState(() => _error = strings.parentSetupTrivial);
          return;
        }
        setState(() {
          _newCode = code;
          _step = _Step.repeat;
          _error = null;
        });
      case _Step.repeat:
        if (_newCode != code) {
          setState(() {
            _newCode = null;
            _step = _Step.fresh;
            _error = strings.parentSetupMismatch;
          });
          return;
        }
        await controller.setPin(code);
        if (!mounted) return;
        Navigator.of(context).pop();
        showAppSnack(
          context,
          strings.securityPinChanged,
          icon: Icons.check_circle_rounded,
        );
    }
  }
}
