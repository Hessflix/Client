import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';

Future<void> checkForWindowsUpdate(BuildContext context) async {
  final currentVersion = '1.0.0'; // Remplace ça par `package_info_plus` si besoin
  final versionUrl = 'https://cdn.hessflix.tv/version.json';

  try {
    final response = await http.get(Uri.parse(versionUrl));
    if (response.statusCode != 200) return;

    final json = jsonDecode(response.body);
    final latestVersion = json['version'];
    final exeUrl = json['windows'];

    if (latestVersion != currentVersion) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Mise à jour disponible"),
          content: Text("Version $latestVersion disponible. Voulez-vous l'installer ?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui")),
          ],
        ),
      );

      if (confirm != true) return;

      final dir = await getTemporaryDirectory();
      final exePath = '${dir.path}/HessflixSetup.exe';

      final download = await http.get(Uri.parse(exeUrl));
      final file = File(exePath);
      await file.writeAsBytes(download.bodyBytes);

      // Lancer l'installeur et quitter l'app
      await Shell().run('"$exePath"');
      exit(0);
    }
  } catch (e) {
    print("❌ Échec de la mise à jour : $e");
  }
}
