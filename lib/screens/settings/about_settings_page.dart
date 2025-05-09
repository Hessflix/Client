import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:hessflix/screens/crash_screen/crash_screen.dart';
import 'package:hessflix/screens/settings/settings_scaffold.dart';
import 'package:hessflix/screens/shared/hessflix_icon.dart';
import 'package:hessflix/screens/shared/hessflix_logo.dart';
import 'package:hessflix/screens/shared/media/external_urls.dart';
import 'package:hessflix/util/application_info.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/localization_helper.dart';

class _Socials {
  final String label;
  final String url;
  final IconData icon;

  const _Socials(this.label, this.url, this.icon);
}

const socials = [
  _Socials(
    'Discord',
    'https://discord.hessflix.tv/',
    FontAwesomeIcons.discord,
  ),
  _Socials(
    'Espace Client',
    'https://my.hessflix.tv',
    IconsaxPlusLinear.global,
  ),
  _Socials(
    'Github',
    'https://github.com/Hessflix/Client',
    IconsaxPlusLinear.githubAlt,
  ),
];

@RoutePage()
class AboutSettingsPage extends ConsumerWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationInfo = ref.watch(applicationInfoProvider);
    return Card(
      child: SettingsScaffold(
        label: "",
        items: [
          const HessflixLogo(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(context.localized.aboutVersion(applicationInfo.versionAndPlatform)),
              Text(context.localized.aboutBuild(applicationInfo.buildNumber)),
              const SizedBox(height: 16),
              Text(context.localized.aboutCreatedBy),
            ],
          ),
          const Divider(),
          Column(
            children: [
              Text(
                context.localized.aboutSocials,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: socials
                    .map(
                      (e) => IconButton.filledTonal(
                        onPressed: () => launchUrl(context, e.url),
                        icon: Column(
                          children: [
                            Icon(e.icon),
                            Text(e.label),
                          ],
                        ),
                      ),
                    )
                    .toList()
                    .addInBetween(const SizedBox(width: 16)),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationIcon: const HessflixIcon(size: 55),
                  applicationVersion: applicationInfo.versionPlatformBuild,
                  applicationLegalese: "DonutWare and edited by Hessflix",
                ),
                child: Text(context.localized.aboutLicenses),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CrashScreen(),
                ),
                child: Text(context.localized.errorLogs),
              )
            ],
          ),
        ].addInBetween(const SizedBox(height: 16)),
      ),
    );
  }
}
