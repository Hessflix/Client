import 'package:auto_route/auto_route.dart';
import 'package:hessflix/models/settings/home_settings_model.dart';
import 'package:hessflix/providers/settings/client_settings_provider.dart';
import 'package:hessflix/routes/auto_router.gr.dart';
import 'package:hessflix/screens/shared/nested_scaffold.dart';
import 'package:hessflix/screens/shared/nested_sliver_appbar.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/widgets/shared/pinch_poster_zoom.dart';
import 'package:hessflix/widgets/shared/poster_size_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/providers/favourites_provider.dart';
import 'package:hessflix/screens/shared/media/poster_grid.dart';
import 'package:hessflix/util/sliver_list_padding.dart';
import 'package:hessflix/widgets/shared/pull_to_refresh.dart';

@RoutePage()
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);

    return PullToRefresh(
      onRefresh: () async => await ref.read(favouritesProvider.notifier).fetchFavourites(),
      child: NestedScaffold(
        body: PinchPosterZoom(
          scaleDifference: (difference) => ref.read(clientSettingsProvider.notifier).addPosterSize(difference / 2),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: AdaptiveLayout.scrollOf(context),
            slivers: [
              if (AdaptiveLayout.viewSizeOf(context) == ViewSize.phone)
                NestedSliverAppBar(
                  searchTitle: "${context.localized.search} ${context.localized.favorites.toLowerCase()}...",
                  parent: context,
                  route: LibrarySearchRoute(favourites: true),
                )
              else
                const DefaultSliverTopBadding(),
              if (AdaptiveLayout.of(context).isDesktop)
                const SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PosterSizeWidget(),
                    ],
                  ),
                ),
              ...favourites.favourites.entries.where((element) => element.value.isNotEmpty).map(
                    (e) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PosterGrid(
                          stickyHeader: true,
                          name: e.key.label(context),
                          posters: e.value,
                        ),
                      ),
                    ),
                  ),
              if (favourites.people.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PosterGrid(
                      stickyHeader: true,
                      name: "People",
                      posters: favourites.people,
                    ),
                  ),
                ),
              const DefautlSliverBottomPadding(),
            ],
          ),
        ),
      ),
    );
  }
}
