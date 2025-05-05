import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/chapters_model.dart';
import 'package:hessflix/models/items/media_segments_model.dart';
import 'package:hessflix/models/items/media_streams_model.dart';
import 'package:hessflix/models/items/trick_play_model.dart';
import 'package:hessflix/models/playback/playback_model.dart';
import 'package:hessflix/models/syncing/sync_item.dart';
import 'package:hessflix/providers/sync_provider.dart';
import 'package:hessflix/util/duration_extensions.dart';
import 'package:hessflix/util/list_extensions.dart';
import 'package:hessflix/wrappers/media_control_wrapper.dart';

class OfflinePlaybackModel extends PlaybackModel {
  OfflinePlaybackModel({
    required this.syncedItem,
    super.mediaStreams,
    super.playbackInfo,
    required super.item,
    required super.media,
    super.mediaSegments,
    super.trickPlay,
    super.queue = const [],
    this.syncedQueue = const [],
  });

  final SyncedItem syncedItem;

  @override
  List<Chapter>? get chapters => syncedItem.chapters;

  @override
  Future<Duration>? startDuration() async => item.userData.playBackPosition;

  @override
  ItemBaseModel? get nextVideo => queue.nextOrNull(item);
  @override
  ItemBaseModel? get previousVideo => queue.previousOrNull(item);

  @override
  List<SubStreamModel> get subStreams => [SubStreamModel.no(), ...syncedItem.subtitles];

  @override
  Future<OfflinePlaybackModel> setSubtitle(SubStreamModel? model, MediaControlsWrapper player) async {
    final newIndex = await player.setSubtitleTrack(model, this);
    return copyWith(mediaStreams: () => mediaStreams?.copyWith(defaultSubStreamIndex: newIndex));
  }

  @override
  List<AudioStreamModel> get audioStreams => [AudioStreamModel.no(), ...mediaStreams?.audioStreams ?? []];

  @override
  Future<OfflinePlaybackModel>? setAudio(AudioStreamModel? model, MediaControlsWrapper player) async {
    final newIndex = await player.setAudioTrack(model, this);
    return copyWith(mediaStreams: () => mediaStreams?.copyWith(defaultAudioStreamIndex: newIndex));
  }

  @override
  Future<PlaybackModel?> playbackStarted(Duration position, Ref ref) async {
    return null;
  }

  @override
  Future<PlaybackModel?> playbackStopped(Duration position, Duration? totalDuration, Ref ref) async {
    return null;
  }

  @override
  Future<PlaybackModel?> updatePlaybackPosition(Duration position, bool isPlaying, Ref ref) async {
    final progress = position.inMilliseconds / (item.overview.runTime?.inMilliseconds ?? 0) * 100;
    final newItem = syncedItem.copyWith(
      userData: syncedItem.userData?.copyWith(
        playbackPositionTicks: position.toRuntimeTicks,
        progress: progress,
        played: isPlayed(position, item.overview.runTime ?? Duration.zero),
      ),
    );
    await ref.read(syncProvider.notifier).updateItem(newItem);
    return this;
  }

  bool isPlayed(Duration position, Duration totalDuration) {
    Duration startBuffer = totalDuration * 0.05;
    Duration endBuffer = totalDuration * 0.90;

    Duration validStart = startBuffer;
    Duration validEnd = endBuffer;

    if (position >= validStart && position <= validEnd) {
      return true;
    }

    return false;
  }

  @override
  String toString() => 'OfflinePlaybackModel(item: $item, syncedItem: $syncedItem)';

  final List<SyncedItem> syncedQueue;

  @override
  OfflinePlaybackModel copyWith({
    ItemBaseModel? item,
    ValueGetter<Media?>? media,
    SyncedItem? syncedItem,
    ValueGetter<MediaStreamsModel?>? mediaStreams,
    ValueGetter<MediaSegmentsModel?>? mediaSegments,
    ValueGetter<TrickPlayModel?>? trickPlay,
    List<ItemBaseModel>? queue,
    List<SyncedItem>? syncedQueue,
  }) {
    return OfflinePlaybackModel(
      item: item ?? this.item,
      media: media != null ? media() : this.media,
      syncedItem: syncedItem ?? this.syncedItem,
      mediaStreams: mediaStreams != null ? mediaStreams() : this.mediaStreams,
      mediaSegments: mediaSegments != null ? mediaSegments() : this.mediaSegments,
      trickPlay: trickPlay != null ? trickPlay() : this.trickPlay,
      queue: queue ?? this.queue,
      syncedQueue: syncedQueue ?? this.syncedQueue,
    );
  }
}
