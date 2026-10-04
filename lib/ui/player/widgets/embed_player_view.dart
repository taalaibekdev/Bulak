import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/youtube_link.dart';

/// Запасной способ воспроизведения — официальный встроенный плеер YouTube.
///
/// Он нужен, когда YouTube не отдаёт прямой поток. Качество здесь выше,
/// но YouTube может показать собственную рекламу, о чём родителю сказано
/// в настройках.
class EmbedPlayerView extends StatefulWidget {
  const EmbedPlayerView({
    super.key,
    required this.videoId,
    this.onExternalNavigationBlocked,
  });

  final String videoId;

  /// Вызывается, когда плеер пытается уйти на посторонний сайт.
  final VoidCallback? onExternalNavigationBlocked;

  @override
  State<EmbedPlayerView> createState() => _EmbedPlayerViewState();
}

class _EmbedPlayerViewState extends State<EmbedPlayerView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  /// Домены, внутри которых встроенному плееру разрешено перемещаться.
  static const List<String> _allowedHosts = [
    'youtube.com',
    'youtube-nocookie.com',
    'ytimg.com',
    'googlevideo.com',
    'google.com',
    'gstatic.com',
    'doubleclick.net',
  ];

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _load();
  }

  WebViewController _createController() {
    // На iOS запрещаем WebKit требовать «жест» для запуска медиа,
    // иначе автозапуск видео не сработает.
    final PlatformWebViewControllerCreationParams params =
        Platform.isIOS || Platform.isMacOS
        ? WebKitWebViewControllerCreationParams(
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
            allowsInlineMediaPlayback: true,
          )
        : const PlatformWebViewControllerCreationParams();

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || !error.isForMainFrame!) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host ?? '';
            final allowed = _allowedHosts.any(host.endsWith);
            if (!allowed) {
              widget.onExternalNavigationBlocked?.call();
            }
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );

    // На Android автозапуск тоже нужно разрешить явно.
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    return controller;
  }

  void _load() {
    _controller.loadRequest(Uri.parse(YouTubeLink.embedUrl(widget.videoId)));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading && !_hasError)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_hasError) _EmbedError(onRetry: _load),
        ],
      ),
    );
  }
}

class _EmbedError extends StatelessWidget {
  const _EmbedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ColoredBox(
      color: AppColors.midnight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                strings.playerErrorTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.playerErrorBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.actionRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
