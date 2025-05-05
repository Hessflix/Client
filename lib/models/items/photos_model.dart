// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hessflix/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/images_models.dart';
import 'package:hessflix/models/items/item_shared_models.dart';
import 'package:hessflix/models/items/overview_model.dart';
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/screens/shared/hessflix_snackbar.dart';
import 'package:hessflix/util/refresh_state.dart';

import 'package:dart_mappable/dart_mappable.dart';

part 'photos_model.mapper.dart';

@MappableClass()
class PhotoAlbumModel extends ItemBaseModel with PhotoAlbumModelMappable {
  final List<ItemBaseModel> photos;

  const PhotoAlbumModel({
    required this.photos,
    required super.name,
    required super.id,
    required super.overview,
    required super.parentId,
    required super.playlistId,
    required super.images,
    required super.childCount,
    required super.primaryRatio,
    required super.userData,
    super.canDelete,
    super.canDownload,
    super.jellyType,
  });
  @override
  bool get unWatched => userData.unPlayedItemCount != 0;

  @override
  bool get playAble => true;

  @override
  ItemBaseModel get parentBaseModel => copyWith(id: parentId);

  factory PhotoAlbumModel.fromBaseDto(dto.BaseItemDto item, Ref ref) {
    return PhotoAlbumModel(
      name: item.name ?? "",
      id: item.id ?? "",
      childCount: item.childCount,
      overview: OverviewModel.fromBaseItemDto(item, ref),
      userData: UserData.fromDto(item.userData),
      parentId: item.parentId,
      playlistId: item.playlistItemId,
      images: ImagesData.fromBaseItem(item, ref),
      primaryRatio: item.primaryImageAspectRatio,
      canDelete: item.canDelete,
      canDownload: item.canDownload,
      photos: [],
    );
  }
}

@MappableClass()
class PhotoModel extends ItemBaseModel with PhotoModelMappable {
  final String? albumId;
  final DateTime? dateTaken;
  final ImagesData? thumbnail;
  final HessflixItemType internalType;

  const PhotoModel({
    required this.albumId,
    required this.dateTaken,
    required this.thumbnail,
    required this.internalType,
    required super.name,
    required super.id,
    required super.overview,
    required super.parentId,
    required super.playlistId,
    required super.images,
    required super.childCount,
    required super.primaryRatio,
    required super.userData,
    required super.canDownload,
    required super.canDelete,
    super.jellyType,
  });

  @override
  PhotoAlbumModel get parentBaseModel => PhotoAlbumModel(
        photos: [],
        name: "",
        id: parentId ?? "",
        overview: overview,
        parentId: parentId,
        playlistId: playlistId,
        images: images,
        childCount: childCount,
        primaryRatio: primaryRatio,
        userData: userData,
      );

  @override
  ImagesData? get getPosters => thumbnail;

  @override
  bool get galleryItem => switch (internalType) {
        HessflixItemType.photo => albumId?.isNotEmpty == true,
        HessflixItemType.video => parentId?.isNotEmpty == true,
        _ => false,
      };

  @override
  bool get unWatched => false;

  factory PhotoModel.fromBaseDto(dto.BaseItemDto item, Ref ref) {
    return PhotoModel(
      name: item.name ?? "",
      id: item.id ?? "",
      childCount: item.childCount,
      overview: OverviewModel.fromBaseItemDto(item, ref),
      userData: UserData.fromDto(item.userData),
      parentId: item.parentId,
      playlistId: item.playlistItemId,
      primaryRatio: double.tryParse(item.aspectRatio ?? "") ?? item.primaryImageAspectRatio ?? 1.0,
      dateTaken: item.dateCreated,
      albumId: item.albumId,
      thumbnail: ImagesData.fromBaseItem(item, ref),
      images: ImagesData.fromBaseItem(item, ref, getOriginalSize: true),
      canDelete: item.canDelete,
      canDownload: item.canDownload,
      internalType: switch (item.type) {
        BaseItemKind.video => HessflixItemType.video,
        _ => HessflixItemType.photo,
      },
    );
  }

  String downloadPath(WidgetRef ref) {
    return "${ref.read(userProvider)?.server}/Items/$id/Download?api_key=${ref.read(userProvider)?.credentials.token}";
  }

  Future<void> navigateToAlbum(BuildContext context) async {
    if ((albumId ?? parentId) == null) {
      hessflixSnackbar(context, title: context.localized.notPartOfAlbum);
      return;
    }
    await parentBaseModel.navigateTo(context);
    if (context.mounted) context.refreshData();
  }
}
