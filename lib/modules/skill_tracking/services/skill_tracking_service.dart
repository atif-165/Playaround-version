import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/skill_tracking_repository.dart';

/// Service layer for skill tracking business logic
class SkillTrackingService {
  final SkillTrackingRepository _repository;
  
  // Cache for frequently accessed data
  final Map<String, List<SkillLog>> _skillLogsCache = {};
  final Map<String, List<SkillGoal>> _skillGoalsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  SkillTrackingService({SkillTrackingRepository? repository})
      : _repository = repository ?? SkillTrackingRepository();

  /// Get skill logs stream with caching
  Stream<List<SkillLog>> getPlayerSkillLogsStream(String playerId) {
    return _repository.getPlayerSkillLogsStream(playerId).map((logs) {
      _updateSkillLogsCache(playerId, logs);
      return logs;
    }).asBroadcastStream();
  }

  /// Get skill goals stream with caching
  Stream<List<SkillGoal>> getPlayerSkillGoalsStream(String playerId) {
    return _repository.getPlayerSkillGoalsStream(playerId).map((goals) {
      _updateSkillGoalsCache(playerId, goals);
      return goals;
    }).asBroadcastStream();
  }

  /// Get cached skill logs or fetch from repository
  Future<List<SkillLog>> getPlayerSkillLogs(
    String playerId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${playerId}_logs';
    
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      final cachedLogs = _skillLogsCache[cacheKey] ?? [];
      return _filterSkillLogs(cachedLogs, startDate, endDate, limit);
    }

    final logs = await _repository.getPlayerSkillLogs(
      playerId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    _updateSkillLogsCache(playerId, logs);
    return logs;
  }

  /// Get cached skill goals or fetch from repository
  Future<List<SkillGoal>> getPlayerSkillGoals(
    String playerId, {
    GoalStatus? status,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${playerId}_goals';
    
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      final cachedGoals = _skillGoalsCache[cacheKey] ?? [];
      return status != null 
          ? cachedGoals.where((goal) => goal.status == status).toList()
          : cachedGoals;
    }

    final goals = await _repository.getPlayerSkillGoals(playerId, status: status);
    _updateSkillGoalsCache(playerId, goals);
    return goals;
  }

  /// Add skill log with validation
  Future<String?> addSkillLog(SkillLog skillLog) async {
    // Validate skill log
    final validationError = _validateSkillLog(skillLog);
    if (validationError != null) {
      debugPrint('Skill log validation failed: $validationError');
      return null;
    }

    final result = await _repository.addSkillLog(skillLog);
    if (result != null) {
      _invalidateCache('${skillLog.playerId}_logs');
      _invalidateCache('${skillLog.playerId}_goals');
    }
    return result;
  }

  /// Update skill log with validation
  Future<bool> updateSkillLog(SkillLog skillLog) async {
    final validationError = _validateSkillLog(skillLog);
    if (validationError != null) {
      debugPrint('Skill log validation failed: $validationError');
      return false;
    }

    final result = await _repository.updateSkillLog(skillLog);
    if (result) {
      _invalidateCache('${skillLog.playerId}_logs');
      _invalidateCache('${skillLog.playerId}_goals');
    }
    return result;
  }

  /// Delete skill log
  Future<bool> deleteSkillLog(String skillLogId, String playerId) async {
    final result = await _repository.deleteSkillLog(skillLogId);
    if (result) {
      _invalidateCache('${playerId}_logs');
    }
    return result;
  }

  /// Add skill goal with validation
  Future<String?> addSkillGoal(SkillGoal skillGoal) async {
    // Validate skill goal
    final validationError = _validateSkillGoal(skillGoal);
    if (validationError != null) {
      debugPrint('Skill goal validation failed: $validationError');
      return null;
    }

    // Check for existing active goal for the same skill
    final existingGoals = await getPlayerSkillGoals(
      skillGoal.playerId,
      status: GoalStatus.active,
    );

    final hasActiveGoal = existingGoals.any(
      (goal) => goal.skillType == skillGoal.skillType,
    );

    if (hasActiveGoal) {
      debugPrint('Player already has an active goal for ${skillGoal.skillType.displayName}');
      return null;
    }

    final result = await _repository.addSkillGoal(skillGoal);
    if (result != null) {
      _invalidateCache('${skillGoal.playerId}_goals');
    }
    return result;
  }

