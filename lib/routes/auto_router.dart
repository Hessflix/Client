import 'package:flutter/foundation.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hessflix/providers/user_provider.dart';
import 'package:hessflix/routes/auto_router.gr.dart';
import 'package:hessflix/screens/login/lock_screen.dart';

const settingsPageRoute = "settings";

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AutoRouter extends RootStackRouter {
  AutoRouter({
    required this.ref,
  });

  final WidgetRef ref;

  @override
  List<AutoRouteGuard> get guards => [...super.guards, AuthGuard(ref: ref)];

  @override
  RouteType get defaultRouteType => kIsWeb ? const RouteType.material() : const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
        ..._defaultRoutes,
        ...otherRoutes,
      ];

  final List<AutoRoute> otherRoutes = [
    _homeRoute.copyWith(
      children: [
        ...homeRoutes,
        AutoRoute(page: DetailsRoute.page, path: 'details', usesPathAsKey: true),
        AutoRoute(page: LibrarySearchRoute.page, path: 'library', usesPathAsKey: true),
        CustomRoute(
          page: SettingsRoute.page,
          path: settingsPageRoute,
          children: _settingsChildren,
          transitionsBuilder: TransitionsBuilders.fadeIn,
        ),
      ],
    ),
    AutoRoute(page: LockRoute.page, path: '/locked'),
  ];
}

final List<AutoRoute> homeRoutes = [
  _dashboardRoute,
  _favouritesRoute,
  _syncedRoute,
];

final List<AutoRoute> _defaultRoutes = [
  AutoRoute(page: SplashRoute.page, path: '/splash'),
  AutoRoute(page: LoginRoute.page, path: '/login'),
];

final AutoRoute _homeRoute = AutoRoute(page: HomeRoute.page, path: '/');
final AutoRoute _dashboardRoute = CustomRoute(
  page: DashboardRoute.page,
  transitionsBuilder: TransitionsBuilders.fadeIn,
  initial: true,
  maintainState: false,
  path: 'dashboard',
);
final AutoRoute _favouritesRoute = CustomRoute(
  page: FavouritesRoute.page,
  transitionsBuilder: TransitionsBuilders.fadeIn,
  maintainState: false,
  path: 'favourites',
);
final AutoRoute _syncedRoute = CustomRoute(
  page: SyncedRoute.page,
  transitionsBuilder: TransitionsBuilders.fadeIn,
  maintainState: false,
  path: 'synced',
);

final List<AutoRoute> _settingsChildren = [
  CustomRoute(page: SettingsSelectionRoute.page, transitionsBuilder: TransitionsBuilders.fadeIn, path: 'list'),
  CustomRoute(page: ClientSettingsRoute.page, transitionsBuilder: TransitionsBuilders.fadeIn, path: 'client'),
  CustomRoute(page: SecuritySettingsRoute.page, transitionsBuilder: TransitionsBuilders.fadeIn, path: 'security'),
  CustomRoute(page: PlayerSettingsRoute.page, transitionsBuilder: TransitionsBuilders.fadeIn, path: 'player'),
  CustomRoute(page: AboutSettingsRoute.page, transitionsBuilder: TransitionsBuilders.fadeIn, path: 'about'),
];

class LockScreenGuard extends AutoRouteGuard {
  final WidgetRef ref;

  const LockScreenGuard({required this.ref});

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (ref.read(lockScreenActiveProvider) && resolver.routeName != const LockRoute().routeName) {
      router.replace(const LockRoute());
      return;
    } else {
      return resolver.next(true);
    }
  }
}

class AuthGuard extends AutoRouteGuard {
  final WidgetRef ref;

  const AuthGuard({required this.ref});

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (ref.read(userProvider) != null ||
        resolver.routeName == const LoginRoute().routeName ||
        resolver.routeName == SplashRoute().routeName) {
      return resolver.next(true);
    }

    resolver.redirect<bool>(SplashRoute(loggedIn: (value) {
      if (value) {
        resolver.next(true);
      } else {
        router.replace(const LoginRoute());
      }
    }));
  }
}
