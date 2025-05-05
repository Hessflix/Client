import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/photos_model.dart';
import 'package:hessflix/providers/items/folder_details_provider.dart';
import 'package:hessflix/screens/photo_viewer/photo_viewer_screen.dart';
import 'package:hessflix/screens/shared/media/poster_grid.dart';
import 'package:hessflix/widgets/shared/pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';

class FolderDetailScreen extends ConsumerWidget {
  final ItemBaseModel item;
  const FolderDetailScreen({required this.item, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerInstance = folderDetailsProvider(item.id);
    final details = ref.watch(providerInstance);

    return PullToRefresh(
      child: Scaffold(
        appBar: AppBar(
            title: Text(
          details?.name ?? "",
        )),
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PosterGrid(
                posters: details?.items ?? [],
                onPressed: (action, item) async {
                  switch (item) {
                    case PhotoModel photoModel:
                      final photoItems = details?.items.whereType<PhotoModel>().toList();
                      await Navigator.of(context, rootNavigator: true).push(PageTransition(
                          child: PhotoViewerScreen(
                            items: photoItems,
                            indexOfSelected: photoItems?.indexOf(photoModel) ?? 0,
                          ),
                          type: PageTransitionType.fade));
                      break;
                    default:
                      if (context.mounted) {
                        await item.navigateTo(context);
                      }
                  }
                },
              ),
            )
          ],
        ),
      ),
      onRefresh: () async {
        await ref.read(providerInstance.notifier).fetchDetails(item.id);
      },
    );
  }
}
