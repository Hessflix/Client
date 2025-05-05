import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/settings/home_settings_model.dart';
import 'package:hessflix/providers/settings/client_settings_provider.dart';
import 'package:hessflix/providers/views_provider.dart';
import 'package:hessflix/routes/auto_router.dart';
import 'package:hessflix/routes/auto_router.gr.dart';
import 'package:hessflix/screens/shared/animated_fade_size.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/adaptive_fab.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/destination_model.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/navigation_drawer.dart';
import 'package:hessflix/widgets/navigation_scaffold/components/settings_user_icon.dart';

class NavigationBody extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  final Widget child;
  final int currentIndex;
  final List<DestinationModel> destinations;
  final String currentLocation;
  final GlobalKey<ScaffoldState> drawerKey;
  const NavigationBody({
    required this.parentContext,
    required this.child,
    required this.currentIndex,
    required this.destinations,
    required this.currentLocation,
    required this.drawerKey,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NavigationBodyState();
}

class _NavigationBodyState extends ConsumerState<NavigationBody> {
  bool expandedSideBar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((value) {
      ref.read(viewsProvider.notifier).fetchViews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final views = ref.watch(viewsProvider.select((value) => value.views));
    final hasOverlay = AdaptiveLayout.layoutModeOf(context) == LayoutMode.dual ||
        homeRoutes.any((element) => element.name.contains(context.router.current.name));
    ref.listen(
      clientSettingsProvider,
      (previous, next) {
        if (previous != next) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarIconBrightness: next.statusBarBrightness(context),
          ));
        }
      },
    );

    return switch (AdaptiveLayout.layoutOf(context)) {
      ViewSize.phone => MediaQuery.removePadding(
          context: widget.parentContext,
          child: widget.child,
        ),
      ViewSize.tablet => Row(
          children: [
            AnimatedFadeSize(
              duration: const Duration(milliseconds: 250),
              child: hasOverlay ? navigationRail(context) : const SizedBox(),
            ),
            Flexible(
              child: MediaQuery(
                data: semiNestedPadding(context, hasOverlay),
                child: widget.child,
              ),
            )
          ],
        ),
      ViewSize.desktop => Row(
          children: [
            AnimatedFadeSize(
              duration: const Duration(milliseconds: 125),
              child: hasOverlay
                  ? expandedSideBar
                      ? MediaQuery.removePadding(
                          context: widget.parentContext,
                          child: NestedNavigationDrawer(
                            isExpanded: expandedSideBar,
                            actionButton: actionButton(),
                            toggleExpanded: (value) {
                              setState(() {
                                expandedSideBar = value;
                              });
                            },
                            views: views,
                            destinations: widget.destinations,
                            currentLocation: widget.currentLocation,
                          ),
                        )
                      : navigationRail(context)
                  : const SizedBox(),
            ),
            Flexible(
              child: MediaQuery(
                data: semiNestedPadding(context, hasOverlay),
                child: widget.child,
              ),
            ),
          ],
        )
    };
  }

  MediaQueryData semiNestedPadding(BuildContext context, bool hasOverlay) {
    final paddingOf = MediaQuery.paddingOf(context);
    return MediaQuery.of(context).copyWith(
      padding: paddingOf.copyWith(left: hasOverlay ? 0 : paddingOf.left),
    );
  }

  AdaptiveFab? actionButton() {
    return (widget.currentIndex >= 0 && widget.currentIndex < widget.destinations.length)
        ? widget.destinations[widget.currentIndex].floatingActionButton
        : null;
  }

  Widget navigationRail(BuildContext context) {
    return Column(
      children: [
        if (AdaptiveLayout.of(context).isDesktop && AdaptiveLayout.of(context).platform != TargetPlatform.macOS) ...{
          const SizedBox(height: 4),
          Text(
            "Hessflix",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        },
        if (AdaptiveLayout.of(context).platform == TargetPlatform.macOS)
          SizedBox(height: MediaQuery.of(context).padding.top),
        Flexible(
          child: Padding(
            key: const Key('navigation_rail'),
            padding:
                MediaQuery.paddingOf(context).copyWith(right: 0, top: AdaptiveLayout.of(context).isDesktop ? 8 : null),
            child: Column(
              children: [
                IconButton(
                  onPressed: () {
                    if (AdaptiveLayout.layoutOf(context) != ViewSize.desktop) {
                      widget.drawerKey.currentState?.openDrawer();
                    } else {
                      setState(() {
                        expandedSideBar = true;
                      });
                    }
                  },
                  icon: const Icon(IconsaxPlusBold.menu),
                ),
                if (AdaptiveLayout.layoutModeOf(context) == LayoutMode.dual) ...[
                  const SizedBox(height: 8),
                  AnimatedFadeSize(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: actionButton()?.normal,
                    ),
                  ),
                ],
                const Spacer(),
                IconTheme(
                  data: const IconThemeData(size: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...widget.destinations.mapIndexed(
                        (index, destination) => destination.toNavigationButton(widget.currentIndex == index, false),
                      )
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 48,
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: widget.currentLocation.contains(const SettingsRoute().routeName)
                          ? Card(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(IconsaxPlusBold.setting_3),
                              ),
                            )
                          : const SettingsUserIcon()),
                ),
                if (AdaptiveLayout.of(context).inputDevice == InputDevice.pointer) const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
