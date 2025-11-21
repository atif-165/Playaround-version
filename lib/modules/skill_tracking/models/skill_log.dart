import 'package:cloud_firestore/cloud_firestore.dart';
import 'skill_type.dart';

/// Enum for skill log sources to track how skills were updated
enum SkillLogSource {
  manual, // Manually logged by coach
  booking, // Auto-updated from booking completion
  tournament, // Auto-updated from tournament participation
  feedback, // Updated from coach/teammate feedback
  systemDecay, // Auto-decay for inactivity
  teamActivity, // Updated from team activities
  achievement; // Updated from achievements/milestones

  String get displayName {
    switch (this) {
      case SkillLogSource.manual:
        return 'Manual Entry';
      case SkillLogSource.booking:
        return 'Session Completion';
      case SkillLogSource.tournament:
        return 'Tournament Participation';
      case SkillLogSource.feedback:
        return 'Performance Feedback';
      case SkillLogSource.systemDecay:
        return 'Inactivity Decay';
      case SkillLogSource.teamActivity:
        return 'Team Activity';
      case SkillLogSource.achievement:
        return 'Achievement Unlock';
    }
  }

  /// Convert from string to enum
  static SkillLogSource fromString(String value) {
    return SkillLogSource.values.firstWhere(
      (source) => source.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkillLogSource.manual,
    );
  }
}

/// Model representing a single skill performance log entry with enhanced tracking
class SkillLog {
  final String id;
  final String playerId;
  final String
      loggedBy; // Coach UID who logged this entry (or 'system' for automated)
  final DateTime date;
  final Map<SkillType, int> skillScores; // Scores out of 100 for each skill
  final Map<SkillType, int> skillChanges; // Changes applied (+/- values)
  final SkillLogSource source; // How this log was created
  final String?
      context; // Additional context (e.g., "45-min football session with Coach John")
  final String? notes;
  final Map<String, dynamic>?
      metadata; // Additional data (booking ID, tournament ID, etc.)
  final DateTime createdAt;
  final DateTime updatedAt;

  const SkillLog({
    required this.id,
    required this.playerId,
    required this.loggedBy,
    required this.date,
    required this.skillScores,
    required this.skillChanges,
    required this.source,
    this.context,
    this.notes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create SkillLog from Firestore document
  factory SkillLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert skill scores from Map<String, dynamic> to Map<SkillType, int>
    final Map<SkillType, int> scores = {};
    final skillScoresData = data['skillScores'] as Map<String, dynamic>? ?? {};

    for (final entry in skillScoresData.entries) {
      try {
        final skillType = SkillType.fromString(entry.key);
        final score = (entry.value as num).toInt().clamp(0, 100);
        scores[skillType] = score;
      } catch (e) {
        // Skip invalid skill types
        continue;
      }
    }

    // Convert skill changes from Map<String, dynamic> to Map<SkillType, int>
    final Map<SkillType, int> changes = {};
    final skillChangesData =
        data['skillChanges'] as Map<String, dynamic>? ?? {};

    for (final entry in skillChangesData.entries) {
      try {
        final skillType = SkillType.fromString(entry.key);
        final change = (entry.value as num).toInt();
        changes[skillType] = change;
      } catch (e) {
        // Skip invalid skill types
        continue;
      }
    }

    return SkillLog(
      id: doc.id,
      playerId: data['playerId'] as String? ?? '',
      loggedBy: data['loggedBy'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      skillScores: scores,
      skillChanges: changes,
      source: SkillLogSource.fromString(data['source'] as String? ?? 'manual'),
      context: data['context'] as String?,
      notes: data['notes'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert SkillLog to Firestore document
  Map<String, dynamic> toFirestore() {
    // Convert skill scores from Map<SkillType, int> to Map<String, dynamic>
    final Map<String, dynamic> skillScoresData = {};
    for (final entry in skillScores.entries) {
      skillScoresData[entry.key.name] = entry.value;
    }

    // Convert skill changes from Map<SkillType, int> to Map<String, dynamic>
    final Map<String, dynamic> skillChangesData = {};
    for (final entry in skillChanges.entries) {
      skillChangesData[entry.key.name] = entry.value;
    }

    return {
      'playerId': playerId,
      'loggedBy': loggedBy,
      'date': Timestamp.fromDate(date),
      'skillScores': skillScoresData,
      'skillChanges': skillChangesData,
      'source': source.name,
      'context': context,
      'notes': notes,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated values
  SkillLog copyWith({
    String? id,
    String? playerId,
    String? loggedBy,
    DateTime? date,
    Map<SkillType, int>? skillScores,
    Map<SkillType, int>? skillChanges,
    SkillLogSource? source,
    String? context,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkillLog(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      loggedBy: loggedBy ?? this.loggedBy,
      date: date ?? this.date,
      skillScores: skillScores ?? this.skillScores,
      skillChanges: skillChanges ?? this.skillChanges,
      source: source ?? this.source,
      context: context ?? this.context,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get score for a specific skill type
  int getSkillScore(SkillType skillType) {
    return skillScores[skillType] ?? 0;
  }

  /// Get change for a specific skill type
  int getSkillChange(SkillType skillType) {
    return skillChanges[skillType] ?? 0;
  }

  /// Check if this log was automatically generated
  bool get isAutomated => source != SkillLogSource.manual;

  /// Check if this log represents a positive change
  bool get hasPositiveChanges {
    return skillChanges.values.any((change) => change > 0);
  }

  /// Check if this log represents a negative change (decay)
  bool get hasNegativeChanges {
    return skillChanges.values.any((change) => change < 0);
  }

  /// Get total positive changes
  int get totalPositiveChanges {
    return skillChanges.values
        .where((change) => change > 0)
        .fold(0, (total, change) => total + change);
  }

  /// Get total negative changes
  int get totalNegativeChanges {
    return skillChanges.values
        .where((change) => change < 0)
        .fold(0, (total, change) => total + change.abs());
  }

  /// Get formatted context for display
  String get displayContext {
    if (context != null && context!.isNotEmpty) {
      return context!;
    }

    switch (source) {
      case SkillLogSource.booking:
        return 'Training session completed';
      case SkillLogSource.tournament:
        return 'Tournament participation';
      case SkillLogSource.feedback:
        return 'Performance feedback received';
      case SkillLogSource.systemDecay:
        return 'Inactivity adjustment';
      case SkillLogSource.teamActivity:
        return 'Team activity participation';
      case SkillLogSource.achievement:
        return 'Achievement unlocked';
      case SkillLogSource.manual:
        return 'Manual assessment';
    }
  }

  /// Get average score across all skills
  double get averageScore {
    if (skillScores.isEmpty) return 0.0;
    final total = skillScores.values.reduce((a, b) => a + b);
    return total / skillScores.length;
  }

  /// Check if this log has all skill types recorded
  bool get isComplete {
    return SkillType.allSkills.every((skill) => skillScores.containsKey(skill));
  }

  /// Get formatted date string
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SkillLog(id: $id, playerId: $playerId, date: $date, averageScore: ${averageScore.toStringAsFixed(1)})';
  }
}
