import 'package:cloud_firestore/cloud_firestore.dart';
import '../../team/models/models.dart';

/// Enum for tournament status
enum TournamentStatus {
  upcoming,
  registrationOpen,
  registrationClosed,
  ongoing,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.registrationOpen:
        return 'Registration Open';
      case TournamentStatus.registrationClosed:
        return 'Registration Closed';
      case TournamentStatus.ongoing:
        return 'Ongoing';
      case TournamentStatus.inProgress:
        return 'In Progress';
      case TournamentStatus.completed:
        return 'Completed';
      case TournamentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Enum for tournament format
enum TournamentFormat {
  singleElimination,
  doubleElimination,
  roundRobin,
  swiss,
  league;

  String get displayName {
    switch (this) {
      case TournamentFormat.singleElimination:
        return 'Single Elimination';
      case TournamentFormat.doubleElimination:
        return 'Double Elimination';
      case TournamentFormat.roundRobin:
        return 'Round Robin';
      case TournamentFormat.swiss:
        return 'Swiss System';
      case TournamentFormat.league:
        return 'League';
    }
  }
}

/// Model representing a tournament
class Tournament {
  final String id;
  final String name;
  final String description;
  final SportType sportType;
  final TournamentFormat format;
  final TournamentStatus status;
  final String organizerId;
  final String organizerName;
  final DateTime registrationStartDate;
  final DateTime registrationEndDate;
  final DateTime startDate;
  final DateTime? endDate;
  final int maxTeams;
  final int minTeams;
  final int currentTeamsCount;
  final String? location;
  final String? venueId; // Reference to selected venue
  final String? venueName; // Venue name for display
  final String? imageUrl;
  final List<String> rules;
  final Map<String, dynamic>? prizes;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // New fields for enhanced tournament management
  final double? entryFee; // Entry fee amount
  final double? winningPrize; // Winning prize amount
  final String? winnerTeamId; // ID of winning team
  final String? winnerTeamName; // Name of winning team
  final String? groupChatId; // Associated group chat ID
  final List<String> qualifyingQuestions; // Questions for team registration
  final bool allowTeamEditing; // Whether teams can be edited before tournament starts
  final Map<String, int> teamPoints; // Team ID -> Points mapping
  final List<TournamentMatch> matches; // Tournament matches
  final Map<String, dynamic>? tournamentResults; // Final results and statistics

  const Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.sportType,
    required this.format,
    required this.status,
    required this.organizerId,
    required this.organizerName,
    required this.registrationStartDate,
    required this.registrationEndDate,
    required this.startDate,
    this.endDate,
    required this.maxTeams,
    this.minTeams = 2,
    this.currentTeamsCount = 0,
    this.location,
    this.venueId,
    this.venueName,
    this.imageUrl,
    this.rules = const [],
    this.prizes,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    // New fields
    this.entryFee,
    this.winningPrize,
    this.winnerTeamId,
    this.winnerTeamName,
    this.groupChatId,
    this.qualifyingQuestions = const [],
    this.allowTeamEditing = true,
    this.teamPoints = const {},
    this.matches = const [],
    this.tournamentResults,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sportType': sportType.name,
      'format': format.name,
      'status': status.name,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'registrationStartDate': Timestamp.fromDate(registrationStartDate),
      'registrationEndDate': Timestamp.fromDate(registrationEndDate),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'maxTeams': maxTeams,
      'minTeams': minTeams,
      'currentTeamsCount': currentTeamsCount,
      'location': location,
      'venueId': venueId,
      'venueName': venueName,
      'imageUrl': imageUrl,
      'rules': rules,
      'prizes': prizes,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      // New fields
      'entryFee': entryFee,
      'winningPrize': winningPrize,
      'winnerTeamId': winnerTeamId,
      'winnerTeamName': winnerTeamName,
      'groupChatId': groupChatId,
      'qualifyingQuestions': qualifyingQuestions,
      'allowTeamEditing': allowTeamEditing,
      'teamPoints': teamPoints,
      'matches': matches.map((match) => match.toMap()).toList(),
      'tournamentResults': tournamentResults,
    };
  }

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      sportType: SportType.values.firstWhere(
        (e) => e.name == map['sportType'],
        orElse: () => SportType.other,
      ),
      format: TournamentFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => TournamentFormat.singleElimination,
      ),
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TournamentStatus.upcoming,
      ),
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      registrationStartDate: (map['registrationStartDate'] as Timestamp).toDate(),
      registrationEndDate: (map['registrationEndDate'] as Timestamp).toDate(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      maxTeams: map['maxTeams'] ?? 0,
      minTeams: map['minTeams'] ?? 2,
      currentTeamsCount: map['currentTeamsCount'] ?? 0,
      location: map['location'],
      venueId: map['venueId'],
      venueName: map['venueName'],
      imageUrl: map['imageUrl'],
      rules: List<String>.from(map['rules'] ?? []),
      prizes: map['prizes'],
      isPublic: map['isPublic'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
      // New fields
      entryFee: map['entryFee']?.toDouble(),
      winningPrize: map['winningPrize']?.toDouble(),
      winnerTeamId: map['winnerTeamId'],
      winnerTeamName: map['winnerTeamName'],
      groupChatId: map['groupChatId'],
      qualifyingQuestions: List<String>.from(map['qualifyingQuestions'] ?? []),
      allowTeamEditing: map['allowTeamEditing'] ?? true,
      teamPoints: Map<String, int>.from(map['teamPoints'] ?? {}),
      matches: (map['matches'] as List<dynamic>?)
          ?.map((matchMap) => TournamentMatch.fromMap(matchMap as Map<String, dynamic>))
          .toList() ?? [],
      tournamentResults: map['tournamentResults'],
    );
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    SportType? sportType,
    TournamentFormat? format,
    TournamentStatus? status,
    String? organizerId,
    String? organizerName,
    DateTime? registrationStartDate,
    DateTime? registrationEndDate,
    DateTime? startDate,
    DateTime? endDate,
    int? maxTeams,
    int? minTeams,
    int? currentTeamsCount,
    String? location,
    String? venueId,
    String? venueName,
    String? imageUrl,
    List<String>? rules,
    Map<String, dynamic>? prizes,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    // New fields
    double? entryFee,
    double? winningPrize,
    String? winnerTeamId,
    String? winnerTeamName,
    String? groupChatId,
    List<String>? qualifyingQuestions,
    bool? allowTeamEditing,
    Map<String, int>? teamPoints,
    List<TournamentMatch>? matches,
    Map<String, dynamic>? tournamentResults,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sportType: sportType ?? this.sportType,
      format: format ?? this.format,
      status: status ?? this.status,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      registrationStartDate: registrationStartDate ?? this.registrationStartDate,
      registrationEndDate: registrationEndDate ?? this.registrationEndDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxTeams: maxTeams ?? this.maxTeams,
      minTeams: minTeams ?? this.minTeams,
      currentTeamsCount: currentTeamsCount ?? this.currentTeamsCount,
      location: location ?? this.location,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      imageUrl: imageUrl ?? this.imageUrl,
      rules: rules ?? this.rules,
      prizes: prizes ?? this.prizes,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      // New fields
      entryFee: entryFee ?? this.entryFee,
      winningPrize: winningPrize ?? this.winningPrize,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      winnerTeamName: winnerTeamName ?? this.winnerTeamName,
      groupChatId: groupChatId ?? this.groupChatId,
      qualifyingQuestions: qualifyingQuestions ?? this.qualifyingQuestions,
      allowTeamEditing: allowTeamEditing ?? this.allowTeamEditing,
      teamPoints: teamPoints ?? this.teamPoints,
      matches: matches ?? this.matches,
      tournamentResults: tournamentResults ?? this.tournamentResults,
    );
  }

  /// Check if registration is currently open
  bool get isRegistrationOpen {
    final now = DateTime.now();
    return status == TournamentStatus.registrationOpen &&
           now.isAfter(registrationStartDate) &&
           now.isBefore(registrationEndDate);
  }

  /// Check if tournament is full
  bool get isFull => currentTeamsCount >= maxTeams;

  /// Check if tournament has minimum teams to start
  bool get hasMinimumTeams => currentTeamsCount >= minTeams;

  /// Get available spots
  int get availableSpots => maxTeams - currentTeamsCount;

  /// Check if tournament is active (in progress or upcoming)
  bool get isActive => status != TournamentStatus.completed &&
                      status != TournamentStatus.cancelled;

  /// Check if tournament can be deleted (no teams have joined)
  bool get canBeDeleted => currentTeamsCount == 0;

  /// Check if tournament can be edited (before it starts and teams can be edited)
  bool get canBeEdited => allowTeamEditing && status == TournamentStatus.upcoming;
}

