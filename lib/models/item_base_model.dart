import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:hessflix/models/book_model.dart';
import 'package:hessflix/models/boxset_model.dart';
import 'package:hessflix/models/items/episode_model.dart';
import 'package:hessflix/models/items/folder_model.dart';
import 'package:hessflix/models/items/images_models.dart';
import 'package:hessflix/models/items/item_shared_models.dart';
import 'package:hessflix/models/items/media_streams_model.dart';
import 'package:hessflix/models/items/movie_model.dart';
import 'package:hessflix/models/items/overview_model.dart';
import 'package:hessflix/models/items/person_model.dart';
import 'package:hessflix/models/items/photos_model.dart';
import 'package:hessflix/models/items/season_model.dart';
import 'package:hessflix/models/items/series_model.dart';
import 'package:hessflix/models/library_search/library_search_options.dart';
import 'package:hessflix/models/playlist_model.dart';
import 'package:hessflix/routes/auto_router.gr.dart';
import 'package:hessflix/screens/details_screens/book_detail_screen.dart';
import 'package:hessflix/screens/details_screens/details_screens.dart';
import 'package:hessflix/screens/details_screens/episode_detail_screen.dart';
import 'package:hessflix/screens/details_screens/season_detail_screen.dart';
import 'package:hessflix/screens/library_search/library_search_screen.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/string_extensions.dart';

part 'item_base_model.mapper.dart';

@MappableClass()
class ItemBaseModel with ItemBaseModelMappable {
  final String name;
  final String id;
  final OverviewModel overview;
  final String? parentId;
  final String? playlistId;
  final ImagesData? images;
  final int? childCount;
  final double? primaryRatio;
  final UserData userData;
  final bool? canDownload;
  final bool? canDelete;
  final dto.BaseItemKind? jellyType;

  const ItemBaseModel({
    required this.name,
    required this.id,
    required this.overview,
    required this.parentId,
    required this.playlistId,
    required this.images,
    required this.childCount,
    required this.primaryRatio,
    required this.userData,
    required this.canDownload,
    required this.canDelete,
    required this.jellyType,
  });

  ItemBaseModel? setProgress(double progress) {
    return copyWith(userData: userData.copyWith(progress: progress));
  }

  Widget? subTitle(SortingOptions options) => switch (options) {
        SortingOptions.parentalRating => overview.parentalRating != null
            ? Row(
                children: [
                  const Icon(
                    IconsaxPlusBold.star_1,
                    size: 14,
                    color: Colors.yellowAccent,
                  ),
                  const SizedBox(width: 6),
                  Text((overview.parentalRating ?? 0.0).toString())
                ],
              )
            : null,
        SortingOptions.communityRating => overview.communityRating != null
            ? Row(
                children: [
                  const Icon(
                    IconsaxPlusBold.star_1,
                    size: 14,
                    color: Colors.yellowAccent,
                  ),
                  const SizedBox(width: 6),
                  Text((overview.communityRating ?? 0.0).toString())
                ],
              )
            : null,
        _ => null,
      };

  String get title => name;

  ///Used for retrieving the correct id when fetching queue
  String get streamId => id;

  ItemBaseModel get parentBaseModel => copyWith(id: parentId);

  bool get emptyShow => false;

  bool get identifiable => false;

  int? get unPlayedItemCount => userData.unPlayedItemCount;

  bool get unWatched => !userData.played && userData.progress <= 0 && userData.unPlayedItemCount == 0;

  String? detailedName(BuildContext context) => "$name${overview.yearAired != null ? " (${overview.yearAired})" : ""}";

  String? get subText => null;
  String? subTextShort(BuildContext context) => null;
  String? label(BuildContext context) => null;

  ImagesData? get getPosters => images;

  ImageData? get bannerImage => images?.primary ?? getPosters?.randomBackDrop ?? getPosters?.primary;

  bool get playAble => false;

  bool get syncAble => false;

  bool get galleryItem => false;

  MediaStreamsModel? get streamModel => null;

  String playText(BuildContext context) => context.localized.play(name);

  double get progress => userData.progress;

  String playButtonLabel(BuildContext context) =>
      progress != 0 ? context.localized.resume(name.maxLength()) : context.localized.play(name.maxLength());

