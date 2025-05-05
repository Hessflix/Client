import 'package:flutter/material.dart';

import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/providers/settings/video_player_settings_provider.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/widgets/shared/hessflix_slider.dart';

class VideoVolumeSlider extends ConsumerStatefulWidget {
  final double? width;
  final Function()? onChanged;
  const VideoVolumeSlider({this.width, this.onChanged, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _VideoVolumeSliderState();
}

class _VideoVolumeSliderState extends ConsumerState<VideoVolumeSlider> {
  bool sliderActive = false;

  @override
  Widget build(BuildContext context) {
    final volume = ref.watch(videoPlayerSettingsProvider.select((value) => value.volume));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(volumeIcon(volume)),
          onPressed: () => ref.read(videoPlayerSettingsProvider.notifier).setVolume(0),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: SizedBox(
            height: 30,
            width: 75,
            child: HessflixSlider(
              min: 0,
              max: 100,
              value: volume,
              onChangeStart: (value) {
                setState(() {
                  sliderActive = true;
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  sliderActive = false;
                });
              },
              onChanged: (value) {
                widget.onChanged?.call();
                ref.read(videoPlayerSettingsProvider.notifier).setVolume(value);
              },
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            (volume).toStringAsFixed(0),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ].addInBetween(const SizedBox(width: 6)),
    );
  }
}

IconData volumeIcon(double value) {
  if (value <= 0) {
    return IconsaxPlusLinear.volume_mute;
  }
  if (value < 50) {
    return IconsaxPlusLinear.volume_low;
  }
  return IconsaxPlusLinear.volume_high;
}
