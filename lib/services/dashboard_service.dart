import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_models.dart';
import '../models/user_profile.dart';
import '../modules/shop/models/product.dart';

/// Service for managing dashboard data and operations
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's dashboard statistics
  Future<DashboardStats> getUserStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection('user_stats').doc(user.uid).get();

      if (doc.exists) {
        return DashboardStats.fromFirestore(doc);
      } else {
        // Create empty stats for new users
        final emptyStats = DashboardStats.empty();
        await _firestore
            .collection('user_stats')
            .doc(user.uid)
            .set(emptyStats.toFirestore());
        return emptyStats;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user stats: $e');
      }
      return DashboardStats.empty();
    }
  }

  /// Get nearby events for discovery
  Future<List<DashboardEvent>> getNearbyEvents({
    String? location,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: DateTime.now())
          .orderBy('dateTime')
          .limit(limit);

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      final snapshot = await query.get();

      // Filter out any documents that fail to parse
      final events = <DashboardEvent>[];
      for (final doc in snapshot.docs) {
        try {
          final event = DashboardEvent.fromFirestore(doc);
          events.add(event);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing event ${doc.id}: $e');
          }
          // Skip this event and continue with others
        }
      }

      return events;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching nearby events: $e');
      }
      return [];
    }
  }

  /// Get featured coaches based on user preferences
  Future<List<FeaturedCoach>> getFeaturedCoaches({
    List<String>? sportsOfInterest,
    String? location,
    int limit = 5,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .where('isProfileComplete', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .orderBy('averageRating', descending: true)
          .limit(limit);

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      final snapshot = await query.get();
      List<FeaturedCoach> coaches =
          snapshot.docs.map((doc) => FeaturedCoach.fromFirestore(doc)).toList();

      // Filter by sports of interest if provided
      if (sportsOfInterest != null && sportsOfInterest.isNotEmpty) {
        coaches = coaches.where((coach) {
          return coach.specializations
              .any((sport) => sportsOfInterest.contains(sport));
        }).toList();
      }

      return coaches;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching featured coaches: $e');
      }
      return [];
    }
  }

  /// Get matchmaking suggestions for the current user
  Future<List<MatchmakingSuggestion>> getMatchmakingSuggestions({
    int limit = 10,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user profile to determine preferences
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final userSports = List<String>.from(userData['sportsOfInterest'] ?? []);
      final userLocation = userData['location'] as String?;

      // Find users with similar interests
      Query query = _firestore
          .collection('users')
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit * 2); // Get more to filter out current user

      if (userSports.isNotEmpty) {
        query = query.where('sportsOfInterest', arrayContainsAny: userSports);
      }

      final snapshot = await query.get();
      List<MatchmakingSuggestion> suggestions = [];

      for (final doc in snapshot.docs) {
        if (doc.id == user.uid) continue; // Skip current user

        final data = doc.data() as Map<String, dynamic>;
        final otherSports = List<String>.from(data['sportsOfInterest'] ?? []);

        // Calculate compatibility score based on common interests
        final commonInterests =
            userSports.where((sport) => otherSports.contains(sport)).toList();

        final compatibilityScore = commonInterests.length /
            (userSports.length + otherSports.length - commonInterests.length);

        // Calculate distance (simplified - in real app would use geolocation)
        final distance = _calculateDistance(userLocation, data['location']);

        final suggestion = MatchmakingSuggestion(
          id: doc.id,
          fullName: data['fullName'] ?? '',
          profilePictureUrl: data['profilePictureUrl'] ?? '',
          role: UserRole.values.firstWhere(
            (role) => role.toString().split('.').last == data['role'],
            orElse: () => UserRole.player,
          ),
          sportsOfInterest: otherSports,
          location: data['location'] ?? '',
          age: data['age'] ?? 0,
          skillLevel: data['skillLevel'] != null
              ? SkillLevel.values.firstWhere(
                  (level) =>
                      level.toString().split('.').last == data['skillLevel'],
                  orElse: () => SkillLevel.beginner,
                )
              : null,
          bio: data['bio'] ?? '',
          compatibilityScore: compatibilityScore,
          commonInterests: commonInterests,
          distance: distance,
        );

        suggestions.add(suggestion);
      }

      // Sort by compatibility score and distance
      suggestions.sort((a, b) {
        final scoreComparison =
            b.compatibilityScore.compareTo(a.compatibilityScore);
        if (scoreComparison != 0) return scoreComparison;
        return a.distance.compareTo(b.distance);
      });

      return suggestions.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching matchmaking suggestions: $e');
      }
      return [];
    }
  }

  /// Get recommended shop products
  Future<List<ShopProduct>> getRecommendedProducts({
    List<String>? sportsOfInterest,
    int limit = 4,
  }) async {
    try {
      Query query = _firestore
          .collection('shop_products')
          .where('isRecommended', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      List<ShopProduct> products = snapshot.docs
          .map((doc) => ShopProduct.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      // Filter by sports of interest if provided
      if (sportsOfInterest != null && sportsOfInterest.isNotEmpty) {
        products = products.where((product) {
          return product.tags.any((tag) => sportsOfInterest.contains(tag));
        }).toList();
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching recommended products: $e');
      }
      return [];
    }
  }

  /// Update user statistics (called after activities)
  Future<void> updateUserStats({
    int? sessionsIncrement,
    int? hoursIncrement,
    int? skillPointsIncrement,
    int? matchesIncrement,
    int? teamsIncrement,
    int? tournamentsIncrement,
    int? bookingsIncrement,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = _firestore.collection('user_stats').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final updates = <String, dynamic>{};

          if (sessionsIncrement != null) {
            updates['sessionsThisMonth'] =
                (data['sessionsThisMonth'] ?? 0) + sessionsIncrement;
          }
          if (hoursIncrement != null) {
            updates['hoursTrained'] =
                (data['hoursTrained'] ?? 0) + hoursIncrement;
          }
          if (skillPointsIncrement != null) {
            updates['skillPoints'] =
                (data['skillPoints'] ?? 0) + skillPointsIncrement;
          }
          if (matchesIncrement != null) {
            updates['matchesPlayed'] =
                (data['matchesPlayed'] ?? 0) + matchesIncrement;
          }
          if (teamsIncrement != null) {
            updates['teamsJoined'] =
                (data['teamsJoined'] ?? 0) + teamsIncrement;
          }
          if (tournamentsIncrement != null) {
            updates['tournamentsParticipated'] =
                (data['tournamentsParticipated'] ?? 0) + tournamentsIncrement;
          }
          if (bookingsIncrement != null) {
            updates['totalBookings'] =
                (data['totalBookings'] ?? 0) + bookingsIncrement;
          }

          if (updates.isNotEmpty) {
            transaction.update(docRef, updates);
          }
        } else {
          // Create new stats document
          final newStats = DashboardStats(
            sessionsThisMonth: sessionsIncrement ?? 0,
            hoursTrained: hoursIncrement ?? 0,
            skillPoints: skillPointsIncrement ?? 0,
            matchesPlayed: matchesIncrement ?? 0,
            teamsJoined: teamsIncrement ?? 0,
            tournamentsParticipated: tournamentsIncrement ?? 0,
            averageRating: 0.0,
            totalBookings: bookingsIncrement ?? 0,
          );
          transaction.set(docRef, newStats.toFirestore());
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating user stats: $e');
      }
    }
  }

  /// Simple distance calculation (placeholder - would use proper geolocation in production)
  double _calculateDistance(String? location1, String? location2) {
    if (location1 == null || location2 == null) return 999.0;
    if (location1 == location2) return 0.0;
    // Simplified distance calculation - in real app would use proper geolocation
    return (location1.hashCode - location2.hashCode).abs() % 50 + 1.0;
  }
}
