import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:hessflix/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/video_properties.dart';

class MediaStreamsModel {
  final int? versionStreamIndex;
  final int? defaultAudioStreamIndex;
  final int? defaultSubStreamIndex;
  final List<VersionStreamModel> versionStreams;
  MediaStreamsModel({
    this.versionStreamIndex,
    this.defaultAudioStreamIndex,
    this.defaultSubStreamIndex,
    required this.versionStreams,
  });

  VersionStreamModel? get currentVersionStream => versionStreams.elementAtOrNull(versionStreamIndex ?? 0);

  List<VideoStreamModel> get videoStreams => currentVersionStream?.videoStreams ?? [];
  List<AudioStreamModel> get audioStreams => currentVersionStream?.audioStreams ?? [];
  List<SubStreamModel> get subStreams => currentVersionStream?.subStreams ?? [];

  bool get isNull {
    return defaultAudioStreamIndex == null ||
        defaultSubStreamIndex == null ||
        audioStreams.isEmpty ||
        subStreams.isEmpty;
  }

  bool get isNotEmpty {
    return audioStreams.isNotEmpty && subStreams.isNotEmpty;
  }

  AudioStreamModel? get currentAudioStream {
    if (defaultAudioStreamIndex == -1 || defaultAudioStreamIndex == null) {
      return AudioStreamModel.no();
    }
    return audioStreams.firstWhereOrNull((element) => element.index == defaultAudioStreamIndex) ??
        audioStreams.firstOrNull;
  }

  SubStreamModel? get currentSubStream {
    if (defaultSubStreamIndex == -1 || defaultSubStreamIndex == null) {
      return SubStreamModel.no();
    }
    return subStreams.firstWhereOrNull((element) => element.index == defaultSubStreamIndex) ?? subStreams.firstOrNull;
  }

  DisplayProfile? get displayProfile {
    return DisplayProfile.fromVideoStreams(videoStreams);
  }

  Resolution? get resolution {
    return Resolution.fromVideoStream(videoStreams.firstOrNull);
  }

  String? get resolutionText {
    final stream = videoStreams.firstOrNull;
    if (stream == null) return null;
    return "${stream.width}x${stream.height}";
  }

  Widget? audioIcon(
    BuildContext context,
    Function()? onTap,
  ) {
    final audioStream = audioStreams.firstWhereOrNull((element) => element.isDefault) ?? audioStreams.firstOrNull;
    if (audioStream == null) return null;
    return DefaultVideoInformationBox(
      onTap: onTap,
      child: Text(
        audioStream.title,
      ),
    );
  }

  Widget subtitleIcon(
    BuildContext context,
    Function()? onTap,
  ) {
    return DefaultVideoInformationBox(
      onTap: onTap,
      child: Icon(
        subStreams.isNotEmpty ? Icons.subtitles_rounded : Icons.subtitles_off_outlined,
      ),
    );
  }

  static MediaStreamsModel fromMediaStreamsList(
    List<dto.MediaSourceInfo>? mediaSource,
    Ref ref,
  ) {
    return MediaStreamsModel(
        defaultAudioStreamIndex: mediaSource?.firstOrNull?.defaultAudioStreamIndex,
        defaultSubStreamIndex: mediaSource?.firstOrNull?.defaultSubtitleStreamIndex,
        versionStreams: mediaSource?.mapIndexed(
              (index, element) {
                final streams = element.mediaStreams ?? [];
                return VersionStreamModel(
                    name: element.name ?? "",
                    index: index,
                    id: element.id,
                    defaultAudioStreamIndex: element.defaultAudioStreamIndex,
                    defaultSubStreamIndex: element.defaultSubtitleStreamIndex,
                    videoStreams: streams
                        .where((element) => element.type == dto.MediaStreamType.video)
                        .map(
                          (e) => VideoStreamModel.fromMediaStream(e),
                        )
                        .sortByExternal(),
                    audioStreams: streams
                        .where((element) => element.type == dto.MediaStreamType.audio)
                        .map(
                          (e) => AudioStreamModel.fromMediaStream(e),
                        )
                        .sortByExternal(),
                    subStreams: streams
                        .where((element) => element.type == dto.MediaStreamType.subtitle)
                        .map(
                          (sub) => SubStreamModel.fromMediaStream(sub, ref),
                        )
                        .sortByExternal());
              },
            ).toList() ??
            []);
  }

