part of 'dashboard_cubit.dart';

/// Base state for dashboard
abstract class DashboardState {}

/// Initial state when dashboard is first created
class DashboardInitial extends DashboardState {}

/// Loading state while fetching dashboard data
class DashboardLoading extends DashboardState {}

/// Loaded state with all dashboard data
class DashboardLoaded extends DashboardState {
  final UserProfile userProfile;
  final DashboardStats stats;
  final List<DashboardEvent> nearbyEvents;
  final List<FeaturedCoach> featuredCoaches;
  final List<MatchmakingSuggestion> matchmakingSuggestions;
  final List<ShopProduct> recommendedProducts;

  DashboardLoaded({
    required this.userProfile,
    required this.stats,
    required this.nearbyEvents,
    required this.featuredCoaches,
    required this.matchmakingSuggestions,
    required this.recommendedProducts,
  });

  /// Create a copy of this state with updated values
  DashboardLoaded copyWith({
    UserProfile? userProfile,
    DashboardStats? stats,
    List<DashboardEvent>? nearbyEvents,
    List<FeaturedCoach>? featuredCoaches,
    List<MatchmakingSuggestion>? matchmakingSuggestions,
    List<ShopProduct>? recommendedProducts,
  }) {
    return DashboardLoaded(
      userProfile: userProfile ?? this.userProfile,
      stats: stats ?? this.stats,
      nearbyEvents: nearbyEvents ?? this.nearbyEvents,
      featuredCoaches: featuredCoaches ?? this.featuredCoaches,
      matchmakingSuggestions: matchmakingSuggestions ?? this.matchmakingSuggestions,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
    );
  }

  /// Check if user is a player
  bool get isPlayer => userProfile.role == UserRole.player;

  /// Check if user is a coach
  bool get isCoach => userProfile.role == UserRole.coach;

  /// Get user's sports of interest
  List<String> get sportsOfInterest {
    if (userProfile is PlayerProfile) {
      return (userProfile as PlayerProfile).sportsOfInterest;
    } else if (userProfile is CoachProfile) {
      return (userProfile as CoachProfile).specializationSports;
    }
    return [];
  }

  /// Get upcoming events (next 7 days)
  List<DashboardEvent> get upcomingEvents {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      return nearbyEvents
          .where((event) =>
              event.dateTime.isAfter(now) &&
              event.dateTime.isBefore(nextWeek))
          .take(3)
          .toList();
    } catch (e) {
      // Return empty list if there's any error
      return <DashboardEvent>[];
    }
  }

  /// Get top-rated coaches
  List<FeaturedCoach> get topRatedCoaches {
    final sortedCoaches = [...featuredCoaches];
    sortedCoaches.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedCoaches.take(3).toList();
  }

  /// Get high compatibility matches
  List<MatchmakingSuggestion> get highCompatibilityMatches {
    return matchmakingSuggestions
        .where((suggestion) => suggestion.compatibilityScore > 0.5)
        .take(5)
        .toList();
  }

  /// Get on-sale products
  List<ShopProduct> get onSaleProducts {
    return recommendedProducts
        .where((product) => product.isOnSale)
        .toList();
  }
}

/// Error state when dashboard data loading fails
class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
