import 'dart:ui';

import 'package:hessflix/models/settings/subtitle_settings_model.dart';
import 'package:hessflix/providers/shared_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subtitleSettingsProvider = StateNotifierProvider<SubtitleSettingsNotifier, SubtitleSettingsModel>((ref) {
  return SubtitleSettingsNotifier(ref);
});

class SubtitleSettingsNotifier extends StateNotifier<SubtitleSettingsModel> {
  SubtitleSettingsNotifier(this.ref) : super(const SubtitleSettingsModel());

  final Ref ref;

  @override
  set state(SubtitleSettingsModel value) {
    super.state = value;
    ref.read(sharedUtilityProvider).subtitleSettings = value;
  }

  void setFontSize(double value) => state = state.copyWith(fontSize: value);

  void setVerticalOffset(double value) => state = state.copyWith(verticalOffset: value);

  void setSubColor(Color color) => state = state.copyWith(color: color);

  void setOutlineColor(Color e) => state = state.copyWith(outlineColor: e);

  SubtitleSettingsModel setOutlineThickness(double value) => state = state.copyWith(outlineSize: value);

  void resetSettings({SubtitleSettingsModel? value}) => state = value ?? const SubtitleSettingsModel();

  void setFontWeight(FontWeight? value) => state = state.copyWith(fontWeight: value);

  SubtitleSettingsModel setBackGroundOpacity(double value) =>
      state = state.copyWith(backGroundColor: state.backGroundColor.withValues(alpha: value));

  SubtitleSettingsModel setShadowIntensity(double value) => state = state.copyWith(shadow: value);
}
