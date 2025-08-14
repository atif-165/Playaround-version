import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:playaround/logic/cubit/dashboard_cubit.dart';
import 'package:playaround/services/dashboard_service.dart';
import 'package:playaround/models/user_profile.dart';
import 'package:playaround/models/player_profile.dart';
import 'package:playaround/models/dashboard_models.dart';

import 'dashboard_cubit_test.mocks.dart';

@GenerateMocks([DashboardService])
void main() {
  group('DashboardCubit', () {
    late DashboardCubit dashboardCubit;
    late MockDashboardService mockDashboardService;
    late PlayerProfile testPlayerProfile;

    setUp(() {
      mockDashboardService = MockDashboardService();
      dashboardCubit = DashboardCubit(dashboardService: mockDashboardService);
      
      testPlayerProfile = PlayerProfile(
        uid: 'test-uid',
        fullName: 'Test Player',
        gender: Gender.male,
        age: 25,
        location: 'Test City',
        isProfileComplete: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sportsOfInterest: ['Basketball', 'Tennis'],
        skillLevel: SkillLevel.intermediate,
        availability: [],
        preferredTrainingType: TrainingType.inPerson,
      );
    });

    tearDown(() {
      dashboardCubit.close();
    });

    test('initial state is DashboardInitial', () {
      expect(dashboardCubit.state, isA<DashboardInitial>());
    });

    group('loadDashboardData', () {
      blocTest<DashboardCubit, DashboardState>(
        'emits [DashboardLoading, DashboardLoaded] when data loads successfully',
        build: () {
          // Mock successful service responses
          when(mockDashboardService.getUserStats())
              .thenAnswer((_) async => DashboardStats.empty());
          when(mockDashboardService.getNearbyEvents(
            location: any,
            limit: any,
          )).thenAnswer((_) async => <DashboardEvent>[]);
          when(mockDashboardService.getFeaturedCoaches(
            sportsOfInterest: any,
            location: any,
            limit: any,
          )).thenAnswer((_) async => <FeaturedCoach>[]);
          when(mockDashboardService.getMatchmakingSuggestions(
            limit: any,
          )).thenAnswer((_) async => <MatchmakingSuggestion>[]);
          when(mockDashboardService.getRecommendedProducts(
            sportsOfInterest: any,
            limit: any,
          )).thenAnswer((_) async => <ShopProduct>[]);

          return dashboardCubit;
        },
        act: (cubit) => cubit.loadDashboardData(testPlayerProfile),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>(),
        ],
      );

      blocTest<DashboardCubit, DashboardState>(
        'emits [DashboardLoading, DashboardError] when data loading fails',
        build: () {
          // Mock service failure
          when(mockDashboardService.getUserStats())
              .thenThrow(Exception('Network error'));

          return dashboardCubit;
        },
        act: (cubit) => cubit.loadDashboardData(testPlayerProfile),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardError>(),
        ],
      );
    });

    group('refreshDashboard', () {
      blocTest<DashboardCubit, DashboardState>(
        'refreshes dashboard when in loaded state',
        build: () {
          // Setup initial loaded state
          when(mockDashboardService.getUserStats())
              .thenAnswer((_) async => DashboardStats.empty());
          when(mockDashboardService.getNearbyEvents(
            location: any,
            limit: any,
          )).thenAnswer((_) async => <DashboardEvent>[]);
          when(mockDashboardService.getFeaturedCoaches(
            sportsOfInterest: any,
            location: any,
            limit: any,
          )).thenAnswer((_) async => <FeaturedCoach>[]);
          when(mockDashboardService.getMatchmakingSuggestions(
            limit: any,
          )).thenAnswer((_) async => <MatchmakingSuggestion>[]);
          when(mockDashboardService.getRecommendedProducts(
            sportsOfInterest: any,
            limit: any,
          )).thenAnswer((_) async => <ShopProduct>[]);

          return dashboardCubit;
        },
        seed: () => DashboardLoaded(
          userProfile: testPlayerProfile,
          stats: DashboardStats.empty(),
          nearbyEvents: [],
          featuredCoaches: [],
          matchmakingSuggestions: [],
          recommendedProducts: [],
        ),
        act: (cubit) => cubit.refreshDashboard(),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>(),
        ],
      );
    });

    group('toggleEventBookmark', () {
      final testEvent = DashboardEvent(
        id: 'event-1',
        title: 'Test Event',
        description: 'Test Description',
        imageUrl: 'test-url',
        dateTime: DateTime.now(),
        location: 'Test Location',
        eventType: 'tournament',
        maxParticipants: 10,
        currentParticipants: 5,
        sportsInvolved: ['Basketball'],
        organizerId: 'organizer-1',
        organizerName: 'Test Organizer',
        isBookmarked: false,
      );

      blocTest<DashboardCubit, DashboardState>(
        'toggles event bookmark status',
        build: () => dashboardCubit,
        seed: () => DashboardLoaded(
          userProfile: testPlayerProfile,
          stats: DashboardStats.empty(),
          nearbyEvents: [testEvent],
          featuredCoaches: [],
          matchmakingSuggestions: [],
          recommendedProducts: [],
        ),
        act: (cubit) => cubit.toggleEventBookmark('event-1'),
        expect: () => [
          isA<DashboardLoaded>().having(
            (state) => state.nearbyEvents.first.isBookmarked,
            'first event bookmark status',
            true,
          ),
        ],
      );
    });

    group('updateStats', () {
      blocTest<DashboardCubit, DashboardState>(
        'updates user statistics and refreshes state',
        build: () {
          when(mockDashboardService.updateUserStats(
            sessionsIncrement: any,
            hoursIncrement: any,
            skillPointsIncrement: any,
          )).thenAnswer((_) async {});
          when(mockDashboardService.getUserStats())
              .thenAnswer((_) async => const DashboardStats(
                sessionsThisMonth: 1,
                hoursTrained: 2,
                skillPoints: 50,
                matchesPlayed: 0,
                teamsJoined: 0,
                tournamentsParticipated: 0,
                averageRating: 0.0,
                totalBookings: 0,
              ));

          return dashboardCubit;
        },
        seed: () => DashboardLoaded(
          userProfile: testPlayerProfile,
          stats: DashboardStats.empty(),
          nearbyEvents: [],
          featuredCoaches: [],
          matchmakingSuggestions: [],
          recommendedProducts: [],
        ),
        act: (cubit) => cubit.updateStats(
          sessionsIncrement: 1,
          hoursIncrement: 2,
          skillPointsIncrement: 50,
        ),
        expect: () => [
          isA<DashboardLoaded>().having(
            (state) => state.stats.sessionsThisMonth,
            'sessions count',
            1,
          ),
        ],
      );
    });
  });
}

// Helper method to create test data
DashboardEvent createTestEvent({
  String id = 'test-event',
  bool isBookmarked = false,
}) {
  return DashboardEvent(
    id: id,
    title: 'Test Event',
    description: 'Test Description',
    imageUrl: 'test-url',
    dateTime: DateTime.now().add(const Duration(days: 1)),
    location: 'Test Location',
    eventType: 'tournament',
    maxParticipants: 10,
    currentParticipants: 5,
    sportsInvolved: ['Basketball'],
    organizerId: 'organizer-1',
    organizerName: 'Test Organizer',
    isBookmarked: isBookmarked,
  );
}

FeaturedCoach createTestCoach({
  String id = 'test-coach',
  bool isAvailable = true,
}) {
  return FeaturedCoach(
    id: id,
    fullName: 'Test Coach',
    profilePictureUrl: 'test-url',
    specializations: ['Basketball', 'Tennis'],
    rating: 4.5,
    reviewCount: 10,
    hourlyRate: 50.0,
    bio: 'Test bio',
    location: 'Test City',
    experienceYears: 5,
    isAvailable: isAvailable,
    certifications: ['Certified Coach'],
  );
}
