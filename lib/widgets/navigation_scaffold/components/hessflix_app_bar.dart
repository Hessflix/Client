import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:auto_route/auto_route.dart';

import 'package:hessflix/screens/shared/default_title_bar.dart';
import 'package:hessflix/util/adaptive_layout.dart';

bool get _isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

class HessflixAppBar extends StatelessWidget implements PreferredSize {
  final double height;
  final String? label;
  final bool automaticallyImplyLeading;
  const HessflixAppBar({this.height = 35, this.automaticallyImplyLeading = false, this.label, super.key});

  @override
  Widget build(BuildContext context) {
    if (AdaptiveLayout.of(context).isDesktop) {
      return PreferredSize(
          preferredSize: Size(double.infinity, height),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                if (automaticallyImplyLeading && context.router.canPop()) const BackButton(),
                Expanded(
                  child: DefaultTitleBar(
                    label: label,
                  ),
                )
              ],
            ),
          ));
    } else {
      return AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
        scrolledUnderElevation: 0,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(),
        title: const Text(""),
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    }
  }

  @override
  Widget get child => Container();

  @override
  Size get preferredSize => Size(double.infinity, _isDesktop ? height : 0);
}
