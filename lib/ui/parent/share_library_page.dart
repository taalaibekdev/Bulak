import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/video_collection.dart';
import '../../data/models/video_item.dart';
import '../../data/services/library_transfer.dart';
import '../../state/download_controller.dart';
import '../../state/library_controller.dart';
import '../widgets/common.dart';

/// Обмен подборками: отдать свой список ссылок и принять чужой.
///
/// Приложение не хранит ничего на сервере, поэтому «поделиться» — это
/// просто текст со ссылками: его можно отправить в мессенджере, а получатель
/// вставит его у себя и скачает те же видео.
class ShareLibraryPage extends StatefulWidget {
  const ShareLibraryPage({super.key, this.collection});

  /// Если задана — делимся одной коллекцией, иначе всей библиотекой.
  final VideoCollection? collection;

  static Route<void> route({VideoCollection? collection}) =>
      MaterialPageRoute<void>(
        builder: (_) => ShareLibraryPage(collection: collection),
      );

  @override
  State<ShareLibraryPage> createState() => _ShareLibraryPageState();
}

class _ShareLibraryPageState extends State<ShareLibraryPage> {
  final TextEditingController _inputController = TextEditingController();

  TransferPayload? _payload;
  bool _checked = false;
  bool _busy = false;

  /// Куда складывать принятые видео.
  _ImportTarget _target = _ImportTarget.newCollection;
  String? _existingCollectionId;
  String _newTitle = '';
  bool _downloadAfterImport = false;

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) {
      _newTitle = widget.collection!.title;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  List<VideoItem> get _exportVideos {
    final library = context.read<LibraryController>();
    final collection = widget.collection;
    return collection == null
        ? library.videos
        : library.videosOf(collection.id);
  }

  String get _exportTitle =>
      widget.collection?.title ?? AppStrings.of(context).shareExportAll;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.shareTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _Section(
            title: strings.shareExportSection,
            icon: Icons.ios_share_rounded,
            children: [
              Text(
                _exportTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.videosCount(_exportVideos.length),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                strings.shareExportHint,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _exportVideos.isEmpty ? null : _shareAsText,
                    icon: const Icon(Icons.link_rounded),
                    label: Text(strings.shareExportAsText),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _exportVideos.isEmpty ? null : _shareAsFile,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(strings.shareExportAsFile),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportVideos.isEmpty
                        ? null
                        : () => _copyToClipboard(
                            LibraryTransfer.encode(
                              title: _exportTitle,
                              videos: _exportVideos,
                            ),
                          ),
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(strings.shareCopied),
                  ),
                ],
              ),
              if (_exportVideos.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  strings.shareExportEmpty,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: strings.shareImportSection,
            icon: Icons.download_rounded,
            children: [
              TextField(
                controller: _inputController,
                minLines: 2,
                maxLines: 6,
                onChanged: (_) {
                  if (_checked) setState(() => _checked = false);
                },
                decoration: InputDecoration(
                  hintText: strings.shareImportHint,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 6, top: 16),
                    child: Icon(Icons.content_paste_rounded),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_go_rounded),
                    label: Text(strings.shareImportPaste),
                  ),
                  FilledButton.icon(
                    onPressed: _check,
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text(strings.shareImportCheck),
                  ),
                ],
              ),
              if (_checked) ...[
                const SizedBox(height: 16),
                _ImportPreview(
                  payload: _payload!,
                  onTargetChanged: (target) => setState(() => _target = target),
                  target: _target,
                  existingCollectionId: _existingCollectionId,
                  onCollectionChanged: (id) =>
                      setState(() => _existingCollectionId = id),
                  initialTitle: _newTitle,
                  onTitleChanged: (value) => _newTitle = value,
                  downloadAfter: _downloadAfterImport,
                  onDownloadChanged: (value) =>
                      setState(() => _downloadAfterImport = value),
                  onImport: _import,
                  busy: _busy,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- Экспорт -----------------------------------------------------------

  Future<void> _shareAsText() async {
    final videos = _exportVideos;
    final text = LibraryTransfer.encode(title: _exportTitle, videos: videos);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '$_exportTitle · ${AppConfig.brandName}',
      ),
    );
  }

  Future<void> _shareAsFile() async {
    final strings = AppStrings.of(context);
    try {
      final directory = await getTemporaryDirectory();
      final safeName = _exportTitle
          .replaceAll(RegExp(r'[^\w\s\-]+', unicode: true), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '-');
      final file = File(
        p.join(
          directory.path,
          '${safeName.isEmpty ? 'bulak' : safeName}'
          '.${LibraryTransfer.fileExtension}',
        ),
      );
      await file.writeAsString(
        LibraryTransfer.encode(title: _exportTitle, videos: _exportVideos),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: _exportTitle,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, strings.somethingWentWrong);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    final strings = AppStrings.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnack(context, strings.shareCopied, icon: Icons.check_rounded);
  }

  // --- Импорт ------------------------------------------------------------

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    _inputController.text = text;
    await _check();
  }

  Future<void> _check() async {
    final strings = AppStrings.of(context);
    final payload = LibraryTransfer.decode(_inputController.text);

    setState(() {
      _payload = payload;
      _checked = true;
      if (payload?.title != null && payload!.title!.trim().isNotEmpty) {
        _newTitle = payload.title!.trim();
      }
    });

    if (payload == null) {
      showAppSnack(
        context,
        strings.shareImportInvalid,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _import() async {
    final strings = AppStrings.of(context);
    final library = context.read<LibraryController>();
    final payload = _payload;
    if (payload == null || payload.isEmpty) return;

    setState(() => _busy = true);

    String? collectionId;
    switch (_target) {
      case _ImportTarget.newCollection:
        final collection = await library.createCollection(
          title: _newTitle.trim().isEmpty
              ? strings.shareImportSection
              : _newTitle.trim(),
          emoji: '📥',
          colorIndex: library.collections.length % 8,
        );
        collectionId = collection.id;
      case _ImportTarget.existing:
        collectionId = _existingCollectionId;
      case _ImportTarget.none:
        collectionId = null;
    }

    final drafts = payload.videos
        .map(
          (item) => VideoDraft(
            id: item.id,
            title: item.title ?? '',
            author: item.author,
            duration: item.durationSeconds == null
                ? null
                : Duration(seconds: item.durationSeconds!),
          ),
        )
        .toList();

    final result = await library.addVideos(drafts, collectionId: collectionId);

    if (_downloadAfterImport &&
        result.added > 0 &&
        AppConfig.downloadsEnabled) {
      if (!mounted) return;
      final controller = context.read<DownloadController>();
      final added = payload.videos
          .map((item) => library.byId(item.id))
          .whereType<VideoItem>();
      controller.enqueueAll(added);
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _checked = false;
      _inputController.clear();
      _payload = null;
    });

    showAppSnack(
      context,
      result.added == 0
          ? strings.shareImportNothingNew
          : strings.shareImportDone(result.added),
      icon: Icons.check_circle_rounded,
    );
  }
}

/// Куда складывать принятые видео.
enum _ImportTarget { newCollection, existing, none }

class _ImportPreview extends StatefulWidget {
  const _ImportPreview({
    required this.payload,
    required this.target,
    required this.onTargetChanged,
    required this.existingCollectionId,
    required this.onCollectionChanged,
    required this.initialTitle,
    required this.onTitleChanged,
    required this.downloadAfter,
    required this.onDownloadChanged,
    required this.onImport,
    required this.busy,
  });

  final TransferPayload payload;
  final _ImportTarget target;
  final ValueChanged<_ImportTarget> onTargetChanged;
  final String? existingCollectionId;
  final ValueChanged<String?> onCollectionChanged;
  final String initialTitle;
  final ValueChanged<String> onTitleChanged;
  final bool downloadAfter;
  final ValueChanged<bool> onDownloadChanged;
  final Future<void> Function() onImport;
  final bool busy;

  @override
  State<_ImportPreview> createState() => _ImportPreviewState();
}

class _ImportPreviewState extends State<_ImportPreview> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final library = context.watch<LibraryController>();

    final fresh = widget.payload.videos
        .where((item) => !library.contains(item.id))
        .length;
    final duplicates = widget.payload.videos.length - fresh;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.payload.title != null &&
              widget.payload.title!.isNotEmpty) ...[
            Text(widget.payload.title!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
          ],
          if (widget.payload.note != null &&
              widget.payload.note!.trim().isNotEmpty) ...[
            Text(widget.payload.note!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
          ],
          Text(
            strings.shareImportFound(widget.payload.videos.length),
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            strings.shareImportNew(fresh),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mint,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (duplicates > 0)
            Text(
              strings.shareImportDuplicates(duplicates),
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 14),
          Text(strings.shareImportTargetNew, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(strings.shareImportTargetNew),
                selected: widget.target == _ImportTarget.newCollection,
                onSelected: (_) =>
                    widget.onTargetChanged(_ImportTarget.newCollection),
              ),
              if (library.collections.isNotEmpty)
                ChoiceChip(
                  label: Text(strings.shareImportTargetExisting),
                  selected: widget.target == _ImportTarget.existing,
                  onSelected: (_) =>
                      widget.onTargetChanged(_ImportTarget.existing),
                ),
              ChoiceChip(
                label: Text(strings.shareImportTargetNone),
                selected: widget.target == _ImportTarget.none,
                onSelected: (_) => widget.onTargetChanged(_ImportTarget.none),
              ),
            ],
          ),
          if (widget.target == _ImportTarget.newCollection) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              onChanged: widget.onTitleChanged,
              decoration: InputDecoration(
                labelText: strings.shareImportTitleLabel,
                prefixIcon: const Icon(Icons.folder_rounded),
              ),
            ),
          ],
          if (widget.target == _ImportTarget.existing) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final collection in library.collections)
                  ChoiceChip(
                    avatar: Text(collection.emoji),
                    label: Text(collection.title),
                    selected: widget.existingCollectionId == collection.id,
                    onSelected: (_) =>
                        widget.onCollectionChanged(collection.id),
                  ),
              ],
            ),
          ],
          if (AppConfig.downloadsEnabled) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              value: widget.downloadAfter,
              onChanged: widget.onDownloadChanged,
              title: Text(strings.shareImportDownloadAfter),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.busy || fresh == 0 ? null : widget.onImport,
              icon: widget.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.library_add_rounded),
              label: Text(strings.shareImportAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
