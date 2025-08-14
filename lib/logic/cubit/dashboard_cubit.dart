import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/dashboard_models.dart';
import '../../models/user_profile.dart';
import '../../models/player_profile.dart';
import '../../models/coach_profile.dart';
import '../../services/dashboard_service.dart';

part 'dashboard_state.dart';

/// Cubit for managing dashboard state and data
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardService _dashboardService;

  DashboardCubit({DashboardService? dashboardService})
      : _dashboardService = dashboardService ?? DashboardService(),
        super(DashboardInitial());

  /// Load all dashboard data for the given user profile
  Future<void> loadDashboardData(UserProfile userProfile) async {
    emit(DashboardLoading());

    try {
      // Load all dashboard data concurrently
      final futures = await Future.wait([
        _dashboardService.getUserStats(),
        _dashboardService.getNearbyEvents(
          location: userProfile.location,
          limit: 10,
        ),
        _dashboardService.getFeaturedCoaches(
          sportsOfInterest: _getSportsOfInterest(userProfile),
          location: userProfile.location,
          limit: 5,
        ),
        _dashboardService.getMatchmakingSuggestions(limit: 10),
        _dashboardService.getRecommendedProducts(
          sportsOfInterest: _getSportsOfInterest(userProfile),
          limit: 4,
        ),
      ]);

      final stats = futures[0] as DashboardStats? ?? DashboardStats.empty();
      final events = futures[1] as List<DashboardEvent>? ?? <DashboardEvent>[];
      final coaches = futures[2] as List<FeaturedCoach>? ?? <FeaturedCoach>[];
      final suggestions = futures[3] as List<MatchmakingSuggestion>? ?? <MatchmakingSuggestion>[];
      final products = futures[4] as List<ShopProduct>? ?? <ShopProduct>[];

      emit(DashboardLoaded(
        userProfile: userProfile,
        stats: stats,
        nearbyEvents: events,
        featuredCoaches: coaches,
        matchmakingSuggestions: suggestions,
        recommendedProducts: products,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading dashboard data: $e');
      }
      emit(DashboardError('Failed to load dashboard data: ${e.toString()}'));
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      await loadDashboardData(currentState.userProfile);
    }
  }

  /// Load more events (for pagination)
  Future<void> loadMoreEvents() async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    try {
      final moreEvents = await _dashboardService.getNearbyEvents(
        location: currentState.userProfile.location,
        limit: 5,
      );

      final updatedEvents = [...currentState.nearbyEvents, ...moreEvents];
      
      emit(currentState.copyWith(nearbyEvents: updatedEvents));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading more events: $e');
      }
    }
  }

  /// Load more coaches (for pagination)
  Future<void> loadMoreCoaches() async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    try {
      final moreCoaches = await _dashboardService.getFeaturedCoaches(
        sportsOfInterest: _getSportsOfInterest(currentState.userProfile),
        location: currentState.userProfile.location,
        limit: 3,
      );

      final updatedCoaches = [...currentState.featuredCoaches, ...moreCoaches];
      
      emit(currentState.copyWith(featuredCoaches: updatedCoaches));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading more coaches: $e');
      }
    }
  }

  /// Update user statistics after an activity
  Future<void> updateStats({
    int? sessionsIncrement,
    int? hoursIncrement,
    int? skillPointsIncrement,
    int? matchesIncrement,
    int? teamsIncrement,
    int? tournamentsIncrement,
    int? bookingsIncrement,
  }) async {
    try {
      await _dashboardService.updateUserStats(
        sessionsIncrement: sessionsIncrement,
        hoursIncrement: hoursIncrement,
        skillPointsIncrement: skillPointsIncrement,
        matchesIncrement: matchesIncrement,
        teamsIncrement: teamsIncrement,
        tournamentsIncrement: tournamentsIncrement,
        bookingsIncrement: bookingsIncrement,
      );

      // Refresh stats in the current state
      final currentState = state;
      if (currentState is DashboardLoaded) {
        final updatedStats = await _dashboardService.getUserStats();
        emit(currentState.copyWith(stats: updatedStats));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating stats: $e');
      }
    }
  }

  /// Toggle event bookmark status
  void toggleEventBookmark(String eventId) {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    final updatedEvents = currentState.nearbyEvents.map((event) {
      if (event.id == eventId) {
        return DashboardEvent(
          id: event.id,
          title: event.title,
          description: event.description,
          imageUrl: event.imageUrl,
          dateTime: event.dateTime,
          location: event.location,
          eventType: event.eventType,
          price: event.price,
          maxParticipants: event.maxParticipants,
          currentParticipants: event.currentParticipants,
          sportsInvolved: event.sportsInvolved,
          organizerId: event.organizerId,
          organizerName: event.organizerName,
          isBookmarked: !event.isBookmarked,
        );
      }
      return event;
    }).toList();

    emit(currentState.copyWith(nearbyEvents: updatedEvents));
  }

  /// Get sports of interest from user profile
  List<String> _getSportsOfInterest(UserProfile userProfile) {
    if (userProfile is PlayerProfile) {
      return userProfile.sportsOfInterest;
    } else if (userProfile is CoachProfile) {
      return userProfile.specializationSports;
    }
    return [];
  }
}
