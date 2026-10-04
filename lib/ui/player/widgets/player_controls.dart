import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// Управление плеером для маленького зрителя.
///
/// Задача — чтобы ребёнок 3–10 лет разобрался без подсказок: крупная
/// центральная кнопка, две понятные кнопки перемотки и минимум мелочей.
/// Размеры подстраиваются под высоту: в портретной ориентации панель
/// помещается в небольшую область с видео, в полный экран — становится
/// крупнее.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.title,
    required this.visible,
    required this.isPlaying,
    required this.isLocked,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekBy,
    required this.onToggleLock,
    required this.onExit,
    required this.onToggleFullscreen,
    required this.isFullscreen,
    required this.showLockButton,
    this.onLockedTap,
    this.isBuffering = false,
    this.extraActions,
    this.showFullscreenButton = true,
  });

  final String title;
  final bool visible;
  final bool isPlaying;
  final bool isLocked;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<int> onSeekBy;
  final VoidCallback onToggleLock;
  final VoidCallback onExit;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final bool showLockButton;
  final VoidCallback? onLockedTap;
  final bool isBuffering;
  final List<Widget>? extraActions;
  final bool showFullscreenButton;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // В узкой области (видео сверху в портретной ориентации) прячем
        // второстепенное, чтобы ничего не наезжало друг на друга.
        final compact = constraints.maxHeight < 340;

        return AnimatedOpacity(
          opacity: visible || isLocked ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: IgnorePointer(
            ignoring: !visible && !isLocked,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      title: title,
                      isLocked: isLocked,
                      compact: compact,
                      onExit: onExit,
                      onToggleLock: onToggleLock,
                      showLockButton: showLockButton,
                      lockTooltip: isLocked
                          ? strings.playerUnlock
                          : strings.playerLock,
                    ),
                    Expanded(
                      child: isLocked
                          ? _LockedLayer(
                              message: strings.playerLockedHint,
                              onUnlock: onLockedTap ?? onToggleLock,
                              unlockLabel: strings.playerUnlock,
                              compact: compact,
                            )
                          : _CenterControls(
                              isPlaying: isPlaying,
                              isBuffering: isBuffering,
                              compact: compact,
                              onPlayPause: onPlayPause,
                              onSeekBy: onSeekBy,
                              backLabel: strings.playerSecondsBack,
                              forwardLabel: strings.playerSecondsForward,
                            ),
                    ),
                    if (!isLocked)
                      _BottomBar(
                        position: position,
                        duration: duration,
                        compact: compact,
                        isFullscreen: isFullscreen,
                        showFullscreenButton: showFullscreenButton,
                        onSeek: onSeek,
                        onToggleFullscreen: onToggleFullscreen,
                        extraActions: compact ? null : extraActions,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isLocked,
    required this.compact,
    required this.onExit,
    required this.onToggleLock,
    required this.showLockButton,
    required this.lockTooltip,
  });

  final String title;
  final bool isLocked;
  final bool compact;
  final VoidCallback onExit;
  final VoidCallback onToggleLock;
  final bool showLockButton;
  final String lockTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(6, compact ? 2 : 6, 6, 0),
      child: Row(
        children: [
          _CircleAction(
            icon: Icons.arrow_back_rounded,
            tooltip: AppStrings.of(context).playerExit,
            size: compact ? 36 : 46,
            onTap: onExit,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 13 : 16,
              ),
            ),
          ),
          if (showLockButton) ...[
            const SizedBox(width: 8),
            _CircleAction(
              icon: isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              tooltip: lockTooltip,
              size: compact ? 36 : 46,
              onTap: onToggleLock,
              highlighted: isLocked,
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.highlighted = false,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool highlighted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: highlighted
          ? AppColors.sunny
          : Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: highlighted ? AppColors.midnight : Colors.white,
            size: size * 0.52,
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _CenterControls extends StatelessWidget {
  const _CenterControls({
    required this.isPlaying,
    required this.isBuffering,
    required this.compact,
    required this.onPlayPause,
    required this.onSeekBy,
    required this.backLabel,
    required this.forwardLabel,
  });

  final bool isPlaying;
  final bool isBuffering;
  final bool compact;
  final VoidCallback onPlayPause;
  final ValueChanged<int> onSeekBy;
  final String backLabel;
  final String forwardLabel;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 12.0 : 22.0;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SeekButton(
            icon: Icons.replay_10_rounded,
            label: backLabel,
            size: compact ? 46 : 62,
            onTap: () => onSeekBy(-10),
          ),
          SizedBox(width: gap),
          _PlayButton(
            isPlaying: isPlaying,
            isBuffering: isBuffering,
            size: compact ? 62 : 84,
            onTap: onPlayPause,
          ),
          SizedBox(width: gap),
          _SeekButton(
            icon: Icons.forward_10_rounded,
            label: forwardLabel,
            size: compact ? 46 : 62,
            onTap: () => onSeekBy(10),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.size,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isBuffering;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black54,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: isBuffering
              ? Padding(
                  padding: EdgeInsets.all(size * 0.3),
                  child: const CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: size * 0.62,
                  color: AppColors.midnight,
                ),
        ),
      ),
    );
  }
}

class _SeekButton extends StatelessWidget {
  const _SeekButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.54, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _LockedLayer extends StatelessWidget {
  const _LockedLayer({
    required this.message,
    required this.onUnlock,
    required this.unlockLabel,
    required this.compact,
  });

  final String message;
  final VoidCallback onUnlock;
  final String unlockLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: TextButton.icon(
          onPressed: onUnlock,
          icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
          label: Text(unlockLabel, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.white70, size: 46),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onUnlock,
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(unlockLabel),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.position,
    required this.duration,
    required this.compact,
    required this.isFullscreen,
    required this.showFullscreenButton,
    required this.onSeek,
    required this.onToggleFullscreen,
    this.extraActions,
  });

  final Duration position;
  final Duration duration;
  final bool compact;
  final bool isFullscreen;
  final bool showFullscreenButton;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onToggleFullscreen;
  final List<Widget>? extraActions;

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
    final value = position.inMilliseconds.clamp(0, total).toDouble();

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, compact ? 2 : 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _TimeLabel(text: Formatters.duration(position), compact: compact),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: compact ? 6 : 8,
                    activeTrackColor: AppColors.sunny,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: compact ? 7 : 9,
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: compact ? 14 : 20,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    max: total.toDouble(),
                    onChanged: (raw) =>
                        onSeek(Duration(milliseconds: raw.round())),
                  ),
                ),
              ),
              _TimeLabel(text: Formatters.duration(duration), compact: compact),
            ],
          ),
          if (extraActions != null && extraActions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: extraActions!,
              ),
            ),
          if (showFullscreenButton)
            Align(
              alignment: Alignment.centerRight,
              child: _CircleAction(
                icon: isFullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                size: compact ? 36 : 46,
                onTap: onToggleFullscreen,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 12 : 13,
        ),
      ),
    );
  }
}
