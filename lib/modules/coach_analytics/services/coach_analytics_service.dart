import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../../team/models/models.dart';
import '../../team/services/team_service.dart';
import '../../skill_tracking/models/models.dart';
import '../../skill_tracking/services/skill_tracking_service.dart';

/// Service for handling coach analytics operations
class CoachAnalyticsService {
  static final CoachAnalyticsService _instance =
      CoachAnalyticsService._internal();
  factory CoachAnalyticsService() => _instance;
  CoachAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TeamService _teamService = TeamService();
  final SkillTrackingService _skillTrackingService = SkillTrackingService();

  // Cache for analytics data
  final Map<String, TeamAnalytics> _teamAnalyticsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Get all teams where the current user is a coach/owner
  Future<List<Team>> getCoachTeams() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teams where user is owner or has coach role
      final teamsSnapshot = await _firestore
          .collection('teams')
          .where('isActive', isEqualTo: true)
          .get();

      final coachTeams = <Team>[];

      for (final doc in teamsSnapshot.docs) {
        final team = Team.fromMap(doc.data());

        // Check if user is owner
        if (team.ownerId == user.uid) {
          coachTeams.add(team);
          continue;
        }

        // Check if user is a coach member
        final isCoach = team.members.any((member) =>
            member.userId == user.uid &&
            (member.role == TeamRole.captain || member.role == TeamRole.owner));

        if (isCoach) {
          coachTeams.add(team);
        }
      }

