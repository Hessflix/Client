import 'package:flutter/material.dart';

import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:hessflix/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:hessflix/models/item_base_model.dart';

extension CollectionTypeExtension on CollectionType {
  IconData get iconOutlined {
    return getIconType(true);
  }

  IconData get icon {
    return getIconType(false);
  }

  Set<HessflixItemType> get itemKinds {
    switch (this) {
      case CollectionType.movies:
        return {HessflixItemType.movie};
      case CollectionType.tvshows:
        return {HessflixItemType.series};
      case CollectionType.homevideos:
        return {HessflixItemType.photoAlbum, HessflixItemType.folder, HessflixItemType.photo, HessflixItemType.video};
      default:
        return {};
    }
  }

  IconData getIconType(bool outlined) {
    switch (this) {
      case CollectionType.movies:
        return outlined ? IconsaxPlusLinear.video_horizontal : IconsaxPlusBold.video_horizontal;
      case CollectionType.tvshows:
        return outlined ? IconsaxPlusLinear.video_vertical : IconsaxPlusBold.video_vertical;
      case CollectionType.boxsets:
        return outlined ? IconsaxPlusLinear.box : IconsaxPlusBold.box;
      case CollectionType.folders:
        return outlined ? IconsaxPlusLinear.folder_2 : IconsaxPlusBold.folder_2;
      case CollectionType.homevideos:
        return outlined ? IconsaxPlusLinear.gallery : IconsaxPlusBold.gallery;
      case CollectionType.books:
        return outlined ? IconsaxPlusLinear.book : IconsaxPlusBold.book;
      case CollectionType.playlists:
        return outlined ? IconsaxPlusLinear.archive : IconsaxPlusBold.archive;
      default:
        return IconsaxPlusLinear.information;
    }
  }
}
