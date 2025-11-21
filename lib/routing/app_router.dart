import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/models.dart';
import '../modules/team/cubit/team_cubit.dart';
import '../modules/tournament/cubit/tournament_cubit.dart';
import '../presentation/auth/screens/create_password_screen.dart';
import '../presentation/auth/screens/email_verification_screen.dart';
import '../screens/forget/ui/forget_screen.dart';
import '../screens/login/ui/login_screen.dart' as animated_login;
import '../screens/onboarding/ui/role_selection_screen.dart';
import '../screens/onboarding/ui/player_onboarding_screen.dart';
import '../screens/onboarding/ui/coach_onboarding_screen.dart';
import '../screens/signup/ui/sign_up_screen.dart' as animated_signup;
import '../screens/splash/splash_screen.dart';
import '../screens/home/ui/home_screen.dart';
import '../screens/main_navigation/main_navigation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/dashboard/ui/dashboard_screen.dart';
import '../modules/skill_tracking/skill_tracking_module.dart';
import '../screens/match_requests/match_requests_screen.dart';
import '../modules/venue/screens/add_venue_screen.dart';
import '../screens/venue/venue_discovery_screen.dart';
import '../screens/venue/venue_profile_screen.dart';
import '../screens/venue_booking/venue_booking_screen.dart';
import '../models/venue.dart';
import '../modules/chat/screens/chat_list_screen.dart';
import '../modules/chat/screens/chat_screen.dart';
import '../modules/chat/screens/user_search_screen.dart';
import '../modules/matchmaking/screens/match_profile_detail_screen.dart';
import '../modules/matchmaking/models/matchmaking_models.dart';
import '../modules/chat/models/chat_room.dart';
import '../modules/booking/screens/my_booking_history_screen.dart';
import '../modules/team/screens/team_list_screen.dart';
import '../modules/team/screens/team_profile_screen.dart';
import '../modules/team/screens/add_team_screen.dart';
import '../modules/team/screens/team_management_screen.dart';
import '../modules/team/screens/team_admin_screen.dart';
import '../modules/tournament/screens/tournament_list_screen.dart';
import '../modules/tournament/screens/tournament_detail_screen.dart';
import '../modules/tournament/screens/create_tournament_screen.dart';
import '../modules/booking/screens/coach_earnings_screen.dart';
import '../modules/booking/screens/booking_detail_screen.dart';
import '../modules/coach_analytics/screens/coach_analytics_dashboard_screen.dart';
import '../modules/coach/screens/coach_profile_edit_screen.dart';
import '../modules/coach/screens/coach_listing_screen.dart';
import '../data/models/booking_model.dart' as data;
import '../models/coach_profile.dart';
// Community
import 'package:playaround/features/community_feed/models/feed_post.dart';
import 'package:playaround/features/community_feed/ui/pages/community_feed_screen.dart';
import 'package:playaround/features/community_feed/ui/pages/post_detail_screen.dart';
import '../modules/community/screens/community_create_post_screen.dart';
import '../modules/community/screens/admin_moderation_screen.dart';
import '../modules/community/models/models.dart';
// Shop
import '../modules/shop/screens/shop_screen.dart';
import '../modules/shop/screens/shop_map_screen.dart';
import '../modules/shop/screens/location_detail_screen.dart';
import '../modules/shop/screens/add_location_screen.dart';
import '../modules/shop/screens/edit_location_screen.dart';
import '../modules/shop/screens/admin_orders_screen.dart';
import '../modules/shop/models/shop_location.dart';

