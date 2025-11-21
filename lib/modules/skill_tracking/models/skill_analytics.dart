import 'skill_type.dart';
import 'session_log.dart';
import 'goal.dart';

/// Model for skill analytics and performance insights
class SkillAnalytics {
  final String playerId;
  final List<SessionLog> skillLogs;
  final List<Goal> skillGoals;
  final DateTime periodStart;
  final DateTime periodEnd;

  const SkillAnalytics({
    required this.playerId,
    required this.skillLogs,
    required this.skillGoals,
    required this.periodStart,
    required this.periodEnd,
  });

  /// Get current skill scores (latest log entry for each skill)
  Map<SkillType, int> get currentSkillScores {
    final Map<SkillType, int> currentScores = {};

    for (final skillType in SkillType.allSkills) {
      // Find the most recent log that has this skill type
      final logsWithSkill = skillLogs
          .where((log) => log.skillScores.containsKey(skillType))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (logsWithSkill.isNotEmpty) {
        currentScores[skillType] = logsWithSkill.first.getSkillScore(skillType);
      } else {
        currentScores[skillType] = 0;
      }
    }

    return currentScores;
  }

  /// Get skill improvement over time for a specific skill
  List<SkillDataPoint> getSkillTrend(SkillType skillType) {
    final logsWithSkill = skillLogs
        .where((log) => log.skillScores.containsKey(skillType))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return logsWithSkill
        .map((log) => SkillDataPoint(
              date: log.date,
              score: log.getSkillScore(skillType),
            ))
        .toList();
  }

  /// Get overall performance trend (average of all skills)
  List<SkillDataPoint> get overallTrend {
    final logsByDate = <DateTime, List<int>>{};

    for (final log in skillLogs) {
      final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
      if (!logsByDate.containsKey(dateKey)) {
        logsByDate[dateKey] = [];
      }
      logsByDate[dateKey]!.addAll(log.skillScores.values);
    }

    final trendPoints = <SkillDataPoint>[];
    for (final entry in logsByDate.entries) {
      final averageScore = entry.value.isEmpty
          ? 0.0
          : entry.value.reduce((a, b) => a + b) / entry.value.length;
      trendPoints.add(SkillDataPoint(
        date: entry.key,
        score: averageScore.round(),
      ));
    }

    trendPoints.sort((a, b) => a.date.compareTo(b.date));
    return trendPoints;
  }

  /// Get skill progress (change from first to last log) for each skill type
  Map<SkillType, int> get skillProgress {
    final Map<SkillType, int> progress = {};

    for (final skillType in SkillType.allSkills) {
      final trend = getSkillTrend(skillType);
      if (trend.length >= 2) {
        final firstScore = trend.first.score;
        final lastScore = trend.last.score;
        progress[skillType] = lastScore - firstScore;
      } else {
        progress[skillType] = 0;
      }
    }

    return progress;
  }

  /// Get skill improvement percentage for each skill type
  Map<SkillType, double> get skillImprovements {
    final Map<SkillType, double> improvements = {};

    for (final skillType in SkillType.allSkills) {
      final trend = getSkillTrend(skillType);
      if (trend.length >= 2) {
        final firstScore = trend.first.score;
        final lastScore = trend.last.score;
        final improvement = firstScore > 0
            ? ((lastScore - firstScore) / firstScore) * 100
            : 0.0;
        improvements[skillType] = improvement;
      } else {
        improvements[skillType] = 0.0;
      }
    }

    return improvements;
  }

  /// Get active goals for each skill type
  Map<SkillType, Goal?> get activeGoalsBySkill {
    final Map<SkillType, Goal?> goalsBySkill = {};

    for (final skillType in SkillType.allSkills) {
      final activeGoal = skillGoals
          .where((goal) =>
              goal.skillType == skillType && goal.status == GoalStatus.active)
          .cast<Goal?>()
          .firstWhere((goal) => true, orElse: () => null);
      goalsBySkill[skillType] = activeGoal;
    }

    return goalsBySkill;
  }

  /// Get total number of training sessions
  int get totalSessions => skillLogs.length;

  /// Get average score across all skills and time
  double get overallAverageScore {
    if (skillLogs.isEmpty) return 0.0;

    final allScores =
        skillLogs.expand((log) => log.skillScores.values).toList();

    if (allScores.isEmpty) return 0.0;

    return allScores.reduce((a, b) => a + b) / allScores.length;
  }

  /// Get strongest skill (highest current score)
  SkillType? get strongestSkill {
    final currentScores = currentSkillScores;
    if (currentScores.isEmpty) return null;

    return currentScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get weakest skill (lowest current score)
  SkillType? get weakestSkill {
    final currentScores = currentSkillScores;
    if (currentScores.isEmpty) return null;

    return currentScores.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// Get most improved skill
  SkillType? get mostImprovedSkill {
    final improvements = skillImprovements;
    if (improvements.isEmpty) return null;

    return improvements.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get goals completion rate
  double get goalsCompletionRate {
    if (skillGoals.isEmpty) return 0.0;

    final completedGoals =
        skillGoals.where((goal) => goal.status == GoalStatus.achieved).length;

    return (completedGoals / skillGoals.length) * 100;
  }

  /// Check if player is improving overall
  bool get isImproving {
    final trend = overallTrend;
    if (trend.length < 2) return false;

    return trend.last.score > trend.first.score;
  }
}

/// Data point for skill trend charts
class SkillDataPoint {
  final DateTime date;
  final int score;

  const SkillDataPoint({
    required this.date,
    required this.score,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillDataPoint &&
        other.date == date &&
        other.score == score;
  }

  @override
  int get hashCode => date.hashCode ^ score.hashCode;

  @override
  String toString() => 'SkillDataPoint(date: $date, score: $score)';
}
