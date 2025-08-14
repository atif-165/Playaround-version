import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Repository for managing skill tracking data in Firestore
class SkillTrackingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _skillLogsCollection => 
      _firestore.collection('skill_logs');
  CollectionReference get _skillGoalsCollection => 
      _firestore.collection('skill_goals');

  /// Stream of skill logs for a specific player
  Stream<List<SkillLog>> getPlayerSkillLogsStream(String playerId) {
    try {
      return _skillLogsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SkillLog.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error getting skill logs stream: $e');
      return Stream.value([]);
    }
  }

  /// Stream of skill goals for a specific player
  Stream<List<SkillGoal>> getPlayerSkillGoalsStream(String playerId) {
    try {
      return _skillGoalsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SkillGoal.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error getting skill goals stream: $e');
      return Stream.value([]);
    }
  }

  /// Get skill logs for a specific player within a date range
  Future<List<SkillLog>> getPlayerSkillLogs(
    String playerId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _skillLogsCollection
          .where('playerId', isEqualTo: playerId);

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
      return snapshot.docs
          .map((doc) => SkillLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting skill logs: $e');
      return [];
    }
  }

  /// Get skill goals for a specific player
  Future<List<SkillGoal>> getPlayerSkillGoals(
    String playerId, {
    GoalStatus? status,
  }) async {
    try {
      Query query = _skillGoalsCollection
          .where('playerId', isEqualTo: playerId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => SkillGoal.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting skill goals: $e');
      return [];
    }
  }

  /// Add a new skill log entry
  Future<String?> addSkillLog(SkillLog skillLog) async {
    try {
      final docRef = await _skillLogsCollection.add(skillLog.toFirestore());
      
      // Update any relevant goals with new scores
      await _updateGoalsWithNewScores(skillLog.playerId, skillLog.skillScores);
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding skill log: $e');
      return null;
    }
  }

  /// Update an existing skill log
  Future<bool> updateSkillLog(SkillLog skillLog) async {
    try {
      await _skillLogsCollection
          .doc(skillLog.id)
          .update(skillLog.toFirestore());
      
      // Update any relevant goals with new scores
      await _updateGoalsWithNewScores(skillLog.playerId, skillLog.skillScores);
      
      return true;
    } catch (e) {
      debugPrint('Error updating skill log: $e');
      return false;
    }
  }

  /// Delete a skill log
  Future<bool> deleteSkillLog(String skillLogId) async {
    try {
      await _skillLogsCollection.doc(skillLogId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting skill log: $e');
      return false;
    }
  }

  /// Add a new skill goal
  Future<String?> addSkillGoal(SkillGoal skillGoal) async {
    try {
      final docRef = await _skillGoalsCollection.add(skillGoal.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding skill goal: $e');
      return null;
    }
  }

  /// Update an existing skill goal
  Future<bool> updateSkillGoal(SkillGoal skillGoal) async {
    try {
      await _skillGoalsCollection
          .doc(skillGoal.id)
          .update(skillGoal.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating skill goal: $e');
      return false;
    }
  }

  /// Delete a skill goal
  Future<bool> deleteSkillGoal(String skillGoalId) async {
    try {
      await _skillGoalsCollection.doc(skillGoalId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting skill goal: $e');
      return false;
    }
  }

  /// Get skill analytics for a player
  Future<SkillAnalytics> getPlayerSkillAnalytics(
    String playerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 90));
    final end = endDate ?? now;

    final skillLogs = await getPlayerSkillLogs(
      playerId,
      startDate: start,
      endDate: end,
    );

    final skillGoals = await getPlayerSkillGoals(playerId);

    return SkillAnalytics(
      playerId: playerId,
      skillLogs: skillLogs,
      skillGoals: skillGoals,
      periodStart: start,
      periodEnd: end,
    );
  }

  /// Get latest skill scores for a player
  Future<Map<SkillType, int>> getLatestSkillScores(String playerId) async {
    try {
      final logs = await getPlayerSkillLogs(playerId, limit: 10);
      final Map<SkillType, int> latestScores = {};

      for (final skillType in SkillType.allSkills) {
        final logWithSkill = logs.firstWhere(
          (log) => log.skillScores.containsKey(skillType),
          orElse: () => SkillLog(
            id: '',
            playerId: playerId,
            loggedBy: '',
            date: DateTime.now(),
            skillScores: {skillType: 0},
            skillChanges: {skillType: 0},
            source: SkillLogSource.manual,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        latestScores[skillType] = logWithSkill.getSkillScore(skillType);
      }

      return latestScores;
    } catch (e) {
      debugPrint('Error getting latest skill scores: $e');
      return {};
    }
  }

  /// Private method to update goals when new scores are logged
  Future<void> _updateGoalsWithNewScores(
    String playerId,
    Map<SkillType, int> newScores,
  ) async {
    try {
      final activeGoals = await getPlayerSkillGoals(
        playerId,
        status: GoalStatus.active,
      );

      for (final goal in activeGoals) {
        if (newScores.containsKey(goal.skillType)) {
          final newScore = newScores[goal.skillType]!;
          if (newScore != goal.currentScore) {
            final updatedGoal = goal.updateScore(newScore);
            await updateSkillGoal(updatedGoal);
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating goals with new scores: $e');
    }
  }

  /// Batch add multiple skill logs (useful for bulk imports)
  Future<bool> batchAddSkillLogs(List<SkillLog> skillLogs) async {
    try {
      final batch = _firestore.batch();

      for (final skillLog in skillLogs) {
        final docRef = _skillLogsCollection.doc();
        batch.set(docRef, skillLog.toFirestore());
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error batch adding skill logs: $e');
      return false;
    }
  }

  /// Get skill logs with limit
  Future<List<SkillLog>> getSkillLogs(String playerId, {int limit = 50}) async {
    try {
      final query = await _skillLogsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => SkillLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting skill logs: $e');
      return [];
    }
  }

  /// Get skill logs by date range
  Future<List<SkillLog>> getSkillLogsByDateRange(
    String playerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _skillLogsCollection
          .where('playerId', isEqualTo: playerId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return query.docs
          .map((doc) => SkillLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting skill logs by date range: $e');
      return [];
    }
  }

  /// Get skill goals for a player
  Future<List<SkillGoal>> getSkillGoals(String playerId) async {
    try {
      final query = await _skillGoalsCollection
          .where('playerId', isEqualTo: playerId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => SkillGoal.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting skill goals: $e');
      return [];
    }
  }
}
