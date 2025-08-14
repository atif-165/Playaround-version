import 'package:flutter/material.dart';

import '../screens/create_password/ui/create_password.dart';
import '../screens/email_verification/ui/email_verification_screen.dart';
import '../screens/forget/ui/forget_screen.dart';
import '../screens/home/ui/home_screen.dart';
import '../screens/login/ui/login_screen.dart';
import '../screens/main_navigation/main_navigation_screen.dart';
import '../screens/onboarding/ui/role_selection_screen.dart';
import '../screens/onboarding/ui/player_onboarding_screen.dart';
import '../screens/onboarding/ui/coach_onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/signup/ui/sign_up_screen.dart';
import '../modules/skill_tracking/skill_tracking_module.dart';
import '../modules/team/screens/team_creation_screen.dart';
import '../modules/team/screens/team_profile_screen.dart';
import '../modules/team/models/models.dart';
import '../screens/match_requests/match_requests_screen.dart';
import '../modules/venue/screens/add_venue_screen.dart';
import '../modules/chat/screens/chat_list_screen.dart';
import '../modules/chat/screens/chat_screen.dart';
import '../modules/chat/screens/user_search_screen.dart';
import '../modules/chat/models/chat_room.dart';
import '../modules/booking/screens/my_booking_history_screen.dart';
import '../modules/booking/screens/coach_earnings_screen.dart';
import '../modules/booking/screens/booking_detail_screen.dart';
import '../modules/coach_analytics/screens/coach_analytics_dashboard_screen.dart';
import '../models/booking_model.dart';
import 'routes.dart';
// Shop
import '../modules/shop/screens/shop_home_screen.dart';
// Quick Action Screens
import '../screens/venue_booking/venue_booking_screen.dart';
import '../screens/team_finder/team_finder_screen.dart';
import '../screens/create_session/create_session_screen.dart';
import '../screens/analytics/analytics_screen.dart';
// People Search Screens
import '../screens/people_search/people_search_screen.dart';

class AppRouter {
  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.forgetScreen:
        return MaterialPageRoute(
          builder: (_) => const ForgetScreen(),
        );

      case Routes.homeScreen:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case Routes.dashboardScreen:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );

      case Routes.createPassword:
        final arguments = settings.arguments;
        if (arguments is List) {
          return MaterialPageRoute(
            builder: (_) => CreatePassword(
              googleUser: arguments[0],
              credential: arguments[1],
            ),
          );
        }
        break;

      case Routes.signupScreen:
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
        );

      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case Routes.emailVerificationScreen:
        return MaterialPageRoute(
          builder: (_) => const EmailVerificationScreen(),
        );

      case Routes.roleSelectionScreen:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        );

      case Routes.playerOnboardingScreen:
        return MaterialPageRoute(
          builder: (_) => const PlayerOnboardingScreen(),
        );

      case Routes.coachOnboardingScreen:
        return MaterialPageRoute(
          builder: (_) => const CoachOnboardingScreen(),
        );

      case Routes.profileScreen:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case Routes.matchRequestsScreen:
        return MaterialPageRoute(
          builder: (_) => const MatchRequestsScreen(),
        );

      case Routes.chatListScreen:
        return MaterialPageRoute(
          builder: (_) => const ChatListScreen(),
        );

      case Routes.userSearchScreen:
        return MaterialPageRoute(
          builder: (_) => const UserSearchScreen(),
        );

      case Routes.chatScreen:
        final chatRoom = settings.arguments;
        if (chatRoom != null && chatRoom is ChatRoom) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(chatRoom: chatRoom),
          );
        }
        break;

      // Skill Tracking Routes
      case Routes.skillDashboardScreen:
        final playerId = settings.arguments as String?;
        if (playerId != null) {
          return MaterialPageRoute(
            builder: (_) => SkillDashboardScreen(playerId: playerId),
          );
        }
        break;

      case Routes.addGoalScreen:
        final arguments = settings.arguments as Map<String, dynamic>?;
        if (arguments != null) {
          return MaterialPageRoute(
            builder: (_) => AddGoalScreen(
              playerId: arguments['playerId'] as String,
              currentSkillScores: arguments['currentSkillScores'] as Map<SkillType, int>,
            ),
          );
        }
        break;

      case Routes.coachLoggingScreen:
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

      case Routes.analyticsDashboardScreen:
        final playerId = settings.arguments as String?;
        if (playerId != null) {
          return MaterialPageRoute(
            builder: (_) => AnalyticsDashboardScreen(playerId: playerId),
          );
        }
        break;

      case Routes.myBookingHistoryScreen:
        return MaterialPageRoute(
          builder: (_) => const MyBookingHistoryScreen(),
        );

      case Routes.coachEarningsScreen:
        return MaterialPageRoute(
          builder: (_) => const CoachEarningsScreen(),
        );

      case Routes.bookingDetailScreen:
        final booking = settings.arguments as BookingModel?;
        if (booking != null) {
          return MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          );
        }
        break;

      case Routes.coachAnalyticsDashboardScreen:
        return MaterialPageRoute(
          builder: (_) => const CoachAnalyticsDashboardScreen(),
        );

      // Venue routes
      case Routes.addVenueScreen:
        return MaterialPageRoute(builder: (_) => const AddVenueScreen());

      // Shop routes
      case Routes.shopHome:
        return MaterialPageRoute(builder: (_) => const ShopHomeScreen());

      // Quick Action routes
      case Routes.venueBookingScreen:
        return MaterialPageRoute(builder: (_) => const VenueBookingScreen());

      case Routes.teamFinderScreen:
        return MaterialPageRoute(builder: (_) => const TeamFinderScreen());

      case Routes.createSessionScreen:
        return MaterialPageRoute(builder: (_) => const CreateSessionScreen());

      case Routes.analyticsScreen:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());

      // Team Management routes
      case Routes.createTeamScreen:
      case '/create-team':
        return MaterialPageRoute(builder: (_) => const TeamCreationScreen());

      case Routes.teamProfileScreen:
        final team = settings.arguments as Team?;
        if (team != null) {
          return MaterialPageRoute(
            builder: (_) => TeamProfileScreen(
              team: team,
              showJoinButton: true,
            ),
          );
        }
        break;

      // People Search routes
      case Routes.peopleSearchScreen:
        return MaterialPageRoute(builder: (_) => const PeopleSearchScreen());

      // TODO: Implement shop routes when shop module is ready

      case Routes.teamPerformanceScreen:
        // Note: This route expects a Team object as argument
        // It's typically navigated to programmatically from the analytics dashboard
        break;

      case Routes.playerComparisonScreen:
        // Note: This route expects a List<Team> as argument
        // It's typically navigated to programmatically from the analytics dashboard
        break;
    }
    return null;
  }
}
