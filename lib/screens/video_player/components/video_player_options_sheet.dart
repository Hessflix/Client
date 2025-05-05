import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:collection/collection.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/item_base_model.dart';
import 'package:hessflix/models/items/episode_model.dart';
import 'package:hessflix/models/playback/direct_playback_model.dart';
import 'package:hessflix/models/playback/offline_playback_model.dart';
import 'package:hessflix/models/playback/playback_model.dart';
import 'package:hessflix/models/playback/transcode_playback_model.dart';
import 'package:hessflix/models/settings/video_player_settings.dart';
import 'package:hessflix/providers/settings/video_player_settings_provider.dart';
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/providers/video_player_provider.dart';
import 'package:hessflix/screens/collections/add_to_collection.dart';
import 'package:hessflix/screens/metadata/info_screen.dart';
import 'package:hessflix/screens/playlists/add_to_playlists.dart';
import 'package:hessflix/screens/video_player/components/video_player_quality_controls.dart';
import 'package:hessflix/screens/video_player/components/video_player_queue.dart';
import 'package:hessflix/screens/video_player/components/video_subtitle_controls.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/device_orientation_extension.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/map_bool_helper.dart';
import 'package:hessflix/util/refresh_state.dart';
import 'package:hessflix/util/string_extensions.dart';
import 'package:hessflix/widgets/shared/enum_selection.dart';
import 'package:hessflix/widgets/shared/hessflix_slider.dart';
import 'package:hessflix/widgets/shared/modal_bottom_sheet.dart';
import 'package:hessflix/widgets/shared/spaced_list_tile.dart';

final playbackRateProvider = StateProvider<double>((ref) => 1.0);

Future<void> showVideoPlayerOptions(BuildContext context, Function() minimizePlayer) {
  return showBottomSheetPill(
    context: context,
    content: (context, scrollController) {
      return VideoOptions(
        controller: scrollController,
        minimizePlayer: minimizePlayer,
      );
    },
  );
}

