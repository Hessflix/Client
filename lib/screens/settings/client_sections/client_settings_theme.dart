import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/providers/settings/client_settings_provider.dart';
import 'package:hessflix/screens/settings/settings_list_tile.dart';
import 'package:hessflix/screens/settings/widgets/settings_label_divider.dart';
import 'package:hessflix/util/color_extensions.dart';
import 'package:hessflix/util/custom_color_themes.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/option_dialogue.dart';
import 'package:hessflix/util/theme_mode_extension.dart';

List<Widget> buildClientSettingsTheme(BuildContext context, WidgetRef ref) {
  final clientSettings = ref.watch(clientSettingsProvider);
  return [
    SettingsLabelDivider(label: context.localized.theme),
    SettingsListTile(
      label: Text(context.localized.mode),
      subLabel: Text(clientSettings.themeMode.label(context)),
      onTap: () => openMultiSelectOptions<ThemeMode>(
        context,
        label: "${context.localized.theme} ${context.localized.mode}",
        items: ThemeMode.values,
        selected: [ref.read(clientSettingsProvider.select((value) => value.themeMode))],
        onChanged: (values) => ref.read(clientSettingsProvider.notifier).setThemeMode(values.first),
        itemBuilder: (type, selected, tap) => RadioListTile(
          value: type,
          title: Text(type.label(context)),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          groupValue: ref.read(clientSettingsProvider.select((value) => value.themeMode)),
          onChanged: (value) => tap(),
        ),
      ),
    ),
    SettingsListTile(
      label: Text(context.localized.amoledBlack),
      subLabel: Text(clientSettings.amoledBlack ? context.localized.enabled : context.localized.disabled),
      onTap: () => ref.read(clientSettingsProvider.notifier).setAmoledBlack(!clientSettings.amoledBlack),
      trailing: Switch(
        value: clientSettings.amoledBlack,
        onChanged: (value) => ref.read(clientSettingsProvider.notifier).setAmoledBlack(value),
      ),
    ),
    const Divider(),
  ];
}
