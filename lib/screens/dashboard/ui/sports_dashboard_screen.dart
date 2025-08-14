import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../models/user_profile.dart';
import '../../../models/dashboard_models.dart';
import '../../../routing/routes.dart';
import '../../../logic/cubit/dashboard_cubit.dart';
import '../widgets/dashboard_widgets.dart' hide FloatingActionButton;


/// Modern sports dashboard screen with personalized content
class SportsDashboardScreen extends StatefulWidget {
  final UserProfile userProfile;

  const SportsDashboardScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<SportsDashboardScreen> createState() => _SportsDashboardScreenState();
}

class _SportsDashboardScreenState extends State<SportsDashboardScreen> {
  late ScrollController _scrollController;
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Load dashboard data
    context.read<DashboardCubit>().loadDashboardData(widget.userProfile);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showButton = _scrollController.offset > 200;
    if (showButton != _showFloatingButton) {
      setState(() {
        _showFloatingButton = showButton;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return _buildLoadingState();
          } else if (state is DashboardError) {
            return _buildErrorState(state.message);
          } else if (state is DashboardLoaded) {
            return _buildLoadedState(state);
          }
          return _buildLoadingState();
        },
      ),
      floatingActionButton: _showFloatingButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: ColorsManager.primary,
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 24.sp,
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          DashboardShimmer.header(),
          Gap(20.h),
          DashboardShimmer.carousel(
            title: 'Quick Actions',
            itemBuilder: () => DashboardShimmer.card(width: 150.w, height: 120.h),
            itemCount: 4,
            height: 120,
          ),
          Gap(24.h),
          DashboardShimmer.carousel(
            title: 'Discover Events',
            itemBuilder: () => DashboardShimmer.eventCard(),
            height: 280,
          ),
          Gap(24.h),
          DashboardShimmer.carousel(
            title: 'Featured Coaches',
            itemBuilder: () => DashboardShimmer.coachCard(),
            height: 320,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: ColorsManager.error,
          ),
          Gap(16.h),
          Text(
            'Oops! Something went wrong',
            style: AppTypography.headlineSmall.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(8.h),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(24.h),
          FilledButton.icon(
            onPressed: () {
              context.read<DashboardCubit>().loadDashboardData(widget.userProfile);
            },
            icon: Icon(Icons.refresh, size: 18.sp),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorsManager.primary,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(DashboardLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<DashboardCubit>().refreshDashboard();
      },
      color: ColorsManager.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Personalized Header
          SliverToBoxAdapter(
            child: PersonalizedHeader(
              userProfile: state.userProfile,
              stats: state.stats,
              onProfileTap: _navigateToProfile,
            ),
          ),

          // Live Updates Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 20.h, bottom: 24.h),
              child: LiveUpdatesBanner(
                updates: _getMockLiveUpdates(),
                onTap: _navigateToLiveUpdates,
              ),
            ),
          ),

          // Quick Actions Section
          SliverToBoxAdapter(
            child: _buildQuickActionsSection(state),
          ),

          // Dynamic Content Based on User Role
          if (state.isPlayer) ...[
            // Player-specific sections
            SliverToBoxAdapter(child: _buildUpcomingSessionsSection(state)),
            SliverToBoxAdapter(child: _buildMatchmakingSection(state)),
          ] else if (state.isCoach) ...[
            // Coach-specific sections
            SliverToBoxAdapter(child: _buildCoachSessionsSection(state)),
            SliverToBoxAdapter(child: _buildStudentProgressSection(state)),
          ],

          // Common sections for all users
          SliverToBoxAdapter(child: _buildEventsDiscoverySection(state)),
          SliverToBoxAdapter(child: _buildFeaturedCoachesSection(state)),
          SliverToBoxAdapter(child: _buildShopSection(state)),

