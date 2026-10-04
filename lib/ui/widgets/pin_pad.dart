import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Ввод PIN-кода: крупные кнопки, точки вместо цифр и «дрожание» при ошибке.
///
/// Экран рассчитан на взрослого, но выглядит в стиле приложения — те же
/// скругления и градиент, что и везде.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onCompleted,
    this.subtitle,
    this.errorText,
    this.length = 4,
    this.emoji = '🔒',
    this.footer,
    this.busy = false,
  });

  final String title;
  final String? subtitle;

  /// Текст ошибки. Как только он меняется, ввод очищается и поле дрожит.
  final String? errorText;

  final int length;
  final String emoji;
  final Widget? footer;
  final bool busy;

  /// Вызывается, когда введено [length] цифр.
  final ValueChanged<String> onCompleted;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _value = '';
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != null && widget.errorText != oldWidget.errorText) {
      _value = '';
      _shakeController.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _append(String digit) {
    if (widget.busy || _value.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() => _value += digit);
    if (_value.length == widget.length) {
      final code = _value;
      // Даём точке отрисоваться до того, как родитель увидит следующий экран.
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted) widget.onCompleted(code);
      });
    }
  }

  void _backspace() {
    if (_value.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: 26),
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final progress = _shakeController.value;
            final offset = hasError
                ? 10 * (1 - progress) * _wave(progress)
                : 0.0;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: _Dots(
            length: widget.length,
            filled: _value.length,
            hasError: hasError,
          ),
        ),
        SizedBox(
          height: 34,
          child: widget.errorText == null
              ? null
              : Center(
                  child: Text(
                    widget.errorText!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: _Keypad(
            enabled: !widget.busy,
            onDigit: _append,
            onBackspace: _backspace,
            onClear: () {
              if (_value.isEmpty) return;
              HapticFeedback.selectionClick();
              setState(() => _value = '');
            },
          ),
        ),
        if (widget.footer != null) ...[
          const SizedBox(height: 18),
          widget.footer!,
        ],
      ],
    );
  }

  /// Пилообразная волна для эффекта дрожания.
  static double _wave(double t) {
    if (t < 0.2) return 1;
    if (t < 0.4) return -1;
    if (t < 0.6) return 1;
    if (t < 0.8) return -0.7;
    return 0.4;
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.length,
    required this.filled,
    required this.hasError,
  });

  final int length;
  final int filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: isFilled ? 20 : 18,
          height: isFilled ? 20 : 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isFilled ? AppColors.brandGradient : null,
            color: isFilled
                ? null
                : hasError
                ? theme.colorScheme.error.withValues(alpha: 0.25)
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.enabled,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: key.isEmpty
                        ? const SizedBox(height: 62)
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _KeyButton(
                              label: key,
                              enabled: enabled,
                              onTap: key == 'del'
                                  ? onBackspace
                                  : () => onDigit(key),
                              onLongPress: key == 'del' ? onClear : null,
                            ),
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    required this.enabled,
    this.onLongPress,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelete = label == 'del';
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: SizedBox(
          height: 62,
          child: Center(
            child: isDelete
                ? Icon(
                    Icons.backspace_outlined,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : Text(
                    label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
