import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/providers/settings/client_settings_provider.dart';
import 'package:hessflix/providers/sync_provider.dart';
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/screens/settings/settings_list_tile.dart';
import 'package:hessflix/screens/settings/widgets/settings_label_divider.dart';
import 'package:hessflix/screens/shared/default_alert_dialog.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/size_formatting.dart';

List<Widget> buildClientSettingsDownload(BuildContext context, WidgetRef ref, Function setState) {
  final clientSettings = ref.watch(clientSettingsProvider);
  final currentFolder = ref.watch(syncProvider.notifier).savePath;
  final canSync = ref.watch(userProvider.select((value) => value?.canDownload ?? false));

  return [
    if (canSync && !kIsWeb) ...[
      SettingsLabelDivider(label: context.localized.downloadsTitle),
      if (AdaptiveLayout.of(context).isDesktop) ...[
        SettingsListTile(
          label: Text(context.localized.downloadsPath),
          subLabel: Text(currentFolder ?? "-"),
          onTap: currentFolder != null
              ? () async => await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.localized.pathEditTitle),
                      content: Text(context.localized.pathEditDesc),
                      actions: [
                        ElevatedButton(
                          onPressed: () async {
                            String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
                                dialogTitle: context.localized.pathEditSelect, initialDirectory: currentFolder);
                            if (selectedDirectory != null) {
                              ref.read(clientSettingsProvider.notifier).setSyncPath(selectedDirectory);
                            }
                            Navigator.of(context).pop();
                          },
                          child: Text(context.localized.change),
                        )
                      ],
                    ),
                  )
              : () async {
                  String? selectedDirectory = await FilePicker.platform
                      .getDirectoryPath(dialogTitle: context.localized.pathEditSelect, initialDirectory: currentFolder);
                  if (selectedDirectory != null) {
                    ref.read(clientSettingsProvider.notifier).setSyncPath(selectedDirectory);
                  }
                },
          trailing: currentFolder?.isNotEmpty == true
              ? IconButton(
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () async => await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.localized.pathClearTitle),
                      content: Text(context.localized.pathEditDesc),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            ref.read(clientSettingsProvider.notifier).setSyncPath(null);
                            Navigator.of(context).pop();
                          },
                          child: Text(context.localized.clear),
                        )
                      ],
                    ),
                  ),
                  icon: const Icon(IconsaxPlusLinear.folder_minus),
                )
              : null,
        ),
      ],
      FutureBuilder(
        future: ref.watch(syncProvider.notifier).directorySize,
        builder: (context, snapshot) {
          final data = snapshot.data ?? 0;
          return SettingsListTile(
            label: Text(context.localized.downloadsSyncedData),
            subLabel: Text(data.byteFormat ?? ""),
            trailing: FilledButton(
              onPressed: () {
                showDefaultAlertDialog(
                  context,
                  context.localized.downloadsClearTitle,
                  context.localized.downloadsClearDesc,
                  (context) async {
                    await ref.read(syncProvider.notifier).clear();
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  context.localized.clear,
                  (context) => Navigator.of(context).pop(),
                  context.localized.cancel,
                );
              },
              child: Text(context.localized.clear),
            ),
          );
        },
      ),
      SettingsListTile(
        label: Text(context.localized.clientSettingsRequireWifiTitle),
        subLabel: Text(context.localized.clientSettingsRequireWifiDesc),
        onTap: () => ref.read(clientSettingsProvider.notifier).setRequireWifi(!clientSettings.requireWifi),
        trailing: Switch(
          value: clientSettings.requireWifi,
          onChanged: (value) => ref.read(clientSettingsProvider.notifier).setRequireWifi(value),
        ),
      ),
      const Divider(),
    ],
  ];
}
