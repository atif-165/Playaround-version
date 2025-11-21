import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/models.dart';
import '../repositories/skill_repository.dart';
import 'skill_tracking_service.dart';

/// Service for automated skill updates based on user activities
class AutomatedSkillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SkillRepository _skillRepository = SkillRepository();
  final SkillTrackingService _skillService = SkillTrackingService();

  // Collection names
  static const String _bookingsCollection = 'bookings';
  static const String _venueBookingsCollection = 'venue_bookings';
  static const String _usersCollection = 'users';

  /// Update skills when a booking is completed
  Future<void> onBookingCompleted({
    required String bookingId,
    required String userId,
    required SportType sportType,
    required double sessionDurationHours,
    required String sessionTitle,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🎯 AutomatedSkillService: Processing booking completion for user $userId');
      }

      // Get recent sessions count for frequency bonus
      final recentSessionsCount = await _getRecentSessionsCount(userId);

      // Calculate skill updates
      final updateResult = SkillUpdateRules.calculateBookingUpdate(
        sportType: sportType,
        sessionDurationHours: sessionDurationHours,
        recentSessionsCount: recentSessionsCount,
        context:
            'Completed session: $sessionTitle (${sessionDurationHours.toStringAsFixed(1)}h)',
        metadata: {
          'bookingId': bookingId,
          'sportType': sportType.displayName,
          'sessionDuration': sessionDurationHours,
          'recentSessionsCount': recentSessionsCount,
          ...?additionalMetadata,
        },
      );

      if (updateResult.hasChanges) {
        await _applySkillUpdate(userId, updateResult);
        await _updateUserLastActive(userId);

        if (kDebugMode) {
          debugPrint(
              '✅ AutomatedSkillService: Applied booking skill updates for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ AutomatedSkillService: Error processing booking completion: $e');
      }
      // Don't throw - skill updates shouldn't break the booking flow
    }
  }

  /// Update skills when a venue booking is completed
  Future<void> onVenueBookingCompleted({
    required String bookingId,
    required String userId,
    required SportType sportType,
    required double sessionDurationHours,
    required String venueTitle,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🎯 AutomatedSkillService: Processing venue booking completion for user $userId');
      }

      // Get recent sessions count for frequency bonus
      final recentSessionsCount = await _getRecentSessionsCount(userId);

      // Calculate skill updates
      final updateResult = SkillUpdateRules.calculateBookingUpdate(
        sportType: sportType,
        sessionDurationHours: sessionDurationHours,
        recentSessionsCount: recentSessionsCount,
        context:
            'Completed venue session: $venueTitle (${sessionDurationHours.toStringAsFixed(1)}h)',
        metadata: {
          'venueBookingId': bookingId,
          'sportType': sportType.displayName,
          'sessionDuration': sessionDurationHours,
          'recentSessionsCount': recentSessionsCount,
          'venueTitle': venueTitle,
          ...?additionalMetadata,
        },
      );

      if (updateResult.hasChanges) {
        await _applySkillUpdate(userId, updateResult);
        await _updateUserLastActive(userId);

        if (kDebugMode) {
          debugPrint(
              '✅ AutomatedSkillService: Applied venue booking skill updates for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ AutomatedSkillService: Error processing venue booking completion: $e');
      }
      // Don't throw - skill updates shouldn't break the booking flow
    }
  }

  /// Update skills when a tournament is completed
  Future<void> onTournamentCompleted({
    required String tournamentId,
    required String userId,
    required SportType sportType,
    required bool isTeamTournament,
    required bool didWin,
    required String tournamentName,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🎯 AutomatedSkillService: Processing tournament completion for user $userId');
      }

      // Calculate skill updates
      final updateResult = SkillUpdateRules.calculateTournamentUpdate(
        sportType: sportType,
        isTeamTournament: isTeamTournament,
        didWin: didWin,
        context:
            'Tournament ${didWin ? 'victory' : 'participation'}: $tournamentName',
        metadata: {
          'tournamentId': tournamentId,
          'sportType': sportType.displayName,
          'isTeamTournament': isTeamTournament,
          'didWin': didWin,
          'tournamentName': tournamentName,
          ...?additionalMetadata,
        },
      );

      if (updateResult.hasChanges) {
        await _applySkillUpdate(userId, updateResult);
        await _updateUserLastActive(userId);

        if (kDebugMode) {
          debugPrint(
              '✅ AutomatedSkillService: Applied tournament skill updates for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ AutomatedSkillService: Error processing tournament completion: $e');
      }
      // Don't throw - skill updates shouldn't break the tournament flow
    }
  }

  /// Update skills based on feedback/rating
  Future<void> onFeedbackReceived({
    required String userId,
    required double rating,
    required String context,
    Map<SkillType, int>? specificSkillFeedback,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🎯 AutomatedSkillService: Processing feedback for user $userId');
      }

      // Calculate skill updates
      final updateResult = SkillUpdateRules.calculateFeedbackUpdate(
        rating: rating,
        specificSkillFeedback: specificSkillFeedback,
        context: context,
        metadata: {
          'rating': rating,
          'hasSpecificFeedback': specificSkillFeedback != null,
          ...?additionalMetadata,
        },
      );

      if (updateResult.hasChanges) {
        await _applySkillUpdate(userId, updateResult);
        await _updateUserLastActive(userId);

        if (kDebugMode) {
          debugPrint(
              '✅ AutomatedSkillService: Applied feedback skill updates for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AutomatedSkillService: Error processing feedback: $e');
      }
      // Don't throw - skill updates shouldn't break the feedback flow
    }
  }

  /// Apply inactivity decay to user's skills
  Future<void> applyInactivityDecay(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🎯 AutomatedSkillService: Checking inactivity decay for user $userId');
      }

      final daysSinceLastActivity = await _getDaysSinceLastActivity(userId);
      if (daysSinceLastActivity < SkillUpdateConfig.inactivityThresholdDays) {
        return; // No decay needed
      }

      // Get current skill scores
      final currentSkills = await _getCurrentSkillScores(userId);

      // Calculate decay
      final updateResult = SkillUpdateRules.calculateInactivityDecay(
        daysSinceLastActivity: daysSinceLastActivity,
        currentSkills: currentSkills,
        context: 'Skill decay due to $daysSinceLastActivity days of inactivity',
      );

      if (updateResult.hasChanges) {
        await _applySkillUpdate(userId, updateResult);

        if (kDebugMode) {
          debugPrint(
              '✅ AutomatedSkillService: Applied inactivity decay for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ AutomatedSkillService: Error applying inactivity decay: $e');
      }
    }
  }

  /// Get count of recent sessions (last 7 days) for frequency bonus
  Future<int> _getRecentSessionsCount(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Count regular bookings
      final bookingsQuery = await _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: BookingStatus.completed.value)
          .where('completedAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      // Count venue bookings
      final venueBookingsQuery = await _firestore
          .collection(_venueBookingsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: VenueBookingStatus.completed.value)
          .where('completedAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      return bookingsQuery.docs.length + venueBookingsQuery.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting recent sessions count: $e');
      }
      return 0;
    }
  }

  /// Get days since last activity
  Future<int> _getDaysSinceLastActivity(String userId) async {
    try {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      final userData = userDoc.data();

      if (userData != null && userData['lastActive'] != null) {
        final lastActive = (userData['lastActive'] as Timestamp).toDate();
        return DateTime.now().difference(lastActive).inDays;
      }

      // If no lastActive field, check recent bookings
      final recentBooking = await _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (recentBooking.docs.isNotEmpty) {
        final lastBooking = recentBooking.docs.first.data();
        final completedAt =
            (lastBooking['completedAt'] as Timestamp?)?.toDate();
        if (completedAt != null) {
          return DateTime.now().difference(completedAt).inDays;
        }
      }

      return 30; // Default to 30 days if no activity found
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting days since last activity: $e');
      }
      return 30;
    }
  }

  /// Get current skill scores for a user
  Future<Map<SkillType, int>> _getCurrentSkillScores(String userId) async {
    try {
      final analytics = await _skillService.getSkillAnalytics(
        userId,
        DateTime.now().subtract(const Duration(days: 365)),
        DateTime.now(),
      );

      return analytics.currentSkillScores;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting current skill scores: $e');
      }
      // Return default scores if error
      return {for (final skillType in SkillType.values) skillType: 50};
    }
  }

  /// Apply skill update by creating a new skill log
  Future<void> _applySkillUpdate(
      String userId, SkillUpdateResult updateResult) async {
    // Get current skill scores
    final currentSkills = await _getCurrentSkillScores(userId);

    // Calculate new scores
    final Map<SkillType, int> newScores = {};
    for (final skillType in SkillType.values) {
      final currentScore = currentSkills[skillType] ?? 50;
      final change = updateResult.skillChanges[skillType] ?? 0;
      newScores[skillType] = (currentScore + change).clamp(0, 100);
    }

    // Create skill log
    final skillLog = SessionLog(
      id: '', // Will be set by Firestore
      playerId: userId,
      loggedBy: 'system',
      date: DateTime.now(),
      skillScores: newScores,
      skillChanges: updateResult.skillChanges,
      source: updateResult.source,
      context: updateResult.context,
      notes: null,
      metadata: updateResult.metadata,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _skillRepository.addSessionLog(skillLog);
  }

  /// Update user's last active timestamp
  Future<void> _updateUserLastActive(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'lastActive': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating user last active: $e');
      }
    }
  }
}