      return coachTeams;
    } catch (e) {
      debugPrint('Error getting coach teams: $e');
      return [];
    }
  }

  /// Get comprehensive analytics for a specific team
  Future<TeamAnalytics> getTeamAnalytics(String teamId) async {
    try {
      // Check cache first
      if (_isDataCached(teamId)) {
        return _teamAnalyticsCache[teamId]!;
      }

      // Get team details
      final team = await _teamService.getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Get player performance data for all team members
      final playerPerformances = <String, PlayerPerformanceData>{};
      final allSkillScores = <SkillType, List<int>>{};

      // Initialize skill score lists
      for (final skillType in SkillType.allSkills) {
        allSkillScores[skillType] = [];
      }

      for (final member in team.members) {
        try {
          // Get player's skill analytics
          final playerAnalytics =
              await _skillTrackingService.getPlayerSkillAnalytics(
            member.userId,
            startDate: DateTime.now().subtract(const Duration(days: 90)),
            endDate: DateTime.now(),
          );

          // Calculate improvement percentages
          final improvementPercentages = <SkillType, double>{};
          for (final skillType in SkillType.allSkills) {
            final improvements = playerAnalytics.skillImprovements;
            improvementPercentages[skillType] = improvements[skillType] ?? 0.0;
          }

          // Create player performance data
          final playerPerformance = PlayerPerformanceData(
            playerId: member.userId,
            playerName: member.userName,
            playerEmail: member.userEmail,
            profileImageUrl: member.profileImageUrl,
            currentSkillScores: playerAnalytics.currentSkillScores,
            improvementPercentages: improvementPercentages,
            overallScore: playerAnalytics.overallAverageScore,
            totalSessions: playerAnalytics.totalSessions,
            lastActiveDate: playerAnalytics.skillLogs.isNotEmpty
                ? playerAnalytics.skillLogs.last.date
                : DateTime.now().subtract(const Duration(days: 30)),
            isActive: playerAnalytics.skillLogs.isNotEmpty &&
                playerAnalytics.skillLogs.last.date
                    .isAfter(DateTime.now().subtract(const Duration(days: 7))),
          );

          playerPerformances[member.userId] = playerPerformance;

          // Add to overall skill scores for averaging
          for (final entry in playerAnalytics.currentSkillScores.entries) {
            allSkillScores[entry.key]!.add(entry.value);
          }
        } catch (e) {
          debugPrint('Error getting analytics for player ${member.userId}: $e');
          // Continue with other players even if one fails
        }
      }

      // Calculate average skill scores
      final averageSkillScores = <SkillType, double>{};
      for (final entry in allSkillScores.entries) {
        if (entry.value.isNotEmpty) {
          averageSkillScores[entry.key] =
              entry.value.reduce((a, b) => a + b) / entry.value.length;
        } else {
          averageSkillScores[entry.key] = 0.0;
        }
      }

      // Calculate overall team score
      final overallTeamScore = averageSkillScores.values.isNotEmpty
          ? averageSkillScores.values.reduce((a, b) => a + b) /
              averageSkillScores.length
          : 0.0;

      // Find most improved player
      String? mostImprovedPlayerId;
      double maxImprovement = 0.0;

      for (final entry in playerPerformances.entries) {
        final totalImprovement = entry.value.improvementPercentages.values
            .fold(0.0, (total, improvement) => total + improvement);

        if (totalImprovement > maxImprovement) {
          maxImprovement = totalImprovement;
          mostImprovedPlayerId = entry.key;
        }
      }

      // Get performance history (simplified - you might want to implement this more thoroughly)
      final performanceHistory = await _getTeamPerformanceHistory(teamId);

      // Create team analytics
      final teamAnalytics = TeamAnalytics(
        teamId: teamId,
        teamName: team.name,
        sportType: team.sportType,
        totalMembers: team.members.length,
        averageSkillScores: averageSkillScores,
        playerPerformances: playerPerformances,
        performanceHistory: performanceHistory,
        mostImprovedPlayerId: mostImprovedPlayerId,
        overallTeamScore: overallTeamScore,
        lastUpdated: DateTime.now(),
      );

      // Cache the result
      _teamAnalyticsCache[teamId] = teamAnalytics;
      _cacheTimestamps[teamId] = DateTime.now();

      return teamAnalytics;
    } catch (e) {
      debugPrint('Error getting team analytics: $e');
      rethrow;
    }
  }

  /// Get performance history for a team
  Future<List<TeamPerformanceDataPoint>> _getTeamPerformanceHistory(
      String teamId) async {
    try {
      // This is a simplified implementation
      // In a real app, you might store this data separately or calculate it from historical logs
      final now = DateTime.now();
      final performanceHistory = <TeamPerformanceDataPoint>[];

      // Generate sample data points for the last 12 weeks
      for (int i = 11; i >= 0; i--) {
        final date = now.subtract(Duration(days: i * 7));

        // In a real implementation, you would query actual historical data
        // For now, we'll create sample data
        final skillAverages = <SkillType, double>{};
        for (final skillType in SkillType.allSkills) {
          skillAverages[skillType] =
              50.0 + (i * 2.0); // Simulated improvement over time
        }

        final averageScore =
            skillAverages.values.reduce((a, b) => a + b) / skillAverages.length;

        performanceHistory.add(TeamPerformanceDataPoint(
          date: date,
          averageScore: averageScore,
          skillAverages: skillAverages,
          activePlayers: 8, // Sample data
        ));
      }

      return performanceHistory;
    } catch (e) {
      debugPrint('Error getting team performance history: $e');
      return [];
    }
  }

  /// Compare two players
  Future<PlayerComparison> comparePlayer(
      String player1Id, String player2Id) async {
    try {
      // Get analytics for both players
      final player1Analytics =
          await _skillTrackingService.getPlayerSkillAnalytics(
        player1Id,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now(),
      );

      final player2Analytics =
          await _skillTrackingService.getPlayerSkillAnalytics(
        player2Id,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now(),
      );

      // Get user details for both players
      final player1Doc =
          await _firestore.collection('users').doc(player1Id).get();
      final player2Doc =
          await _firestore.collection('users').doc(player2Id).get();

      if (!player1Doc.exists || !player2Doc.exists) {
        throw Exception('One or both players not found');
      }

      final player1Data = player1Doc.data()!;
      final player2Data = player2Doc.data()!;

      // Create player performance data
      final player1Performance = PlayerPerformanceData(
        playerId: player1Id,
        playerName: player1Data['fullName'] ?? 'Unknown Player',
        playerEmail: player1Data['email'],
        profileImageUrl: player1Data['profilePictureUrl'],
        currentSkillScores: player1Analytics.currentSkillScores,
        improvementPercentages: player1Analytics.skillImprovements,
        overallScore: player1Analytics.overallAverageScore,
        totalSessions: player1Analytics.totalSessions,
        lastActiveDate: player1Analytics.skillLogs.isNotEmpty
            ? player1Analytics.skillLogs.last.date
            : DateTime.now().subtract(const Duration(days: 30)),
        isActive: player1Analytics.skillLogs.isNotEmpty,
      );

      final player2Performance = PlayerPerformanceData(
        playerId: player2Id,
        playerName: player2Data['fullName'] ?? 'Unknown Player',
        playerEmail: player2Data['email'],
        profileImageUrl: player2Data['profilePictureUrl'],
        currentSkillScores: player2Analytics.currentSkillScores,
        improvementPercentages: player2Analytics.skillImprovements,
        overallScore: player2Analytics.overallAverageScore,
        totalSessions: player2Analytics.totalSessions,
        lastActiveDate: player2Analytics.skillLogs.isNotEmpty
            ? player2Analytics.skillLogs.last.date
            : DateTime.now().subtract(const Duration(days: 30)),
        isActive: player2Analytics.skillLogs.isNotEmpty,
      );

      // Create and return comparison
      return PlayerComparison.create(
        player1: player1Performance,
        player2: player2Performance,
      );
    } catch (e) {
      debugPrint('Error comparing players: $e');
      rethrow;
    }
  }

  /// Get coach dashboard summary data
  Future<Map<String, dynamic>> getCoachDashboardSummary() async {
    try {
      final teams = await getCoachTeams();

      if (teams.isEmpty) {
        return {
          'totalTeams': 0,
          'totalPlayers': 0,
          'averageTeamScore': 0.0,
          'mostImprovedTeam': null,
          'topPerformingTeam': null,
        };
      }

      int totalPlayers = 0;
      double totalTeamScore = 0.0;
      String? mostImprovedTeamId;
      String? topPerformingTeamId;
      double maxImprovement = 0.0;
      double maxScore = 0.0;

      for (final team in teams) {
        totalPlayers += team.members.length;

        try {
          final teamAnalytics = await getTeamAnalytics(team.id);
          totalTeamScore += teamAnalytics.overallTeamScore;

          if (teamAnalytics.improvementPercentage > maxImprovement) {
            maxImprovement = teamAnalytics.improvementPercentage;
            mostImprovedTeamId = team.id;
          }

          if (teamAnalytics.overallTeamScore > maxScore) {
            maxScore = teamAnalytics.overallTeamScore;
            topPerformingTeamId = team.id;
          }
        } catch (e) {
          debugPrint('Error getting analytics for team ${team.id}: $e');
        }
      }

      final averageTeamScore =
          teams.isNotEmpty ? totalTeamScore / teams.length : 0.0;

      return {
        'totalTeams': teams.length,
        'totalPlayers': totalPlayers,
        'averageTeamScore': averageTeamScore,
        'mostImprovedTeam': mostImprovedTeamId != null
            ? teams.firstWhere((t) => t.id == mostImprovedTeamId).name
            : null,
        'topPerformingTeam': topPerformingTeamId != null
            ? teams.firstWhere((t) => t.id == topPerformingTeamId).name
            : null,
      };
    } catch (e) {
      debugPrint('Error getting coach dashboard summary: $e');
      return {
        'totalTeams': 0,
        'totalPlayers': 0,
        'averageTeamScore': 0.0,
        'mostImprovedTeam': null,
        'topPerformingTeam': null,
      };
    }
  }

  /// Check if data is cached and still valid
  bool _isDataCached(String teamId) {
    if (!_teamAnalyticsCache.containsKey(teamId) ||
        !_cacheTimestamps.containsKey(teamId)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[teamId]!;
    return DateTime.now().difference(cacheTime) < _cacheExpiry;
  }

  /// Clear cache for a specific team
  void clearTeamCache(String teamId) {
    _teamAnalyticsCache.remove(teamId);
    _cacheTimestamps.remove(teamId);
  }

  /// Clear all cache
  void clearAllCache() {
    _teamAnalyticsCache.clear();
    _cacheTimestamps.clear();
  }
}
