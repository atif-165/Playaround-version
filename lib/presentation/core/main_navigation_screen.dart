import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_route_paths.dart';
import '../../core/i18n/localizations.dart';
import 'providers/auth_state_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);

    final navItems = _buildNavItems(strings, authState.role);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: widget.navigationShell,
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _GlassNavigationBar(
          items: navItems,
          currentIndex: widget.navigationShell.currentIndex,
          onItemSelected: (item) {
            context.go(item.route);
          },
        ),
      ),
    );
  }

  List<_NavItem> _buildNavItems(
    AppLocalizations strings,
    AppUserRole role,
  ) {
    final navItems = <_NavItem>[
      _NavItem(
        label: strings.translate('nav.home'),
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        route: AppRoutePaths.home,
      ),
      _NavItem(
        label: strings.translate('nav.explore'),
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore,
        route: AppRoutePaths.explore,
      ),
      _NavItem(
        label: strings.translate('nav.schedule'),
        icon: Icons.event_outlined,
        activeIcon: Icons.event,
        route: AppRoutePaths.schedule,
      ),
      _roleAwareItem(strings, role),
      _NavItem(
        label: strings.translate('nav.profile'),
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        route: AppRoutePaths.profile,
      ),
    ];

    return navItems;
  }

  _NavItem _roleAwareItem(AppLocalizations strings, AppUserRole role) {
    switch (role) {
      case AppUserRole.admin:
        return _NavItem(
          label: strings.translate('nav.admin'),
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          route: AppRoutePaths.admin,
        );
      case AppUserRole.coach:
        return _NavItem(
          label: strings.translate('nav.coach'),
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics,
          route: AppRoutePaths.analytics,
        );
      default:
        return _NavItem(
          label: strings.translate('nav.community'),
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups,
          route: AppRoutePaths.community,
        );
    }
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}

class _GlassNavigationBar extends StatelessWidget {
  const _GlassNavigationBar({
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<_NavItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.white.withOpacity(0.18),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 68,
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => onItemSelected(items[index]),
              destinations: [
                for (final item in items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: item.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
