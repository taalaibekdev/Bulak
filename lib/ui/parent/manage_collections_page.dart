import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/video_collection.dart';
import '../../state/library_controller.dart';
import '../widgets/common.dart';

/// Управление коллекциями: создать, переименовать, сменить значок и цвет.
class ManageCollectionsPage extends StatelessWidget {
  const ManageCollectionsPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ManageCollectionsPage());

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final collections = library.collections;

    return Scaffold(
      appBar: AppBar(title: Text(strings.collectionsTitle)),
      // Плавающая кнопка нужна только когда список уже есть: на пустом
      // экране её роль выполняет кнопка внутри подсказки.
      floatingActionButton: collections.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.collectionNew),
            ),
      body: collections.isEmpty
          ? EmptyState(
              emoji: '🗂️',
              title: strings.collectionsEmptyTitle,
              body: strings.collectionsEmptyBody,
              compact: true,
              action: FilledButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(strings.collectionNew),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: collections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final collection = collections[index];
                return _CollectionRow(
                  collection: collection,
                  videoCount: library.countOf(collection.id),
                  onEdit: () => _openEditor(context, collection: collection),
                  onDelete: () => _delete(context, collection),
                );
              },
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    VideoCollection? collection,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CollectionEditorSheet(collection: collection),
    );
  }

  Future<void> _delete(BuildContext context, VideoCollection collection) async {
    final strings = AppStrings.of(context);
    final library = context.read<LibraryController>();
    final confirmed = await showConfirmDialog(
      context,
      title: strings.collectionDeleteTitle,
      body: strings.collectionDeleteBody,
      destructive: true,
      icon: Icons.folder_delete_outlined,
    );
    if (!confirmed) return;
    await library.deleteCollection(collection.id);
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.collection,
    required this.videoCount,
    required this.onEdit,
    required this.onDelete,
  });

  final VideoCollection collection;
  final int videoCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.collectionGradient(collection.colorIndex);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(collection.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  strings.videosCount(videoCount),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: strings.actionEdit,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: strings.actionDelete,
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Панель создания и редактирования коллекции.
class _CollectionEditorSheet extends StatefulWidget {
  const _CollectionEditorSheet({this.collection});

  final VideoCollection? collection;

  @override
  State<_CollectionEditorSheet> createState() => _CollectionEditorSheetState();
}

class _CollectionEditorSheetState extends State<_CollectionEditorSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.collection?.title ?? '',
  );
  late String _emoji =
      widget.collection?.emoji ?? AppColors.collectionEmojis.first;
  late int _colorIndex = widget.collection?.colorIndex ?? 0;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    final library = context.read<LibraryController>();
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(() => _error = strings.collectionNameRequired);
      return;
    }

    if (widget.collection == null) {
      await library.createCollection(
        title: title,
        emoji: _emoji,
        colorIndex: _colorIndex,
      );
    } else {
      await library.updateCollection(
        widget.collection!.copyWith(
          title: title,
          emoji: _emoji,
          colorIndex: _colorIndex,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isNew = widget.collection == null;

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
            Text(
              isNew ? strings.collectionNew : strings.collectionEdit,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: strings.collectionNameLabel,
                hintText: strings.collectionNameHint,
                errorText: _error,
                prefixIcon: const Icon(Icons.edit_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.collectionEmojiLabel,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in AppColors.collectionEmojis)
                  GestureDetector(
                    onTap: () => setState(() => _emoji = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _emoji == emoji
                            ? theme.colorScheme.primary.withValues(alpha: 0.18)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _emoji == emoji
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              strings.collectionColorLabel,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (
                  var index = 0;
                  index < AppColors.collectionGradients.length;
                  index++
                )
                  GestureDetector(
                    onTap: () => setState(() => _colorIndex = index),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.collectionGradient(index),
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _colorIndex == index
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: _colorIndex == index
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(strings.actionSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
