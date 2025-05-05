import 'package:chopper/chopper.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/episode_model.dart';
import 'package:hessflix/models/items/item_shared_models.dart';
import 'package:hessflix/models/items/series_model.dart';
import 'package:hessflix/providers/api_provider.dart';
import 'package:hessflix/providers/service_provider.dart';
import 'package:hessflix/providers/sync_provider.dart';

class EpisodeDetailModel {
  final SeriesModel? series;
  final List<EpisodeModel> episodes;
  final EpisodeModel? episode;
  final List<Person> guestActors;
  EpisodeDetailModel({
    this.series,
    this.episodes = const [],
    this.episode,
    this.guestActors = const [],
  });

  EpisodeDetailModel copyWith({
    SeriesModel? series,
    List<EpisodeModel>? episodes,
    EpisodeModel? episode,
    List<Person>? guestActors,
  }) {
    return EpisodeDetailModel(
      series: series ?? this.series,
      episodes: episodes ?? this.episodes,
      episode: episode ?? this.episode,
      guestActors: guestActors ?? this.guestActors,
    );
  }
}

final episodeDetailsProvider =
    StateNotifierProvider.autoDispose.family<EpisodeDetailsProvider, EpisodeDetailModel, String>((ref, id) {
  return EpisodeDetailsProvider(ref);
});

class EpisodeDetailsProvider extends StateNotifier<EpisodeDetailModel> {
  EpisodeDetailsProvider(this.ref) : super(EpisodeDetailModel());

  final Ref ref;

  late final JellyService api = ref.read(jellyApiProvider);

  Future<Response?> fetchDetails(ItemBaseModel item) async {
    try {
      final seriesResponse = await api.usersUserIdItemsItemIdGet(itemId: item.parentBaseModel.id);
      if (seriesResponse.body == null) return null;
      final episodes = await api.showsSeriesIdEpisodesGet(seriesId: item.parentBaseModel.id);

      if (episodes.body == null) return null;

      final episode = (await api.usersUserIdItemsItemIdGet(itemId: item.id)).bodyOrThrow as EpisodeModel;

      state = state.copyWith(
        series: seriesResponse.bodyOrThrow as SeriesModel,
        episodes: EpisodeModel.episodesFromDto(episodes.bodyOrThrow.items, ref),
        episode: episode,
      );

      return seriesResponse;
    } catch (e) {
      _tryToCreateOfflineState(item);
      return null;
    }
  }

  void _tryToCreateOfflineState(ItemBaseModel item) {
    final syncNotifier = ref.read(syncProvider.notifier);
    final episodeModel = syncNotifier.getSyncedItem(item)?.createItemModel(ref) as EpisodeModel?;
    if (episodeModel == null) return;
    final seriesSyncedItem = syncNotifier.getSyncedItem(episodeModel.parentBaseModel);
    if (seriesSyncedItem == null) return;
    final seriesModel = seriesSyncedItem.createItemModel(ref) as SeriesModel?;
    if (seriesModel == null) return;
    final episodes = syncNotifier
        .getNestedChildren(seriesSyncedItem)
        .map(
          (e) => e.createItemModel(ref),
        )
        .nonNulls
        .whereType<EpisodeModel>()
        .toList();
    state = state.copyWith(
      series: seriesModel,
      episode: episodes.firstWhereOrNull((element) => element.id == item.id),
      episodes: episodes,
    );
    return;
  }

  void setSubIndex(int index) {
    state = state.copyWith(
        episode: state.episode?.copyWith(
            mediaStreams: state.episode?.mediaStreams.copyWith(
      defaultSubStreamIndex: index,
    )));
  }

  void setAudioIndex(int index) {
    state = state.copyWith(
        episode: state.episode?.copyWith(
            mediaStreams: state.episode?.mediaStreams.copyWith(
      defaultAudioStreamIndex: index,
    )));
  }

  void setVersionIndex(int index) {
    state = state.copyWith(
        episode: state.episode?.copyWith(
            mediaStreams: state.episode?.mediaStreams.copyWith(
      versionStreamIndex: index,
    )));
  }
}
