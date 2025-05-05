// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_filters_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LibraryFiltersModelImpl _$$LibraryFiltersModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LibraryFiltersModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isFavourite: json['isFavourite'] as bool,
      ids: (json['ids'] as List<dynamic>).map((e) => e as String).toList(),
      genres: Map<String, bool>.from(json['genres'] as Map),
      filters: (json['filters'] as Map<String, dynamic>).map(
        (k, e) => MapEntry($enumDecode(_$ItemFilterEnumMap, k), e as bool),
      ),
      studios: const StudioEncoder().fromJson(json['studios'] as String),
      tags: Map<String, bool>.from(json['tags'] as Map),
      years: (json['years'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(int.parse(k), e as bool),
      ),
      officialRatings: Map<String, bool>.from(json['officialRatings'] as Map),
      types: (json['types'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$HessflixItemTypeEnumMap, k), e as bool),
      ),
      sortingOption:
          $enumDecode(_$SortingOptionsEnumMap, json['sortingOption']),
      sortOrder: $enumDecode(_$SortingOrderEnumMap, json['sortOrder']),
      favourites: json['favourites'] as bool,
      hideEmptyShows: json['hideEmptyShows'] as bool,
      recursive: json['recursive'] as bool,
      groupBy: $enumDecode(_$GroupByEnumMap, json['groupBy']),
    );

Map<String, dynamic> _$$LibraryFiltersModelImplToJson(
        _$LibraryFiltersModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isFavourite': instance.isFavourite,
      'ids': instance.ids,
      'genres': instance.genres,
      'filters':
          instance.filters.map((k, e) => MapEntry(_$ItemFilterEnumMap[k], e)),
      'studios': const StudioEncoder().toJson(instance.studios),
      'tags': instance.tags,
      'years': instance.years.map((k, e) => MapEntry(k.toString(), e)),
      'officialRatings': instance.officialRatings,
      'types': instance.types
          .map((k, e) => MapEntry(_$HessflixItemTypeEnumMap[k]!, e)),
      'sortingOption': _$SortingOptionsEnumMap[instance.sortingOption]!,
      'sortOrder': _$SortingOrderEnumMap[instance.sortOrder]!,
      'favourites': instance.favourites,
      'hideEmptyShows': instance.hideEmptyShows,
      'recursive': instance.recursive,
      'groupBy': _$GroupByEnumMap[instance.groupBy]!,
    };

const _$ItemFilterEnumMap = {
  ItemFilter.swaggerGeneratedUnknown: null,
  ItemFilter.isfolder: 'IsFolder',
  ItemFilter.isnotfolder: 'IsNotFolder',
  ItemFilter.isunplayed: 'IsUnplayed',
  ItemFilter.isplayed: 'IsPlayed',
  ItemFilter.isfavorite: 'IsFavorite',
  ItemFilter.isresumable: 'IsResumable',
  ItemFilter.likes: 'Likes',
  ItemFilter.dislikes: 'Dislikes',
  ItemFilter.isfavoriteorlikes: 'IsFavoriteOrLikes',
};

const _$HessflixItemTypeEnumMap = {
  HessflixItemType.baseType: 'baseType',
  HessflixItemType.audio: 'audio',
  HessflixItemType.musicAlbum: 'musicAlbum',
  HessflixItemType.musicVideo: 'musicVideo',
  HessflixItemType.collectionFolder: 'collectionFolder',
  HessflixItemType.video: 'video',
  HessflixItemType.movie: 'movie',
  HessflixItemType.series: 'series',
  HessflixItemType.season: 'season',
  HessflixItemType.episode: 'episode',
  HessflixItemType.photo: 'photo',
  HessflixItemType.person: 'person',
  HessflixItemType.photoAlbum: 'photoAlbum',
  HessflixItemType.folder: 'folder',
  HessflixItemType.boxset: 'boxset',
  HessflixItemType.playlist: 'playlist',
  HessflixItemType.book: 'book',
};

const _$SortingOptionsEnumMap = {
  SortingOptions.name: 'name',
  SortingOptions.communityRating: 'communityRating',
  SortingOptions.parentalRating: 'parentalRating',
  SortingOptions.dateAdded: 'dateAdded',
  SortingOptions.dateLastContentAdded: 'dateLastContentAdded',
  SortingOptions.favorite: 'favorite',
  SortingOptions.datePlayed: 'datePlayed',
  SortingOptions.folders: 'folders',
  SortingOptions.playCount: 'playCount',
  SortingOptions.releaseDate: 'releaseDate',
  SortingOptions.runTime: 'runTime',
  SortingOptions.random: 'random',
};

const _$SortingOrderEnumMap = {
  SortingOrder.ascending: 'ascending',
  SortingOrder.descending: 'descending',
};

const _$GroupByEnumMap = {
  GroupBy.none: 'none',
  GroupBy.name: 'name',
  GroupBy.genres: 'genres',
  GroupBy.dateAdded: 'dateAdded',
  GroupBy.tags: 'tags',
  GroupBy.releaseDate: 'releaseDate',
  GroupBy.rating: 'rating',
  GroupBy.type: 'type',
};
