class Routes {
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
  static const String addGoalScreen = '/add-goal';
  static const String coachLoggingScreen = '/coach-logging';
  static const String analyticsDashboardScreen = '/analytics-dashboard';
  static const String myBookingHistoryScreen = '/my-booking-history';
  static const String coachEarningsScreen = '/coach-earnings';
  static const String bookingDetailScreen = '/booking-detail';
  static const String playerMatchmakingScreen = '/player-matchmaking';
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
  static const String createTeamScreen = '/add-team'; // Alias for addTeamScreen
  static const String teamManagementScreen = '/team-management';
  static const String addTeamMemberScreen = '/add-team-member';

  // Tournament routes
  static const String tournamentListScreen = '/tournament-list';
  static const String tournamentDetailScreen = '/tournament-detail';
  static const String addTournamentScreen = '/add-tournament';
  static const String createTournamentScreen =
      '/add-tournament'; // Alias for addTournamentScreen
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
