import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/episode_model.dart';
import 'package:hessflix/models/items/images_models.dart';
import 'package:hessflix/models/items/item_shared_models.dart';
import 'package:hessflix/models/items/media_streams_model.dart';
import 'package:hessflix/models/items/movie_model.dart';
import 'package:hessflix/models/items/overview_model.dart';

part 'item_stream_model.mapper.dart';

@MappableClass()
class ItemStreamModel extends ItemBaseModel with ItemStreamModelMappable {
  final ImagesData? parentImages;
  final MediaStreamsModel mediaStreams;
  const ItemStreamModel({
    required this.parentImages,
    required this.mediaStreams,
    required super.name,
    required super.id,
    required super.overview,
    required super.parentId,
    required super.playlistId,
    required super.images,
    required super.childCount,
    required super.primaryRatio,
    required super.userData,
    required super.canDelete,
    required super.canDownload,
    super.jellyType,
  });
  factory ItemStreamModel.fromBaseDto(dto.BaseItemDto item, Ref ref) {
    return switch (item.type) {
      BaseItemKind.episode => EpisodeModel.fromBaseDto(item, ref),
      BaseItemKind.movie => MovieModel.fromBaseDto(item, ref),
      _ => ItemStreamModel._fromBaseDto(item, ref)
    };
  }

  factory ItemStreamModel._fromBaseDto(dto.BaseItemDto item, Ref ref) {
    return ItemStreamModel(
      name: item.name ?? "",
      id: item.id ?? "",
      childCount: item.childCount,
      overview: OverviewModel.fromBaseItemDto(item, ref),
      userData: UserData.fromDto(item.userData),
      parentId: item.parentId,
      playlistId: item.playlistItemId,
      images: ImagesData.fromBaseItem(item, ref),
      primaryRatio: item.primaryImageAspectRatio,
      parentImages: ImagesData.fromBaseItemParent(item, ref),
      canDelete: item.canDelete,
      canDownload: item.canDownload,
      mediaStreams: MediaStreamsModel.fromMediaStreamsList(item.mediaSources, ref),
    );
  }

  String? get videoPropertiesLabel {
    if (mediaStreams.displayProfile == null && mediaStreams.resolution == null) return null;
    return "${mediaStreams.displayProfile?.value}";
  }
}
