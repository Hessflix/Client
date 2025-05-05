import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/settings/home_settings_model.dart';
import 'package:hessflix/providers/items/movies_details_provider.dart';
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/screens/details_screens/components/media_stream_information.dart';
import 'package:hessflix/screens/details_screens/components/overview_header.dart';
import 'package:hessflix/screens/shared/detail_scaffold.dart';
import 'package:hessflix/screens/shared/media/chapter_row.dart';
import 'package:hessflix/screens/shared/media/components/media_play_button.dart';
import 'package:hessflix/screens/shared/media/expanding_overview.dart';
import 'package:hessflix/screens/shared/media/external_urls.dart';
import 'package:hessflix/screens/shared/media/people_row.dart';
import 'package:hessflix/screens/shared/media/poster_row.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/item_base_model/item_base_model_extensions.dart';
import 'package:hessflix/util/item_base_model/play_item_helpers.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/router_extension.dart';
import 'package:hessflix/util/widget_extensions.dart';
import 'package:hessflix/widgets/shared/selectable_icon_button.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final ItemBaseModel item;
  const MovieDetailScreen({required this.item, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<MovieDetailScreen> {
  MovieDetailsProvider get providerInstance => movieDetailsProvider(widget.item.id);

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(providerInstance);
    final wrapAlignment =
        AdaptiveLayout.viewSizeOf(context) != ViewSize.phone ? WrapAlignment.start : WrapAlignment.center;

    return DetailScaffold(
      label: widget.item.name,
      item: details,
      actions: (context) => details?.generateActions(
        context,
        ref,
        exclude: {
          ItemActions.play,
          ItemActions.playFromStart,
          ItemActions.details,
        },
        onDeleteSuccesFully: (item) {
          if (context.mounted) {
            context.router.popBack();
          }
        },
      ),
      onRefresh: () async => await ref.read(providerInstance.notifier).fetchDetails(widget.item),
      backDrops: details?.images,
      content: (padding) => details != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OverviewHeader(
                    name: details.name,
                    image: details.images,
                    padding: padding,
                    centerButtons: MediaPlayButton(
                      item: details,
                      onLongPressed: () async {
                        await details.play(
                          context,
                          ref,
                          showPlaybackOption: true,
                        );
                        ref.read(providerInstance.notifier).fetchDetails(widget.item);
                      },
                      onPressed: () async {
                        await details.play(
                          context,
                          ref,
                        );
                        ref.read(providerInstance.notifier).fetchDetails(widget.item);
                      },
                    ),
                    originalTitle: details.originalTitle,
                    productionYear: details.overview.productionYear,
                    runTime: details.overview.runTime,
                    genres: details.overview.genreItems,
                    studios: details.overview.studios,
                    officialRating: details.overview.parentalRating,
                    communityRating: details.overview.communityRating,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: wrapAlignment,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SelectableIconButton(
                        onPressed: () async {
                          await ref
                              .read(userProvider.notifier)
                              .setAsFavorite(!details.userData.isFavourite, details.id);
                        },
                        selected: details.userData.isFavourite,
                        selectedIcon: IconsaxPlusBold.heart,
                        icon: IconsaxPlusLinear.heart,
                      ),
                      SelectableIconButton(
                        onPressed: () async {
                          await ref.read(userProvider.notifier).markAsPlayed(!details.userData.played, details.id);
                        },
                        selected: details.userData.played,
                        selectedIcon: IconsaxPlusBold.tick_circle,
                        icon: IconsaxPlusLinear.tick_circle,
                      ),
                    ],
                  ).padding(padding),
                  if (details.mediaStreams.isNotEmpty)
                    MediaStreamInformation(
                      onVersionIndexChanged: (index) {
                        ref.read(providerInstance.notifier).setVersionIndex(index);
                      },
                      onSubIndexChanged: (index) {
                        ref.read(providerInstance.notifier).setSubIndex(index);
                      },
                      onAudioIndexChanged: (index) {
                        ref.read(providerInstance.notifier).setAudioIndex(index);
                      },
                      mediaStream: details.mediaStreams,
                    ).padding(padding),
                  if (details.overview.summary.isNotEmpty == true)
                    ExpandingOverview(
                      text: details.overview.summary,
                    ).padding(padding),
                  if (details.chapters.isNotEmpty)
                    ChapterRow(
                      chapters: details.chapters,
                      contentPadding: padding,
                      onPressed: (chapter) {
                        details.play(
                          context,
                          ref,
                          startPosition: chapter.startPosition,
                        );
                      },
                    ),
                  if (details.overview.people.isNotEmpty)
                    PeopleRow(
                      people: details.overview.people,
                      contentPadding: padding,
                    ),
                  if (details.related.isNotEmpty)
                    PosterRow(posters: details.related, contentPadding: padding, label: "Related"),
                  if (details.overview.externalUrls?.isNotEmpty == true)
                    Padding(
                      padding: padding,
                      child: ExternalUrlsRow(
                        urls: details.overview.externalUrls,
                      ),
                    )
                ].addPadding(const EdgeInsets.symmetric(vertical: 16)),
              ),
            )
          : Container(),
    );
  }
}
