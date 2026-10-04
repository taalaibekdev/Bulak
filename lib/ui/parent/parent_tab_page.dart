import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/pin_code.dart';
import '../../state/library_controller.dart';
import '../../state/settings_controller.dart';
import '../shell/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/pin_pad.dart';
import 'about_page.dart';
import 'add_video_page.dart';
import 'appearance_page.dart';
import 'manage_collections_page.dart';
import 'manage_videos_page.dart';
import 'security_page.dart';
import 'time_limit_page.dart';

/// Вкладка «Родителям».
///
/// Пока PIN не настроен — предлагаем его придумать. Пока не введён верный
/// код — показываем только цифровую клавиатуру. И лишь после этого открываем
/// управление библиотекой.
class ParentTabPage extends StatefulWidget {
  const ParentTabPage({super.key});

  @override
  State<ParentTabPage> createState() => _ParentTabPageState();
}

class _ParentTabPageState extends State<ParentTabPage> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    Widget body;
    if (!settings.hasPin) {
      body = _PinSetupFlow(onDone: () => setState(() => _unlocked = true));
    } else if (!_unlocked) {
      body = _PinGate(onUnlocked: () => setState(() => _unlocked = true));
    } else {
      body = _ParentHome(onLock: () => setState(() => _unlocked = false));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(bottom: false, child: body),
    );
  }
}

/// Первичная настройка PIN-кода: ввод и подтверждение.
class _PinSetupFlow extends StatefulWidget {
  const _PinSetupFlow({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_PinSetupFlow> createState() => _PinSetupFlowState();
}

class _PinSetupFlowState extends State<_PinSetupFlow> {
  String? _firstCode;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isRepeat = _firstCode != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, kShellBottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: PinPad(
            emoji: isRepeat ? '🔁' : '🔐',
            title: isRepeat
                ? strings.parentSetupRepeat
                : strings.parentSetupTitle,
            subtitle: isRepeat ? null : strings.parentSetupBody,
            errorText: _error,
            length: AppConfig.pinLength,
            onCompleted: _handleCode,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCode(String code) async {
    final strings = AppStrings.of(context);
    final settings = context.read<SettingsController>();

    if (_firstCode == null) {
      if (PinCode.isWeak(code)) {
        setState(() => _error = strings.parentSetupTrivial);
        return;
      }
      setState(() {
        _firstCode = code;
        _error = null;
      });
      return;
    }

    if (_firstCode != code) {
      setState(() {
        _firstCode = null;
        _error = strings.parentSetupMismatch;
      });
      return;
    }

    await settings.setPin(code);
    if (!mounted) return;
    showAppSnack(context, strings.onboardPinDone, icon: Icons.check_rounded);
    widget.onDone();
  }
}

/// Ввод PIN-кода для входа в родительский режим.
class _PinGate extends StatefulWidget {
  const _PinGate({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, kShellBottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: PinPad(
            emoji: '🔒',
            title: strings.parentGateTitle,
            subtitle: strings.parentGateBody,
            errorText: _error,
            length: AppConfig.pinLength,
            onCompleted: (code) {
              final settings = context.read<SettingsController>();
              if (settings.verifyPin(code)) {
                widget.onUnlocked();
                return;
              }
              setState(() => _error = strings.parentGateWrong);
            },
          ),
        ),
      ),
    );
  }
}

/// Содержимое родительского режима.
class _ParentHome extends StatelessWidget {
  const _ParentHome({required this.onLock});

  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final library = context.watch<LibraryController>();
    final settings = context.watch<SettingsController>().settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kShellBottomInset),
      children: [
        Text(strings.parentTitle, style: theme.textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          strings.parentHelloBody,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        _PrimaryTile(
          title: strings.parentAddVideo,
          subtitle: strings.parentAddVideoSubtitle,
          icon: Icons.add_rounded,
          onTap: () => Navigator.of(context).push(AddVideoPage.route()),
        ),
        const SizedBox(height: 12),
        _Tile(
          title: strings.parentMyVideos,
          subtitle: strings.videosCount(library.videoCount),
          icon: Icons.video_library_rounded,
          onTap: () => Navigator.of(context).push(ManageVideosPage.route()),
        ),
        const SizedBox(height: 12),
        _Tile(
          title: strings.collectionsTitle,
          subtitle: strings.videosCount(library.collections.length),
          icon: Icons.folder_copy_rounded,
          onTap: () =>
              Navigator.of(context).push(ManageCollectionsPage.route()),
        ),
        const SizedBox(height: 12),
        _Tile(
          title: strings.parentTimeLimit,
          subtitle: settings.hasDailyLimit
              ? strings.timeLimitMinutes(settings.dailyLimitMinutes)
              : strings.timeLimitUnlimited,
          icon: Icons.timer_rounded,
          onTap: () => Navigator.of(context).push(TimeLimitPage.route()),
        ),
        const SizedBox(height: 12),
        _Tile(
          title: strings.parentSecurity,
          subtitle: strings.parentSecuritySubtitle,
          icon: Icons.shield_rounded,
          onTap: () => Navigator.of(context).push(SecurityPage.route()),
        ),
        const SizedBox(height: 12),
        _Tile(
          title: strings.parentAppearance,
          subtitle: strings.parentAppearanceSubtitle,
          icon: Icons.palette_rounded,
          onTap: () => Navigator.of(context).push(AppearancePage.route()),
        ),
        const SizedBox(height: 12),
        _Tile(
          title: strings.parentAbout,
          subtitle: '${strings.aboutVersion} 1.0.0',
          icon: Icons.info_rounded,
          onTap: () => Navigator.of(context).push(AboutPage.route()),
        ),
        const SizedBox(height: 26),
        OutlinedButton.icon(
          onPressed: onLock,
          icon: const Icon(Icons.lock_rounded),
          label: Text(strings.parentExit),
        ),
      ],
    );
  }
}

/// Главная кнопка родительского экрана — добавление видео.
class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2AD1FF), Color(0xFF2A6BFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A6BFF).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Обычная строка-раздел родительского экрана.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
