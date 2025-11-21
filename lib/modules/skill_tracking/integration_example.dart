// INTEGRATION EXAMPLE - How to use the intelligent skill tracking system

import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'services/skill_integration_service.dart';

/// Example of how to integrate the intelligent skill tracking system
/// throughout your app. This file shows the key integration points.
class SkillTrackingIntegrationExample {
  final SkillIntegrationService _skillIntegration = SkillIntegrationService();

  /// 1. Initialize the system on app startup
  Future<void> initializeApp() async {
    // Call this in your main() function or app initialization
    await _skillIntegration.initialize();
  }

  /// 2. Example: Integrate with booking completion
  Future<void> onBookingCompleted({
    required String bookingId,
    required String userId,
    required SportType sportType,
    required String sessionTitle,
    required double durationHours,
  }) async {
    // This would be called from your BookingService.completeBooking method
    await _skillIntegration.handleBookingCompletion(
      bookingId: bookingId,
      userId: userId,
      sportType: sportType,
      sessionDurationHours: durationHours,
      sessionTitle: sessionTitle,
      additionalMetadata: {
        'completedAt': DateTime.now().toIso8601String(),
        'source': 'booking_service',
      },
    );
  }

  /// 3. Example: Integrate with tournament completion
  Future<void> onTournamentMatchCompleted({
    required String tournamentId,
    required String userId,
    required SportType sportType,
    required String tournamentName,
    required bool didWin,
  }) async {
    // This would be called from your TournamentService
    await _skillIntegration.handleTournamentCompletion(
      tournamentId: tournamentId,
      userId: userId,
      sportType: sportType,
      isTeamTournament: true,
      didWin: didWin,
      tournamentName: tournamentName,
      additionalMetadata: {
        'completedAt': DateTime.now().toIso8601String(),
        'source': 'tournament_service',
      },
    );
  }

  /// 4. Example: Integrate with feedback/rating system
  Future<void> onFeedbackReceived({
    required String userId,
    required double rating,
    required String feedbackContext,
  }) async {
    // This would be called when a coach or teammate gives feedback
    await _skillIntegration.handleFeedbackSubmission(
      userId: userId,
      rating: rating,
      context: feedbackContext,
      additionalMetadata: {
        'submittedAt': DateTime.now().toIso8601String(),
        'source': 'feedback_system',
      },
    );
  }

  /// 5. Example: Manual skill logging by coach
  Future<void> onCoachLogSkills({
    required String playerId,
    required String coachId,
    required Map<SkillType, int> skillScores,
    String? notes,
  }) async {
    // This would be called from your coach logging screen
    await _skillIntegration.handleManualSkillLog(
      playerId: playerId,
      coachId: coachId,
      skillScores: skillScores,
      context: 'Manual assessment by coach',
      notes: notes,
      metadata: {
        'loggedAt': DateTime.now().toIso8601String(),
        'source': 'coach_manual_entry',
      },
    );
  }

  /// 6. Example: Get comprehensive skill dashboard data
  Future<Map<String, dynamic>> getPlayerSkillDashboard(String playerId) async {
    // This would be called from your skill tracking dashboard screen
    return await _skillIntegration.getSkillDashboard(playerId);
  }

  /// 7. Example: Run maintenance tasks (could be scheduled)
  Future<void> runSystemMaintenance() async {
    // This could be called periodically or by admin users
    await _skillIntegration.runMaintenance();
  }
}

/// Example Widget showing how to display skill tracking data
class SkillDashboardWidget extends StatefulWidget {
  final String playerId;

  const SkillDashboardWidget({
    super.key,
    required this.playerId,
  });

  @override
  State<SkillDashboardWidget> createState() => _SkillDashboardWidgetState();
}

class _SkillDashboardWidgetState extends State<SkillDashboardWidget> {
  final SkillIntegrationService _skillIntegration = SkillIntegrationService();
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await _skillIntegration.getSkillDashboard(widget.playerId);
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardData == null || dashboardData!.containsKey('error')) {
      return const Center(child: Text('Error loading skill data'));
    }

    final analytics = dashboardData!['analytics'] as Map<String, dynamic>;
    final currentSkills =
        analytics['currentSkillScores'] as Map<String, dynamic>;
    final activityStatus =
        dashboardData!['activityStatus'] as Map<String, dynamic>;
    final mostImproved = dashboardData!['mostImproved'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Skill Scores
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Skills',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...currentSkills.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text('${entry.value}/100'),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),

        // Most Improved Skill
        if (mostImproved['skill'] != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Most Improved Skill',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${mostImproved['skill']} (+${mostImproved['improvement']})',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Activity Status
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      activityStatus['isInactive']
                          ? Icons.warning
                          : Icons.check_circle,
                      color: activityStatus['isInactive']
                          ? Colors.orange
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activityStatus['isInactive']
                          ? 'Inactive (${activityStatus['daysSinceActive']} days)'
                          : 'Active',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Example of how to integrate activity tracking in your screens
mixin SkillTrackingScreenMixin<T extends StatefulWidget> on State<T> {
  final SkillIntegrationService _skillIntegration = SkillIntegrationService();

  /// Call this when user performs significant actions
  Future<void> trackUserActivity() async {
    await _skillIntegration.trackUserActivity();
  }

  /// Example: Track activity when user navigates to screen
  @override
  void initState() {
    super.initState();
    trackUserActivity();
  }
}

/// Key Integration Points Summary:
///
/// 1. App Initialization:
///    - Call SkillIntegrationService().initialize() in main()
///
/// 2. Booking Completion:
///    - Call handleBookingCompletion() in BookingService.completeBooking()
///
/// 3. Tournament Completion:
///    - Call handleTournamentCompletion() in TournamentService
///
/// 4. Feedback Submission:
///    - Call handleFeedbackSubmission() when ratings are given
///
/// 5. Manual Skill Logging:
///    - Call handleManualSkillLog() in coach logging screens
///
/// 6. Dashboard Display:
///    - Use getSkillDashboard() to get comprehensive data
///
/// 7. Activity Tracking:
///    - Use ActivityTrackingMixin or call trackUserActivity() on significant actions
///
/// 8. Maintenance:
///    - Schedule runMaintenance() to run periodically (daily/weekly)
///
/// 9. System Health:
///    - Use getSystemHealth() for admin monitoring
///
/// The system is designed to be:
/// - Non-blocking: Skill updates won't break main app flows
/// - Intelligent: Calculates skill changes based on real activities
/// - Comprehensive: Tracks all sources of skill improvement
/// - Maintainable: Centralized configuration and easy to extend
/// - Data-driven: Provides rich analytics and insights
