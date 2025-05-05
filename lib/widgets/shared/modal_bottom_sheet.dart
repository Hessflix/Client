import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/settings/home_settings_model.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/hessflix_image.dart';

Future<void> showBottomSheetPill({
  ItemBaseModel? item,
  bool showPill = true,
  Function()? onDismiss,
  EdgeInsets padding = const EdgeInsets.all(16),
  required BuildContext context,
  required Widget Function(
    BuildContext context,
    ScrollController scrollController,
  ) content,
}) async {
  final screenSize = MediaQuery.sizeOf(context);
  await showModalBottomSheet(
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    enableDrag: true,
    context: context,
    constraints: AdaptiveLayout.viewSizeOf(context) == ViewSize.phone
        ? BoxConstraints(maxHeight: screenSize.height * 0.9)
        : BoxConstraints(maxWidth: screenSize.width * 0.75, maxHeight: screenSize.height * 0.85),
    builder: (context) {
      final controller = ScrollController();
      return ListView(
        shrinkWrap: true,
        controller: controller,
        children: [
          if (item != null) ...{
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ItemBottomSheetPreview(item: item),
            ),
            const Divider(),
          },
          content(context, controller),
        ],
      );
    },
  );
  onDismiss?.call();
}

class ItemBottomSheetPreview extends ConsumerWidget {
  final ItemBaseModel item;
  const ItemBottomSheetPreview({required this.item, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Card(
              child: SizedBox(
                height: 90,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: HessflixImage(
                    image: item.images?.primary,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (item.subText?.isNotEmpty ?? false)
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        item.subText!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
