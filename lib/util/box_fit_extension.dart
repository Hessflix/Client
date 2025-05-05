import 'package:hessflix/util/localization_helper.dart';
import 'package:flutter/material.dart';

extension BoxFitExtension on BoxFit {
  String label(BuildContext context) {
    return switch (this) {
      BoxFit.fill => context.localized.videoScalingFill,
      BoxFit.contain => context.localized.videoScalingContain,
      BoxFit.cover => context.localized.videoScalingCover,
      BoxFit.fitWidth => context.localized.videoScalingFitWidth,
      BoxFit.fitHeight => context.localized.videoScalingFitHeight,
      BoxFit.none => context.localized.none,
      BoxFit.scaleDown => context.localized.videoScalingScaleDown,
    };
  }
}