  /// Update skill goal with validation
  Future<bool> updateSkillGoal(SkillGoal skillGoal) async {
    final validationError = _validateSkillGoal(skillGoal);
    if (validationError != null) {
      debugPrint('Skill goal validation failed: $validationError');
      return false;
    }

    final result = await _repository.updateSkillGoal(skillGoal);
    if (result) {
      _invalidateCache('${skillGoal.playerId}_goals');
    }
    return result;
  }

  /// Delete skill goal
  Future<bool> deleteSkillGoal(String skillGoalId, String playerId) async {
    final result = await _repository.deleteSkillGoal(skillGoalId);
    if (result) {
      _invalidateCache('${playerId}_goals');
    }
    return result;
  }

  /// Get comprehensive skill analytics
  Future<SkillAnalytics> getPlayerSkillAnalytics(
    String playerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getPlayerSkillAnalytics(
      playerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get latest skill scores with caching
  Future<Map<SkillType, int>> getLatestSkillScores(String playerId) async {
    return await _repository.getLatestSkillScores(playerId);
  }

  /// Create a new skill log for coach logging
  SkillLog createSkillLog({
    required String playerId,
    required String coachId,
    required Map<SkillType, int> skillScores,
    Map<SkillType, int>? skillChanges,
    SkillLogSource source = SkillLogSource.manual,
    String? context,
    DateTime? date,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();

    // Calculate skill changes if not provided
    final Map<SkillType, int> changes = skillChanges ?? {};
    if (skillChanges == null) {
      // For manual logs, we don't have previous scores to calculate changes
      // So we'll set changes to 0 for all skills
      for (final skillType in SkillType.values) {
        changes[skillType] = 0;
      }
    }

    return SkillLog(
      id: '', // Will be set by Firestore
      playerId: playerId,
      loggedBy: coachId,
      date: date ?? now,
      skillScores: skillScores,
      skillChanges: changes,
      source: source,
      context: context ?? 'Manual assessment by coach',
      notes: notes,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a new skill goal for player
  SkillGoal createSkillGoal({
    required String playerId,
    required SkillType skillType,
    required int currentScore,
    required int targetScore,
    required DateTime targetDate,
    String? description,
  }) {
    final now = DateTime.now();
    return SkillGoal(
      id: '', // Will be set by Firestore
      playerId: playerId,
      skillType: skillType,
      currentScore: currentScore,
      targetScore: targetScore,
      targetDate: targetDate,
      status: GoalStatus.active,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Validate skill log data
  String? _validateSkillLog(SkillLog skillLog) {
    if (skillLog.playerId.isEmpty) return 'Player ID is required';
    if (skillLog.loggedBy.isEmpty) return 'Logger ID is required';
    if (skillLog.skillScores.isEmpty) return 'At least one skill score is required';
    
    for (final entry in skillLog.skillScores.entries) {
      if (entry.value < 0 || entry.value > 100) {
        return 'Skill scores must be between 0 and 100';
      }
    }
    
    return null;
  }

  /// Validate skill goal data
  String? _validateSkillGoal(SkillGoal skillGoal) {
    if (skillGoal.playerId.isEmpty) return 'Player ID is required';
    if (skillGoal.currentScore < 0 || skillGoal.currentScore > 100) {
      return 'Current score must be between 0 and 100';
    }
    if (skillGoal.targetScore < 0 || skillGoal.targetScore > 100) {
      return 'Target score must be between 0 and 100';
    }
    if (skillGoal.targetScore <= skillGoal.currentScore) {
      return 'Target score must be higher than current score';
    }
    if (skillGoal.targetDate.isBefore(DateTime.now())) {
      return 'Target date must be in the future';
    }
    
    return null;
  }

  /// Cache management methods
  void _updateSkillLogsCache(String playerId, List<SkillLog> logs) {
    final cacheKey = '${playerId}_logs';
    _skillLogsCache[cacheKey] = logs;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  void _updateSkillGoalsCache(String playerId, List<SkillGoal> goals) {
    final cacheKey = '${playerId}_goals';
    _skillGoalsCache[cacheKey] = goals;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  void _invalidateCache(String cacheKey) {
    _skillLogsCache.remove(cacheKey);
    _skillGoalsCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
  }

  List<SkillLog> _filterSkillLogs(
    List<SkillLog> logs,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  ) {
    var filteredLogs = logs;

    if (startDate != null) {
      filteredLogs = filteredLogs
          .where((log) => log.date.isAfter(startDate) || log.date.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      filteredLogs = filteredLogs
          .where((log) => log.date.isBefore(endDate) || log.date.isAtSameMomentAs(endDate))
          .toList();
    }

    if (limit != null && filteredLogs.length > limit) {
      filteredLogs = filteredLogs.take(limit).toList();
    }

    return filteredLogs;
  }

  /// Clear all caches
  void clearCache() {
    _skillLogsCache.clear();
    _skillGoalsCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get skill logs by source type
  Future<List<SkillLog>> getSkillLogsBySource(
    String playerId,
    SkillLogSource source, {
    int limit = 50,
  }) async {
    try {
      final logs = await _repository.getSkillLogs(playerId, limit: limit);
      return logs.where((log) => log.source == source).toList();
    } catch (e) {
      debugPrint('Error getting skill logs by source: $e');
      return [];
    }
  }

  /// Get skill improvement trends
  Future<Map<SkillType, List<int>>> getSkillTrends(
    String playerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final logs = await _repository.getSkillLogsByDateRange(
        playerId,
        startDate,
        endDate,
      );

      final Map<SkillType, List<int>> trends = {};

      // Initialize trends map
      for (final skillType in SkillType.values) {
        trends[skillType] = [];
      }

      // Sort logs by date
      logs.sort((a, b) => a.date.compareTo(b.date));

      // Extract scores for each skill type
      for (final log in logs) {
        for (final skillType in SkillType.values) {
          trends[skillType]!.add(log.getSkillScore(skillType));
        }
      }

      return trends;
    } catch (e) {
      debugPrint('Error getting skill trends: $e');
      return {};
    }
  }

  /// Get skill change summary for a period
  Future<Map<String, dynamic>> getSkillChangeSummary(
    String playerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final logs = await _repository.getSkillLogsByDateRange(
        playerId,
        startDate,
        endDate,
      );

      if (logs.isEmpty) {
        return {
          'totalLogs': 0,
          'totalPositiveChanges': 0,
          'totalNegativeChanges': 0,
          'changesBySource': <String, int>{},
          'changesBySkill': <String, int>{},
        };
      }

      int totalPositiveChanges = 0;
      int totalNegativeChanges = 0;
      final Map<String, int> changesBySource = {};
      final Map<String, int> changesBySkill = {};

      for (final log in logs) {
        // Count positive and negative changes
        totalPositiveChanges += log.totalPositiveChanges;
        totalNegativeChanges += log.totalNegativeChanges;

        // Count changes by source
        final sourceName = log.source.displayName;
        changesBySource[sourceName] = (changesBySource[sourceName] ?? 0) + 1;

        // Count changes by skill type
        for (final entry in log.skillChanges.entries) {
          if (entry.value != 0) {
            final skillName = entry.key.displayName;
            changesBySkill[skillName] = (changesBySkill[skillName] ?? 0) + entry.value.abs();
          }
        }
      }

      return {
        'totalLogs': logs.length,
        'totalPositiveChanges': totalPositiveChanges,
        'totalNegativeChanges': totalNegativeChanges,
        'changesBySource': changesBySource,
        'changesBySkill': changesBySkill,
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'days': endDate.difference(startDate).inDays,
        },
      };
    } catch (e) {
      debugPrint('Error getting skill change summary: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get most improved skill for a player
  Future<Map<String, dynamic>> getMostImprovedSkill(
    String playerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final logs = await _repository.getSkillLogsByDateRange(
        playerId,
        startDate,
        endDate,
      );

      if (logs.isEmpty) {
        return {
          'skill': null,
          'improvement': 0,
          'startScore': 0,
          'endScore': 0,
        };
      }

      // Sort logs by date
      logs.sort((a, b) => a.date.compareTo(b.date));

      final firstLog = logs.first;
      final lastLog = logs.last;

      SkillType? mostImprovedSkill;
      int maxImprovement = 0;

      for (final skillType in SkillType.values) {
        final startScore = firstLog.getSkillScore(skillType);
        final endScore = lastLog.getSkillScore(skillType);
        final improvement = endScore - startScore;

        if (improvement > maxImprovement) {
          maxImprovement = improvement;
          mostImprovedSkill = skillType;
        }
      }

      if (mostImprovedSkill != null) {
        return {
          'skill': mostImprovedSkill.displayName,
          'skillType': mostImprovedSkill.name,
          'improvement': maxImprovement,
          'startScore': firstLog.getSkillScore(mostImprovedSkill),
          'endScore': lastLog.getSkillScore(mostImprovedSkill),
        };
      }

      return {
        'skill': null,
        'improvement': 0,
        'startScore': 0,
        'endScore': 0,
      };
    } catch (e) {
      debugPrint('Error getting most improved skill: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get skill log statistics
  Future<Map<String, dynamic>> getSkillLogStatistics(String playerId) async {
    try {
      final allLogs = await _repository.getSkillLogs(playerId, limit: 1000);

      if (allLogs.isEmpty) {
        return {
          'totalLogs': 0,
          'logsBySource': <String, int>{},
          'averageScores': <String, double>{},
          'lastLogDate': null,
          'firstLogDate': null,
        };
      }

      // Count logs by source
      final Map<String, int> logsBySource = {};
      for (final log in allLogs) {
        final sourceName = log.source.displayName;
        logsBySource[sourceName] = (logsBySource[sourceName] ?? 0) + 1;
      }

      // Calculate average scores
      final Map<String, double> averageScores = {};
      for (final skillType in SkillType.values) {
        final scores = allLogs.map((log) => log.getSkillScore(skillType)).toList();
        if (scores.isNotEmpty) {
          averageScores[skillType.displayName] =
              scores.reduce((a, b) => a + b) / scores.length.toDouble();
        }
      }

      // Sort logs by date to get first and last
      allLogs.sort((a, b) => a.date.compareTo(b.date));

      return {
        'totalLogs': allLogs.length,
        'logsBySource': logsBySource,
        'averageScores': averageScores,
        'lastLogDate': allLogs.last.date.toIso8601String(),
        'firstLogDate': allLogs.first.date.toIso8601String(),
        'trackingPeriodDays': allLogs.last.date.difference(allLogs.first.date).inDays,
      };
    } catch (e) {
      debugPrint('Error getting skill log statistics: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get skill analytics for a player
  Future<SkillAnalytics> getSkillAnalytics(
    String playerId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    try {
      final skillLogs = await _repository.getSkillLogsByDateRange(
        playerId,
        periodStart,
        periodEnd,
      );

      final skillGoals = await _repository.getSkillGoals(playerId);

      return SkillAnalytics(
        playerId: playerId,
        skillLogs: skillLogs,
        skillGoals: skillGoals,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    } catch (e) {
      debugPrint('Error getting skill analytics: $e');
      // Return empty analytics on error
      return SkillAnalytics(
        playerId: playerId,
        skillLogs: [],
        skillGoals: [],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    }
  }

  /// Get skill logs for a player with limit
  Future<List<SkillLog>> getSkillLogs(String playerId, {int limit = 50}) async {
    try {
      return await _repository.getSkillLogs(playerId, limit: limit);
    } catch (e) {
      debugPrint('Error getting skill logs: $e');
      return [];
    }
  }
}
