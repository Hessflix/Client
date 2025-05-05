import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:hessflix/models/book_model.dart';
import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/item_shared_models.dart';
import 'package:hessflix/providers/settings/client_settings_provider.dart';
import 'package:hessflix/screens/shared/flat_button.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/hessflix_image.dart';
import 'package:hessflix/util/item_base_model/item_base_model_extensions.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/widgets/shared/clickable_text.dart';
import 'package:hessflix/widgets/shared/item_actions.dart';
import 'package:hessflix/widgets/shared/modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PosterListItem extends ConsumerWidget {
  final ItemBaseModel poster;
  final bool? selected;
  final Widget? subTitle;
  final Set<ItemActions> excludeActions;
  final List<ItemAction> otherActions;

  // Useful for intercepting button press
  final Function(VoidCallback action, ItemBaseModel item)? onPressed;
  final Function(String id, UserData? newData)? onUserDataChanged;
  final Function(ItemBaseModel newItem)? onItemUpdated;
  final Function(ItemBaseModel oldItem)? onItemRemoved;

  const PosterListItem({
    super.key,
    this.selected,
    this.subTitle,
    this.excludeActions = const {},
    this.otherActions = const [],
    required this.poster,
    this.onPressed,
    this.onItemUpdated,
    this.onItemRemoved,
    this.onUserDataChanged,
  });

  void pressedWidget(BuildContext context) {
    if (onPressed != null) {
      onPressed?.call(() {
        poster.navigateTo(context);
      }, poster);
    } else {
      poster.navigateTo(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        child: SizedBox(
          height: 75 * ref.read(clientSettingsProvider.select((value) => value.posterSize)),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: selected == true ? 0.25 : 0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FlatButton(
              onTap: () => pressedWidget(context),
              onSecondaryTapDown: (details) async {
                Offset localPosition = details.globalPosition;
                RelativeRect position =
                    RelativeRect.fromLTRB(localPosition.dx - 320, localPosition.dy, localPosition.dx, localPosition.dy);
                await showMenu(
                  context: context,
                  position: position,
                  items: poster
                      .generateActions(
                        context,
                        ref,
                        exclude: excludeActions,
                        otherActions: otherActions,
                        onUserDataChanged: (newData) => onUserDataChanged?.call(poster.id, newData),
                        onDeleteSuccesFully: onItemRemoved,
                        onItemUpdated: onItemUpdated,
                      )
                      .popupMenuItems(useIcons: true),
                );
              },
              onLongPress: () {
                showBottomSheetPill(
                  context: context,
                  item: poster,
                  content: (scrollContext, scrollController) => ListView(
                    shrinkWrap: true,
                    controller: scrollController,
                    children: poster
                        .generateActions(
                          context,
                          ref,
                          exclude: excludeActions,
                          otherActions: otherActions,
                          onUserDataChanged: (newData) => onUserDataChanged?.call(poster.id, newData),
                          onDeleteSuccesFully: onItemRemoved,
                          onItemUpdated: onItemUpdated,
                        )
                        .listTileItems(scrollContext, useIcons: true),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Hero(
                          tag: poster.id,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: HessflixImage(
                              image: poster.getPosters?.primary ?? poster.getPosters?.backDrop?.lastOrNull,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poster.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((poster.subText ?? poster.subTextShort(context))?.isNotEmpty == true)
                            Opacity(
                              opacity: 0.45,
                              child: Text(
                                poster.subText ?? poster.subTextShort(context) ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Row(
                            children: [
                              if (subTitle != null) ...[
                                subTitle!,
                                const Spacer(),
                              ],
                              if (poster.subText != null && poster.subText != poster.name)
                                ClickableText(
                                  opacity: 0.45,
                                  text: poster.subText!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (poster.type == HessflixItemType.book)
                      if (poster.userData.progress > 0)
                        Card(
                          color: Theme.of(context).colorScheme.primary,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              context.localized.page((poster as BookModel).currentPage),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                        ),
                    if (poster.userData.isFavourite)
                      const Icon(
                        IconsaxPlusBold.heart,
                        color: Colors.red,
                      ),
                    if (AdaptiveLayout.of(context).isDesktop)
                      Tooltip(
                        message: context.localized.options,
                        child: PopupMenuButton(
                          tooltip: context.localized.options,
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          itemBuilder: (context) => poster
                              .generateActions(
                                context,
                                ref,
                                exclude: excludeActions,
                                otherActions: otherActions,
                                onUserDataChanged: (newData) => onUserDataChanged?.call(poster.id, newData),
                                onDeleteSuccesFully: onItemRemoved,
                                onItemUpdated: onItemUpdated,
                              )
                              .popupMenuItems(useIcons: true),
                        ),
                      )
                  ].addInBetween(const SizedBox(width: 8)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
