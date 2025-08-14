import '../../skill_tracking/models/models.dart';
import 'team_analytics.dart';

/// Model for comparing two players side by side
class PlayerComparison {
  final PlayerPerformanceData player1;
  final PlayerPerformanceData player2;
  final Map<SkillType, ComparisonResult> skillComparisons;
  final ComparisonSummary summary;
  final DateTime comparisonDate;

  const PlayerComparison({
    required this.player1,
    required this.player2,
    required this.skillComparisons,
    required this.summary,
    required this.comparisonDate,
  });

  /// Create comparison between two players
  factory PlayerComparison.create({
    required PlayerPerformanceData player1,
    required PlayerPerformanceData player2,
  }) {
    final skillComparisons = <SkillType, ComparisonResult>{};
    
    // Compare each skill
    for (final skillType in SkillType.allSkills) {
      final player1Score = player1.currentSkillScores[skillType] ?? 0;
      final player2Score = player2.currentSkillScores[skillType] ?? 0;
      final player1Improvement = player1.improvementPercentages[skillType] ?? 0.0;
      final player2Improvement = player2.improvementPercentages[skillType] ?? 0.0;
      
      skillComparisons[skillType] = ComparisonResult(
        skillType: skillType,
        player1Score: player1Score,
        player2Score: player2Score,
        player1Improvement: player1Improvement,
        player2Improvement: player2Improvement,
        scoreDifference: player1Score - player2Score,
        improvementDifference: player1Improvement - player2Improvement,
      );
    }

    // Create summary
    final summary = ComparisonSummary.create(
      player1: player1,
      player2: player2,
      skillComparisons: skillComparisons,
    );

    return PlayerComparison(
      player1: player1,
      player2: player2,
      skillComparisons: skillComparisons,
      summary: summary,
      comparisonDate: DateTime.now(),
    );
  }

