import 'package:cloud_firestore/cloud_firestore.dart';
import '../../skill_tracking/models/models.dart';
import '../../team/models/models.dart';

/// Model representing comprehensive analytics for a team
class TeamAnalytics {
  final String teamId;
  final String teamName;
  final SportType sportType;
  final int totalMembers;
  final Map<SkillType, double> averageSkillScores;
  final Map<String, PlayerPerformanceData> playerPerformances;
  final List<TeamPerformanceDataPoint> performanceHistory;
  final String? mostImprovedPlayerId;
  final double overallTeamScore;
  final DateTime lastUpdated;
  final Map<String, dynamic>? metadata;

  const TeamAnalytics({
    required this.teamId,
    required this.teamName,
    required this.sportType,
    required this.totalMembers,
    required this.averageSkillScores,
    required this.playerPerformances,
    required this.performanceHistory,
    this.mostImprovedPlayerId,
    required this.overallTeamScore,
    required this.lastUpdated,
    this.metadata,
  });

  /// Create from Firestore document
  factory TeamAnalytics.fromMap(Map<String, dynamic> map) {
    return TeamAnalytics(
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      sportType: SportType.values.firstWhere(
        (e) => e.name == map['sportType'],
        orElse: () => SportType.other,
      ),
      totalMembers: map['totalMembers'] ?? 0,
      averageSkillScores: Map<SkillType, double>.from(
        (map['averageSkillScores'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            SkillType.fromString(key),
            (value as num).toDouble(),
          ),
        ) ?? {},
      ),
      playerPerformances: Map<String, PlayerPerformanceData>.from(
        (map['playerPerformances'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            PlayerPerformanceData.fromMap(value as Map<String, dynamic>),
          ),
        ) ?? {},
      ),
      performanceHistory: (map['performanceHistory'] as List<dynamic>?)
          ?.map((item) => TeamPerformanceDataPoint.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      mostImprovedPlayerId: map['mostImprovedPlayerId'],
      overallTeamScore: (map['overallTeamScore'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'sportType': sportType.name,
      'totalMembers': totalMembers,
      'averageSkillScores': averageSkillScores.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'playerPerformances': playerPerformances.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'performanceHistory': performanceHistory.map((point) => point.toMap()).toList(),
      'mostImprovedPlayerId': mostImprovedPlayerId,
      'overallTeamScore': overallTeamScore,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'metadata': metadata,
    };
  }

  /// Get the strongest skill for the team
  SkillType? get strongestSkill {
    if (averageSkillScores.isEmpty) return null;
    return averageSkillScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the weakest skill for the team
  SkillType? get weakestSkill {
    if (averageSkillScores.isEmpty) return null;
    return averageSkillScores.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// Get team improvement percentage over time
  double get improvementPercentage {
    if (performanceHistory.length < 2) return 0.0;
    
    final firstScore = performanceHistory.first.averageScore;
    final lastScore = performanceHistory.last.averageScore;
    
    if (firstScore == 0) return 0.0;
    
    return ((lastScore - firstScore) / firstScore) * 100;
  }

  /// Check if team is improving
  bool get isImproving => improvementPercentage > 0;

  /// Get top performing players (top 3)
  List<String> get topPerformers {
    final sortedPlayers = playerPerformances.entries.toList()
      ..sort((a, b) => b.value.overallScore.compareTo(a.value.overallScore));
    
    return sortedPlayers.take(3).map((entry) => entry.key).toList();
  }

  /// Get players who need improvement (bottom 3)
  List<String> get playersNeedingImprovement {
    final sortedPlayers = playerPerformances.entries.toList()
      ..sort((a, b) => a.value.overallScore.compareTo(b.value.overallScore));
    
    return sortedPlayers.take(3).map((entry) => entry.key).toList();
  }

  /// Copy with updated values
  TeamAnalytics copyWith({
    String? teamId,
    String? teamName,
    SportType? sportType,
    int? totalMembers,
    Map<SkillType, double>? averageSkillScores,
    Map<String, PlayerPerformanceData>? playerPerformances,
    List<TeamPerformanceDataPoint>? performanceHistory,
    String? mostImprovedPlayerId,
    double? overallTeamScore,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return TeamAnalytics(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      sportType: sportType ?? this.sportType,
      totalMembers: totalMembers ?? this.totalMembers,
      averageSkillScores: averageSkillScores ?? this.averageSkillScores,
      playerPerformances: playerPerformances ?? this.playerPerformances,
      performanceHistory: performanceHistory ?? this.performanceHistory,
      mostImprovedPlayerId: mostImprovedPlayerId ?? this.mostImprovedPlayerId,
      overallTeamScore: overallTeamScore ?? this.overallTeamScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Model representing individual player performance data within a team context
class PlayerPerformanceData {
  final String playerId;
  final String playerName;
  final String? playerEmail;
  final String? profileImageUrl;
  final Map<SkillType, int> currentSkillScores;
  final Map<SkillType, double> improvementPercentages;
  final double overallScore;
  final int totalSessions;
  final DateTime lastActiveDate;
  final bool isActive;

  const PlayerPerformanceData({
    required this.playerId,
    required this.playerName,
    this.playerEmail,
    this.profileImageUrl,
    required this.currentSkillScores,
    required this.improvementPercentages,
    required this.overallScore,
    required this.totalSessions,
    required this.lastActiveDate,
    this.isActive = true,
  });

  /// Create from map
  factory PlayerPerformanceData.fromMap(Map<String, dynamic> map) {
    return PlayerPerformanceData(
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      playerEmail: map['playerEmail'],
      profileImageUrl: map['profileImageUrl'],
      currentSkillScores: Map<SkillType, int>.from(
        (map['currentSkillScores'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            SkillType.fromString(key),
            value as int,
          ),
        ) ?? {},
      ),
      improvementPercentages: Map<SkillType, double>.from(
        (map['improvementPercentages'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            SkillType.fromString(key),
            (value as num).toDouble(),
          ),
        ) ?? {},
      ),
      overallScore: (map['overallScore'] as num?)?.toDouble() ?? 0.0,
      totalSessions: map['totalSessions'] ?? 0,
      lastActiveDate: (map['lastActiveDate'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'playerEmail': playerEmail,
      'profileImageUrl': profileImageUrl,
      'currentSkillScores': currentSkillScores.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'improvementPercentages': improvementPercentages.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'overallScore': overallScore,
      'totalSessions': totalSessions,
      'lastActiveDate': Timestamp.fromDate(lastActiveDate),
      'isActive': isActive,
    };
  }

  /// Get strongest skill for this player
  SkillType? get strongestSkill {
    if (currentSkillScores.isEmpty) return null;
    return currentSkillScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get most improved skill for this player
  SkillType? get mostImprovedSkill {
    if (improvementPercentages.isEmpty) return null;
    return improvementPercentages.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Check if player is actively improving
  bool get isImproving {
    final totalImprovement = improvementPercentages.values
        .fold(0.0, (total, improvement) => total + improvement);
    return totalImprovement > 0;
  }
}

/// Model representing team performance at a specific point in time
class TeamPerformanceDataPoint {
  final DateTime date;
  final double averageScore;
  final Map<SkillType, double> skillAverages;
  final int activePlayers;
  final Map<String, dynamic>? metadata;

  const TeamPerformanceDataPoint({
    required this.date,
    required this.averageScore,
    required this.skillAverages,
    required this.activePlayers,
    this.metadata,
  });

  /// Create from map
  factory TeamPerformanceDataPoint.fromMap(Map<String, dynamic> map) {
    return TeamPerformanceDataPoint(
      date: (map['date'] as Timestamp).toDate(),
      averageScore: (map['averageScore'] as num).toDouble(),
      skillAverages: Map<SkillType, double>.from(
        (map['skillAverages'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            SkillType.fromString(key),
            (value as num).toDouble(),
          ),
        ),
      ),
      activePlayers: map['activePlayers'] ?? 0,
      metadata: map['metadata'],
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'averageScore': averageScore,
      'skillAverages': skillAverages.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'activePlayers': activePlayers,
      'metadata': metadata,
    };
  }
}
