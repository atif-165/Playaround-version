import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../modules/coach/screens/coach_listing_screen.dart';
import '../../screens/venue/venue_discovery_screen.dart';
import '../../modules/tournament/screens/tournament_list_screen.dart';
import '../../modules/team/screens/team_management_screen.dart';
import '../../theming/colors.dart';

import '../../core/widgets/notification_badge.dart' as notification_badge;
import '../dashboard/ui/dashboard_screen.dart';
import '../dashboard/dashboard_integration.dart';
import '../../modules/shop/screens/enhanced_shop_home_screen.dart';
import '../../routing/routes.dart';
import 'package:flutter/material.dart' as material;

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }



  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.sports_outlined),
      selectedIcon: Icon(Icons.sports),
      label: 'Coaches',
    ),
    const NavigationDestination(
      icon: Icon(Icons.location_on_outlined),
      selectedIcon: Icon(Icons.location_on),
      label: 'Venues',
    ),
    const NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      label: 'Teams',
    ),
    const NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events),
      label: 'Tournaments',
    ),
    const NavigationDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront),
      label: 'Shop',
    ),
  ];

  final List<Widget> _screens = [
    const DashboardScreen(),     // Dashboard (main hub)
    const CoachListingScreen(),  // Coach
    const VenueDiscoveryScreen(), // Venues
    const TeamManagementScreen(), // Teams
    const TournamentListScreen(), // Tournaments
    const EnhancedShopHomeScreen(),      // Shop
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBody(),
          _buildNavigationBar(),
          if (_buildFloatingActionButton() != null)
            Positioned(
              bottom: 90.h,
              right: 16.w,
              child: _buildFloatingActionButton()!,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: _screens.map((screen) =>
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: screen,
        ),
      ).toList(),
    );
  }

  Widget _buildNavigationBar() {
    return Positioned(
      bottom: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.outline.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _destinations.asMap().entries.map((entry) {
            final index = entry.key;
            final destination = entry.value;
            final isSelected = index == _currentIndex;

            Widget icon = IconTheme(
              data: IconThemeData(color: isSelected ? Colors.red : Colors.grey[400], size: 24),
              child: isSelected ? (destination.selectedIcon ?? destination.icon) : destination.icon,
            );

            if (destination.label == 'Dashboard' && index == 0) {
              icon = notification_badge.NotificationBadge(
                count: 0,
                child: IconTheme(
                  data: IconThemeData(color: isSelected ? Colors.red : Colors.grey[400], size: 24),
                  child: isSelected ? (destination.selectedIcon ?? destination.icon) : destination.icon,
                ),
              );
            }

            return GestureDetector(
              onTap: () => _onDestinationSelected(index),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: isSelected ? BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ) : null,
                child: icon,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show different FABs based on current screen
    switch (_currentIndex) {
      case 1: // Listings/Book
        return material.FloatingActionButton(
          onPressed: _navigateToCreateListing,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.add),
        );
      case 2: // Venues
        return material.FloatingActionButton(
          onPressed: _navigateToAddVenue,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.add_location),
        );
      case 3: // Teams
        return material.FloatingActionButton(
          onPressed: _navigateToCreateTeam,
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.group_add),
        );
      case 4: // Tournaments
        return material.FloatingActionButton(
          onPressed: _navigateToCreateTournament,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.emoji_events),
        );
      case 5: // Shop
        return material.FloatingActionButton(
          onPressed: _navigateToAddProduct,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.add_shopping_cart),
        );
      default:
        return null;
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) {
      // If tapping the same tab, scroll to top or refresh
      _scrollToTop();
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Trigger animation
    _animationController.forward().then((_) {
      _animationController.reset();
    });
  }

  void _scrollToTop() {
    // TODO: Implement scroll to top functionality for each screen
    // This would require passing scroll controllers to each screen
  }

  // Navigation methods for FAB actions
  void _navigateToCreateListing() {
    Navigator.pushNamed(context, Routes.shopAddProduct);
  }

  void _navigateToAddVenue() {
    Navigator.pushNamed(context, Routes.addVenueScreen);
  }

  void _navigateToCreateTeam() {
    Navigator.pushNamed(context, Routes.createTeamScreen);
  }

  void _navigateToCreateTournament() {
    Navigator.pushNamed(context, Routes.createTournamentScreen);
  }

  void _navigateToAddProduct() {
    Navigator.pushNamed(context, Routes.shopAddProduct);
  }
}
