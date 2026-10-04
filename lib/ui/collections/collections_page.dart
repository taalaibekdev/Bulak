import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../state/library_controller.dart';
import '../library/all_videos_page.dart';
import '../shell/app_shell.dart';
import '../widgets/collection_card.dart';
import '../widgets/common.dart';
import 'collection_detail_page.dart';

/// Список коллекций — «папок» с мультиками, уроками и музыкой.
class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final collections = library.collections;

    final columns = _columnsFor(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Text(
                  strings.collectionsTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
            if (collections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: kShellBottomInset),
                  child: EmptyState(
                    emoji: '🗂️',
                    title: strings.collectionsEmptyTitle,
                    body: strings.collectionsEmptyBody,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  kShellBottomInset,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 152,
                  ),
                  itemCount: collections.length + 1,
                  itemBuilder: (context, index) {
                    if (index == collections.length) {
                      return AllVideosCard(
                        videoCount: library.videoCount,
                        onTap: () =>
                            Navigator.of(context).push(AllVideosPage.route()),
                      );
                    }
                    final collection = collections[index];
                    return CollectionCard(
                      collection: collection,
                      videoCount: library.countOf(collection.id),
                      onTap: () =>
                          Navigator.of(context)
                              .push(CollectionDetailPage.route(collection)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static int _columnsFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 4;
    if (width >= 820) return 3;
    return 2;
  }
}