class VideoOptions extends ConsumerStatefulWidget {
  final ScrollController controller;
  final Function() minimizePlayer;
  const VideoOptions({required this.controller, required this.minimizePlayer, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _VideoOptionsMobileState();
}

class _VideoOptionsMobileState extends ConsumerState<VideoOptions> {
  late int page = 0;

  @override
  Widget build(BuildContext context) {
    final currentItem = ref.watch(playBackModel.select((value) => value?.item));
    final videoSettings = ref.watch(videoPlayerSettingsProvider);
    final currentMediaStreams = ref.watch(playBackModel.select((value) => value?.mediaStreams));
    final bitRateOptions = ref.watch(playBackModel.select((value) => value?.bitRateOptions));

    Widget mainPage() {
      return ListView(
        key: const Key("mainPage"),
        shrinkWrap: true,
        controller: widget.controller,
        children: [
          InkWell(
            onTap: () => setState(() => page = 2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentItem?.title ?? "",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Opacity(opacity: 0.1, child: Icon(Icons.info_outline_rounded))
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (!AdaptiveLayout.of(context).isDesktop)
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(flex: 1, child: Text(context.localized.screenBrightness)),
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: Opacity(
                            opacity: videoSettings.screenBrightness == null ? 0.5 : 1,
                            child: Slider(
                              value: videoSettings.screenBrightness ?? 1.0,
                              min: 0,
                              max: 1,
                              onChanged: (value) =>
                                  ref.read(videoPlayerSettingsProvider.notifier).setScreenBrightness(value),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => ref.read(videoPlayerSettingsProvider.notifier).setScreenBrightness(null),
                          icon: Opacity(
                            opacity: videoSettings.screenBrightness != null ? 0.5 : 1,
                            child: Icon(
                              IconsaxPlusBold.autobrightness,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SpacedListTile(
            title: Text(context.localized.subtitles),
            content: Text(currentMediaStreams?.currentSubStream?.label(context) ?? context.localized.off),
            onTap: currentMediaStreams?.subStreams.isNotEmpty == true ? () => showSubSelection(context) : null,
          ),
          SpacedListTile(
            title: Text(context.localized.audio),
            content: Text(currentMediaStreams?.currentAudioStream?.label(context) ?? context.localized.off),
            onTap: currentMediaStreams?.audioStreams.isNotEmpty == true ? () => showAudioSelection(context) : null,
          ),
          ListTile(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: EnumSelection(
                    label: Text(context.localized.scale),
                    current: videoSettings.videoFit.name.toUpperCaseSplit(),
                    itemBuilder: (context) => BoxFit.values
                        .map((value) => PopupMenuItem(
                              value: value,
                              child: Text(value.name.toUpperCaseSplit()),
                              onTap: () => ref.read(videoPlayerSettingsProvider.notifier).setFitType(value),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          if (!AdaptiveLayout.of(context).isDesktop)
            ListTile(
              onTap: () => ref.read(videoPlayerSettingsProvider.notifier).setFillScreen(!videoSettings.fillScreen),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(context.localized.videoScalingFill),
                  ),
                  const Spacer(),
                  Switch(
                    value: videoSettings.fillScreen,
                    onChanged: (value) => ref.read(videoPlayerSettingsProvider.notifier).setFillScreen(value),
                  )
                ],
              ),
            ),
          if (!AdaptiveLayout.of(context).isDesktop && !kIsWeb)
            SpacedListTile(
              title: Text(context.localized.playerSettingsOrientationTitle),
              onTap: () => showOrientationOptions(context, ref),
            ),
          ListTile(
            onTap: () {
              Navigator.of(context).pop();
              showPlaybackSpeed(context);
            },
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(context.localized.playbackRate),
                ),
                const Spacer(),
                Text("x${ref.watch(playbackRateProvider)}")
              ],
            ),
          ),
          if (bitRateOptions?.isNotEmpty == true)
            ListTile(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(context.localized.qualityOptionsTitle),
                  ),
                  const Spacer(),
                  Text(bitRateOptions?.enabledFirst.keys.firstOrNull?.label(context) ?? "")
                ],
              ),
              onTap: () {
                Navigator.of(context).pop();
                openQualityOptions(context);
              },
            )
        ],
      );
    }

    Widget playbackSettings() {
      final playbackState = ref.watch(playBackModel);
      return ListView(
        key: const Key("PlaybackSettings"),
        shrinkWrap: true,
        controller: widget.controller,
        children: [
          navTitle(context.localized.playBackSettings, null),
          if (playbackState?.queue.isNotEmpty == true)
            ListTile(
              leading: const Icon(Icons.video_collection_rounded),
              title: const Text("Show queue"),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(videoPlayerProvider).pause();
                showFullScreenItemQueue(
                  context,
                  items: playbackState?.queue ?? [],
                  currentItem: playbackState?.item,
                  playSelected: (item) {
                    throw UnimplementedError();
                  },
                );
              },
            )
        ],
      );
    }

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (page) {
              1 => playbackSettings(),
              2 => itemInfo(currentItem, context),
              _ => mainPage(),
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  ListView itemInfo(ItemBaseModel? currentItem, BuildContext context) {
    return ListView(
      shrinkWrap: true,
      controller: widget.controller,
      children: [
        navTitle(currentItem?.title, currentItem?.subTextShort(context)),
        if (currentItem != null) ...{
          if (currentItem.type == HessflixItemType.episode)
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
                widget.minimizePlayer();
                (this as EpisodeModel).parentBaseModel.navigateTo(context);
              },
              title: Text(context.localized.openShow),
            ),
          ListTile(
            onTap: () async {
              Navigator.of(context).pop();
              widget.minimizePlayer();
              await currentItem.navigateTo(context);
            },
            title: Text(context.localized.showDetails),
          ),
          if (currentItem.type != HessflixItemType.boxset)
            ListTile(
              onTap: () async {
                await addItemToCollection(context, [currentItem]);
                if (context.mounted) {
                  context.refreshData();
                }
              },
              title: Text(context.localized.addToCollection),
            ),
          if (currentItem.type != HessflixItemType.playlist)
            ListTile(
              onTap: () async {
                await addItemToPlaylist(context, [currentItem]);
                if (context.mounted) {
                  context.refreshData();
                }
              },
              title: Text(context.localized.addToPlaylist),
            ),
          ListTile(
            onTap: () async {
              final response = await ref
                  .read(userProvider.notifier)
                  .setAsFavorite(!(currentItem.userData.isFavourite == true), currentItem.id);
              final newItem = currentItem.copyWith(userData: response?.body);
              final playbackModel = switch (ref.read(playBackModel)) {
                DirectPlaybackModel value => value.copyWith(item: newItem),
                TranscodePlaybackModel value => value.copyWith(item: newItem),
                OfflinePlaybackModel value => value.copyWith(item: newItem),
                _ => null
              };
              ref.read(playBackModel.notifier).update((state) => playbackModel);
              Navigator.of(context).pop();
            },
            title: Text(currentItem.userData.isFavourite == true
                ? context.localized.removeAsFavorite
                : context.localized.addAsFavorite),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).pop();
              showInfoScreen(context, currentItem);
            },
            title: Text(context.localized.info),
          ),
        }
      ],
    );
  }

