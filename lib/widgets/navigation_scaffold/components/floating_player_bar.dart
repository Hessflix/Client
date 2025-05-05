import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:hessflix/models/media_playback_model.dart';
import 'package:hessflix/providers/settings/video_player_settings_provider.dart';
import 'package:hessflix/providers/video_player_provider.dart';
import 'package:hessflix/screens/shared/hessflix_snackbar.dart';
import 'package:hessflix/screens/shared/flat_button.dart';
import 'package:hessflix/screens/video_player/video_player.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/duration_extensions.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/refresh_state.dart';

const videoPlayerHeroTag = "HeroPlayer";

class FloatingPlayerBar extends ConsumerStatefulWidget {
  const FloatingPlayerBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CurrentlyPlayingBarState();
}

class _CurrentlyPlayingBarState extends ConsumerState<FloatingPlayerBar> {
  bool showExpandButton = false;

  Future<void> openFullScreenPlayer() async {
    setState(() => showExpandButton = false);
    ref.read(mediaPlaybackProvider.notifier).update((state) => state.copyWith(state: VideoPlayerState.fullScreen));
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => const VideoPlayer(),
      ),
    );
    if (AdaptiveLayout.of(context).isDesktop || kIsWeb) {
      final fullScreen = await windowManager.isFullScreen();
      if (fullScreen) {
        await windowManager.setFullScreen(false);
      }
    }
    if (context.mounted) {
      context.refreshData();
    }
  }

  Future<void> stopPlayer() async {
    ref.read(mediaPlaybackProvider.notifier).update((state) => state.copyWith(state: VideoPlayerState.disposed));
    return ref.read(videoPlayerProvider).stop();
  }

  @override
  Widget build(BuildContext context) {
    final playbackInfo = ref.watch(mediaPlaybackProvider);
    final player = ref.watch(videoPlayerProvider);
    final playbackModel = ref.watch(playBackModel.select((value) => value?.item));
    final progress = playbackInfo.position.inMilliseconds / playbackInfo.duration.inMilliseconds;
    return Dismissible(
      key: const Key("CurrentlyPlayingBar"),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.up) {
          await openFullScreenPlayer();
        } else {
          await stopPlayer();
        }
        return false;
      },
      direction: DismissDirection.vertical,
      child: InkWell(
        onLongPress: () {
          hessflixSnackbar(context, title: "Swipe up/down to open/close the player");
        },
        child: Card(
          elevation: 5,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50, maxHeight: 85),
            child: LayoutBuilder(builder: (context, constraints) {
              return Row(
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                if (playbackInfo.state == VideoPlayerState.minimized)
                                  Card(
                                    child: SizedBox(
                                      child: AspectRatio(
                                        aspectRatio: 1.67,
                                        child: MouseRegion(
                                          onEnter: (event) => setState(() => showExpandButton = true),
                                          onExit: (event) => setState(() => showExpandButton = false),
                                          child: Stack(
                                            children: [
                                              Hero(
                                                tag: videoPlayerHeroTag,
                                                child: player.videoWidget(
                                                      UniqueKey(),
                                                      BoxFit.fitHeight,
                                                    ) ??
                                                    const SizedBox.shrink(),
                                              ),
                                              Positioned.fill(
                                                child: Tooltip(
                                                  message: "Expand player",
                                                  waitDuration: const Duration(milliseconds: 500),
                                                  child: AnimatedOpacity(
                                                    opacity: showExpandButton ? 1 : 0,
                                                    duration: const Duration(milliseconds: 125),
                                                    child: Container(
                                                      color: Colors.black.withValues(alpha: 0.6),
                                                      child: FlatButton(
                                                        onTap: () async => openFullScreenPlayer(),
                                                        child: const Icon(Icons.keyboard_arrow_up_rounded),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          playbackModel?.title ?? "",
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                      ),
                                      if (playbackModel?.detailedName(context)?.isNotEmpty == true)
                                        Flexible(
                                          child: Text(
                                            playbackModel?.detailedName(context) ?? "",
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!progress.isNaN && constraints.maxWidth > 500)
                                  Text(
                                      "${playbackInfo.position.readAbleDuration} / ${playbackInfo.duration.readAbleDuration}"),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: IconButton.filledTonal(
                                    onPressed: () => ref.read(videoPlayerProvider).playOrPause(),
                                    icon: playbackInfo.playing
                                        ? const Icon(Icons.pause_rounded)
                                        : const Icon(Icons.play_arrow_rounded),
                                  ),
                                ),
                                if (constraints.maxWidth > 500) ...{
                                  IconButton(
                                    onPressed: () {
                                      final volume = player.lastState?.volume == 0 ? 100.0 : 0.0;
                                      player.setVolume(volume);
                                    },
                                    icon: Icon(
                                      ref.watch(videoPlayerSettingsProvider.select((value) => value.volume)) <= 0
                                          ? IconsaxPlusBold.volume_cross
                                          : IconsaxPlusBold.volume_high,
                                    ),
                                  ),
                                },
                                Tooltip(
                                  message: context.localized.stop,
                                  waitDuration: const Duration(milliseconds: 500),
                                  child: IconButton(
                                    onPressed: () async => stopPlayer(),
                                    icon: const Icon(IconsaxPlusBold.stop),
                                  ),
                                ),
                              ].addInBetween(const SizedBox(width: 6)),
                            ),
                          ),
                        ),
                        LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: Colors.black.withValues(alpha: 0.25),
                          color: Theme.of(context).colorScheme.primary,
                          value: progress.clamp(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
