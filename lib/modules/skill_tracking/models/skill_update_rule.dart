import '../../../models/models.dart';

/// Configuration for skill update rules and calculations
class SkillUpdateConfig {
  // Booking-based updates
  static const int baseBookingBonus = 3;
  static const int longSessionBonus = 2; // For sessions > 60 minutes
  static const int frequencyBonus = 1; // For multiple sessions per week
  
  // Tournament-based updates
  static const int tournamentParticipationBonus = 8;
  static const int tournamentWinBonus = 5;
  static const int teamworkTournamentBonus = 10;
  
  // Feedback-based updates
  static const int excellentFeedbackBonus = 8;
  static const int goodFeedbackBonus = 5;
  static const int averageFeedbackBonus = 2;
  
  // Decay settings
  static const int inactivityThresholdDays = 10;
  static const int decayPerWeek = 2;
  static const int maxDecayPerSession = 10;
  
  // Skill caps
  static const int minSkillScore = 0;
  static const int maxSkillScore = 100;
}

/// Represents a skill update calculation result
class SkillUpdateResult {
  final Map<SkillType, int> skillChanges;
  final String context;
  final SkillLogSource source;
  final Map<String, dynamic>? metadata;

  const SkillUpdateResult({
    required this.skillChanges,
    required this.context,
    required this.source,
    this.metadata,
  });

  /// Check if any skills were updated
  bool get hasChanges => skillChanges.values.any((change) => change != 0);

  /// Get total positive changes
  int get totalPositiveChanges {
    return skillChanges.values.where((change) => change > 0).fold(0, (total, change) => total + change);
  }

  /// Get total negative changes
  int get totalNegativeChanges {
    return skillChanges.values.where((change) => change < 0).fold(0, (total, change) => total + change.abs());
  }
}

/// Rules engine for calculating skill updates based on different events
class SkillUpdateRules {
  
  /// Calculate skill updates from booking completion
  static SkillUpdateResult calculateBookingUpdate({
    required SportType sportType,
    required double sessionDurationHours,
    required int recentSessionsCount, // Sessions in last 7 days
    required String context,
    Map<String, dynamic>? metadata,
  }) {
    final Map<SkillType, int> changes = {};
    
    // Base updates for all sports
    int speedBonus = SkillUpdateConfig.baseBookingBonus;
    int enduranceBonus = SkillUpdateConfig.baseBookingBonus;
    int strengthBonus = SkillUpdateConfig.baseBookingBonus;
    int accuracyBonus = SkillUpdateConfig.baseBookingBonus;
    int teamworkBonus = 1; // Lower for individual sessions
    
    // Sport-specific bonuses
    switch (sportType) {
      case SportType.football:
        speedBonus += 2;
        enduranceBonus += 3;
        teamworkBonus += 2;
        break;
      case SportType.basketball:
        accuracyBonus += 2;
        speedBonus += 1;
        teamworkBonus += 2;
        break;
      case SportType.tennis:
        accuracyBonus += 3;
        speedBonus += 2;
        break;
      case SportType.badminton:
        accuracyBonus += 2;
        speedBonus += 2;
        break;
      case SportType.cricket:
        accuracyBonus += 2;
        strengthBonus += 1;
        teamworkBonus += 1;
        break;
      case SportType.swimming:
        enduranceBonus += 4;
        strengthBonus += 2;
        break;
      case SportType.running:
        enduranceBonus += 4;
        speedBonus += 3;
        break;
      case SportType.cycling:
        enduranceBonus += 3;
        strengthBonus += 1;
        break;
      case SportType.volleyball:
        speedBonus += 1;
        teamworkBonus += 2;
        break;
      case SportType.other:
        // Generic bonuses for other sports
        speedBonus += 1;
        enduranceBonus += 1;
        strengthBonus += 1;
        break;
      // Note: gym and yoga are not defined in SportType enum
      // These would need to be added to the SportType enum if needed
    }
    
    // Duration bonuses
    if (sessionDurationHours >= 1.0) {
      speedBonus += SkillUpdateConfig.longSessionBonus;
      enduranceBonus += SkillUpdateConfig.longSessionBonus;
      strengthBonus += SkillUpdateConfig.longSessionBonus;
    }
    
    // Frequency bonuses (consistency reward)
    if (recentSessionsCount >= 3) {
      speedBonus += SkillUpdateConfig.frequencyBonus;
      enduranceBonus += SkillUpdateConfig.frequencyBonus;
      strengthBonus += SkillUpdateConfig.frequencyBonus;
    }
    
    changes[SkillType.speed] = speedBonus;
    changes[SkillType.endurance] = enduranceBonus;
    changes[SkillType.strength] = strengthBonus;
    changes[SkillType.accuracy] = accuracyBonus;
    changes[SkillType.teamwork] = teamworkBonus;
    
    return SkillUpdateResult(
      skillChanges: changes,
      context: context,
      source: SkillLogSource.booking,
      metadata: metadata,
    );
  }