  Widget navTitle(String? title, String? subText) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            BackButton(
              onPressed: () => setState(() => page = 0),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                if (title != null)
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                if (subText != null)
                  Text(
                    subText,
                    style: Theme.of(context).textTheme.titleMedium,
                  )
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}

Future<void> showSubSelection(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final playbackModel = ref.watch(playBackModel);
          final player = ref.watch(videoPlayerProvider);
          return SimpleDialog(
            contentPadding: const EdgeInsets.only(top: 8, bottom: 24),
            title: Row(
              children: [
                Text(context.localized.subtitle),
                const Spacer(),
                if (player.backend == PlayerOptions.libMPV)
                  IconButton.outlined(
                      onPressed: () {
                        Navigator.pop(context);
                        showSubtitleControls(
                          context: context,
                          label: context.localized.subtitleConfiguration,
                        );
                      },
                      icon: const Icon(Icons.display_settings_rounded))
              ],
            ),
            children: playbackModel?.subStreams?.mapIndexed(
              (index, subModel) {
                final selected = playbackModel.mediaStreams?.defaultSubStreamIndex == subModel.index;
                return ListTile(
                  title: Text(subModel.label(context)),
                  tileColor: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : null,
                  subtitle: subModel.language.isNotEmpty
                      ? Opacity(opacity: 0.6, child: Text(subModel.language.capitalize()))
                      : null,
                  onTap: () async {
                    final newModel = await playbackModel.setSubtitle(subModel, player);
                    ref.read(playBackModel.notifier).update((state) => newModel);
                    if (newModel != null) {
                      await ref.read(playbackModelHelper).shouldReload(newModel);
                    }
                  },
                );
              },
            ).toList(),
          );
        },
      );
    },
  );
}

Future<void> showAudioSelection(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final playbackModel = ref.watch(playBackModel);
          final player = ref.watch(videoPlayerProvider);
          return SimpleDialog(
            contentPadding: const EdgeInsets.only(top: 8, bottom: 24),
            title: Row(
              children: [
                Text(context.localized.audio),
              ],
            ),
            children: playbackModel?.audioStreams?.mapIndexed(
              (index, audioStream) {
                final selected = playbackModel.mediaStreams?.defaultAudioStreamIndex == audioStream.index;
                return ListTile(
                    title: Text(audioStream.label(context)),
                    tileColor: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : null,
                    subtitle: audioStream.language.isNotEmpty
                        ? Opacity(opacity: 0.6, child: Text(audioStream.language.capitalize()))
                        : null,
                    onTap: () async {
                      final newModel = await playbackModel.setAudio(audioStream, player);
                      ref.read(playBackModel.notifier).update((state) => newModel);
                      if (newModel != null) {
                        await ref.read(playbackModelHelper).shouldReload(newModel);
                      }
                    });
              },
            ).toList(),
          );
        },
      );
    },
  );
}

Future<void> showPlaybackSpeed(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Consumer(
          builder: (context, ref, child) {
            final player = ref.watch(videoPlayerProvider);
            final lastSpeed = ref.watch(playbackRateProvider);
            return SimpleDialog(
              contentPadding: const EdgeInsets.only(top: 8, bottom: 24),
              title: Row(children: [Text(context.localized.playbackRate)]),
              children: [
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("${context.localized.speed}: "),
                      Flexible(
                        child: SizedBox(
                          width: 250,
                          child: HessflixSlider(
                            min: 0.25,
                            max: 10,
                            value: lastSpeed,
                            divisions: 39,
                            onChanged: (value) {
                              ref.read(playbackRateProvider.notifier).state = value;
                              player.setSpeed(value);
                            },
                          ),
                        ),
                      ),
                      Text("x${lastSpeed.toStringAsFixed(2)}")
                    ].addInBetween(const SizedBox(width: 8)),
                  ),
                )
              ],
            );
          },
        );
      });
    },
  );
}

Future<void> showOrientationOptions(BuildContext context, WidgetRef ref) async {
  Set<DeviceOrientation> orientations = ref
      .read(videoPlayerSettingsProvider
          .select((value) => value.allowedOrientations ?? Set.from(DeviceOrientation.values)))
      .toSet();

  void toggleOrientation(DeviceOrientation orientation) {
    if (orientations.contains(orientation) && orientations.length > 1) {
      orientations.remove(orientation);
    } else {
      orientations.add(orientation);
    }
  }

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, state) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.only(top: 8, bottom: 24),
          title: Row(children: [Text(context.localized.playerSettingsOrientationTitle)]),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Divider(),
                  ...DeviceOrientation.values.map(
                    (orientation) => CheckboxListTile(
                      title: Text(orientation.label(context)),
                      value: orientations.contains(orientation),
                      onChanged: (value) {
                        state(() => toggleOrientation(orientation));
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.localized.cancel),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.read(videoPlayerSettingsProvider.notifier).toggleOrientation(orientations);
                        },
                        child: Text(context.localized.save),
                      ),
                    ].addInBetween(const SizedBox(width: 8)),
                  )
                ].addInBetween(const SizedBox(width: 8)),
              ),
            )
          ],
        );
      });
    },
  );
}
