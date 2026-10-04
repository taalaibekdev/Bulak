import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/playback_result.dart';
import '../../data/models/video_item.dart';
import '../../data/services/youtube_service.dart';
import '../../state/library_controller.dart';
import '../../state/settings_controller.dart';
import '../parent/widgets/pin_dialog.dart';
import '../widgets/common.dart';
import 'widgets/embed_player_view.dart';
import 'widgets/player_controls.dart';
import 'widgets/time_up_dialog.dart';

/// Экран просмотра видео.
///
/// Два режима:
/// * прямой поток — чистый экран без интерфейса и рекламы YouTube
///   (качество до 360p, как отдаёт сам YouTube);
/// * встроенный плеер YouTube — выше качество, но со своим интерфейсом.
///
/// Выбор режима хранится в настройках, а в режиме «автоматически»
/// приложение само переключается на встроенный плеер, если поток не отдался.
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.video});

  final VideoItem video;

  static Route<void> route(VideoItem video) => MaterialPageRoute<void>(
    builder: (_) => PlayerPage(video: video),
    fullscreenDialog: true,
  );

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

enum _PlayerMode { direct, embed }

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  late _PlayerMode _mode;
  bool _preparing = false;
  PlaybackFailureReason? _error;

  Timer? _ticker;
  Timer? _hideTimer;

  bool _controlsVisible = true;
  bool _locked = false;
  bool _fullscreen = false;
  bool _finished = false;
  bool _limitDialogShown = false;

  int _secondsSinceSave = 0;

  late SettingsController _settings;
  late LibraryController _library;
  late YouTubeService _youtube;

  VideoItem get _video => widget.video;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _settings = context.read<SettingsController>();
    _library = context.read<LibraryController>();
    _youtube = context.read<YouTubeService>();

    _mode = _settings.settings.playbackMode == PlaybackMode.embed
        ? _PlayerMode.embed
        : _PlayerMode.direct;

    if (_mode == _PlayerMode.direct) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareDirect());
    }
    _startTicker();
    _scheduleHide();

    // Если лимит уже исчерпан, не начинаем показ вовсе.
    if (_settings.isLimitReached) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleLimitReached(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
      _saveProgress();
      _settings.flushWatchTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _hideTimer?.cancel();
    _saveProgress();
    _settings.flushWatchTime();
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _restoreSystemUi();
    WakelockPlus.disable();
    super.dispose();
  }

  // --- Подготовка воспроизведения ---------------------------------------

  Future<void> _prepareDirect() async {
    setState(() {
      _preparing = true;
      _error = null;
    });

    final url = await _youtube.resolveStreamUrl(_video.id);
    if (!mounted) return;

    if (url == null) {
      await _handleFailure(PlaybackFailureReason.notPlayable);
      return;
    }

    final controller = VideoPlayerController.networkUrl(url);
    _controller = controller;
    controller.addListener(_onControllerChanged);

    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(false);

      final resume = Duration(seconds: _video.watchedSeconds);
      final total = controller.value.duration;
      if (resume > const Duration(seconds: 5) && resume < total) {
        await controller.seekTo(resume);
      }
      await controller.play();
      if (!mounted) return;
      setState(() => _preparing = false);
      await WakelockPlus.enable();
      _scheduleHide();
    } catch (_) {
      controller.removeListener(_onControllerChanged);
      await controller.dispose();
      _controller = null;
      if (!mounted) return;
      await _handleFailure(PlaybackFailureReason.playerError);
    }
  }

  /// Решает, что делать при неудаче: в авторежиме уходим на встроенный плеер.
  Future<void> _handleFailure(PlaybackFailureReason reason) async {
    final isAuto = _settings.settings.playbackMode == PlaybackMode.auto;
    if (isAuto && _mode == _PlayerMode.direct) {
      setState(() {
        _mode = _PlayerMode.embed;
        _preparing = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _preparing = false;
      _error = reason;
    });
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final value = controller.value;

    if (value.hasError && _error == null) {
      // Не переключаем автоматически: дадим родителю решить самому.
      setState(() => _error = PlaybackFailureReason.playerError);
      return;
    }

    if (!_finished &&
        value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 500)) {
      _finished = true;
      _library.markFinished(_video.id);
      _settings.flushWatchTime();
      setState(_showControls);
    }
  }

  // --- Таймер просмотра и лимит времени ---------------------------------

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final isPlaying = _mode == _PlayerMode.direct
          ? (_controller?.value.isPlaying ?? false)
          : true; // во встроенном плеере считаем время, пока экран открыт
      if (!isPlaying) return;

      _settings.addWatchedSeconds(1);
      _secondsSinceSave++;
      if (_secondsSinceSave >= 10) {
        _secondsSinceSave = 0;
        _saveProgress();
      }
      if (_settings.isLimitReached) _handleLimitReached();
    });
  }

  Future<void> _handleLimitReached() async {
    if (_limitDialogShown || !mounted) return;
    _limitDialogShown = true;
    _controller?.pause();
    _saveProgress();
    await _settings.flushWatchTime();
    if (!mounted) return;

    await showTimeUpDialog(context);
    if (mounted) Navigator.of(context).maybePop();
  }

  void _saveProgress() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final position = controller.value.position.inSeconds;
    if (position <= 0) return;
    _library.recordProgress(_video.id, positionSeconds: position);
  }

  // --- Управление --------------------------------------------------------

  void _showControls() {
    _controlsVisible = true;
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_locked || _finished) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      if (_controlsVisible) _scheduleHide();
    });
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      _saveProgress();
      _settings.flushWatchTime();
      _showControls();
    } else {
      if (_settings.isLimitReached) {
        await _handleLimitReached();
        return;
      }
      if (_finished) _finished = false;
      await controller.play();
      _scheduleHide();
    }
    if (mounted) setState(() {});
  }

  Future<void> _seekBy(int seconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final target = controller.value.position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > controller.value.duration
              ? controller.value.duration
              : target);
    await controller.seekTo(clamped);
    _showControls();
  }

  Future<void> _seekTo(Duration position) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.seekTo(position);
    if (_finished && position < controller.value.duration) {
      setState(() => _finished = false);
    }
    _showControls();
  }

  Future<void> _toggleLock() async {
    if (!_locked) {
      setState(() {
        _locked = true;
        _controlsVisible = true;
      });
      _hideTimer?.cancel();
      return;
    }
    final strings = AppStrings.of(context);
    final unlocked = await askParentPin(
      context,
      title: strings.playerUnlockTitle,
      subtitle: strings.parentGateBody,
      emoji: '🔓',
    );
    if (!mounted || !unlocked) return;
    setState(() {
      _locked = false;
      _controlsVisible = true;
    });
    _scheduleHide();
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _showControls();
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _playNext() async {
    final next = _library.nextAfter(_video);
    if (next == null) return;
    _saveProgress();
    if (!mounted) return;
    // Заменяем текущий экран, чтобы «Назад» возвращал в библиотеку,
    // а не перелистывал просмотренное.
    Navigator.of(context).pushReplacement(PlayerPage.route(next));
  }

  Future<void> _switchToEmbed() async {
    await _controller?.pause();
    _saveProgress();
    if (!mounted) return;
    setState(() {
      _mode = _PlayerMode.embed;
      _error = null;
      _finished = false;
      _controlsVisible = false;
      _hideTimer?.cancel();
    });
  }

  Future<void> _retryDirect() async {
    _controller?.removeListener(_onControllerChanged);
    await _controller?.dispose();
    _controller = null;
    _finished = false;
    if (!mounted) return;
    setState(() {
      _mode = _PlayerMode.direct;
      _error = null;
    });
    await _prepareDirect();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return PopScope(
      canPop: !_locked,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showAppSnack(
          context,
          strings.playerLockedHint,
          icon: Icons.lock_rounded,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _mode == _PlayerMode.embed
            ? _buildEmbed(strings)
            : _buildDirect(strings),
      ),
    );
  }

  Widget _buildEmbed(AppStrings strings) {
    return Stack(
      fit: StackFit.expand,
      children: [
        EmbedPlayerView(
          videoId: _video.id,
          onExternalNavigationBlocked: () {
            showAppSnack(
              context,
              strings.somethingWentWrong,
              icon: Icons.block_rounded,
            );
          },
        ),
        // Собственная панель поверх встроенного плеера: выход, замочек и
        // понятное название — чтобы ребёнок не потерялся в интерфейсе YouTube.
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    background: Colors.black.withValues(alpha: 0.45),
                    foreground: Colors.white,
                    tooltip: strings.playerExit,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_settings.settings.playbackMode == PlaybackMode.auto &&
                      _canOfferAdFree)
                    TextButton.icon(
                      onPressed: _retryDirect,
                      icon: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.sunny,
                      ),
                      label: Text(
                        strings.playerUseDirect,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _canOfferAdFree => true;

  Widget _buildDirect(AppStrings strings) {
    if (_preparing) {
      return _BlackMessage(
        title: strings.playerBufferring,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }

    final error = _error;
    if (error != null) {
      return _BlackMessage(
        title: strings.playerErrorTitle,
        body: strings.playerErrorBody,
        icon: error == PlaybackFailureReason.notPlayable
            ? Icons.videocam_off_rounded
            : Icons.wifi_off_rounded,
        actions: [
          FilledButton.icon(
            onPressed: _retryDirect,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.actionRetry),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _switchToEmbed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            icon: const Icon(Icons.ondemand_video_rounded),
            label: Text(strings.playerUseEmbed),
          ),
        ],
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _BlackMessage(
        title: strings.playerBufferring,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }

    final hasNext = _library.nextAfter(_video) != null;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final aspect = value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio;
        final isPortrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        // В портретной ориентации видео занимает верхнюю часть, а под ним
        // остаётся место для крупных кнопок — так удобнее малышу.
        final usePortraitLayout = isPortrait && !_fullscreen;

        Future<void> replay() async {
          await controller.seekTo(Duration.zero);
          if (!mounted) return;
          setState(() => _finished = false);
          await controller.play();
        }

        final finishedOverlay = _finished
            ? _FinishedOverlay(
                onReplay: replay,
                onNext: hasNext ? _playNext : null,
                canGoBack: true,
              )
            : const SizedBox.shrink();

        final controls = PlayerControls(
          title: usePortraitLayout ? '' : _video.title,
          visible: _controlsVisible,
          isPlaying: value.isPlaying,
          isLocked: _locked,
          position: value.position,
          duration: value.duration,
          isBuffering: value.isBuffering,
          showLockButton: _settings.settings.kidLockEnabled,
          isFullscreen: _fullscreen,
          showFullscreenButton: !usePortraitLayout,
          onPlayPause: _togglePlay,
          onSeek: _seekTo,
          onSeekBy: _seekBy,
          onToggleLock: _toggleLock,
          onExit: () => Navigator.of(context).maybePop(),
          onToggleFullscreen: _toggleFullscreen,
          onLockedTap: _toggleLock,
          extraActions: [
            if (_settings.settings.playbackMode == PlaybackMode.auto)
              _MiniAction(
                icon: Icons.ondemand_video_rounded,
                label: strings.playerUseEmbed,
                onTap: _switchToEmbed,
              ),
          ],
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _locked || _finished ? _showControls : _toggleControls,
          child: usePortraitLayout
              ? Column(
                  children: [
                    AspectRatio(
                      aspectRatio: aspect,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(controller),
                          finishedOverlay,
                          controls,
                        ],
                      ),
                    ),
                    Expanded(
                      child: _PortraitPanel(
                        video: _video,
                        onNext: hasNext ? _playNext : null,
                        onFullscreen: _toggleFullscreen,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: aspect,
                        child: VideoPlayer(controller),
                      ),
                    ),
                    finishedOverlay,
                    controls,
                  ],
                ),
        );
      },
    );
  }
}

/// Кнопка-«пилюля» на панели плеера.
class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Панель под видео в портретной ориентации: название и крупные кнопки.
class _PortraitPanel extends StatelessWidget {
  const _PortraitPanel({
    required this.video,
    required this.onFullscreen,
    this.onNext,
  });

  final VideoItem video;
  final VoidCallback onFullscreen;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (video.author != null) ...[
            const SizedBox(height: 8),
            Text(
              video.author!,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onFullscreen,
                icon: const Icon(Icons.fullscreen_rounded),
                label: Text(strings.playerFullscreen),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
              ),
              if (onNext != null)
                FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(strings.playerNext),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.midnight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Экран «видео закончилось».
class _FinishedOverlay extends StatelessWidget {
  const _FinishedOverlay({
    required this.onReplay,
    this.onNext,
    this.canGoBack = true,
  });

  final VoidCallback onReplay;
  final VoidCallback? onNext;
  final bool canGoBack;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(strings.playerReplay),
                ),
                if (onNext != null)
                  FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(strings.playerNext),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.midnight,
                    ),
                  ),
                if (canGoBack)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: Text(strings.playerExit),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Полноэкранное сообщение в плеере.
class _BlackMessage extends StatelessWidget {
  const _BlackMessage({
    required this.title,
    this.body,
    this.child,
    this.icon,
    this.actions = const [],
  });

  final String title;
  final String? body;
  final Widget? child;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, color: Colors.white70, size: 52)
              else
                ?child,
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    body!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
