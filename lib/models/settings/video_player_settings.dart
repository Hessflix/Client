import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:hessflix/models/items/media_segments_model.dart';
import 'package:hessflix/util/bitrate_helper.dart';
import 'package:hessflix/util/localization_helper.dart';

part 'video_player_settings.freezed.dart';
part 'video_player_settings.g.dart';

@freezed
class VideoPlayerSettingsModel with _$VideoPlayerSettingsModel {
  const VideoPlayerSettingsModel._();

  factory VideoPlayerSettingsModel({
    double? screenBrightness,
    @Default(BoxFit.contain) BoxFit videoFit,
    @Default(false) bool fillScreen,
    @Default(true) bool hardwareAccel,
    @Default(false) bool useLibass,
    @Default(32) int bufferSize,
    PlayerOptions? playerOptions,
    @Default(100) double internalVolume,
    Set<DeviceOrientation>? allowedOrientations,
    @Default(AutoNextType.smart) AutoNextType nextVideoType,
    @Default(Bitrate.original) Bitrate maxHomeBitrate,
    @Default(Bitrate.original) Bitrate maxInternetBitrate,
    String? audioDevice,
    @Default(defaultSegmentSkipValues) Map<MediaSegmentType, SegmentSkip> segmentSkipSettings,
  }) = _VideoPlayerSettingsModel;

  double get volume => switch (defaultTargetPlatform) {
        TargetPlatform.android || TargetPlatform.iOS => 100,
        _ => internalVolume,
      };

  factory VideoPlayerSettingsModel.fromJson(Map<String, dynamic> json) => _$VideoPlayerSettingsModelFromJson(json);

  PlayerOptions get wantedPlayer => playerOptions ?? PlayerOptions.platformDefaults;

  bool playerSame(VideoPlayerSettingsModel other) {
    return other.hardwareAccel == hardwareAccel && other.useLibass == useLibass && other.bufferSize == bufferSize && other.wantedPlayer == wantedPlayer;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VideoPlayerSettingsModel &&
        other.screenBrightness == screenBrightness &&
        other.videoFit == videoFit &&
        other.fillScreen == fillScreen &&
        other.hardwareAccel == hardwareAccel &&
        other.useLibass == useLibass &&
        other.bufferSize == bufferSize &&
        other.internalVolume == internalVolume &&
        other.playerOptions == playerOptions &&
        other.audioDevice == audioDevice;
  }

  @override
  int get hashCode {
    return screenBrightness.hashCode ^
        videoFit.hashCode ^
        fillScreen.hashCode ^
        hardwareAccel.hashCode ^
        useLibass.hashCode ^
        bufferSize.hashCode ^
        internalVolume.hashCode ^
        audioDevice.hashCode;
  }
}

enum PlayerOptions {
  libMDK,
  libMPV;

  const PlayerOptions();

  static Iterable<PlayerOptions> get available => kIsWeb ? {PlayerOptions.libMPV} : PlayerOptions.values;

  static PlayerOptions get platformDefaults {
    if (kIsWeb) return PlayerOptions.libMPV;
    return switch (defaultTargetPlatform) {
      _ => PlayerOptions.libMPV,
    };
  }

  String label(BuildContext context) => switch (this) {
        PlayerOptions.libMDK => "MDK",
        PlayerOptions.libMPV => "MPV",
      };
}

enum AutoNextType {
  off,
  smart,
  static;

  const AutoNextType();

  String label(BuildContext context) => switch (this) {
        AutoNextType.off => context.localized.off,
        AutoNextType.smart => context.localized.autoNextOffSmartTitle,
        AutoNextType.static => context.localized.autoNextOffStaticTitle,
      };

  String desc(BuildContext context) => switch (this) {
        AutoNextType.off => context.localized.off,
        AutoNextType.smart => context.localized.autoNextOffSmartDesc,
        AutoNextType.static => context.localized.autoNextOffStaticDesc,
      };
}