// Quick Action Screens
import '../screens/team_finder/team_finder_screen.dart';
import '../screens/create_session/create_session_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/explore/screens/player_matchmaking_screen.dart';
// People Search Screens
import '../screens/people_search/people_search_screen.dart';
// Tournament Screens - REPLACED WITH NEW IMPLEMENTATION
import '../modules/tournament/models/tournament_model.dart';
import '../screens/coach/my_students_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/events/event_details_screen.dart';
import '../screens/coach/book_coach_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class AppRoutePath {
  static const String dashboard = '/dashboard';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String venues = '/venues';
  static const String tournaments = '/tournaments';
  static const String teams = '/teams';
  static const String community = '/community';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String onboarding = '/onboarding';
  static const String emailVerification = '/email-verification';
  static const String createPassword = '/create-password';
  static const String forgotPassword = '/forgot-password';
  static const String splash = '/splash';
  static const String main = '/main';

  // Screen routes
  static const String splashScreen = '/splash';
  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';
  static const String loginScreen = authLogin;
  static const String signupScreen = authSignup;
  static const String dashboardScreen = '/dashboard';
  static const String forgetScreen = '/forgot-password';
  static const String homeScreen = '/home';
  static const String emailVerificationScreen = '/auth/verify-email';
  static const String roleSelectionScreen = '/auth/onboarding/role';
  static const String playerOnboardingScreen = '/onboarding/player';
  static const String coachOnboardingScreen = '/onboarding/coach';
  static const String unifiedOnboardingScreen = '/auth/onboarding';
  static const String profileScreen = '/profile';
  static const String matchRequestsScreen = '/match-requests';
  static const String chatListScreen = '/chat-list';
  static const String userSearchScreen = '/user-search';
  static const String chatScreen = '/chat';
  static const String skillDashboardScreen = '/skill-dashboard';
  static const String playerMatchmakingScreen = '/player-matchmaking';
  static const String addGoalScreen = '/add-goal';
  static const String coachLoggingScreen = '/coach-logging';
  static const String analyticsDashboardScreen = '/analytics-dashboard';
  static const String myBookingHistoryScreen = '/my-booking-history';
  static const String coachEarningsScreen = '/coach-earnings';
  static const String bookingDetailScreen = '/booking-detail';
  static const String coachAnalyticsDashboardScreen =
      '/coach-analytics-dashboard';
  static const String venueDiscoveryScreen = '/venue-discovery';
  static const String venueProfileScreen = '/venue-profile';
  static const String venueBookingScreen = '/venue-booking';
  static const String addVenueScreen = '/add-venue';
  // Community routes
  static const String communityHome = '/community-home';
  static const String communityCreatePost = '/community-create-post';
  static const String communityPostDetail = '/community-post-detail';
  static const String communityUserProfile = '/community-user-profile';
  static const String communityAdminModeration = '/community-admin-moderation';

  // Shop routes
  static const String shop = '/shop';
  static const String shopMap = '/shop-map';
  static const String locationDetail = '/location-detail';
  static const String addLocation = '/add-location';
  static const String editLocation = '/edit-location';
  static const String shopAddProduct = '/shop-add-product';
  static const String shopProductDetail = '/shop-product-detail';
  static const String shopCheckout = '/shop-checkout';
  static const String shopDetail = '/shop-detail';
  static const String shopCart = '/shop-cart';
  static const String shopOrders = '/shop-orders';
  static const String shopAdminOrders = '/shop-admin-orders';

  static const String teamFinderScreen = '/team-finder';
  static const String mainNavigation = '/main-navigation';
  static const String createSessionScreen = '/create-session';
  static const String analyticsScreen = '/analytics';
  static const String peopleSearchScreen = '/people-search';
  // Team routes
  static const String teamListScreen = '/team-list';
  static const String teamDetailScreen = '/team-detail';
  static const String addTeamScreen = '/add-team';
  static const String teamManagementScreen = '/team-management';
  static const String addTeamMemberScreen = '/add-team-member';
  static const String teamAdminScreen = '/teamAdminScreen';

  // Tournament routes
  static const String tournamentListScreen = '/tournament-list';
  static const String tournamentDetailScreen = '/tournament-detail';
  static const String addTournamentScreen = '/add-tournament';
  static const String tournamentManagementScreen = '/tournament-management';
  static const String tournamentAdminScreen = '/tournament-admin';
  static const String matchDetailScreen = '/match-detail';
  static const String tournamentDebugScreen = '/tournament-debug';
  static const String playerComparisonScreen = '/player-comparison';
  static const String notificationsScreen = '/notifications';
  static const String coachListingScreen = '/coach-listing';
  static const String coachProfileEditScreen = '/coach-profile-edit';
  static const String myStudentsScreen = '/my-students';
  static const String scheduleScreen = '/schedule';
  static const String eventDetailsScreen = '/event-details';
  static const String bookCoachScreen = '/book-coach';
  static const String matchProfileDetailScreen = '/match-profile-detail';
}

