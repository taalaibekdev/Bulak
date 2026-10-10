import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video_item.dart';
import '../../state/download_controller.dart';
import '../../state/library_controller.dart';
import '../widgets/thumbnail_image.dart';
import 'player_page.dart';

/// Экран подготовки видео к просмотру.
///
/// Приложение не играет видео из сети: сначала файл сохраняется на телефон,
/// и только потом запускается плеер. Так просмотр не обрывается на середине
/// из-за того, что ссылка на поток перестала работать.
///
/// Экран сам запускает загрузку, показывает прогресс и переходит к плееру,
/// как только файл готов. Ребёнку не нужно ничего нажимать.
class PrepareVideoPage extends StatefulWidget {
  const PrepareVideoPage({super.key, required this.video});

  final VideoItem video;

  static Route<void> route(VideoItem video) => MaterialPageRoute<void>(
    builder: (_) => PrepareVideoPage(video: video),
    fullscreenDialog: true,
  );

  @override
  State<PrepareVideoPage> createState() => _PrepareVideoPageState();
}

class _PrepareVideoPageState extends State<PrepareVideoPage> {
  bool _started = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDownloading());
  }

  /// Ставит видео в очередь, если оно ещё не скачано и не качается.
  void _ensureDownloading() {
    if (!mounted || _started) return;
    final library = context.read<LibraryController>();
    final downloads = context.read<DownloadController>();

    final video = library.byId(widget.video.id) ?? widget.video;
    if (video.isDownloaded) {
      _openPlayer();
      return;
    }

    final task = downloads.taskFor(video.id);
    if (task == null || task.state == DownloadState.failed) {
      downloads.enqueue(video);
    }
    _started = true;
    setState(() {});
  }

  void _openPlayer() {
    if (!mounted || _navigated) return;
    _navigated = true;
    // Берём свежую запись из библиотеки: в переданном объекте ещё нет
    // отметки о скачанном файле, а плееру она нужна, чтобы найти файл
    // на устройстве.
    final fresh =
        context.read<LibraryController>().byId(widget.video.id) ?? widget.video;
    Navigator.of(context).pushReplacement(PlayerPage.route(fresh));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final downloads = context.watch<DownloadController>();

    final video = library.byId(widget.video.id) ?? widget.video;
    final task = downloads.taskFor(video.id);

    // Файл уже на месте (скачали раньше или только что) — сразу в плеер.
    if (video.isDownloaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPlayer());
    }

    final isFailed = task?.state == DownloadState.failed;
    final progress = task?.progress;
    final received = task?.received ?? 0;
    final total = task?.total ?? 0;

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Фон — превью видео, чтобы экран выглядел живым, а не пустым.
          ThumbnailImage(
            videoId: video.id,
            borderRadius: 0,
            semanticLabel: video.title,
          ),
          const ColoredBox(color: Color(0xB3000000)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFailed)
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 64,
                        color: AppColors.coral,
                      )
                    else
                      _ProgressRing(progress: progress),
                    const SizedBox(height: 26),
                    Text(
                      isFailed
                          ? strings.prepareFailedTitle
                          : strings.prepareTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Text(
                        isFailed
                            ? strings.prepareFailedBody
                            : strings.prepareBody,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      video.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!isFailed && total > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${Formatters.bytes(received)} / ${Formatters.bytes(total)}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    if (isFailed)
                      FilledButton.icon(
                        onPressed: () {
                          _started = false;
                          _ensureDownloading();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(strings.prepareRetry),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.midnight,
                        ),
                      )
                    else if (task == null || task.state == DownloadState.queued)
                      Text(
                        strings.prepareWaitingForQueue,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        if (task != null && task.isActive) {
                          downloads.cancel(video.id);
                        }
                        Navigator.of(context).maybePop();
                      },
                      child: Text(
                        strings.prepareCancel,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Круговой индикатор загрузки с процентом внутри.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final percent = progress == null ? null : (progress! * 100).round();
    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 126,
            height: 126,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              backgroundColor: Colors.white24,
              color: AppColors.greenLight,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                percent == null ? '…' : '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                Icons.download_rounded,
                color: AppColors.greenLight,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
