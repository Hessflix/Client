import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smtc_windows/smtc_windows.dart' if (dart.library.html) 'package:hessflix/stubs/web/smtc_web.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/media_streams_model.dart';
import 'package:hessflix/models/playback/playback_model.dart';
import 'package:hessflix/models/settings/video_player_settings.dart';
import 'package:hessflix/providers/settings/client_settings_provider.dart';
import 'package:hessflix/providers/settings/video_player_settings_provider.dart';
import 'package:hessflix/providers/video_player_provider.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/wrappers/players/base_player.dart';
import 'package:hessflix/wrappers/players/lib_mdk.dart'
    if (dart.library.html) 'package:hessflix/stubs/web/lib_mdk_web.dart';
import 'package:hessflix/wrappers/players/lib_mpv.dart';
import 'package:hessflix/wrappers/players/player_states.dart';

class MediaControlsWrapper extends BaseAudioHandler {
  MediaControlsWrapper({required this.ref});

  BasePlayer? _player;

  bool get hasPlayer => _player != null;

  PlayerOptions? get backend => switch (_player) {
        LibMPV _ => PlayerOptions.libMPV,
        LibMDK _ => PlayerOptions.libMDK,
        _ => null,
      };

  Stream<PlayerState>? get stateStream => _player?.stateStream;
  PlayerState? get lastState => _player?.lastState;

  Widget? subtitleWidget(bool showOverlay) => _player?.subtitles(showOverlay);
  Widget? videoWidget(Key key, BoxFit fit) => _player?.videoWidget(key, fit);

  final Ref ref;

  List<StreamSubscription> subscriptions = [];
  SMTCWindows? smtc;

  bool initMediaControls = false;

  Future<void> init() async {
    if (!initMediaControls) {
      await AudioService.init(
        builder: () => this,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'tv.hessflix.client.channel.playback',
          androidNotificationChannelName: 'Video playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          rewindInterval: Duration(seconds: 10),
          fastForwardInterval: Duration(seconds: 15),
          androidNotificationChannelDescription: "Playback",
          androidShowNotificationBadge: true,
        ),
      );
      initMediaControls = true;
    }

    final player = switch (ref.read(videoPlayerSettingsProvider.select((value) => value.wantedPlayer))) {
      PlayerOptions.libMDK => LibMDK(),
      PlayerOptions.libMPV => LibMPV(),
    };

