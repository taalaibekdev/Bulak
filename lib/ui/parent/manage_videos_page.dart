import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/video_item.dart';
import '../../state/library_controller.dart';
import '../widgets/common.dart';
import '../widgets/download_button.dart';
import '../widgets/video_card.dart';

/// Управление библиотекой: переименовать, перенести, удалить.
class ManageVideosPage extends StatefulWidget {
  const ManageVideosPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ManageVideosPage());

  @override
  State<ManageVideosPage> createState() => _ManageVideosPageState();
}

class _ManageVideosPageState extends State<ManageVideosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();

    final videos = library.videos.where((video) {
      if (_query.isEmpty) return true;
      final query = _query.toLowerCase();
      return video.title.toLowerCase().contains(query) ||
          (video.author?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(strings.manageVideosTitle)),
      body: library.videos.isEmpty
          ? EmptyState(
              emoji: '📼',
              title: strings.manageVideosTitle,
              body: strings.manageVideosEmpty,
              compact: true,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: strings.manageVideosSearch,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    itemCount: videos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      final collection = library.collectionById(
                        video.collectionId,
                      );
                      return VideoListTile(
                        video: video,
                        subtitle: [
                          if (video.author != null) video.author!,
                          if (collection != null)
                            '${collection.emoji} ${collection.title}',
                        ].join(' · '),
                        onTap: () => _openEditor(context, video),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (AppConfig.downloadsEnabled)
                              DownloadButton(video: video),
                            IconButton(
                              tooltip: strings.actionEdit,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openEditor(context, video),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _openEditor(BuildContext context, VideoItem video) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VideoEditorSheet(video: video),
    );
  }
}

/// Нижняя панель редактирования одного видео.
class _VideoEditorSheet extends StatefulWidget {
  const _VideoEditorSheet({required this.video});

  final VideoItem video;

  @override
  State<_VideoEditorSheet> createState() => _VideoEditorSheetState();
}

class _VideoEditorSheetState extends State<_VideoEditorSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.video.title,
  );
  late String? _collectionId = widget.video.collectionId;
  late bool _favorite = widget.video.favorite;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    final library = context.read<LibraryController>();
    final updated = widget.video.copyWith(
      title: _titleController.text.trim().isEmpty
          ? widget.video.title
          : _titleController.text.trim(),
      collectionId: _collectionId,
      favorite: _favorite,
    );
    await library.updateVideo(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnack(context, strings.videoSaved, icon: Icons.check_rounded);
  }

  Future<void> _delete() async {
    final strings = AppStrings.of(context);
    final library = context.read<LibraryController>();
    final confirmed = await showConfirmDialog(
      context,
      title: strings.deleteVideoTitle,
      body: strings.deleteVideoBody,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    await library.deleteVideo(widget.video.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnack(context, strings.videoRemoved, icon: Icons.delete_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final collections = context.watch<LibraryController>().collections;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.editVideoTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: strings.addVideoTitleLabel,
                prefixIcon: const Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 18),
            Text(strings.moveToCollection, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  label: Text(strings.addVideoNoCollection),
                  selected: _collectionId == null,
                  onSelected: (_) => setState(() => _collectionId = null),
                ),
                for (final collection in collections)
                  ChoiceChip(
                    avatar: Text(collection.emoji),
                    label: Text(collection.title),
                    selected: _collectionId == collection.id,
                    onSelected: (_) =>
                        setState(() => _collectionId = collection.id),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              value: _favorite,
              onChanged: (value) => setState(() => _favorite = value),
              title: Text(strings.favoritesTitle),
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                _favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _favorite ? theme.colorScheme.error : null,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(strings.actionDelete),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(strings.actionSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
