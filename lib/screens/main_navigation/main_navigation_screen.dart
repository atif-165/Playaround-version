import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../modules/coach/screens/coach_listing_screen.dart';
import '../../modules/venue/screens/venues_screen.dart';
import '../../modules/tournament/screens/tournament_list_screen.dart';
import '../../modules/team/screens/team_management_screen.dart';
import '../../theming/colors.dart';
import '../../core/widgets/material3/material3_components.dart';
import '../dashboard/ui/dashboard_screen.dart';
import '../../modules/shop/screens/shop_home_screen.dart';

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
      label: '',
    ),
    const NavigationDestination(
      icon: Icon(Icons.sports_outlined),
      selectedIcon: Icon(Icons.sports),
      label: '',
    ),
    const NavigationDestination(
      icon: Icon(Icons.location_on_outlined),
      selectedIcon: Icon(Icons.location_on),
      label: '',
    ),
    const NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      label: '',
    ),
    const NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events),
      label: '',
    ),
    const NavigationDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront),
      label: '',
    ),
  ];

  final List<Widget> _screens = [
    const DashboardScreen(),     // Dashboard (main hub)
    const CoachListingScreen(),  // Coach
    const VenuesScreen(),        // Venues
    const TeamManagementScreen(), // Teams
    const TournamentListScreen(), // Tournaments
    const ShopHomeScreen(),      // Shop
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: ColorsManager.surface,
        surfaceTintColor: ColorsManager.surfaceTint,
        indicatorColor: ColorsManager.secondaryContainer,
        height: 80.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: _destinations.map((destination) {
          final index = _destinations.indexOf(destination);

          // Add badge for ratings if needed
          Widget icon = destination.icon;
          Widget selectedIcon = destination.selectedIcon ?? destination.icon;

          if (destination.label == 'Dashboard' && index == 0) {
            // Add notification badge to dashboard if there are pending items
            icon = NotificationBadge(
              count: 0, // TODO: Get actual notification count
              showZero: false,
              child: destination.icon,
            );
            selectedIcon = NotificationBadge(
              count: 0, // TODO: Get actual notification count
              showZero: false,
              child: destination.selectedIcon ?? destination.icon,
            );
          }

          return NavigationDestination(
            icon: icon,
            selectedIcon: selectedIcon,
            label: destination.label,
          );
        }).toList(),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show different FABs based on current screen
    switch (_currentIndex) {
      case 1: // Listings/Book
        return FloatingActionButton(
          onPressed: _navigateToCreateListing,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.add),
        );
      case 2: // Venues
        return FloatingActionButton(
          onPressed: _navigateToAddVenue,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.add_location),
        );
      case 3: // Teams
        return FloatingActionButton(
          onPressed: _navigateToCreateTeam,
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.group_add),
        );
      case 4: // Tournaments
        return FloatingActionButton(
          onPressed: _navigateToCreateTournament,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.emoji_events),
        );
      case 5: // Shop
        return FloatingActionButton(
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
    Navigator.pushNamed(context, '/create-listing');
  }

  void _navigateToAddVenue() {
    Navigator.pushNamed(context, '/add-venue');
  }

  void _navigateToCreateTeam() {
    Navigator.pushNamed(context, '/create-team');
  }

  void _navigateToCreateTournament() {
    Navigator.pushNamed(context, '/create-tournament');
  }

  void _navigateToAddProduct() {
    Navigator.pushNamed(context, '/shop/add-product');
  }
}
