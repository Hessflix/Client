import 'package:flutter/material.dart';

import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/season_model.dart';
import 'package:hessflix/providers/items/season_details_provider.dart';
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/screens/details_screens/components/overview_header.dart';
import 'package:hessflix/screens/shared/detail_scaffold.dart';
import 'package:hessflix/screens/shared/media/episode_details_list.dart';
import 'package:hessflix/screens/shared/media/expanding_overview.dart';
import 'package:hessflix/screens/shared/media/external_urls.dart';
import 'package:hessflix/screens/shared/media/people_row.dart';
import 'package:hessflix/screens/shared/media/person_list_.dart';
import 'package:hessflix/util/item_base_model/item_base_model_extensions.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/people_extension.dart';
import 'package:hessflix/util/string_extensions.dart';
import 'package:hessflix/util/theme_extensions.dart';
import 'package:hessflix/util/widget_extensions.dart';
import 'package:hessflix/widgets/shared/selectable_icon_button.dart';

class SeasonDetailScreen extends ConsumerStatefulWidget {
  final ItemBaseModel item;
  const SeasonDetailScreen({required this.item, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends ConsumerState<SeasonDetailScreen> {
  Set<EpisodeDetailsViewType> viewOptions = {EpisodeDetailsViewType.grid};
  AutoDisposeStateNotifierProvider<SeasonDetailsNotifier, SeasonModel?> get providerId =>
      seasonDetailsProvider(widget.item.id);

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(providerId);

    return DetailScaffold(
      label: details?.localizedName(context) ?? "",
      item: details,
      actions: (context) => details?.generateActions(context, ref, exclude: {
        ItemActions.details,
      }),
      onRefresh: () async {
        await ref.read(providerId.notifier).fetchDetails(widget.item.id);
      },
      backDrops: details?.parentImages,
      content: (padding) => Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: details != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OverviewHeader(
                    name: details.seriesName,
                    image: details.parentImages,
                    padding: padding,
                    subTitle: details.localizedName(context),
                    onTitleClicked: () => details.parentBaseModel.navigateTo(context),
                    originalTitle: details.seriesName,
                    productionYear: details.overview.productionYear,
                    runTime: details.overview.runTime,
                    studios: details.overview.studios,
                    officialRating: details.overview.parentalRating,
                    genres: details.overview.genreItems,
                    communityRating: details.overview.communityRating,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SelectableIconButton(
                              onPressed: () async => await ref
                                  .read(userProvider.notifier)
                                  .setAsFavorite(!details.userData.isFavourite, details.id),
                              selected: details.userData.isFavourite,
                              selectedIcon: IconsaxPlusBold.heart,
                              icon: IconsaxPlusLinear.heart,
                            ),
                            SelectableIconButton(
                              onPressed: () async => await ref
                                  .read(userProvider.notifier)
                                  .markAsPlayed(!details.userData.played, details.id),
                              selected: details.userData.played,
                              selectedIcon: IconsaxPlusBold.tick_circle,
                              icon: IconsaxPlusLinear.tick_circle,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          SegmentedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith((state) {
                                if (state.contains(WidgetState.selected)) {
                                  return context.colors.primaryContainer;
                                }
                                return context.colors.surfaceContainer;
                              }),
                              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8, horizontal: 16)),
                              elevation: const WidgetStatePropertyAll(5),
                              side: const WidgetStatePropertyAll(BorderSide.none),
                            ),
                            showSelectedIcon: true,
                            segments: EpisodeDetailsViewType.values
                                .map(
                                  (e) => ButtonSegment(
                                    value: e,
                                    icon: Icon(e.icon),
                                    label: SizedBox(
                                        height: 40,
                                        child: Center(
                                          child: Text(
                                            e.name.capitalize(),
                                          ),
                                        )),
                                  ),
                                )
                                .toList(),
                            selected: viewOptions,
                            onSelectionChanged: (newOptions) {
                              setState(() {
                                viewOptions = newOptions;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ).padding(padding),
                  if (details.overview.summary.isNotEmpty)
                    ExpandingOverview(
                      text: details.overview.summary,
                    ).padding(padding),
                  if (details.overview.directors.isNotEmpty)
                    PersonList(
                      label: context.localized.director(2),
                      people: details.overview.directors,
                    ).padding(padding),
                  if (details.overview.writers.isNotEmpty)
                    PersonList(label: context.localized.writer(2), people: details.overview.writers).padding(padding),
                  if (details.episodes.isNotEmpty)
                    EpisodeDetailsList(
                      viewType: viewOptions.first,
                      episodes: details.episodes,
                      padding: padding,
                    ),
                  if (details.overview.people.mainCast.isNotEmpty)
                    PeopleRow(
                      people: details.overview.people.mainCast,
                      contentPadding: padding,
                    ),
                  if (details.overview.people.guestActors.isNotEmpty)
                    PeopleRow(
                      people: details.overview.people.guestActors,
                      contentPadding: padding,
                    ),
                  if (details.overview.externalUrls?.isNotEmpty == true)
                    Padding(
                      padding: padding,
                      child: ExternalUrlsRow(
                        urls: details.overview.externalUrls,
                      ),
                    )
                ].addPadding(const EdgeInsets.symmetric(vertical: 16)),
              )
            : null,
      ),
    );
  }
}
