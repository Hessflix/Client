import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/screens/shared/hessflix_icon.dart';
import 'package:hessflix/util/application_info.dart';
import 'package:hessflix/util/string_extensions.dart';
import 'package:hessflix/util/theme_extensions.dart';

class HessflixLogo extends ConsumerWidget {
  const HessflixLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Hero(
      tag: "Hessflix_Logo_Tag",
      child: Wrap(
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          const HessflixIcon(),
          Text(
            ref.read(applicationInfoProvider).name.capitalize(),
            style: context.textTheme.displayLarge,
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
