import 'package:chopper/chopper.dart';
import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/providers/service_provider.dart';
import 'package:hessflix/providers/sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:hessflix/models/items/episode_model.dart';
import 'package:hessflix/models/items/season_model.dart';
import 'package:hessflix/models/items/series_model.dart';
import 'package:hessflix/providers/api_provider.dart';
import 'package:hessflix/providers/related_provider.dart';

final seriesDetailsProvider =
    StateNotifierProvider.autoDispose.family<SeriesDetailViewNotifier, SeriesModel?, String>((ref, id) {
  return SeriesDetailViewNotifier(ref);
});

class SeriesDetailViewNotifier extends StateNotifier<SeriesModel?> {
  SeriesDetailViewNotifier(this.ref) : super(null);

  final Ref ref;

  late final JellyService api = ref.read(jellyApiProvider);

  Future<Response?> fetchDetails(ItemBaseModel seriesModel) async {
    try {
      if (seriesModel is SeriesModel) {
        state = state ?? seriesModel;
      }
      SeriesModel? newState;
      final response = await api.usersUserIdItemsItemIdGet(itemId: seriesModel.id);
      if (response.body == null) return null;
      newState = response.bodyOrThrow as SeriesModel;
      final seasons = await api.showsSeriesIdSeasonsGet(seriesId: seriesModel.id);
      newState = newState.copyWith(seasons: SeasonModel.seasonsFromDto(seasons.body?.items, ref));

      final episodes = await api.showsSeriesIdEpisodesGet(seriesId: seriesModel.id, fields: [
        ItemFields.mediastreams,
        ItemFields.mediasources,
        ItemFields.overview,
      ]);

      newState = newState.copyWith(
        availableEpisodes: EpisodeModel.episodesFromDto(
          episodes.body?.items,
          ref,
        ),
      );

      final related = await ref.read(relatedUtilityProvider).relatedContent(seriesModel.id);
      state = newState.copyWith(related: related.body);
      return response;
    } catch (e) {
      _tryToCreateOfflineState(seriesModel);
      return null;
    }
  }

  Future<void> _tryToCreateOfflineState(ItemBaseModel series) async {
    final syncNotifier = ref.read(syncProvider.notifier);
    final syncedItem = syncNotifier.getSyncedItem(series);
    if (syncedItem == null) return;
    final seriesModel = syncedItem.createItemModel(ref) as SeriesModel;
    final allChildren = syncedItem
        .getNestedChildren(ref)
        .map(
          (e) => e.createItemModel(ref),
        )
        .nonNulls
        .toList();
    state = seriesModel.copyWith(
      availableEpisodes: allChildren.whereType<EpisodeModel>().toList(),
      seasons: allChildren.whereType<SeasonModel>().toList(),
    );
    return;
  }

  void updateEpisodeInfo(EpisodeModel episode) {
    final index = state?.availableEpisodes?.indexOf(episode);

    if (index != null) {
      state = state?.copyWith(
        availableEpisodes: state?.availableEpisodes
          ?..remove(episode)
          ..insert(index, episode),
      );
    }
  }
}
