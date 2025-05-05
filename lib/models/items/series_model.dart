import 'package:hessflix/screens/details_screens/series_detail_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/episode_model.dart';
import 'package:hessflix/models/items/images_models.dart';
import 'package:hessflix/models/items/item_shared_models.dart';
import 'package:hessflix/models/items/overview_model.dart';
import 'package:hessflix/models/items/season_model.dart';

import 'package:dart_mappable/dart_mappable.dart';

part 'series_model.mapper.dart';

@MappableClass()
class SeriesModel extends ItemBaseModel with SeriesModelMappable {
  final List<EpisodeModel>? availableEpisodes;
  final List<SeasonModel>? seasons;
  final String originalTitle;
  final String sortName;
  final String status;
  final List<ItemBaseModel> related;
  const SeriesModel({
    this.availableEpisodes,
    this.seasons,
    required this.originalTitle,
    required this.sortName,
    required this.status,
    this.related = const [],
    required super.name,
    required super.id,
    required super.overview,
    required super.parentId,
    required super.playlistId,
    required super.images,
    required super.childCount,
    required super.primaryRatio,
    required super.userData,
    super.canDownload,
    super.canDelete,
    super.jellyType,
  });

  EpisodeModel? get nextUp => availableEpisodes?.nextUp ?? availableEpisodes?.firstOrNull;

  @override
  String detailedName(BuildContext context) => name;

  @override
  ItemBaseModel get parentBaseModel => this;

  @override
  Widget get detailScreenWidget => SeriesDetailScreen(item: this);

  @override
  bool get emptyShow => childCount == 0;

  @override
  bool get playAble => userData.unPlayedItemCount != 0;

  @override
  bool get identifiable => true;

  @override
  bool get unWatched =>
      !userData.played && userData.progress <= 0 && userData.unPlayedItemCount == 0 && childCount != 0;

  @override
  String get subText => overview.yearAired?.toString() ?? "";

  List<ItemBaseModel> fetchAllShows() {
    return availableEpisodes?.map((e) => e).toList() ?? [];
  }

  @override
  bool get syncAble => true;

  factory SeriesModel.fromBaseDto(dto.BaseItemDto item, Ref ref) => SeriesModel(
        name: item.name ?? "",
        id: item.id ?? "",
        childCount: item.childCount,
        overview: OverviewModel.fromBaseItemDto(item, ref),
        userData: UserData.fromDto(item.userData),
        parentId: item.parentId,
        playlistId: item.playlistItemId,
        images: ImagesData.fromBaseItem(item, ref, getOriginalSize: true),
        primaryRatio: item.primaryImageAspectRatio,
        originalTitle: item.originalTitle ?? "",
        sortName: item.sortName ?? "",
        canDelete: item.canDelete,
        canDownload: item.canDownload,
        status: item.status ?? "Continuing",
      );
}