  Widget get detailScreenWidget {
    switch (this) {
      case PersonModel _:
        return PersonDetailScreen(person: Person(id: id, image: images?.primary));
      case SeasonModel _:
        return SeasonDetailScreen(item: this);
      case FolderModel _:
      case PhotoAlbumModel _:
      case BoxSetModel _:
      case PlaylistModel _:
        return LibrarySearchScreen(folderId: [id]);
      case PhotoModel _:
        final photo = this as PhotoModel;
        return LibrarySearchScreen(
          folderId: [photo.albumId ?? photo.parentId ?? ""],
          photoToView: photo,
        );
      case BookModel book:
        return BookDetailScreen(item: book);
      case MovieModel _:
        return MovieDetailScreen(item: this);
      case EpisodeModel _:
        return EpisodeDetailScreen(item: this);
      case SeriesModel series:
        return SeriesDetailScreen(item: series);
      default:
        return EmptyItem(item: this);
    }
  }

  Future<void> navigateTo(BuildContext context) async => context.router.push(DetailsRoute(id: id, item: this));

  factory ItemBaseModel.fromBaseDto(dto.BaseItemDto item, Ref ref) {
    return switch (item.type) {
      BaseItemKind.photo || BaseItemKind.video => PhotoModel.fromBaseDto(item, ref),
      BaseItemKind.photoalbum => PhotoAlbumModel.fromBaseDto(item, ref),
      BaseItemKind.folder ||
      BaseItemKind.collectionfolder ||
      BaseItemKind.aggregatefolder =>
        FolderModel.fromBaseDto(item, ref),
      BaseItemKind.episode => EpisodeModel.fromBaseDto(item, ref),
      BaseItemKind.movie => MovieModel.fromBaseDto(item, ref),
      BaseItemKind.series => SeriesModel.fromBaseDto(item, ref),
      BaseItemKind.person => PersonModel.fromBaseDto(item, ref),
      BaseItemKind.season => SeasonModel.fromBaseDto(item, ref),
      BaseItemKind.boxset => BoxSetModel.fromBaseDto(item, ref),
      BaseItemKind.book => BookModel.fromBaseDto(item, ref),
      BaseItemKind.playlist => PlaylistModel.fromBaseDto(item, ref),
      _ => ItemBaseModel._fromBaseDto(item, ref)
    };
  }

  factory ItemBaseModel._fromBaseDto(dto.BaseItemDto item, Ref ref) {
    return ItemBaseModel(
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
      jellyType: item.type,
    );
  }

  HessflixItemType get type => switch (this) {
        MovieModel _ => HessflixItemType.movie,
        SeriesModel _ => HessflixItemType.series,
        SeasonModel _ => HessflixItemType.season,
        PhotoAlbumModel _ => HessflixItemType.photoAlbum,
        PhotoModel model => model.internalType,
        EpisodeModel _ => HessflixItemType.episode,
        BookModel _ => HessflixItemType.book,
        PlaylistModel _ => HessflixItemType.playlist,
        FolderModel _ => HessflixItemType.folder,
        ItemBaseModel _ => HessflixItemType.baseType,
      };

  @override
  bool operator ==(covariant ItemBaseModel other) {
    if (identical(this, other)) return true;
    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode ^ type.hashCode;
  }
}