/// Enum for match status
enum MatchStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case MatchStatus.scheduled:
        return 'Scheduled';
      case MatchStatus.inProgress:
        return 'In Progress';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Model representing a tournament match
class TournamentMatch {
  final String id;
  final String tournamentId;
  final String team1Id;
  final String team1Name;
  final String team2Id;
  final String team2Name;
  final DateTime scheduledDate;
  final MatchStatus status;
  final int? team1Score;
  final int? team2Score;
  final String? winnerTeamId;
  final String? winnerTeamName;
  final String round; // 'Round 1', 'Quarter Final', 'Semi Final', 'Final'
  final int matchNumber;
  final String? venueId;
  final String? venueName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.team1Id,
    required this.team1Name,
    required this.team2Id,
    required this.team2Name,
    required this.scheduledDate,
    required this.status,
    this.team1Score,
    this.team2Score,
    this.winnerTeamId,
    this.winnerTeamName,
    required this.round,
    required this.matchNumber,
    this.venueId,
    this.venueName,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'team1Id': team1Id,
      'team1Name': team1Name,
      'team2Id': team2Id,
      'team2Name': team2Name,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status.name,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'winnerTeamId': winnerTeamId,
      'winnerTeamName': winnerTeamName,
      'round': round,
      'matchNumber': matchNumber,
      'venueId': venueId,
      'venueName': venueName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  factory TournamentMatch.fromMap(Map<String, dynamic> map) {
    return TournamentMatch(
      id: map['id'] ?? '',
      tournamentId: map['tournamentId'] ?? '',
      team1Id: map['team1Id'] ?? '',
      team1Name: map['team1Name'] ?? '',
      team2Id: map['team2Id'] ?? '',
      team2Name: map['team2Name'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      team1Score: map['team1Score'],
      team2Score: map['team2Score'],
      winnerTeamId: map['winnerTeamId'],
      winnerTeamName: map['winnerTeamName'],
      round: map['round'] ?? '',
      matchNumber: map['matchNumber'] ?? 0,
      venueId: map['venueId'],
      venueName: map['venueName'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }

  /// Check if match is today
  bool get isToday {
    final now = DateTime.now();
    final matchDate = scheduledDate;
    return now.year == matchDate.year &&
           now.month == matchDate.month &&
           now.day == matchDate.day;
  }

  /// Check if match is in the past
  bool get isPast => scheduledDate.isBefore(DateTime.now());

  /// Check if match is in the future
  bool get isFuture => scheduledDate.isAfter(DateTime.now());
}
