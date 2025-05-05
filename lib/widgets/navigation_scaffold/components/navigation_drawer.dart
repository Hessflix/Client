import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:hessflix/models/collection_types.dart';
import 'package:hessflix/models/settings/home_settings_model.dart';
import 'package:hessflix/models/view_model.dart';
import 'package:hessflix/routes/auto_router.gr.dart';
import 'package:hessflix/screens/metadata/refresh_metadata.dart';
import 'package:hessflix/screens/shared/animated_fade_size.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/adaptive_fab.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/destination_model.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/drawer_list_button.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/settings_user_icon.dart';
import 'package:hessflix/widgets/shared/item_actions.dart';

class NestedNavigationDrawer extends ConsumerWidget {
  final bool isExpanded;
  final Function(bool expanded) toggleExpanded;
  final List<DestinationModel> destinations;
  final AdaptiveFab? actionButton;
  final List<ViewModel> views;
  final String currentLocation;
  const NestedNavigationDrawer(
      {this.isExpanded = false,
      required this.toggleExpanded,
      required this.actionButton,
      required this.destinations,
      required this.views,
      required this.currentLocation,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationDrawer(
      key: const Key('navigation_drawer'),
      backgroundColor: isExpanded ? Colors.transparent : null,
      surfaceTintColor: isExpanded ? Colors.transparent : null,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(28, AdaptiveLayout.of(context).isDesktop || kIsWeb ? 0 : 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.localized.navigation,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => toggleExpanded(false),
                icon: const Icon(IconsaxPlusLinear.menu_1),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: actionButton != null ? 8 : 0),
          child: AnimatedFadeSize(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: actionButton?.extended,
            ),
          ),
        ),
        ...destinations.map((destination) => DrawerListButton(
              label: destination.label,
              selected: context.router.current.name == destination.route?.routeName,
              selectedIcon: destination.selectedIcon!,
              icon: destination.icon!,
              onPressed: () {
                destination.action!();
                Scaffold.of(context).closeDrawer();
              },
            )),
        if (views.isNotEmpty) ...{
          const Divider(indent: 28, endIndent: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              context.localized.library(2),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...views.map((library) => DrawerListButton(
              label: library.name,
              selected: context.router.currentUrl.contains(library.id),
              actions: [
                ItemActionButton(
                  label: Text(context.localized.scanLibrary),
                  icon: const Icon(IconsaxPlusLinear.refresh),
                  action: () => showRefreshPopup(context, library.id, library.name),
                ),
              ],
              onPressed: () {
                context.router.push(LibrarySearchRoute(viewModelId: library.id));
                Scaffold.of(context).closeDrawer();
              },
              selectedIcon: Icon(library.collectionType.icon),
              icon: Icon(library.collectionType.iconOutlined))),
        },
        const Divider(indent: 28, endIndent: 28),
        if (isExpanded)
          Transform.translate(
            offset: const Offset(-8, 0),
            child: DrawerListButton(
              label: context.localized.settings,
              selectedIcon: const Icon(IconsaxPlusBold.setting_3),
              selected: currentLocation.contains(const SettingsRoute().routeName),
              icon: const SizedBox(width: 35, height: 35, child: SettingsUserIcon()),
              onPressed: () {
                switch (AdaptiveLayout.layoutModeOf(context)) {
                  case LayoutMode.single:
                    const SettingsRoute().push(context);
                    break;
                  case LayoutMode.dual:
                    context.router.push(const ClientSettingsRoute());
                    break;
                }
                Scaffold.of(context).closeDrawer();
              },
            ),
          )
        else
          DrawerListButton(
            label: context.localized.settings,
            selectedIcon: const Icon(IconsaxPlusBold.setting_2),
            icon: const Icon(IconsaxPlusLinear.setting_2),
            selected: currentLocation.contains(const SettingsRoute().routeName),
            onPressed: () {
              switch (AdaptiveLayout.layoutModeOf(context)) {
                case LayoutMode.single:
                  const SettingsRoute().push(context);
                  break;
                case LayoutMode.dual:
                  context.router.push(const ClientSettingsRoute());
                  break;
              }
              Scaffold.of(context).closeDrawer();
            },
          ),
        if (AdaptiveLayout.of(context).isDesktop || kIsWeb) const SizedBox(height: 8),
      ],
    );
  }
}
