import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_route_paths.dart';
import '../presentation/analytics/analytics_screen.dart';
import '../screens/login/ui/login_screen.dart' as animated_login;
import '../presentation/community/community_screen.dart';
import '../presentation/core/main_navigation_screen.dart';
import '../presentation/core/providers/auth_state_provider.dart';
import '../presentation/dashboard/home_screen.dart';
import '../presentation/explore/explore_screen.dart';
import '../presentation/profile/profile_screen.dart';
import '../presentation/schedule/schedule_screen.dart';
import '../presentation/admin/admin_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutePaths.home,
    debugLogDiagnostics: false,
    refreshListenable: _RouterRefreshListenable(authNotifier.changes),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggingIn = state.matchedLocation == AppRoutePaths.login;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!authState.isAuthenticated && !isAuthRoute) {
        return AppRoutePaths.login;
      }

      if (authState.isAuthenticated && loggingIn) {
        return AppRoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.login,
        name: AppRouteNames.login,
        builder: (context, state) => const animated_login.LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.home,
                name: AppRouteNames.home,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.explore,
                name: AppRouteNames.explore,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ExploreScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.schedule,
                name: AppRouteNames.schedule,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ScheduleScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.community,
                name: AppRouteNames.community,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CommunityScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutePaths.analytics,
                name: AppRouteNames.analytics,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AnalyticsScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutePaths.admin,
                name: AppRouteNames.admin,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AdminDashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.profile,
                name: AppRouteNames.profile,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
