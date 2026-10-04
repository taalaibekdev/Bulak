import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video_collection.dart';
import '../../data/services/youtube_service.dart';
import '../../state/library_controller.dart';
import '../widgets/common.dart';
import '../widgets/thumbnail_image.dart';

/// Добавление видео по ссылке с YouTube.
///
/// Родитель вставляет одну или несколько ссылок — приложение разбирает их,
/// подтягивает названия и показывает, как карточки будут выглядеть для
/// ребёнка. После подтверждения видео попадает в библиотеку.
class AddVideoPage extends StatefulWidget {
  const AddVideoPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const AddVideoPage());

  @override
  State<AddVideoPage> createState() => _AddVideoPageState();
}

class _AddVideoPageState extends State<AddVideoPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;

  List<String> _ids = const [];
  final Map<String, VideoMetadata?> _metadata = {};
  final Set<String> _loading = {};

  int _duplicates = 0;
  int _invalid = 0;

  String? _collectionId;
  bool _saving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _parse);
  }

  Future<void> _parse() async {
    final library = context.read<LibraryController>();
    final summary = library.parseLinks(_textController.text);

    if (!mounted) return;
    setState(() {
      _ids = summary.validIds;
      _duplicates = summary.duplicates;
      _invalid = summary.invalid;
    });

    for (final id in _ids) {
      if (_metadata.containsKey(id) || _loading.contains(id)) continue;
      _loading.add(id);
      final meta = await library.fetchMetadata(id);
      if (!mounted) return;
      setState(() {
        _metadata[id] = meta;
        _loading.remove(id);
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    _textController.text = text;
    _textController.selection = TextSelection.collapsed(offset: text.length);
    await _parse();
  }

  List<VideoDraft> _drafts() {
    return _ids.map((id) {
      final meta = _metadata[id];
      return meta == null
          ? VideoDraft.fallback(id)
          : VideoDraft.fromMetadata(meta);
    }).toList();
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    final library = context.read<LibraryController>();
    setState(() => _saving = true);

    final result = await library.addVideos(
      _drafts(),
      collectionId: _collectionId,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.added == 0) {
      showAppSnack(
        context,
        result.limitReached
            ? strings.addVideoLimitReached
            : strings.addVideoDuplicate,
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    Navigator.of(context).pop();
    showAppSnack(
      context,
      strings.addVideoAdded(result.added),
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final collections = context.watch<LibraryController>().collections;

    return Scaffold(
      appBar: AppBar(title: Text(strings.addVideoTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            strings.addVideoManyHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            onChanged: _onChanged,
            minLines: 2,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: strings.addVideoHint,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 6, top: 16),
                child: Icon(Icons.link_rounded),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              suffixIcon: IconButton(
                tooltip: strings.addVideoPaste,
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_go_rounded),
                label: Text(strings.addVideoPaste),
              ),
              const SizedBox(width: 12),
              if (_ids.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.check_rounded, size: 18),
                  label: Text(strings.videosCount(_ids.length)),
                ),
            ],
          ),
          if (_invalid > 0) ...[
            const SizedBox(height: 14),
            _Message(
              icon: Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              text: strings.addVideoInvalid,
            ),
          ],
          if (_duplicates > 0) ...[
            const SizedBox(height: 14),
            _Message(
              icon: Icons.copy_all_rounded,
              color: AppColors.sunny,
              text: '$strings.addVideoDuplicate ($_duplicates)',
            ),
          ],
          if (_ids.isNotEmpty) ...[
            const SizedBox(height: 26),
            SectionHeader(
              title: strings.addVideoPreview,
              icon: Icons.visibility_rounded,
            ),
            for (final id in _ids) _buildPreview(context, id),
            const SizedBox(height: 20),
            SectionHeader(
              title: strings.addVideoCollectionLabel,
              icon: Icons.folder_copy_rounded,
            ),
            _CollectionPicker(
              collections: collections,
              selectedId: _collectionId,
              onSelected: (id) => setState(() => _collectionId = id),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text('$strings.actionAdd · ${_ids.length}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, String id) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isLoading = _loading.contains(id);
    final meta = _metadata[id];
    final failed = !isLoading && meta == null;

    final title =
        meta?.title ??
        (failed ? strings.addVideoMissingTitle : strings.addVideoFetching);
    final subtitle =
        meta?.author ??
        (meta?.duration != null ? Formatters.duration(meta!.duration) : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 116,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ThumbnailImage(
                  videoId: id,
                  borderRadius: 14,
                  overlay: meta?.duration == null
                      ? null
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: PillBadge(
                              label: Formatters.duration(meta!.duration),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(title, style: theme.textTheme.bodySmall),
                        ),
                      ],
                    )
                  else
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: failed ? theme.colorScheme.error : null,
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: strings.actionDelete,
              onPressed: () {
                setState(() {
                  _ids = List.of(_ids)..remove(id);
                  final text = _textController.text
                      .split(RegExp(r'[\r\n]+'))
                      .where((line) => !line.contains(id))
                      .join('\n');
                  _textController.text = text;
                });
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

/// Выбор коллекции в виде «пилюль».
class _CollectionPicker extends StatelessWidget {
  const _CollectionPicker({
    required this.collections,
    required this.selectedId,
    required this.onSelected,
  });

  final List<VideoCollection> collections;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ChoiceChip(
          label: Text(strings.addVideoNoCollection),
          selected: selectedId == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final collection in collections)
          ChoiceChip(
            avatar: Text(collection.emoji),
            label: Text(collection.title),
            selected: selectedId == collection.id,
            onSelected: (_) => onSelected(collection.id),
          ),
      ],
    );
  }
}

/// Строка-сообщение под полем ввода.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
