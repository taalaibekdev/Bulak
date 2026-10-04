import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pin_code.dart';
import '../../state/settings_controller.dart';
import '../parent/add_video_page.dart';
import '../widgets/pin_pad.dart';

/// Первый запуск: коротко объясняем идею, создаём PIN и предлагаем сразу
/// добавить первое видео — чтобы родитель не остался с пустым экраном.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

enum _Step { welcome, createPin, repeatPin }

class _OnboardingPageState extends State<OnboardingPage> {
  _Step _step = _Step.welcome;
  String? _code;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Градиент обязан закрывать весь экран: SizedBox.expand задаёт жёсткие
      // ограничения, иначе DecoratedBox сжимается по высоте содержимого
      // и снизу проступает фон Scaffold.
      backgroundColor: AppColors.violet,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: SafeArea(
            child: switch (_step) {
              _Step.welcome => _WelcomeStep(onStart: _goToPin),
              _Step.createPin => _pinStep(
                emoji: '🔐',
                title: AppStrings.of(context).parentSetupTitle,
                subtitle: AppStrings.of(context).parentSetupBody,
                step: AppStrings.of(context).onboardPinStep,
              ),
              _Step.repeatPin => _pinStep(
                emoji: '🔁',
                title: AppStrings.of(context).parentSetupRepeat,
                subtitle: null,
                step: AppStrings.of(context).onboardPinStep,
              ),
            },
          ),
        ),
      ),
    );
  }

  void _goToPin() => setState(() => _step = _Step.createPin);

  Widget _pinStep({
    required String emoji,
    required String title,
    required String? subtitle,
    required String step,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _step = _step == _Step.repeatPin
                        ? _Step.createPin
                        : _Step.welcome;
                    _error = null;
                  }),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    step,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: PinPad(
                  // Ключ зависит от шага: без него состояние клавиатуры
                  // сохраняется, введённые цифры «переезжают» на следующий
                  // шаг и блокируют ввод новых.
                  key: ValueKey<_Step>(_step),
                  emoji: emoji,
                  title: title,
                  subtitle: subtitle,
                  errorText: _error,
                  length: AppConfig.pinLength,
                  onCompleted: _handleCode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCode(String code) async {
    final strings = AppStrings.of(context);
    final settings = context.read<SettingsController>();

    if (_step == _Step.createPin) {
      if (PinCode.isWeak(code)) {
        setState(() => _error = strings.parentSetupTrivial);
        return;
      }
      setState(() {
        _code = code;
        _step = _Step.repeatPin;
        _error = null;
      });
      return;
    }

    if (_code != code) {
      setState(() {
        _code = null;
        _step = _Step.createPin;
        _error = strings.parentSetupMismatch;
      });
      return;
    }

    await settings.setPin(code);
    if (!mounted) return;

    // Сразу предлагаем добавить первое видео — это главное действие родителя.
    await Navigator.of(context).push(AddVideoPage.route());
    if (!mounted) return;
    await settings.completeOnboarding();
  }
}

/// Приветственный шаг с объяснением идеи приложения.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(38),
            ),
            alignment: Alignment.center,
            child: Text(strings.appName, style: AppTheme.brandStyle(size: 38)),
          ),
          const SizedBox(height: 26),
          Text(
            strings.onboardTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.onboardBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 30),
          _Bullet(text: strings.onboardBullet1),
          _Bullet(text: strings.onboardBullet2),
          _Bullet(text: strings.onboardBullet3),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blue,
                minimumSize: const Size.fromHeight(58),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(strings.onboardStart),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${strings.aboutVersion} 1.0.0 · ${AppConfig.applicationId}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
