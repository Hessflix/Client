import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future<void> checkForWindowsUpdate(BuildContext context) async {
  const versionUrl = 'https://cdn.hessflix.tv/version.json';

  try {
    print("🔧 Démarrage de la vérification de mise à jour...");

    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = Version.parse(packageInfo.version);
    print("📦 Version locale : $localVersion");

    final response = await http.get(Uri.parse(versionUrl));
    print("🌐 Requête version.json status: ${response.statusCode}");

    if (response.statusCode != 200) return;

    final json = jsonDecode(response.body);
    final serverVersion = Version.parse(json['version']);
    final exeUrl = json['windows'];
    final expectedHash = json['sha256'];

    print("🆕 Version distante : $serverVersion");
    print("🔗 Fichier exe : $exeUrl");
    print("🔐 SHA256 attendu : $expectedHash");

    if (serverVersion > localVersion) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Mise à jour disponible"),
          content: Text("La version $serverVersion est disponible. Voulez-vous l’installer ?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui")),
          ],
        ),
      );

      if (confirm != true) return;

      print("📥 Téléchargement de l’installeur avec progression...");
      final dir = await getTemporaryDirectory();
      final exePath = '${dir.path}/HessflixSetup.exe';

      await showDownloadProgressDialog(context, exeUrl, exePath);

      final computedHash = await computeSha256(exePath);
      print("🧮 SHA256 calculé : $computedHash");

      if (computedHash != expectedHash) {
        print("❌ Hash invalide, suppression du fichier.");
        await File(exePath).delete();
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Erreur de sécurité"),
            content: const Text("Le fichier téléchargé est corrompu ou a été modifié."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
            ],
          ),
        );
        return;
      }

      print("🚀 Lancement de l'installeur...");
      await Shell().run('"$exePath"');
      exit(0);
    } else {
      print("✅ Aucune mise à jour nécessaire");
    }
  } catch (e) {
    print("❌ Erreur durant la vérification de mise à jour : $e");
  }
}

Future<void> showDownloadProgressDialog(
    BuildContext context, String url, String savePath) async {
  final client = http.Client();
  final request = http.Request('GET', Uri.parse(url));
  final response = await client.send(request);

  final total = response.contentLength ?? 0;
  int received = 0;

  final file = File(savePath);
  final sink = file.openWrite();

  double progress = 0.0;
  late void Function(void Function()) updateState;

  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          updateState = setState;
          return AlertDialog(
            title: const Text("Téléchargement de la mise à jour"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 12),
                Text("${(progress * 100).toStringAsFixed(1)}%"),
              ],
            ),
          );
        },
      );
    },
  );

  await for (final chunk in response.stream) {
    received += chunk.length;
    sink.add(chunk);

    progress = total > 0 ? received / total : 0.0;
    updateState(() {});
  }

  await sink.flush();
  await sink.close();
  client.close();

  Navigator.of(context).pop();
}

Future<String> computeSha256(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final digest = sha256.convert(bytes);
  return digest.toString();
}