  /// Calculate skill updates from tournament participation
  static SkillUpdateResult calculateTournamentUpdate({
    required SportType sportType,
    required bool isTeamTournament,
    required bool didWin,
    required String context,
    Map<String, dynamic>? metadata,
  }) {
    final Map<SkillType, int> changes = {};
    
    // Base tournament bonuses
    int speedBonus = 5;
    int enduranceBonus = SkillUpdateConfig.tournamentParticipationBonus;
    int strengthBonus = 3;
    int accuracyBonus = 5;
    int teamworkBonus = isTeamTournament ? SkillUpdateConfig.teamworkTournamentBonus : 3;
    
    // Win bonuses
    if (didWin) {
      speedBonus += SkillUpdateConfig.tournamentWinBonus;
      enduranceBonus += SkillUpdateConfig.tournamentWinBonus;
      strengthBonus += SkillUpdateConfig.tournamentWinBonus;
      accuracyBonus += SkillUpdateConfig.tournamentWinBonus;
      teamworkBonus += SkillUpdateConfig.tournamentWinBonus;
    }
    
    changes[SkillType.speed] = speedBonus;
    changes[SkillType.endurance] = enduranceBonus;
    changes[SkillType.strength] = strengthBonus;
    changes[SkillType.accuracy] = accuracyBonus;
    changes[SkillType.teamwork] = teamworkBonus;
    
    return SkillUpdateResult(
      skillChanges: changes,
      context: context,
      source: SkillLogSource.tournament,
      metadata: metadata,
    );
  }

  /// Calculate skill updates from feedback/ratings
  static SkillUpdateResult calculateFeedbackUpdate({
    required double rating, // 1-5 stars
    required Map<SkillType, int>? specificSkillFeedback,
    required String context,
    Map<String, dynamic>? metadata,
  }) {
    final Map<SkillType, int> changes = {};
    
    // Base bonus from overall rating
    int baseBonus = 0;
    if (rating >= 4.5) {
      baseBonus = SkillUpdateConfig.excellentFeedbackBonus;
    } else if (rating >= 3.5) {
      baseBonus = SkillUpdateConfig.goodFeedbackBonus;
    } else if (rating >= 2.5) {
      baseBonus = SkillUpdateConfig.averageFeedbackBonus;
    }
    
    // Apply base bonus to teamwork (feedback implies good collaboration)
    changes[SkillType.teamwork] = baseBonus;
    
    // Apply specific skill feedback if provided
    if (specificSkillFeedback != null) {
      for (final entry in specificSkillFeedback.entries) {
        changes[entry.key] = (changes[entry.key] ?? 0) + entry.value;
      }
    } else {
      // Distribute base bonus across all skills
      changes[SkillType.speed] = baseBonus ~/ 2;
      changes[SkillType.endurance] = baseBonus ~/ 2;
      changes[SkillType.strength] = baseBonus ~/ 2;
      changes[SkillType.accuracy] = baseBonus ~/ 2;
    }
    
    return SkillUpdateResult(
      skillChanges: changes,
      context: context,
      source: SkillLogSource.feedback,
      metadata: metadata,
    );
  }

  /// Calculate skill decay for inactive users
  static SkillUpdateResult calculateInactivityDecay({
    required int daysSinceLastActivity,
    required Map<SkillType, int> currentSkills,
    required String context,
  }) {
    final Map<SkillType, int> changes = {};
    
    if (daysSinceLastActivity < SkillUpdateConfig.inactivityThresholdDays) {
      // No decay needed
      return SkillUpdateResult(
        skillChanges: changes,
        context: context,
        source: SkillLogSource.systemDecay,
      );
    }
    
    // Calculate weeks of inactivity
    final weeksInactive = (daysSinceLastActivity - SkillUpdateConfig.inactivityThresholdDays) ~/ 7;
    final decayAmount = (weeksInactive * SkillUpdateConfig.decayPerWeek)
        .clamp(0, SkillUpdateConfig.maxDecayPerSession);
    
    // Apply decay to all skills, but don't go below 0
    for (final skillType in SkillType.values) {
      final currentScore = currentSkills[skillType] ?? 0;
      final decay = -decayAmount.clamp(0, currentScore);
      if (decay < 0) {
        changes[skillType] = decay;
      }
    }
    
    return SkillUpdateResult(
      skillChanges: changes,
      context: context,
      source: SkillLogSource.systemDecay,
      metadata: {
        'daysSinceLastActivity': daysSinceLastActivity,
        'weeksInactive': weeksInactive,
        'decayAmount': decayAmount,
      },
    );
  }

  /// Clamp skill scores to valid range
  static Map<SkillType, int> clampSkillScores(Map<SkillType, int> scores) {
    final Map<SkillType, int> clampedScores = {};
    for (final entry in scores.entries) {
      clampedScores[entry.key] = entry.value.clamp(
        SkillUpdateConfig.minSkillScore,
        SkillUpdateConfig.maxSkillScore,
      );
    }
    return clampedScores;
  }
}
