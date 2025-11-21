import 'package:cloud_firestore/cloud_firestore.dart';

import '../../team/models/models.dart';

/// Enum for tournament type
enum TournamentType {
  individual,
  team,
  mixed,
  knockout,
  knockOut, // Alias for knockout, kept for compatibility
  league;

  String get displayName {
    switch (this) {
      case TournamentType.individual:
        return 'Individual';
      case TournamentType.team:
        return 'Team';
      case TournamentType.mixed:
        return 'Mixed';
      case TournamentType.knockout:
        return 'Knockout';
      case TournamentType.knockOut:
        return 'Knockout';
      case TournamentType.league:
        return 'League';
    }
  }

  int get minTeamRequirement {
    switch (this) {
      case TournamentType.knockout:
      case TournamentType.knockOut:
        return 4;
      case TournamentType.league:
        return 3;
      default:
        return 2;
    }
  }
}

/// Enum for tournament status
enum TournamentStatus {
  upcoming,
  registrationOpen,
  registrationClosed,
  ongoing,
  running, // Same as ongoing, kept for compatibility
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
      case TournamentStatus.running:
        return 'Running';
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
  final bool
      allowTeamEditing; // Whether teams can be edited before tournament starts
  final Map<String, int> teamPoints; // Team ID -> Points mapping
  // Note: Matches are now managed separately via TournamentMatchService
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
      'tournamentResults': tournamentResults,
    };
  }

  static DateTime _coerceToDate(dynamic raw, {DateTime? fallback}) {
    if (raw == null) return fallback ?? DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String && raw.isNotEmpty) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }
    return fallback ?? DateTime.now();
  }

  static T _safeFirstWhere<T>(
    Iterable<T> values,
    bool Function(T element) test,
    T fallback,
  ) {
    return values.firstWhere(
      test,
      orElse: () => fallback,
    );
  }

  static TournamentFormat _parseFormat(Map<String, dynamic> map) {
    final raw = (map['format'] ?? map['type'] ?? '').toString();
    if (raw.isEmpty) return TournamentFormat.singleElimination;
    return _safeFirstWhere(
      TournamentFormat.values,
      (value) => value.name.toLowerCase() == raw.toLowerCase(),
      TournamentFormat.singleElimination,
    );
  }

  static SportType _parseSportType(Map<String, dynamic> map) {
    final raw = (map['sportType'] ?? map['sport'] ?? '').toString();
    if (raw.isEmpty) return SportType.other;
    return _safeFirstWhere(
      SportType.values,
      (value) => value.name.toLowerCase() == raw.toLowerCase(),
      SportType.other,
    );
  }

  static TournamentStatus _parseStatus(Map<String, dynamic> map) {
    final raw = (map['status'] ?? '').toString();
    if (raw.isEmpty) return TournamentStatus.upcoming;
    return _safeFirstWhere(
      TournamentStatus.values,
      (value) => value.name.toLowerCase() == raw.toLowerCase(),
      TournamentStatus.upcoming,
    );
  }

  static String _resolveOrganizerName(Map<String, dynamic> map) {
    if (map['organizerName'] != null && map['organizerName'].toString().isNotEmpty) {
      return map['organizerName'].toString();
    }

    final members = map['members'];
    if (members is List && members.isNotEmpty) {
      for (final member in members) {
        if (member is Map<String, dynamic>) {
          final role = member['role']?.toString().toLowerCase();
          if (role == 'organizer' || role == 'owner') {
            final name = member['name'] ?? member['userName'];
            if (name != null && name.toString().isNotEmpty) {
              return name.toString();
            }
          }
        }
      }
    }

    if (map['members'] is List && (map['members'] as List).isNotEmpty) {
      final fallbackMember = (map['members'] as List).first;
      if (fallbackMember is Map<String, dynamic>) {
        final name = fallbackMember['name'] ?? fallbackMember['userName'];
        if (name != null && name.toString().isNotEmpty) {
          return name.toString();
        }
      }
    }

    return 'Tournament Organizer';
  }

  static int _resolveCurrentTeamsCount(Map<String, dynamic> map) {
    if (map['currentTeamsCount'] is int) {
      return map['currentTeamsCount'] as int;
    }
    if (map['currentTeamsCount'] is double) {
      return (map['currentTeamsCount'] as double).round();
    }

    final stat = map['stat'];
    if (stat is Map<String, dynamic>) {
      final activeTeams = stat['activeTeams'] ?? stat['totalTeams'];
      if (activeTeams is int) return activeTeams;
      if (activeTeams is double) return activeTeams.round();
    }

    final teamIds = map['teamIds'];
    if (teamIds is List) return teamIds.length;

    final members = map['members'];
    if (members is List) return members.length;

    return 0;
  }

  static Map<String, int> _parseTeamPoints(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(key, (value is num) ? value.toInt() : 0));
    }
    return const {};
  }

  static Map<String, dynamic>? _mergeMetadata(Map<String, dynamic> map) {
    final existing = map['metadata'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['metadata'] as Map<String, dynamic>)
        : <String, dynamic>{};

    void attach(String key) {
      if (map[key] != null) {
        existing.putIfAbsent(key, () => map[key]);
      }
    }

    attach('currency');
    attach('stat');
    attach('members');
    attach('teamIds');
    attach('bannerImageUrl');
    attach('profileImageUrl');

    return existing.isEmpty ? null : existing;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static Map<String, dynamic>? _parseMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  factory Tournament.fromMap(Map<String, dynamic> map) {
    final startDate = _coerceToDate(map['startDate']);
    final registrationStartDate = _coerceToDate(
      map['registrationStartDate'],
      fallback: map['registrationOpenDate'] != null
          ? _coerceToDate(map['registrationOpenDate'])
          : _coerceToDate(map['createdAt'], fallback: startDate.subtract(const Duration(days: 14))),
    );
    final registrationEndDate = _coerceToDate(
      map['registrationEndDate'],
      fallback: map['registrationDeadline'] != null
          ? _coerceToDate(map['registrationDeadline'])
          : startDate,
    );
    final createdAt = _coerceToDate(map['createdAt'], fallback: startDate);
    final updatedAt = _coerceToDate(map['updatedAt'], fallback: createdAt);

    return Tournament(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      sportType: _parseSportType(map),
      format: _parseFormat(map),
      status: _parseStatus(map),
      organizerId: map['organizerId']?.toString() ?? map['createdBy']?.toString() ?? '',
      organizerName: _resolveOrganizerName(map),
      registrationStartDate: registrationStartDate,
      registrationEndDate: registrationEndDate,
      startDate: startDate,
      endDate: map['endDate'] != null ? _coerceToDate(map['endDate']) : null,
      maxTeams: (map['maxTeams'] is num) ? (map['maxTeams'] as num).toInt() : 0,
      minTeams: (map['minTeams'] is num) ? (map['minTeams'] as num).toInt() : 2,
      currentTeamsCount: _resolveCurrentTeamsCount(map),
      location: map['location']?.toString(),
      venueId: map['venueId']?.toString(),
      venueName: map['venueName']?.toString(),
      imageUrl: (map['imageUrl'] ??
              map['bannerImageUrl'] ??
              map['profileImageUrl'])
          ?.toString(),
      rules: _parseStringList(map['rules']),
      prizes: _parseMap(map['prizes']),
      isPublic: map['isPublic'] is bool ? map['isPublic'] as bool : true,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: _mergeMetadata(map),
      // New fields
      entryFee: map['entryFee'] is num ? (map['entryFee'] as num).toDouble() : null,
      winningPrize:
          map['winningPrize'] is num ? (map['winningPrize'] as num).toDouble() : null,
      winnerTeamId: map['winnerTeamId']?.toString(),
      winnerTeamName: map['winnerTeamName']?.toString(),
      groupChatId: map['groupChatId']?.toString(),
      qualifyingQuestions: _parseStringList(map['qualifyingQuestions']),
      allowTeamEditing: map['allowTeamEditing'] is bool
          ? map['allowTeamEditing'] as bool
          : true,
      teamPoints: _parseTeamPoints(map['teamPoints']),
      tournamentResults: _parseMap(map['tournamentResults']),
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
      registrationStartDate:
          registrationStartDate ?? this.registrationStartDate,
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
  bool get isActive =>
      status != TournamentStatus.completed &&
      status != TournamentStatus.cancelled;

  /// Check if tournament can be deleted (no teams have joined)
  bool get canBeDeleted => currentTeamsCount == 0;

  /// Check if tournament can be edited (before it starts and teams can be edited)
  bool get canBeEdited =>
      allowTeamEditing && status == TournamentStatus.upcoming;
}

/// Extension for backward compatibility
extension TournamentBackwardCompatibility on Tournament {
  /// Profile image URL (backward compatibility - maps to imageUrl)
  String? get profileImageUrl => imageUrl;

  /// Banner image URL (backward compatibility - currently not supported)
  String? get bannerImageUrl => null;

  /// Tournament type (backward compatibility - maps to format)
  TournamentFormat get type => format;

  /// Team IDs list (backward compatibility - needs to be fetched from service)
  /// This is a placeholder that returns empty list
  List<String> get teamIds => [];

  /// Match IDs list (backward compatibility - needs to be fetched from service)
  /// This is a placeholder that returns empty list
  List<String> get matchIds => [];

  /// Tournament statistics (backward compatibility - placeholder)
  TournamentStats get stat => TournamentStats(
        totalMatches: 0,
        completedMatches: 0,
        upcomingMatches: 0,
      );

  /// Matches list (backward compatibility - needs to be fetched from service)
  /// This is a placeholder that returns empty list
  List<dynamic> get matches => [];
}

/// Stats model for backward compatibility
class TournamentStats {
  final int totalMatches;
  final int completedMatches;
  final int upcomingMatches;

  const TournamentStats({
    required this.totalMatches,
    required this.completedMatches,
    required this.upcomingMatches,
  });
}

// Typedef to maintain backward compatibility with code using TournamentModel
typedef TournamentModel = Tournament;
