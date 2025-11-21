import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Repository for managing skill tracking data in Firestore.
class SkillRepository {
  SkillRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Collection references
  CollectionReference get _sessionLogsCollection =>
      _firestore.collection('skill_logs');
  CollectionReference get _goalsCollection =>
      _firestore.collection('skill_goals');

  /// Stream of session logs for a specific player.
  Stream<List<SessionLog>> getPlayerSessionLogsStream(String playerId) {
    try {
      return _sessionLogsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map(SessionLog.fromFirestore).toList(),
          );
    } catch (e) {
      debugPrint('Error getting session logs stream: $e');
      return Stream.value(const <SessionLog>[]);
    }
  }

  /// Stream of skill goals for a specific player.
  Stream<List<Goal>> getPlayerGoalsStream(String playerId) {
    try {
      return _goalsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map(Goal.fromFirestore).toList(),
          );
    } catch (e) {
      debugPrint('Error getting skill goals stream: $e');
      return Stream.value(const <Goal>[]);
    }
  }

  /// Get session logs for a specific player within a date range.
  Future<List<SessionLog>> getPlayerSessionLogs(
    String playerId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query =
          _sessionLogsCollection.where('playerId', isEqualTo: playerId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(SessionLog.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting session logs: $e');
      return const <SessionLog>[];
    }
  }

  /// Get skill goals for a specific player.
  Future<List<Goal>> getPlayerGoals(
    String playerId, {
    GoalStatus? status,
  }) async {
    try {
      Query query = _goalsCollection.where('playerId', isEqualTo: playerId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs.map(Goal.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting skill goals: $e');
      return const <Goal>[];
    }
  }

  /// Add a new session log entry.
  Future<String?> addSessionLog(SessionLog sessionLog) async {
    try {
      final docRef = await _sessionLogsCollection.add(sessionLog.toFirestore());

      // Update any relevant goals with new scores.
      await _updateGoalsWithNewScores(
          sessionLog.playerId, sessionLog.skillScores);

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding session log: $e');
      return null;
    }
  }

  /// Update an existing session log.
  Future<bool> updateSessionLog(SessionLog sessionLog) async {
    try {
      await _sessionLogsCollection
          .doc(sessionLog.id)
          .update(sessionLog.toFirestore());

      // Update any relevant goals with new scores.
      await _updateGoalsWithNewScores(
          sessionLog.playerId, sessionLog.skillScores);

      return true;
    } catch (e) {
      debugPrint('Error updating session log: $e');
      return false;
    }
  }

  /// Delete a session log.
  Future<bool> deleteSessionLog(String sessionLogId) async {
    try {
      await _sessionLogsCollection.doc(sessionLogId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting session log: $e');
      return false;
    }
  }

  /// Add a new goal.
  Future<String?> addGoal(Goal goal) async {
    try {
      final docRef = await _goalsCollection.add(goal.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding skill goal: $e');
      return null;
    }
  }

  /// Update an existing goal.
  Future<bool> updateGoal(Goal goal) async {
    try {
      await _goalsCollection.doc(goal.id).update(goal.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating skill goal: $e');
      return false;
    }
  }

  /// Delete a goal.
  Future<bool> deleteGoal(String goalId) async {
    try {
      await _goalsCollection.doc(goalId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting skill goal: $e');
      return false;
    }
  }

  /// Get skill analytics for a player.
  Future<SkillRecord> getPlayerSkillRecord(
    String playerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 90));
    final end = endDate ?? now;

    final sessionLogs = await getPlayerSessionLogs(
      playerId,
      startDate: start,
      endDate: end,
    );

    final goals = await getPlayerGoals(playerId);

    return SkillRecord(
      playerId: playerId,
      skillLogs: sessionLogs,
      skillGoals: goals,
      periodStart: start,
      periodEnd: end,
    );
  }

  /// Get latest skill scores for a player.
  Future<Map<SkillType, int>> getLatestSkillScores(String playerId) async {
    try {
      final logs = await getSessionLogs(playerId, limit: 10);
      final Map<SkillType, int> latestScores = {};

      for (final skillType in SkillType.allSkills) {
        final logWithSkill = logs.firstWhere(
          (log) => log.skillScores.containsKey(skillType),
          orElse: () => SessionLog(
            id: '',
            playerId: playerId,
            loggedBy: '',
            date: DateTime.now(),
            skillScores: {skillType: 0},
            skillChanges: {skillType: 0},
            source: SessionLogSource.manual,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        latestScores[skillType] = logWithSkill.getSkillScore(skillType);
      }

      return latestScores;
    } catch (e) {
      debugPrint('Error getting latest skill scores: $e');
      return const <SkillType, int>{};
    }
  }

  /// Batch add multiple session logs (useful for bulk imports).
  Future<bool> batchAddSessionLogs(List<SessionLog> sessionLogs) async {
    try {
      final batch = _firestore.batch();

      for (final sessionLog in sessionLogs) {
        final docRef = _sessionLogsCollection.doc();
        batch.set(docRef, sessionLog.toFirestore());
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error batch adding session logs: $e');
      return false;
    }
  }

  /// Get session logs with limit.
  Future<List<SessionLog>> getSessionLogs(String playerId,
      {int limit = 50}) async {
    try {
      final query = await _sessionLogsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return query.docs.map(SessionLog.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting session logs: $e');
      return const <SessionLog>[];
    }
  }

  /// Get session logs by date range.
  Future<List<SessionLog>> getSessionLogsByDateRange(
    String playerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _sessionLogsCollection
          .where('playerId', isEqualTo: playerId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return query.docs.map(SessionLog.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting session logs by date range: $e');
      return const [];
    }
  }

  /// Private method to update goals when new scores are logged.
  Future<void> _updateGoalsWithNewScores(
    String playerId,
    Map<SkillType, int> newScores,
  ) async {
    try {
      final activeGoals = await getPlayerGoals(
        playerId,
        status: GoalStatus.active,
      );

      for (final goal in activeGoals) {
        if (newScores.containsKey(goal.skillType)) {
          final newScore = newScores[goal.skillType]!;
          if (newScore != goal.currentScore) {
            final updatedGoal = goal.updateScore(newScore);
            await updateGoal(updatedGoal);
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating goals with new scores: $e');
    }
  }
}
