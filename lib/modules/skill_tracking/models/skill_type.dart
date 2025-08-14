/// Enumeration of different skill types that can be tracked
enum SkillType {
  speed,
  strength,
  endurance,
  accuracy,
  teamwork;

  /// Get display name for the skill type
  String get displayName {
    switch (this) {
      case SkillType.speed:
        return 'Speed';
      case SkillType.strength:
        return 'Strength';
      case SkillType.endurance:
        return 'Endurance';
      case SkillType.accuracy:
        return 'Accuracy';
      case SkillType.teamwork:
        return 'Teamwork';
    }
  }

  /// Get description for the skill type
  String get description {
    switch (this) {
      case SkillType.speed:
        return 'Measures player\'s movement speed and agility';
      case SkillType.strength:
        return 'Measures player\'s physical power and muscle strength';
      case SkillType.endurance:
        return 'Measures player\'s stamina and cardiovascular fitness';
      case SkillType.accuracy:
        return 'Measures player\'s precision and technical skills';
      case SkillType.teamwork:
        return 'Measures player\'s collaboration and communication skills';
    }
  }

  /// Convert from string to enum
  static SkillType fromString(String value) {
    return SkillType.values.firstWhere(
      (skill) => skill.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkillType.speed,
    );
  }

  /// Get all skill types as a list
  static List<SkillType> get allSkills => SkillType.values;

  /// Get skill type color for UI representation
  String get colorHex {
    switch (this) {
      case SkillType.speed:
        return '#FF6B6B'; // Red
      case SkillType.strength:
        return '#4ECDC4'; // Teal
      case SkillType.endurance:
        return '#45B7D1'; // Blue
      case SkillType.accuracy:
        return '#96CEB4'; // Green
      case SkillType.teamwork:
        return '#FFEAA7'; // Yellow
    }
  }

  /// Get skill type icon for UI representation
  String get iconName {
    switch (this) {
      case SkillType.speed:
        return 'speed';
      case SkillType.strength:
        return 'fitness_center';
      case SkillType.endurance:
        return 'directions_run';
      case SkillType.accuracy:
        return 'gps_fixed';
      case SkillType.teamwork:
        return 'group';
    }
  }
}
