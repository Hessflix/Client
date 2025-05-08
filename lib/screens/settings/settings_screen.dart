import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:auto_route/auto_route.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/models/settings/home_settings_model.dart';
import 'package:hessflix/providers/auth_provider.dart';
import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/routes/auto_router.gr.dart';
import 'package:hessflix/screens/settings/quick_connect_window.dart';
import 'package:hessflix/screens/settings/settings_list_tile.dart';
import 'package:hessflix/screens/settings/settings_scaffold.dart';
import 'package:hessflix/screens/shared/hessflix_icon.dart';
import 'package:hessflix/util/adaptive_layout.dart';
import 'package:hessflix/util/localization_helper.dart';
import 'package:hessflix/util/theme_extensions.dart';

@RoutePage()
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final scrollController = ScrollController();
  final minVerticalPadding = 20.0;
  late LayoutMode lastAdaptiveLayout = AdaptiveLayout.layoutModeOf(context);

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      builder: (context, content) {
        checkForNullIndex(context);
        return PopScope(
          canPop: context.tabsRouter.activeIndex == 0 || AdaptiveLayout.layoutModeOf(context) == LayoutMode.dual,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              context.tabsRouter.setActiveIndex(0);
            }
          },
          child: AdaptiveLayout.layoutModeOf(context) == LayoutMode.single
              ? Card(
                  elevation: 0,
                  child: Stack(
                    children: [_leftPane(context), content],
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 1, child: _leftPane(context)),
                    Expanded(
                      flex: 2,
                      child: content,
                    ),
                  ],
                ),
        );
      },
    );
  }

  //We have to navigate to the first screen after switching layouts && index == 0 otherwise the dual-layout is empty
  void checkForNullIndex(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentIndex = context.tabsRouter.activeIndex;
      if (AdaptiveLayout.layoutModeOf(context) == LayoutMode.dual && currentIndex == 0) {
        context.tabsRouter.setActiveIndex(1);
      }
    });
  }

  IconData get deviceIcon {
    if (AdaptiveLayout.of(context).isDesktop) {
      return IconsaxPlusLinear.monitor;
    }
    switch (AdaptiveLayout.viewSizeOf(context)) {
      case ViewSize.phone:
        return IconsaxPlusLinear.mobile;
      case ViewSize.tablet:
        return IconsaxPlusLinear.monitor;
      case ViewSize.desktop:
        return IconsaxPlusLinear.monitor;
    }
  }

  Widget _leftPane(BuildContext context) {
    void navigateTo(PageRouteInfo route) => context.tabsRouter.navigate(route);

    bool containsRoute(PageRouteInfo route) =>
        AdaptiveLayout.layoutModeOf(context) == LayoutMode.dual && context.tabsRouter.current.name == route.routeName;

    final quickConnectAvailable =
        ref.watch(userProvider.select((value) => value?.serverConfiguration?.quickConnectAvailable ?? false));

    return Container(
      color: context.colors.surface,
      child: SettingsScaffold(
        label: context.localized.settings,
        scrollController: scrollController,
        showBackButtonNested: true,
        showUserIcon: true,
        items: [
          SettingsListTile(
            label: Text(context.localized.settingsClientTitle),
            subLabel: Text(context.localized.settingsClientDesc),
            selected: containsRoute(const ClientSettingsRoute()),
            icon: deviceIcon,
            onTap: () => navigateTo(const ClientSettingsRoute()),
          ),
          if (quickConnectAvailable)
            SettingsListTile(
              label: Text(context.localized.settingsQuickConnectTitle),
              icon: IconsaxPlusLinear.password_check,
              onTap: () => openQuickConnectDialog(context),
            ),
          SettingsListTile(
            label: Text(context.localized.settingsProfileTitle),
            subLabel: Text(context.localized.settingsProfileDesc),
            selected: containsRoute(const SecuritySettingsRoute()),
            icon: IconsaxPlusLinear.security_user,
            onTap: () => navigateTo(const SecuritySettingsRoute()),
          ),
          SettingsListTile(
            label: Text(context.localized.settingsPlayerTitle),
            subLabel: Text(context.localized.settingsPlayerDesc),
            selected: containsRoute(const PlayerSettingsRoute()),
            icon: IconsaxPlusLinear.video_play,
            onTap: () => navigateTo(const PlayerSettingsRoute()),
          ),
          SettingsListTile(
            label: Text(context.localized.about),
            subLabel: const Text("Hessflix"),
            selected: containsRoute(const AboutSettingsRoute()),
            suffix: Opacity(
              opacity: 1,
              child: HessflixIconOutlined(
                size: 24,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            onTap: () => navigateTo(const AboutSettingsRoute()),
          ),
        ],
        floatingActionButton: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.paddingOf(context).horizontal),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                FloatingActionButton(
                  key: Key(context.localized.switchUser),
                  tooltip: context.localized.switchUser,
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logOutUser();
                    if (!kIsWeb && context.mounted) {
                      context.router.replaceAll([const LoginRoute()]);
                    }
                  },
                  child: const Icon(
                    IconsaxPlusLinear.arrow_swap_horizontal,
                  ),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: context.localized.logout,
                  key: Key(context.localized.logout),
                  tooltip: context.localized.logout,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  onPressed: () {
                    final user = ref.read(userProvider);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.localized.logoutUserPopupTitle(user?.name ?? "")),
                        scrollable: true,
                        content: Text(
                          context.localized.logoutUserPopupContent(user?.name ?? "", user?.server ?? ""),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.localized.cancel),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom().copyWith(
                              iconColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.onErrorContainer),
                              foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.onErrorContainer),
                              backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.errorContainer),
                            ),
                            onPressed: () async {
                              await ref.read(authProvider.notifier).logOutUser();
                              if (context.mounted) {
                                context.router.replaceAll([const LoginRoute()]);
                              }
                            },
                            child: Text(context.localized.logout),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    IconsaxPlusLinear.logout,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