  /// Get skills where player 1 is stronger
  List<SkillType> get player1StrongerSkills {
    return skillComparisons.entries
        .where((entry) => entry.value.scoreDifference > 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get skills where player 2 is stronger
  List<SkillType> get player2StrongerSkills {
    return skillComparisons.entries
        .where((entry) => entry.value.scoreDifference < 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get skills where players are equal (within 5 points)
  List<SkillType> get equalSkills {
    return skillComparisons.entries
        .where((entry) => entry.value.scoreDifference.abs() <= 5)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get the skill with the biggest difference
  SkillType? get biggestDifferenceSkill {
    if (skillComparisons.isEmpty) return null;
    
    return skillComparisons.entries
        .reduce((a, b) => a.value.scoreDifference.abs() > b.value.scoreDifference.abs() ? a : b)
        .key;
  }

  /// Get skills where player 1 is improving faster
  List<SkillType> get player1ImprovingFasterSkills {
    return skillComparisons.entries
        .where((entry) => entry.value.improvementDifference > 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get skills where player 2 is improving faster
  List<SkillType> get player2ImprovingFasterSkills {
    return skillComparisons.entries
        .where((entry) => entry.value.improvementDifference < 0)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Result of comparing a specific skill between two players
class ComparisonResult {
  final SkillType skillType;
  final int player1Score;
  final int player2Score;
  final double player1Improvement;
  final double player2Improvement;
  final int scoreDifference; // player1 - player2
  final double improvementDifference; // player1 - player2

  const ComparisonResult({
    required this.skillType,
    required this.player1Score,
    required this.player2Score,
    required this.player1Improvement,
    required this.player2Improvement,
    required this.scoreDifference,
    required this.improvementDifference,
  });

  /// Get the winner for current score
  PlayerComparisonWinner get scoreWinner {
    if (scoreDifference > 5) return PlayerComparisonWinner.player1;
    if (scoreDifference < -5) return PlayerComparisonWinner.player2;
    return PlayerComparisonWinner.tie;
  }

  /// Get the winner for improvement rate
  PlayerComparisonWinner get improvementWinner {
    if (improvementDifference > 2.0) return PlayerComparisonWinner.player1;
    if (improvementDifference < -2.0) return PlayerComparisonWinner.player2;
    return PlayerComparisonWinner.tie;
  }

  /// Get percentage difference in scores
  double get scorePercentageDifference {
    final maxScore = [player1Score, player2Score].reduce((a, b) => a > b ? a : b);
    if (maxScore == 0) return 0.0;
    return (scoreDifference.abs() / maxScore) * 100;
  }
}

/// Summary of the overall comparison between two players
class ComparisonSummary {
  final String overallWinner; // player1, player2, or tie
  final int player1WinCount;
  final int player2WinCount;
  final int tieCount;
  final double player1OverallScore;
  final double player2OverallScore;
  final double overallScoreDifference;
  final String player1StrongestSkill;
  final String player2StrongestSkill;
  final String mostImprovedPlayer;
  final List<String> recommendations;

  const ComparisonSummary({
    required this.overallWinner,
    required this.player1WinCount,
    required this.player2WinCount,
    required this.tieCount,
    required this.player1OverallScore,
    required this.player2OverallScore,
    required this.overallScoreDifference,
    required this.player1StrongestSkill,
    required this.player2StrongestSkill,
    required this.mostImprovedPlayer,
    required this.recommendations,
  });

  /// Create summary from comparison data
  factory ComparisonSummary.create({
    required PlayerPerformanceData player1,
    required PlayerPerformanceData player2,
    required Map<SkillType, ComparisonResult> skillComparisons,
  }) {
    int player1Wins = 0;
    int player2Wins = 0;
    int ties = 0;

    // Count wins for each player
    for (final comparison in skillComparisons.values) {
      switch (comparison.scoreWinner) {
        case PlayerComparisonWinner.player1:
          player1Wins++;
          break;
        case PlayerComparisonWinner.player2:
          player2Wins++;
          break;
        case PlayerComparisonWinner.tie:
          ties++;
          break;
      }
    }

    // Determine overall winner
    String overallWinner;
    if (player1Wins > player2Wins) {
      overallWinner = 'player1';
    } else if (player2Wins > player1Wins) {
      overallWinner = 'player2';
    } else {
      overallWinner = 'tie';
    }

    // Calculate overall scores
    final player1OverallScore = player1.overallScore;
    final player2OverallScore = player2.overallScore;
    final overallScoreDifference = player1OverallScore - player2OverallScore;

    // Find strongest skills
    final player1StrongestSkill = player1.strongestSkill?.displayName ?? 'None';
    final player2StrongestSkill = player2.strongestSkill?.displayName ?? 'None';

    // Determine most improved player
    final player1TotalImprovement = player1.improvementPercentages.values
        .fold(0.0, (sum, improvement) => sum + improvement);
    final player2TotalImprovement = player2.improvementPercentages.values
        .fold(0.0, (sum, improvement) => sum + improvement);
    
    final mostImprovedPlayer = player1TotalImprovement > player2TotalImprovement
        ? player1.playerName
        : player2.playerName;

    // Generate recommendations
    final recommendations = _generateRecommendations(
      player1: player1,
      player2: player2,
      skillComparisons: skillComparisons,
    );

    return ComparisonSummary(
      overallWinner: overallWinner,
      player1WinCount: player1Wins,
      player2WinCount: player2Wins,
      tieCount: ties,
      player1OverallScore: player1OverallScore,
      player2OverallScore: player2OverallScore,
      overallScoreDifference: overallScoreDifference,
      player1StrongestSkill: player1StrongestSkill,
      player2StrongestSkill: player2StrongestSkill,
      mostImprovedPlayer: mostImprovedPlayer,
      recommendations: recommendations,
    );
  }

  /// Generate coaching recommendations based on comparison
  static List<String> _generateRecommendations({
    required PlayerPerformanceData player1,
    required PlayerPerformanceData player2,
    required Map<SkillType, ComparisonResult> skillComparisons,
  }) {
    final recommendations = <String>[];

    // Find areas where each player needs improvement
    final player1WeakSkills = <SkillType>[];
    final player2WeakSkills = <SkillType>[];

    for (final entry in skillComparisons.entries) {
      final skillType = entry.key;
      final comparison = entry.value;

      if (comparison.player1Score < 60) {
        player1WeakSkills.add(skillType);
      }
      if (comparison.player2Score < 60) {
        player2WeakSkills.add(skillType);
      }
    }

    // Generate recommendations for player 1
    if (player1WeakSkills.isNotEmpty) {
      recommendations.add(
        '${player1.playerName} should focus on improving: ${player1WeakSkills.map((s) => s.displayName).join(', ')}',
      );
    }

    // Generate recommendations for player 2
    if (player2WeakSkills.isNotEmpty) {
      recommendations.add(
        '${player2.playerName} should focus on improving: ${player2WeakSkills.map((s) => s.displayName).join(', ')}',
      );
    }

    // Suggest pairing opportunities
    final player1Strengths = skillComparisons.entries
        .where((entry) => entry.value.scoreDifference > 10)
        .map((entry) => entry.key)
        .toList();
    
    final player2Strengths = skillComparisons.entries
        .where((entry) => entry.value.scoreDifference < -10)
        .map((entry) => entry.key)
        .toList();

    if (player1Strengths.isNotEmpty && player2WeakSkills.any(player1Strengths.contains)) {
      recommendations.add(
        '${player1.playerName} could mentor ${player2.playerName} in their strong areas',
      );
    }

    if (player2Strengths.isNotEmpty && player1WeakSkills.any(player2Strengths.contains)) {
      recommendations.add(
        '${player2.playerName} could mentor ${player1.playerName} in their strong areas',
      );
    }

    return recommendations;
  }
}

/// Enum for comparison winners
enum PlayerComparisonWinner {
  player1,
  player2,
  tie;

  String get displayName {
    switch (this) {
      case PlayerComparisonWinner.player1:
        return 'Player 1';
      case PlayerComparisonWinner.player2:
        return 'Player 2';
      case PlayerComparisonWinner.tie:
        return 'Tie';
    }
  }
}