class AppRouter {
  static const String initialRoute = AppRoutePath.splashScreen;

  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutePath.splashScreen:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case AppRoutePath.mainNavigation:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );

      case AppRoutePath.onboarding:
        // Redirect to role selection instead of showing onboarding form
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        );

      case AppRoutePath.forgetScreen:
        return MaterialPageRoute(
          builder: (_) => const ForgetScreen(),
        );

      case AppRoutePath.homeScreen:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case AppRoutePath.dashboardScreen:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );

      case AppRoutePath.main:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );

      case AppRoutePath.createPassword:
        return MaterialPageRoute(
          builder: (_) => const CreatePasswordScreen(),
        );

      case AppRoutePath.signupScreen:
        return MaterialPageRoute(
          builder: (_) => const animated_signup.SignUpScreen(),
        );

      case AppRoutePath.loginScreen:
        return MaterialPageRoute(
          builder: (_) => const animated_login.LoginScreen(),
        );

      case AppRoutePath.emailVerificationScreen:
        return MaterialPageRoute(
          builder: (_) => const EmailVerificationScreen(),
        );

      case AppRoutePath.roleSelectionScreen:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        );

      case AppRoutePath.playerOnboardingScreen:
        return MaterialPageRoute(
          builder: (_) => const PlayerOnboardingScreen(),
        );

      case AppRoutePath.coachOnboardingScreen:
        return MaterialPageRoute(
          builder: (_) => const CoachOnboardingScreen(),
        );

      case AppRoutePath.unifiedOnboardingScreen:
        // Redirect to role selection instead of showing onboarding form
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        );

      case AppRoutePath.profileScreen:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case AppRoutePath.matchRequestsScreen:
        return MaterialPageRoute(
          builder: (_) => const MatchRequestsScreen(),
        );

      case AppRoutePath.chatListScreen:
        return MaterialPageRoute(
          builder: (_) => const ChatListScreen(),
        );

      case AppRoutePath.userSearchScreen:
        return MaterialPageRoute(
          builder: (_) => const UserSearchScreen(),
        );

      case AppRoutePath.chatScreen:
        final chatRoom = settings.arguments;
        if (chatRoom != null && chatRoom is ChatRoom) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(chatRoom: chatRoom),
          );
        }
        break;

      // Skill Tracking Routes
      case AppRoutePath.skillDashboardScreen:
        final playerId = settings.arguments as String?;
        if (playerId != null) {
          return MaterialPageRoute(
            builder: (_) => SkillDashboardScreen(playerId: playerId),
          );
        }
        break;

      case AppRoutePath.playerMatchmakingScreen:
        return MaterialPageRoute(
          builder: (_) => const PlayerMatchmakingScreen(),
        );

      case AppRoutePath.addGoalScreen:
        final arguments = settings.arguments as Map<String, dynamic>?;
        if (arguments != null) {
          return MaterialPageRoute(
            builder: (_) => AddGoalScreen(
              playerId: arguments['playerId'] as String,
              currentSkillScores:
                  arguments['currentSkillScores'] as Map<SkillType, int>,
            ),
          );
        }
        break;

      case AppRoutePath.coachLoggingScreen:
        final arguments = settings.arguments as Map<String, dynamic>?;
        if (arguments != null) {
          return MaterialPageRoute(
            builder: (_) => CoachLoggingScreen(
              coachId: arguments['coachId'] as String,
              playerId: arguments['playerId'] as String,
              playerName: arguments['playerName'] as String,
            ),
          );
        }
        break;

      case AppRoutePath.analyticsDashboardScreen:
        final playerId = settings.arguments as String?;
        if (playerId != null) {
          return MaterialPageRoute(
            builder: (_) => AnalyticsDashboardScreen(playerId: playerId),
          );
        }
        break;

      case AppRoutePath.myBookingHistoryScreen:
        return MaterialPageRoute(
          builder: (_) => const MyBookingHistoryScreen(),
        );

      case AppRoutePath.coachEarningsScreen:
        return MaterialPageRoute(
          builder: (_) => const CoachEarningsScreen(),
        );

      case AppRoutePath.bookingDetailScreen:
        final booking = settings.arguments as data.BookingModel?;
        if (booking != null) {
          return MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          );
        }
        break;

      case AppRoutePath.coachAnalyticsDashboardScreen:
        return MaterialPageRoute(
          builder: (_) => const CoachAnalyticsDashboardScreen(),
        );

      case AppRoutePath.coachProfileEditScreen:
        final coach = settings.arguments as CoachProfile?;
        if (coach != null) {
          return MaterialPageRoute(
            builder: (_) => CoachProfileEditScreen(coach: coach),
          );
        }
        break;

      case AppRoutePath.coachListingScreen:
        return MaterialPageRoute(
          builder: (_) => const CoachListingScreen(),
        );

      // Venue routes
      case AppRoutePath.venueDiscoveryScreen:
        return MaterialPageRoute(builder: (_) => const VenueDiscoveryScreen());

      case AppRoutePath.venueProfileScreen:
        final venue = settings.arguments as Venue?;
        if (venue != null) {
          return MaterialPageRoute(
            builder: (_) => VenueProfileScreen(venue: venue),
          );
        }
        break;

      case AppRoutePath.venueBookingScreen:
        return MaterialPageRoute(
          builder: (_) => const VenueBookingScreen(),
        );

      case AppRoutePath.addVenueScreen:
        return MaterialPageRoute(builder: (_) => const AddVenueScreen());

      case AppRoutePath.notifications:
      case AppRoutePath.notificationsScreen:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      // Community routes
      case AppRoutePath.communityHome:
        return MaterialPageRoute(builder: (_) => const CommunityFeedScreen());

      case AppRoutePath.communityCreatePost:
        return MaterialPageRoute(
            builder: (_) => const CommunityCreatePostScreen());

      case AppRoutePath.communityPostDetail:
        final args = settings.arguments;
        if (args is CommunityPost) {
          final feedPost = args.toFeedPost();
          return MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              postId: args.id,
              initialPost: feedPost,
            ),
          );
        } else if (args is FeedPost) {
          return MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              postId: args.id,
              initialPost: args,
            ),
          );
        } else if (args is String && args.isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: args),
          );
        }
        break;

      case AppRoutePath.communityUserProfile:
        final userId = settings.arguments as String?;
        if (userId != null) {
          return MaterialPageRoute(
            builder: (_) => DashboardScreen(userId: userId),
          );
        }
        break;

      case AppRoutePath.communityAdminModeration:
        return MaterialPageRoute(builder: (_) => const AdminModerationScreen());

      // Shop routes
      case AppRoutePath.shop:
        return MaterialPageRoute(builder: (_) => const ShopScreen());

      case AppRoutePath.shopMap:
        return MaterialPageRoute(builder: (_) => const ShopMapScreen());

      case AppRoutePath.shopAdminOrders:
        return MaterialPageRoute(builder: (_) => AdminOrdersScreen());

      case AppRoutePath.locationDetail:
        final location = settings.arguments as ShopLocation?;
        if (location != null) {
          return MaterialPageRoute(
            builder: (_) => LocationDetailScreen(location: location),
          );
        }
        break;

      case AppRoutePath.addLocation:
        final position = settings.arguments as LatLng?;
        return MaterialPageRoute(
          builder: (_) => AddLocationScreen(initialPosition: position),
        );

      case AppRoutePath.editLocation:
        final location = settings.arguments as ShopLocation?;
        if (location != null) {
          return MaterialPageRoute(
            builder: (_) => EditLocationScreen(location: location),
          );
        }
        break;

      // Quick Action routes

      case AppRoutePath.teamFinderScreen:
        return MaterialPageRoute(builder: (_) => const TeamFinderScreen());

      case AppRoutePath.createSessionScreen:
        return MaterialPageRoute(builder: (_) => const CreateSessionScreen());

      case AppRoutePath.analyticsScreen:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());

      // Team Management routes
      case AppRoutePath.teamListScreen:
        return MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<TeamCubit>(),
            child: const TeamListScreen(),
          ),
        );

      case AppRoutePath.teamManagementScreen:
        final teamId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => TeamManagementScreen(teamId: teamId),
        );

      case AppRoutePath.teamAdminScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final teamId = args?['teamId'] as String?;
        final teamName = args?['teamName'] as String? ?? 'Team Admin';
        final canEdit = args?['canEdit'] as bool? ?? true;
        if (teamId != null) {
          return MaterialPageRoute(
            builder: (_) => TeamAdminScreen(
              teamId: teamId,
              teamName: teamName,
              isReadOnly: !canEdit,
            ),
          );
        }
        break;

      case AppRoutePath.teamDetailScreen:
        final team = settings.arguments as TeamModel?;
        if (team != null) {
          return MaterialPageRoute(
            builder: (_) => TeamProfileScreen(
              team: team,
            ),
          );
        }
        break;

      case AppRoutePath.addTeamScreen:
        return MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<TeamCubit>(),
            child: const AddTeamScreen(),
          ),
        );

      // People Search routes
      case AppRoutePath.peopleSearchScreen:
        return MaterialPageRoute(builder: (_) => const PeopleSearchScreen());

      // Tournament routes
      case AppRoutePath.tournamentListScreen:
        return MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<TournamentCubit>(),
            child: const TournamentListScreen(),
          ),
        );

      case AppRoutePath.tournamentDetailScreen:
        final tournament = settings.arguments as TournamentModel?;
        if (tournament != null) {
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: context.read<TournamentCubit>(),
              child: TournamentDetailScreen(tournament: tournament),
            ),
          );
        }
        break;

      case AppRoutePath.addTournamentScreen:
        return MaterialPageRoute(
          builder: (_) => const CreateTournamentScreen(),
        );

      // Legacy routes removed - replaced with new team/tournament modules

      case AppRoutePath.playerComparisonScreen:
        // Note: This route expects a List<Team> as argument
        // It's typically navigated to programmatically from the analytics dashboard
        break;

      case AppRoutePath.myStudentsScreen:
        return MaterialPageRoute(builder: (_) => const MyStudentsScreen());

      case AppRoutePath.scheduleScreen:
        return MaterialPageRoute(builder: (_) => const ScheduleScreen());

      case AppRoutePath.eventDetailsScreen:
        final eventId = settings.arguments as String?;
        if (eventId != null) {
          return MaterialPageRoute(
            builder: (_) => EventDetailsScreen(eventId: eventId),
          );
        }
        break;

      case AppRoutePath.bookCoachScreen:
        final coachId = settings.arguments as String?;
        if (coachId != null) {
          return MaterialPageRoute(
            builder: (_) => BookCoachScreen(coachId: coachId),
          );
        }
        break;

      case AppRoutePath.matchProfileDetailScreen:
        final profile = settings.arguments as MatchProfile?;
        if (profile != null) {
          return MaterialPageRoute(
            builder: (_) => MatchProfileDetailScreen(profile: profile),
          );
        }
        break;
    }
    return null;
  }
}
