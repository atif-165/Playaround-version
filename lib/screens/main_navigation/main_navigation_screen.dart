import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../modules/coach/screens/coach_listing_screen.dart';
import '../../modules/coach/services/coach_service.dart';
import '../../screens/venue/venue_discovery_screen.dart';
import '../../modules/tournament/screens/tournament_list_screen.dart';
import '../../modules/team/screens/team_management_screen.dart';
import '../../theming/colors.dart';

import '../../core/widgets/notification_badge.dart' as notification_badge;
import '../dashboard/ui/dashboard_screen.dart';
import '../dashboard/dashboard_integration.dart';
import 'package:playaround/features/community_feed/ui/pages/community_feed_screen.dart';
import '../explore/screens/player_matchmaking_screen.dart';
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
  int _currentIndex = 3; // Community as default landing
  late PageController _pageController;
  late AnimationController _animationController;
  final CoachService _coachService = CoachService();
  bool _isCoachAdminLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
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
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
    const NavigationDestination(
      icon: Icon(Icons.sports_outlined),
      selectedIcon: Icon(Icons.sports),
      label: 'Coaches',
    ),
    const NavigationDestination(
      icon: Icon(Icons.swap_horiz),
      selectedIcon: Icon(Icons.swap_horiz),
      label: 'Swipe',
    ),
    const NavigationDestination(
      icon: Icon(Icons.forum_outlined),
      selectedIcon: Icon(Icons.forum),
      label: 'Community',
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
  ];

  final List<Widget> _screens = [
    const DashboardScreen(), // Profile
    const CoachListingScreen(), // Coaches
    const PlayerMatchmakingScreen(showBackButton: false), // Swipe Matches from nav
    const CommunityFeedScreen(), // Community (home)
    const VenueDiscoveryScreen(), // Venues
    const TeamManagementScreen(), // Teams
    const TournamentListScreen(), // Tournaments
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
      children: _screens
          .map(
            (screen) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: screen,
            ),
          )
          .toList(),
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
              data: IconThemeData(
                  color: isSelected ? Colors.red : Colors.grey[400], size: 24),
              child: isSelected
                  ? (destination.selectedIcon ?? destination.icon)
                  : destination.icon,
            );

            if (destination.label == 'Profile' && index == 0) {
              icon = notification_badge.NotificationBadge(
                count: 0,
                child: IconTheme(
                  data: IconThemeData(
                      color: isSelected ? Colors.red : Colors.grey[400],
                      size: 24),
                  child: isSelected
                      ? (destination.selectedIcon ?? destination.icon)
                      : destination.icon,
                ),
              );
            }

            return GestureDetector(
              onTap: () => _onDestinationSelected(index),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: isSelected
                    ? BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      )
                    : null,
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
      case 1: // Coaches - admin panel
        return material.FloatingActionButton(
          onPressed: _isCoachAdminLoading ? null : _navigateToCoachAdminPanel,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: _isCoachAdminLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.admin_panel_settings_outlined),
        );
      case 4: // Venues
        return material.FloatingActionButton(
          onPressed: _navigateToAddVenue,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.add_location),
        );
      case 5: // Teams
        return material.FloatingActionButton(
          onPressed: _navigateToCreateTeam,
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.group_add),
        );
      case 6: // Tournaments
        return material.FloatingActionButton(
          onPressed: _navigateToCreateTournament,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.emoji_events),
        );
      case 3: // Community (home)
        return material.FloatingActionButton(
          onPressed: _navigateToCreateCommunityPost,
          backgroundColor: ColorsManager.primary,
          foregroundColor: ColorsManager.onPrimary,
          child: const Icon(Icons.post_add),
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
  Future<void> _navigateToCoachAdminPanel() async {
    if (!mounted) return;
    setState(() {
      _isCoachAdminLoading = true;
    });

    try {
      final coachProfile = await _coachService.getCurrentUserCoachProfile();
      if (!mounted) return;

      if (coachProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only coaches can manage the coaching admin panel. Complete coach onboarding to continue.',
            ),
          ),
        );
        return;
      }

      await Navigator.pushNamed(
        context,
        Routes.coachProfileEditScreen,
        arguments: coachProfile,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open coach admin panel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isCoachAdminLoading = false;
      });
    }
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

  void _navigateToCreateCommunityPost() {
    Navigator.pushNamed(context, Routes.communityCreatePost);
  }
}