          // Bottom padding
          SliverToBoxAdapter(
            child: Gap(100.h),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(DashboardLoaded state) {
    final actions = _getQuickActions(state);
    
    return ActionSection(
      title: 'Quick Actions',
      subtitle: 'Get started with your sports journey',
      actionButtons: actions,
      crossAxisCount: 2,
    );
  }

  Widget _buildUpcomingSessionsSection(DashboardLoaded state) {
    // Mock upcoming sessions - in real app would come from state
    final upcomingSessions = <Widget>[
      CompactEventCard(
        event: state.upcomingEvents.isNotEmpty 
            ? state.upcomingEvents.first 
            : _getMockEvent(),
        onTap: () => _navigateToEventDetails('session1'),
      ),
      // Add more session cards...
    ];

    return DashboardSection(
      title: 'Your Next Practice',
      subtitle: 'Don\'t miss your upcoming sessions',
      onSeeAll: _navigateToSessions,
      child: Column(
        children: [
          Gap(16.h),
          ...upcomingSessions.map((session) => Padding(
            padding: EdgeInsets.only(bottom: 12.h, left: 20.w, right: 20.w),
            child: session,
          )),
        ],
      ),
    );
  }

  Widget _buildMatchmakingSection(DashboardLoaded state) {
    return CarouselSection(
      title: 'Find Your Match',
      subtitle: 'Connect with players and coaches near you',
      height: 420.h,
      onSeeAll: _navigateToMatchmaking,
      children: state.matchmakingSuggestions.map((suggestion) {
        return MatchmakingCard(
          suggestion: suggestion,
          onLike: () => _handleMatchmakingLike(suggestion.id),
          onPass: () => _handleMatchmakingPass(suggestion.id),
          onTap: () => _navigateToProfile(suggestion.id),
        );
      }).toList(),
    );
  }

  Widget _buildCoachSessionsSection(DashboardLoaded state) {
    return DashboardSection(
      title: 'Today\'s Sessions',
      subtitle: 'Your coaching schedule',
      onSeeAll: _navigateToCoachSessions,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            // Mock coach sessions
            _buildCoachSessionCard('Morning Basketball', '09:00 - 10:30', 8),
            Gap(12.h),
            _buildCoachSessionCard('Tennis Fundamentals', '14:00 - 15:30', 6),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentProgressSection(DashboardLoaded state) {
    return StatsSection(
      title: 'Student Progress',
      statCards: [
        QuickStatsCard(
          title: 'Active Students',
          value: '24',
          icon: Icons.people,
          color: ColorsManager.success,
          onTap: _navigateToStudents,
        ),
        const QuickStatsCard(
          title: 'Avg Rating',
          value: '4.8',
          icon: Icons.star,
          color: Colors.amber,
          showTrend: true,
          trendValue: 2.5,
          isPositiveTrend: true,
        ),
        const QuickStatsCard(
          title: 'This Week',
          value: '12',
          icon: Icons.schedule,
          color: ColorsManager.primary,
          subtitle: 'sessions',
        ),
      ],
    );
  }

  Widget _buildEventsDiscoverySection(DashboardLoaded state) {
    if (state.nearbyEvents.isEmpty) {
      return DashboardSection(
        title: 'Discover Events',
        subtitle: 'Tournaments and activities near you',
        onSeeAll: _navigateToEvents,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: DashboardEmptyStates.noEvents(),
        ),
      );
    }

    return CarouselSection(
      title: 'Discover Events',
      subtitle: 'Tournaments and activities near you',
      height: 280.h,
      onSeeAll: _navigateToEvents,
      children: state.nearbyEvents.map((event) {
        return EventCard(
          event: event,
          onTap: () => _navigateToEventDetails(event.id),
          onBookmark: () => _toggleEventBookmark(event.id),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturedCoachesSection(DashboardLoaded state) {
    if (state.featuredCoaches.isEmpty) {
      return DashboardSection(
        title: 'Featured Coaches',
        subtitle: 'Top-rated coaches in your area',
        onSeeAll: _navigateToCoaches,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: DashboardEmptyStates.noCoaches(),
        ),
      );
    }

    return CarouselSection(
      title: 'Featured Coaches',
      subtitle: 'Top-rated coaches in your area',
      height: 320.h,
      onSeeAll: _navigateToCoaches,
      children: state.featuredCoaches.map((coach) {
        return CoachCard(
          coach: coach,
          onTap: () => _navigateToCoachProfile(coach.id),
          onMessage: () => _messageCoach(coach.id),
          onBook: () => _bookCoach(coach.id),
        );
      }).toList(),
    );
  }

  Widget _buildShopSection(DashboardLoaded state) {
    if (state.recommendedProducts.isEmpty) {
      return DashboardSection(
        title: 'Recommended Gear',
        subtitle: 'Equipment picked just for you',
        onSeeAll: _navigateToShop,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: DashboardEmptyStates.noProducts(),
        ),
      );
    }

    return CarouselSection(
      title: 'Recommended Gear',
      subtitle: 'Equipment picked just for you',
      height: 240.h,
      onSeeAll: _navigateToShop,
      children: state.recommendedProducts.map((product) {
        return ShopProductCard(
          product: product,
          onTap: () => _navigateToProduct(product.id),
          onAddToCart: () => _addToCart(product.id),
          onFavorite: () => _toggleProductFavorite(product.id),
        );
      }).toList(),
    );
  }

  Widget _buildCoachSessionCard(String title, String time, int participants) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.outlineVariant,
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.sports,
              color: ColorsManager.primary,
              size: 20.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: ColorsManager.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(4.h),
                Text(
                  time,
                  style: AppTypography.bodySmall.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: ColorsManager.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '$participants students',
              style: AppTypography.labelSmall.copyWith(
                color: ColorsManager.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Navigation methods
  void _navigateToProfile([String? userId]) {
    if (userId != null) {
      Navigator.pushNamed(context, '/profileViewScreen', arguments: userId);
    } else {
      Navigator.pushNamed(context, '/profileScreen');
    }
  }

  void _navigateToLiveUpdates() {
    // TODO: Navigate to live updates screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live updates feature coming soon!')),
    );
  }

  void _navigateToSessions() {
    // TODO: Navigate to sessions screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sessions management coming soon!')),
    );
  }

  void _navigateToMatchmaking() {
    Navigator.pushNamed(context, Routes.peopleSearchScreen);
  }

  void _navigateToEvents() {
    // Show message that tournaments feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tournaments feature coming soon! Stay tuned for exciting competitions.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToCoaches() {
    // Show message that coaches listing is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coaches listing feature coming soon! For now, use People Search to find coaches.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToShop() {
    Navigator.pushNamed(context, '/shop');
  }

  void _navigateToEventDetails(String eventId) {
    // TODO: Navigate to event details when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event details coming soon!')),
    );
  }

  void _navigateToCoachProfile(String coachId) {
    Navigator.pushNamed(context, '/profileViewScreen', arguments: coachId);
  }

  void _navigateToProduct(String productId) {
    // TODO: Navigate to product details when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product details coming soon!')),
    );
  }

  void _navigateToCoachSessions() {
    Navigator.pushNamed(context, '/createSessionScreen');
  }

  void _navigateToStudents() {
    // TODO: Navigate to students list when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Students management coming soon!')),
    );
  }

  // Action methods
  void _handleMatchmakingLike(String userId) {
    // Handle matchmaking like
  }

  void _handleMatchmakingPass(String userId) {
    // Handle matchmaking pass
  }

  void _toggleEventBookmark(String eventId) {
    context.read<DashboardCubit>().toggleEventBookmark(eventId);
  }

  void _messageCoach(String coachId) {
    // Open chat with coach
  }

  void _bookCoach(String coachId) {
    // Navigate to booking screen
  }

  void _addToCart(String productId) {
    // Add product to cart
  }

  void _toggleProductFavorite(String productId) {
    // Toggle product favorite
  }

  // Helper methods
  List<Widget> _getQuickActions(DashboardLoaded state) {
    if (state.isPlayer) {
      return [
        CompactActionButton(
          title: 'Find Coach',
          icon: Icons.person_search,
          color: ColorsManager.primary,
          onPressed: _navigateToCoaches,
        ),
        CompactActionButton(
          title: 'Join Tournament',
          icon: Icons.emoji_events,
          color: ColorsManager.secondary,
          onPressed: _navigateToEvents,
        ),
        CompactActionButton(
          title: 'Book Venue',
          icon: Icons.location_on,
          color: ColorsManager.tertiary,
          onPressed: () => Navigator.pushNamed(context, '/venueBookingScreen'),
        ),
        CompactActionButton(
          title: 'Find Team',
          icon: Icons.group,
          color: ColorsManager.success,
          onPressed: () => Navigator.pushNamed(context, '/teamFinderScreen'),
        ),
      ];
    } else {
      return [
        CompactActionButton(
          title: 'Create Session',
          icon: Icons.add_circle,
          color: ColorsManager.primary,
          onPressed: () => Navigator.pushNamed(context, '/createSessionScreen'),
        ),
        CompactActionButton(
          title: 'My Students',
          icon: Icons.people,
          color: ColorsManager.secondary,
          onPressed: _navigateToStudents,
        ),
        CompactActionButton(
          title: 'Analytics',
          icon: Icons.analytics,
          color: ColorsManager.tertiary,
          onPressed: () => Navigator.pushNamed(context, '/analyticsScreen'),
        ),
        CompactActionButton(
          title: 'Schedule',
          icon: Icons.calendar_today,
          color: ColorsManager.success,
          onPressed: _navigateToCoachSessions,
        ),
      ];
    }
  }

  List<LiveUpdate> _getMockLiveUpdates() {
    return [
      LiveUpdate(
        id: '1',
        title: 'Basketball Tournament',
        description: 'Finals starting in 30 minutes',
        type: LiveUpdateType.tournament,
        actionText: 'Watch Live',
        timestamp: DateTime.now(),
      ),
      LiveUpdate(
        id: '2',
        title: 'New Team Member',
        description: 'Sarah joined your tennis team',
        type: LiveUpdateType.team,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  // Mock data helper (remove in production)
  DashboardEvent _getMockEvent() {
    return DashboardEvent(
      id: 'mock-event-1',
      title: 'Basketball Training Session',
      description: 'Improve your shooting skills with professional coaching',
      imageUrl: '', // Empty string will trigger placeholder in CachedNetworkImage
      dateTime: DateTime.now().add(const Duration(days: 1)),
      location: 'Sports Center',
      eventType: 'training',
      price: 25.0,
      maxParticipants: 12,
      currentParticipants: 8,
      sportsInvolved: ['Basketball'],
      organizerId: 'coach-123',
      organizerName: 'Coach Mike',
      isBookmarked: false,
    );
  }
}