    setup(player);
  }

  Future<void> dispose() async => _player?.dispose();

  Future<void> setup(BasePlayer newPlayer) async {
    _player = newPlayer;
    await newPlayer.init(ref.read(videoPlayerSettingsProvider));
    _initPlayer();
  }

  void _initPlayer() {
    for (var element in subscriptions) {
      element.cancel();
    }
    stop();
    _subscribePlayer();
  }

  Future<void> open(String url, bool play) async => _player?.open(url, play);

  void _subscribePlayer() {
    if (Platform.isWindows && !kIsWeb) {
      smtc = SMTCWindows(
        config: const SMTCConfig(
          fastForwardEnabled: true,
          nextEnabled: false,
          pauseEnabled: true,
          playEnabled: true,
          rewindEnabled: true,
          prevEnabled: false,
          stopEnabled: true,
        ),
      );

      if (smtc != null) {
        subscriptions.add(
          smtc!.buttonPressStream.listen((event) {
            switch (event) {
              case PressedButton.play:
                play();
                break;
              case PressedButton.pause:
                pause();
                break;
              case PressedButton.fastForward:
                fastForward();
                break;
              case PressedButton.rewind:
                rewind();
                break;
              case PressedButton.previous:
                break;
              case PressedButton.stop:
                stop();
                break;
              default:
                break;
            }
          }),
        );
      }
    }

    subscriptions.add(_player!.stateStream.listen((value) {
      playbackState.add(playbackState.value.copyWith(
        bufferedPosition: value.buffer,
      ));
      playbackState.add(playbackState.value.copyWith(
        processingState: value.buffering ? AudioProcessingState.buffering : AudioProcessingState.ready,
      ));
      playbackState.add(playbackState.value.copyWith(
        updatePosition: value.position,
      ));
      smtc?.setPosition(value.position);
      playbackState.add(playbackState.value.copyWith(
        playing: value.playing,
      ));
      smtc?.setPlaybackStatus(value.playing ? PlaybackStatus.playing : PlaybackStatus.paused);
    }));
  }

  @override
  Future<void> pause() async {
    await _player?.pause();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [MediaControl.play],
    ));
    WakelockPlus.disable();
    final playerState = _player;
    if (playerState != null) {
      ref.read(playBackModel)?.updatePlaybackPosition(playerState.lastState.position, false, ref);
    }
  }

  @override
  Future<void> play() async {
    WakelockPlus.enable();
    _player?.play();
    if (!ref.read(clientSettingsProvider).enableMediaKeys) return;

    final playBackItem = ref.read(playBackModel.select((value) => value?.item));
    final currentPosition = await ref.read(playBackModel.select((value) => value?.startDuration()));
    final poster = playBackItem?.images?.firstOrNull;

    if (playBackItem == null) return;

    windowSMTCSetup(playBackItem, currentPosition ?? Duration.zero);

    //Everything else setup
    mediaItem.add(MediaItem(
      id: playBackItem.id,
      title: playBackItem.title,
      rating: Rating.newHeartRating(playBackItem.userData.isFavourite),
      duration: playBackItem.overview.runTime ?? const Duration(seconds: 0),
      artUri: poster != null ? Uri.parse(poster.path) : null,
    ));
    playbackState.add(PlaybackState(
      playing: true,
      controls: [
        MediaControl.pause,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.fastForward,
        MediaAction.setSpeed,
        MediaAction.rewind,
      },
      processingState: AudioProcessingState.ready,
    ));

    ref.read(playBackModel)?.playbackStarted(currentPosition ?? Duration.zero, ref);

    return super.play();
  }

  Future<void> windowSMTCSetup(ItemBaseModel playBackItem, Duration currentPosition) async {
    final poster = playBackItem.images?.firstOrNull;
    final mainContext = ref.read(localizationContextProvider);

    //Windows setup
    smtc?.updateMetadata(MusicMetadata(
      title: playBackItem.title,
      artist: mainContext != null ? playBackItem.label(mainContext) : null,
      thumbnail: poster?.path,
    ));
    smtc?.updateTimeline(
      PlaybackTimeline(
        startTimeMs: currentPosition.inMilliseconds,
        endTimeMs: (playBackItem.overview.runTime ?? const Duration(seconds: 0)).inMilliseconds,
        positionMs: 0,
        minSeekTimeMs: 0,
        maxSeekTimeMs: (playBackItem.overview.runTime ?? const Duration(seconds: 0)).inMilliseconds,
      ),
    );

    smtc?.enableSmtc();
    smtc?.setPlaybackStatus(PlaybackStatus.playing);
  }

  @override
  Future<void> stop() async {
    WakelockPlus.disable();
    super.stop();
    _player?.stop();

    final position = _player?.lastState.position;
    final totalDuration = _player?.lastState.duration;

    //Small delay so we don't post right after playback/progress update
    await Future.delayed(const Duration(seconds: 1));

    ref.read(playBackModel)?.playbackStopped(position ?? Duration.zero, totalDuration, ref);
    ref.read(mediaPlaybackProvider.notifier).update((state) => state.copyWith(position: Duration.zero));

    smtc?.setPlaybackStatus(PlaybackStatus.stopped);
    smtc?.clearMetadata();
    smtc?.disableSmtc();

    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.completed,
        controls: [],
      ),
    );
    return super.stop();
  }

  Future<void> playOrPause() async {
    await _player?.playOrPause();
    final playing = _player?.lastState.playing ?? false;
    playbackState.add(playbackState.value.copyWith(
      playing: playing,
      controls: [playing ? MediaControl.pause : MediaControl.play],
    ));

    if (playing) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    final playerState = _player;
    if (playerState != null) {
      ref
          .read(playBackModel)
          ?.updatePlaybackPosition(playerState.lastState.position, playerState.lastState.playing, ref);
    }
  }

  Future<int> setAudioTrack(AudioStreamModel? model, PlaybackModel playbackModel) async =>
      await _player?.setAudioTrack(model, playbackModel) ?? -1;

  Future<int> setSubtitleTrack(SubStreamModel? model, PlaybackModel playbackModel) async =>
      await _player?.setSubtitleTrack(model, playbackModel) ?? -1;

  Future<void> setVolume(double speed) async => _player?.setVolume(speed);

  @override
  Future<void> seek(Duration position) {
    _player?.seek(position);
    return super.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) {
    _player?.setSpeed(speed);
    return super.setSpeed(speed);
  }
}
