import 'package:cloud_firestore/cloud_firestore.dart';
import 'skill_type.dart';

/// Status of a skill goal
enum GoalStatus {
  active('Active', 'Goal is currently being pursued'),
  achieved('Achieved', 'Goal has been successfully completed'),
  paused('Paused', 'Goal is temporarily on hold'),
  cancelled('Cancelled', 'Goal has been cancelled');

  const GoalStatus(this.displayName, this.description);

  final String displayName;
  final String description;

  static GoalStatus fromString(String value) {
    return GoalStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GoalStatus.active,
    );
  }
}

/// Model representing a player's skill improvement goal
class SkillGoal {
  final String id;
  final String playerId;
  final SkillType skillType;
  final int currentScore;
  final int targetScore;
  final DateTime targetDate;
  final GoalStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? achievedAt;

  const SkillGoal({
    required this.id,
    required this.playerId,
    required this.skillType,
    required this.currentScore,
    required this.targetScore,
    required this.targetDate,
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.achievedAt,
  });

  /// Create SkillGoal from Firestore document
  factory SkillGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SkillGoal(
      id: doc.id,
      playerId: data['playerId'] as String? ?? '',
      skillType: SkillType.fromString(data['skillType'] as String? ?? 'speed'),
      currentScore: (data['currentScore'] as num?)?.toInt().clamp(0, 100) ?? 0,
      targetScore: (data['targetScore'] as num?)?.toInt().clamp(0, 100) ?? 100,
      targetDate: (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: GoalStatus.fromString(data['status'] as String? ?? 'active'),
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      achievedAt: (data['achievedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert SkillGoal to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'playerId': playerId,
      'skillType': skillType.name,
      'currentScore': currentScore,
      'targetScore': targetScore,
      'targetDate': Timestamp.fromDate(targetDate),
      'status': status.name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'achievedAt': achievedAt != null ? Timestamp.fromDate(achievedAt!) : null,
    };
  }

  /// Create a copy with updated values
  SkillGoal copyWith({
    String? id,
    String? playerId,
    SkillType? skillType,
    int? currentScore,
    int? targetScore,
    DateTime? targetDate,
    GoalStatus? status,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? achievedAt,
  }) {
    return SkillGoal(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      skillType: skillType ?? this.skillType,
      currentScore: currentScore ?? this.currentScore,
      targetScore: targetScore ?? this.targetScore,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  /// Calculate progress percentage (0-100)
  double get progressPercentage {
    if (targetScore <= currentScore) return 100.0;
    final progress = ((currentScore / targetScore) * 100).clamp(0.0, 100.0);
    return progress;
  }

  /// Get remaining points needed to achieve goal
  int get remainingPoints {
    return (targetScore - currentScore).clamp(0, 100);
  }

  /// Check if goal is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && status == GoalStatus.active;
  }

  /// Get days remaining until target date
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays;
  }

  /// Get formatted target date string
  String get formattedTargetDate {
    return '${targetDate.day}/${targetDate.month}/${targetDate.year}';
  }

  /// Check if goal can be marked as achieved
  bool get canBeAchieved {
    return status == GoalStatus.active && currentScore >= targetScore;
  }

  /// Mark goal as achieved
  SkillGoal markAsAchieved() {
    return copyWith(
      status: GoalStatus.achieved,
      achievedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update current score and check if goal is achieved
  SkillGoal updateScore(int newScore) {
    final updatedGoal = copyWith(
      currentScore: newScore.clamp(0, 100),
      updatedAt: DateTime.now(),
    );

    // Auto-achieve if target is reached
    if (updatedGoal.canBeAchieved) {
      return updatedGoal.markAsAchieved();
    }

    return updatedGoal;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SkillGoal(id: $id, skillType: ${skillType.displayName}, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}