// Currently supported types
enum HessflixItemType {
  baseType(
    icon: IconsaxPlusLinear.folder_2,
    selectedicon: IconsaxPlusBold.folder_2,
  ),
  audio(
    icon: IconsaxPlusLinear.music,
    selectedicon: IconsaxPlusBold.music,
  ),
  musicAlbum(
    icon: IconsaxPlusLinear.music,
    selectedicon: IconsaxPlusBold.music,
  ),
  musicVideo(
    icon: IconsaxPlusLinear.music,
    selectedicon: IconsaxPlusBold.music,
  ),
  collectionFolder(
    icon: IconsaxPlusLinear.music,
    selectedicon: IconsaxPlusBold.music,
  ),
  video(
    icon: IconsaxPlusLinear.video,
    selectedicon: IconsaxPlusBold.video,
  ),
  movie(
    icon: IconsaxPlusLinear.video_horizontal,
    selectedicon: IconsaxPlusBold.video_horizontal,
  ),
  series(
    icon: IconsaxPlusLinear.video_vertical,
    selectedicon: IconsaxPlusBold.video_vertical,
  ),
  season(
    icon: IconsaxPlusLinear.video_vertical,
    selectedicon: IconsaxPlusBold.video_vertical,
  ),
  episode(
    icon: IconsaxPlusLinear.video_vertical,
    selectedicon: IconsaxPlusBold.video_vertical,
  ),
  photo(
    icon: IconsaxPlusLinear.picture_frame,
    selectedicon: IconsaxPlusBold.picture_frame,
  ),
  person(
    icon: IconsaxPlusLinear.user,
    selectedicon: IconsaxPlusBold.user,
  ),
  photoAlbum(
    icon: IconsaxPlusLinear.gallery,
    selectedicon: IconsaxPlusBold.gallery,
  ),
  folder(
    icon: IconsaxPlusLinear.folder,
    selectedicon: IconsaxPlusBold.folder,
  ),
  boxset(
    icon: IconsaxPlusLinear.bookmark,
    selectedicon: IconsaxPlusBold.bookmark,
  ),
  playlist(
    icon: IconsaxPlusLinear.archive_book,
    selectedicon: IconsaxPlusBold.archive_book,
  ),
  book(
    icon: IconsaxPlusLinear.book,
    selectedicon: IconsaxPlusBold.book,
  );

  const HessflixItemType({required this.icon, required this.selectedicon});

  static Set<HessflixItemType> get playable => {
        HessflixItemType.series,
        HessflixItemType.episode,
        HessflixItemType.season,
        HessflixItemType.movie,
        HessflixItemType.musicVideo,
      };

  static Set<HessflixItemType> get galleryItem => {
        HessflixItemType.photo,
        HessflixItemType.video,
      };

  String label(BuildContext context) {
    return switch (this) {
      HessflixItemType.baseType => context.localized.mediaTypeBase,
      HessflixItemType.audio => context.localized.audio,
      HessflixItemType.collectionFolder => context.localized.collectionFolder,
      HessflixItemType.musicAlbum => context.localized.musicAlbum,
      HessflixItemType.musicVideo => context.localized.video,
      HessflixItemType.video => context.localized.video,
      HessflixItemType.movie => context.localized.mediaTypeMovie,
      HessflixItemType.series => context.localized.mediaTypeSeries,
      HessflixItemType.season => context.localized.mediaTypeSeason,
      HessflixItemType.episode => context.localized.mediaTypeEpisode,
      HessflixItemType.photo => context.localized.mediaTypePhoto,
      HessflixItemType.person => context.localized.mediaTypePerson,
      HessflixItemType.photoAlbum => context.localized.mediaTypePhotoAlbum,
      HessflixItemType.folder => context.localized.mediaTypeFolder,
      HessflixItemType.boxset => context.localized.mediaTypeBoxset,
      HessflixItemType.playlist => context.localized.mediaTypePlaylist,
      HessflixItemType.book => context.localized.mediaTypeBook,
    };
  }

  BaseItemKind get dtoKind => switch (this) {
        HessflixItemType.baseType => BaseItemKind.userrootfolder,
        HessflixItemType.audio => BaseItemKind.audio,
        HessflixItemType.collectionFolder => BaseItemKind.collectionfolder,
        HessflixItemType.musicAlbum => BaseItemKind.musicalbum,
        HessflixItemType.musicVideo => BaseItemKind.video,
        HessflixItemType.video => BaseItemKind.video,
        HessflixItemType.movie => BaseItemKind.movie,
        HessflixItemType.series => BaseItemKind.series,
        HessflixItemType.season => BaseItemKind.season,
        HessflixItemType.episode => BaseItemKind.episode,
        HessflixItemType.photo => BaseItemKind.photo,
        HessflixItemType.person => BaseItemKind.person,
        HessflixItemType.photoAlbum => BaseItemKind.photoalbum,
        HessflixItemType.folder => BaseItemKind.folder,
        HessflixItemType.boxset => BaseItemKind.boxset,
        HessflixItemType.playlist => BaseItemKind.playlist,
        HessflixItemType.book => BaseItemKind.book,
      };

  final IconData icon;
  final IconData selectedicon;
}
