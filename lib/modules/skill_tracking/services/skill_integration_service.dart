import 'package:flutter/foundation.dart';

import '../../../models/models.dart';
import '../../../services/user_activity_service.dart';
import 'automated_skill_service.dart';
import 'skill_decay_service.dart';
import 'skill_tracking_service.dart';

/// Central integration service for all skill tracking functionality
class SkillIntegrationService with ActivityTrackingMixin {
  static final SkillIntegrationService _instance = SkillIntegrationService._internal();
  factory SkillIntegrationService() => _instance;
  SkillIntegrationService._internal();

  final SkillTrackingService _skillTrackingService = SkillTrackingService();
  final AutomatedSkillService _automatedSkillService = AutomatedSkillService();
  final SkillDecayService _skillDecayService = SkillDecayService();
  final UserActivityService _activityService = UserActivityService();

  /// Initialize the skill tracking system
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 SkillIntegrationService: Initializing skill tracking system...');
      }

      // Initialize activity tracking
      await _activityService.initializeActivityTracking();

      // Initialize decay service (will run background checks if needed)
      await _skillDecayService.initialize();

      if (kDebugMode) {
        debugPrint('✅ SkillIntegrationService: Skill tracking system initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillIntegrationService: Error initializing: $e');
      }
    }
  }

  /// Handle booking completion with skill updates and activity tracking
  Future<void> handleBookingCompletion({
    required String bookingId,
    required String userId,
    required SportType sportType,
    required double sessionDurationHours,
    required String sessionTitle,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Track user activity
      await _activityService.trackActivityForUser(userId);

      // Apply skill updates
      await _automatedSkillService.onBookingCompleted(
        bookingId: bookingId,
        userId: userId,
        sportType: sportType,
        sessionDurationHours: sessionDurationHours,
        sessionTitle: sessionTitle,
        additionalMetadata: additionalMetadata,
      );

      if (kDebugMode) {
        debugPrint('✅ SkillIntegrationService: Handled booking completion for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillIntegrationService: Error handling booking completion: $e');
      }
    }
  }

  /// Handle venue booking completion with skill updates and activity tracking
  Future<void> handleVenueBookingCompletion({
    required String bookingId,
    required String userId,
    required SportType sportType,
    required double sessionDurationHours,
    required String venueTitle,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Track user activity
      await _activityService.trackActivityForUser(userId);

      // Apply skill updates
      await _automatedSkillService.onVenueBookingCompleted(
        bookingId: bookingId,
        userId: userId,
        sportType: sportType,
        sessionDurationHours: sessionDurationHours,
        venueTitle: venueTitle,
        additionalMetadata: additionalMetadata,
      );

      if (kDebugMode) {
        debugPrint('✅ SkillIntegrationService: Handled venue booking completion for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillIntegrationService: Error handling venue booking completion: $e');
      }
    }
  }

  /// Handle tournament completion with skill updates and activity tracking
  Future<void> handleTournamentCompletion({
    required String tournamentId,
    required String userId,
    required SportType sportType,
    required bool isTeamTournament,
    required bool didWin,
    required String tournamentName,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Track user activity
      await _activityService.trackActivityForUser(userId);

      // Apply skill updates
      await _automatedSkillService.onTournamentCompleted(
        tournamentId: tournamentId,
        userId: userId,
        sportType: sportType,
        isTeamTournament: isTeamTournament,
        didWin: didWin,
        tournamentName: tournamentName,
        additionalMetadata: additionalMetadata,
      );

      if (kDebugMode) {
        debugPrint('✅ SkillIntegrationService: Handled tournament completion for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillIntegrationService: Error handling tournament completion: $e');
      }
    }
  }

  /// Handle feedback submission with skill updates and activity tracking
  Future<void> handleFeedbackSubmission({
    required String userId,
    required double rating,
    required String context,
    Map<SkillType, int>? specificSkillFeedback,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Track user activity
      await _activityService.trackActivityForUser(userId);

      // Apply skill updates
      await _automatedSkillService.onFeedbackReceived(
        userId: userId,
        rating: rating,
        context: context,
        specificSkillFeedback: specificSkillFeedback,
        additionalMetadata: additionalMetadata,
      );

      if (kDebugMode) {
        debugPrint('✅ SkillIntegrationService: Handled feedback submission for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillIntegrationService: Error handling feedback submission: $e');
      }
    }
  }

  /// Handle manual skill log creation with activity tracking
  Future<String?> handleManualSkillLog({
    required String playerId,
    required String coachId,
    required Map<SkillType, int> skillScores,
    Map<SkillType, int>? skillChanges,
    String? context,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Track activity for both coach and player
      await _activityService.trackActivityForUser(coachId);
      await _activityService.trackActivityForUser(playerId);

      // Create skill log
      final skillLog = _skillTrackingService.createSkillLog(
        playerId: playerId,
        coachId: coachId,
        skillScores: skillScores,
        skillChanges: skillChanges,
        source: SkillLogSource.manual,
        context: context,
        notes: notes,
        metadata: metadata,
      );

      final logId = await _skillTrackingService.addSkillLog(skillLog);

      if (kDebugMode) {
        debugPrint('✅ SkillIntegrationService: Created manual skill log for player $playerId');
      }

      return logId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillIntegrationService: Error creating manual skill log: $e');
      }
      return null;
    }
  }

  /// Get comprehensive skill dashboard data
  Future<Map<String, dynamic>> getSkillDashboard(String playerId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Get analytics
      final analytics = await _skillTrackingService.getSkillAnalytics(
        playerId,
        thirtyDaysAgo,
        now,
      );

      // Get recent activity
      final recentLogs = await _skillTrackingService.getSkillLogs(
        playerId,
        limit: 10,
      );

      // Get skill trends
      final trends = await _skillTrackingService.getSkillTrends(
        playerId,
        thirtyDaysAgo,
        now,
      );

      // Get change summary
      final changeSummary = await _skillTrackingService.getSkillChangeSummary(
        playerId,
        sevenDaysAgo,
        now,
      );

      // Get most improved skill
      final mostImproved = await _skillTrackingService.getMostImprovedSkill(
        playerId,
        thirtyDaysAgo,
        now,
      );

      // Get statistics
      final statistics = await _skillTrackingService.getSkillLogStatistics(playerId);

      // Get activity info
      final lastActive = await _activityService.getLastActive(playerId);
      final daysSinceActive = await _activityService.getDaysSinceLastActive(playerId);
      final isInactive = await _activityService.isUserInactive(playerId);

      return {
        'analytics': {
          'currentSkillScores': analytics.currentSkillScores.map(
            (key, value) => MapEntry(key.displayName, value),
          ),
          'skillProgress': analytics.skillProgress.map(
            (key, value) => MapEntry(key.displayName, value),
          ),
          'totalLogs': analytics.skillLogs.length,
          'activeGoals': analytics.skillGoals.where((g) => g.status == GoalStatus.active).length,
        },
        'recentActivity': {
          'logs': recentLogs.map((log) => {
            'date': log.date.toIso8601String(),
            'source': log.source.displayName,
            'context': log.displayContext,
            'hasPositiveChanges': log.hasPositiveChanges,
            'hasNegativeChanges': log.hasNegativeChanges,
          }).toList(),
        },
        'trends': trends.map(
          (key, value) => MapEntry(key.displayName, value),
        ),
        'weeklyChanges': changeSummary,
        'mostImproved': mostImproved,
        'statistics': statistics,
        'activityStatus': {
          'lastActive': lastActive?.toIso8601String(),
          'daysSinceActive': daysSinceActive,
          'isInactive': isInactive,
          'inactivityThreshold': SkillUpdateConfig.inactivityThresholdDays,
        },
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillIntegrationService: Error getting skill dashboard: $e');
      }
      return {
        'error': e.toString(),
      };
    }
  }

  /// Run maintenance tasks (decay check, cleanup, etc.)
  Future<void> runMaintenance() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 SkillIntegrationService: Running maintenance tasks...');
      }

      // Run skill decay check
      await _skillDecayService.runSkillDecayCheck();

      // Clear old caches
      _skillTrackingService.clearCache();

      if (kDebugMode) {
        debugPrint('✅ SkillIntegrationService: Maintenance tasks completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillIntegrationService: Error running maintenance: $e');
      }
    }
  }

  /// Get system health status
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final decayStats = await _skillDecayService.getDecayStatistics();
      
      return {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'decaySystem': decayStats,
        'cacheStatus': {
          'skillTrackingCacheSize': _skillTrackingService.toString(), // This would need cache size info
        },
      };
    } catch (e) {
      return {
        'status': 'error',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
}
