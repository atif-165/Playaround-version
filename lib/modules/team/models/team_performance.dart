import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking individual player performance
class PlayerPerformance {
  final String playerId;
  final String playerName;
  final String teamId;
  final int matchesPlayed;
  final int goalsScored;
  final int assists;
  final int saves; // For goalkeepers
  final int yellowCards;
  final int redCards;
  final double winRatio;
  final double averageRating;
  final Map<String, dynamic> customStats; // Sport-specific stats
  final DateTime lastUpdated;

  const PlayerPerformance({
    required this.playerId,
    required this.playerName,
    required this.teamId,
    this.matchesPlayed = 0,
    this.goalsScored = 0,
    this.assists = 0,
    this.saves = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.winRatio = 0.0,
    this.averageRating = 0.0,
    this.customStats = const {},
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'teamId': teamId,
      'matchesPlayed': matchesPlayed,
      'goalsScored': goalsScored,
      'assists': assists,
      'saves': saves,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'winRatio': winRatio,
      'averageRating': averageRating,
      'customStats': customStats,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory PlayerPerformance.fromMap(Map<String, dynamic> map) {
    return PlayerPerformance(
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      teamId: map['teamId'] ?? '',
      matchesPlayed: map['matchesPlayed'] ?? 0,
      goalsScored: map['goalsScored'] ?? 0,
      assists: map['assists'] ?? 0,
      saves: map['saves'] ?? 0,
      yellowCards: map['yellowCards'] ?? 0,
      redCards: map['redCards'] ?? 0,
      winRatio: (map['winRatio'] ?? 0.0).toDouble(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      customStats: Map<String, dynamic>.from(map['customStats'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  PlayerPerformance copyWith({
    String? playerId,
    String? playerName,
    String? teamId,
    int? matchesPlayed,
    int? goalsScored,
    int? assists,
    int? saves,
    int? yellowCards,
    int? redCards,
    double? winRatio,
    double? averageRating,
    Map<String, dynamic>? customStats,
    DateTime? lastUpdated,
  }) {
    return PlayerPerformance(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      teamId: teamId ?? this.teamId,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      goalsScored: goalsScored ?? this.goalsScored,
      assists: assists ?? this.assists,
      saves: saves ?? this.saves,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      winRatio: winRatio ?? this.winRatio,
      averageRating: averageRating ?? this.averageRating,
      customStats: customStats ?? this.customStats,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Model for tracking team performance
class TeamPerformance {
  final String teamId;
  final String teamName;
  final int totalMatches;
  final int wins;
  final int losses;
  final int draws;
  final double winPercentage;
  final int totalGoalsScored;
  final int totalGoalsConceded;
  final int cleanSheets; // Matches without conceding goals
  final double averageGoalsPerMatch;
  final List<String> topScorers; // Player IDs
  final List<String> topAssists; // Player IDs
  final Map<String, dynamic> achievements; // Trophies, records, etc.
  final DateTime lastUpdated;

  const TeamPerformance({
    required this.teamId,
    required this.teamName,
    this.totalMatches = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winPercentage = 0.0,
    this.totalGoalsScored = 0,
    this.totalGoalsConceded = 0,
    this.cleanSheets = 0,
    this.averageGoalsPerMatch = 0.0,
    this.topScorers = const [],
    this.topAssists = const [],
    this.achievements = const {},
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'totalMatches': totalMatches,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'winPercentage': winPercentage,
      'totalGoalsScored': totalGoalsScored,
      'totalGoalsConceded': totalGoalsConceded,
      'cleanSheets': cleanSheets,
      'averageGoalsPerMatch': averageGoalsPerMatch,
      'topScorers': topScorers,
      'topAssists': topAssists,
      'achievements': achievements,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory TeamPerformance.fromMap(Map<String, dynamic> map) {
    return TeamPerformance(
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      totalMatches: map['totalMatches'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      draws: map['draws'] ?? 0,
      winPercentage: (map['winPercentage'] ?? 0.0).toDouble(),
      totalGoalsScored: map['totalGoalsScored'] ?? 0,
      totalGoalsConceded: map['totalGoalsConceded'] ?? 0,
      cleanSheets: map['cleanSheets'] ?? 0,
      averageGoalsPerMatch: (map['averageGoalsPerMatch'] ?? 0.0).toDouble(),
      topScorers: List<String>.from(map['topScorers'] ?? []),
      topAssists: List<String>.from(map['topAssists'] ?? []),
      achievements: Map<String, dynamic>.from(map['achievements'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  TeamPerformance copyWith({
    String? teamId,
    String? teamName,
    int? totalMatches,
    int? wins,
    int? losses,
    int? draws,
    double? winPercentage,
    int? totalGoalsScored,
    int? totalGoalsConceded,
    int? cleanSheets,
    double? averageGoalsPerMatch,
    List<String>? topScorers,
    List<String>? topAssists,
    Map<String, dynamic>? achievements,
    DateTime? lastUpdated,
  }) {
    return TeamPerformance(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      totalMatches: totalMatches ?? this.totalMatches,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      winPercentage: winPercentage ?? this.winPercentage,
      totalGoalsScored: totalGoalsScored ?? this.totalGoalsScored,
      totalGoalsConceded: totalGoalsConceded ?? this.totalGoalsConceded,
      cleanSheets: cleanSheets ?? this.cleanSheets,
      averageGoalsPerMatch: averageGoalsPerMatch ?? this.averageGoalsPerMatch,
      topScorers: topScorers ?? this.topScorers,
      topAssists: topAssists ?? this.topAssists,
      achievements: achievements ?? this.achievements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Calculate win percentage
  double get calculatedWinPercentage {
    if (totalMatches == 0) return 0.0;
    return (wins / totalMatches) * 100;
  }

  /// Get team form (last 5 matches)
  String get form {
    // This would be calculated from recent match results
    // For now, return a placeholder
    return 'WWLWD';
  }
}

/// Model for team achievements
class TeamAchievement {
  final String id;
  final String teamId;
  final String title;
  final String description;
  final String type; // 'tournament_win', 'record', 'milestone', etc.
  final String? imageUrl;
  final DateTime achievedAt;
  final Map<String, dynamic> metadata;

  const TeamAchievement({
    required this.id,
    required this.teamId,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.achievedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'title': title,
      'description': description,
      'type': type,
      'imageUrl': imageUrl,
      'achievedAt': Timestamp.fromDate(achievedAt),
      'metadata': metadata,
    };
  }

  factory TeamAchievement.fromMap(Map<String, dynamic> map) {
    return TeamAchievement(
      id: map['id'] ?? '',
      teamId: map['teamId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      imageUrl: map['imageUrl'],
      achievedAt: (map['achievedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}
