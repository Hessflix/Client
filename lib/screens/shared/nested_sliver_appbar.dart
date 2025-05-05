import 'package:auto_route/auto_route.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:hessflix/util/list_padding.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/settings_user_icon.dart';
import 'package:hessflix/widgets/shared/shapes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NestedSliverAppBar extends ConsumerWidget {
  final BuildContext parent;
  final String? searchTitle;
  final PageRouteInfo? route;
  const NestedSliverAppBar({required this.parent, this.route, this.searchTitle, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      elevation: 16,
      forceElevated: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: AppBarShape(),
      title: SizedBox(
        height: 65,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton.filledTonal(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surface),
                ),
                onPressed: () => Scaffold.of(parent).openDrawer(),
                icon: const Icon(
                  IconsaxPlusBold.menu,
                  size: 28,
                ),
              ),
              Expanded(
                child: Hero(
                  tag: "PrimarySearch",
                  child: Card(
                    elevation: 3,
                    shadowColor: Colors.transparent,
                    child: InkWell(
                      onTap: route != null
                          ? () {
                              route?.push(context);
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Opacity(
                          opacity: 0.65,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(IconsaxPlusLinear.search_normal),
                              const SizedBox(width: 16),
                              Transform.translate(
                                  offset: const Offset(0, 2.5),
                                  child: Text(searchTitle ?? "${context.localized.search}...")),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SettingsUserIcon()
            ].addInBetween(const SizedBox(width: 16)),
          ),
        ),
      ),
      toolbarHeight: 80,
      floating: true,
    );
  }
}