  MediaStreamsModel copyWith({
    int? versionStreamIndex,
    int? defaultAudioStreamIndex,
    int? defaultSubStreamIndex,
    List<VersionStreamModel>? versionStreams,
  }) {
    final streamIndexChanged = versionStreamIndex != this.versionStreamIndex && versionStreamIndex != null;
    final currentVersionStreams = versionStreams ?? this.versionStreams;
    return MediaStreamsModel(
      versionStreamIndex: versionStreamIndex ?? this.versionStreamIndex,
      defaultAudioStreamIndex: streamIndexChanged
          ? currentVersionStreams.elementAtOrNull(versionStreamIndex)?.defaultAudioStreamIndex
          : defaultAudioStreamIndex ?? this.defaultAudioStreamIndex,
      defaultSubStreamIndex: streamIndexChanged
          ? currentVersionStreams.elementAtOrNull(versionStreamIndex)?.defaultSubStreamIndex
          : defaultSubStreamIndex ?? this.defaultSubStreamIndex,
      versionStreams: versionStreams ?? this.versionStreams,
    );
  }

  @override
  String toString() {
    return 'MediaStreamsModel(defaultAudioStreamIndex: $defaultAudioStreamIndex, defaultSubStreamIndex: $defaultSubStreamIndex, videoStreams: $videoStreams, audioStreams: $audioStreams, subStreams: $subStreams)';
  }
}

class StreamModel {
  final String name;
  final String codec;
  final bool isDefault;
  final bool isExternal;
  final int index;
  StreamModel({
    required this.name,
    required this.codec,
    required this.isDefault,
    required this.isExternal,
    required this.index,
  });
}

class VersionStreamModel {
  final String name;
  final int index;
  final String? id;
  final int? defaultAudioStreamIndex;
  final int? defaultSubStreamIndex;
  final List<VideoStreamModel> videoStreams;
  final List<AudioStreamModel> audioStreams;
  final List<SubStreamModel> subStreams;

  VersionStreamModel({
    required this.name,
    required this.index,
    this.id,
    required this.defaultAudioStreamIndex,
    required this.defaultSubStreamIndex,
    required this.videoStreams,
    required this.audioStreams,
    required this.subStreams,
  });
}

class VideoStreamModel extends StreamModel {
  final int width;
  final int height;
  final int? bitRate;
  final double frameRate;
  final String? videoDoViTitle;
  final VideoRangeType? videoRangeType;
  VideoStreamModel({
    required super.name,
    required super.codec,
    required super.isDefault,
    required super.isExternal,
    required super.index,
    required this.videoDoViTitle,
    required this.videoRangeType,
    required this.bitRate,
    required this.width,
    required this.height,
    required this.frameRate,
  });

  factory VideoStreamModel.fromMediaStream(dto.MediaStream stream) {
    return VideoStreamModel(
      name: stream.title ?? "",
      isDefault: stream.isDefault ?? false,
      codec: stream.codec ?? "",
      videoDoViTitle: stream.videoDoViTitle,
      bitRate: stream.bitRate,
      videoRangeType: stream.videoRangeType,
      width: stream.width ?? 0,
      height: stream.height ?? 0,
      frameRate: stream.realFrameRate ?? 24,
      isExternal: stream.isExternal ?? false,
      index: stream.index ?? -1,
    );
  }
  String get prettyName {
    return "${Resolution.fromVideoStream(this)?.value} - ${DisplayProfile.fromVideoStream(this).value} - (${codec.toUpperCase()})";
  }

  @override
  String toString() {
    return 'VideoStreamModel(width: $width, height: $height, frameRate: $frameRate, videoDoViTitle: $videoDoViTitle, videoRangeType: $videoRangeType)';
  }
}

//Instead of using sortBy(a.isExternal etc..) this one seems to be more consistent for some reason
extension SortByExternalExtension<T extends StreamModel> on Iterable<T> {
  List<T> sortByExternal() {
    return [...where((element) => !element.isExternal), ...where((element) => element.isExternal)];
  }
}

class AudioStreamModel extends StreamModel {
  final String displayTitle;
  final String language;
  final String channelLayout;

  AudioStreamModel({
    required this.displayTitle,
    required super.name,
    required super.codec,
    required super.isDefault,
    required super.isExternal,
    required super.index,
    required this.language,
    required this.channelLayout,
  });

