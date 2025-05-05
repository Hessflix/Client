// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:hessflix/models/syncing/sync_item.dart';

part 'sync_settings_model.freezed.dart';

@Freezed(toJson: false, fromJson: false)
class SyncSettingsModel with _$SyncSettingsModel {
  const SyncSettingsModel._();

  factory SyncSettingsModel({
    @Default([]) List<SyncedItem> items,
  }) = _SyncSettignsModel;
}