  factory AudioStreamModel.fromMediaStream(dto.MediaStream stream) {
    return AudioStreamModel(
      displayTitle: stream.displayTitle ?? "",
      name: stream.title ?? "",
      isDefault: stream.isDefault ?? false,
      codec: stream.codec ?? "",
      language: stream.language ?? "Unknown",
      channelLayout: stream.channelLayout ?? "",
      isExternal: stream.isExternal ?? false,
      index: stream.index ?? -1,
    );
  }

  String label(BuildContext context) {
    if (index == -1) {
      return context.localized.off;
    } else {
      return displayTitle;
    }
  }

  String get title =>
      [name, language, codec, channelLayout].nonNulls.where((element) => element.isNotEmpty).join(' - ');

  AudioStreamModel.no({
    super.name = 'Off',
    this.displayTitle = 'Off',
    this.language = '',
    super.codec = '',
    this.channelLayout = '',
    super.isDefault = false,
    super.isExternal = false,
    super.index = -1,
  });
}

class SubStreamModel extends StreamModel {
  String id;
  String title;
  String displayTitle;
  String language;
  String? url;
  bool supportsExternalStream;
  SubStreamModel({
    required super.name,
    required this.id,
    required this.title,
    required this.displayTitle,
    required this.language,
    this.url,
    required super.codec,
    required super.isDefault,
    required super.isExternal,
    required super.index,
    this.supportsExternalStream = false,
  });

  SubStreamModel.no({
    super.name = 'Off',
    this.id = 'Off',
    this.title = 'Off',
    this.displayTitle = 'Off',
    this.language = '',
    this.url = '',
    super.codec = '',
    super.isDefault = false,
    super.isExternal = false,
    super.index = -1,
    this.supportsExternalStream = false,
  });

  String label(BuildContext context) {
    if (index == -1) {
      return context.localized.off;
    } else {
      return displayTitle;
    }
  }

  factory SubStreamModel.fromMediaStream(dto.MediaStream stream, Ref ref) {
    return SubStreamModel(
      name: stream.title ?? "",
      title: stream.title ?? "",
      displayTitle: stream.displayTitle ?? "",
      language: stream.language ?? "Unknown",
      isDefault: stream.isDefault ?? false,
      codec: stream.codec ?? "",
      id: stream.hashCode.toString(),
      supportsExternalStream: stream.supportsExternalStream ?? false,
      url: stream.deliveryUrl != null
          ? "${ref.read(userProvider)?.server ?? ""}${stream.deliveryUrl}}".replaceAll(".vtt", ".srt")
          : null,
      isExternal: stream.isExternal ?? false,
      index: stream.index ?? -1,
    );
  }

  SubStreamModel copyWith({
    String? name,
    String? id,
    String? title,
    String? displayTitle,
    String? language,
    ValueGetter<String?>? url,
    String? codec,
    bool? isDefault,
    bool? isExternal,
    int? index,
    bool? supportsExternalStream,
  }) {
    return SubStreamModel(
      name: name ?? this.name,
      id: id ?? this.id,
      title: title ?? this.title,
      displayTitle: displayTitle ?? this.displayTitle,
      language: language ?? this.language,
      url: url != null ? url() : this.url,
      supportsExternalStream: supportsExternalStream ?? this.supportsExternalStream,
      codec: codec ?? this.codec,
      isDefault: isDefault ?? this.isDefault,
      isExternal: isExternal ?? this.isExternal,
      index: index ?? this.index,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
      'title': title,
      'displayTitle': displayTitle,
      'language': language,
      'url': url,
      'supportsExternalStream': supportsExternalStream,
      'codec': codec,
      'isExternal': isExternal,
      'isDefault': isDefault,
      'index': index,
    };
  }

  factory SubStreamModel.fromMap(Map<String, dynamic> map) {
    return SubStreamModel(
      name: map['name'] ?? '',
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      displayTitle: map['displayTitle'] ?? '',
      language: map['language'] ?? '',
      url: map['url'],
      supportsExternalStream: map['supportsExternalStream'] ?? false,
      codec: map['codec'] ?? '',
      isDefault: map['isDefault'] ?? false,
      isExternal: map['isExternal'] ?? false,
      index: map['index'] ?? -1,
    );
  }

  String toJson() => json.encode(toMap());

  factory SubStreamModel.fromJson(String source) => SubStreamModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SubFile(title: $title, displayTitle: $displayTitle, language: $language, url: $url, isExternal: $isExternal)';
  }
}
