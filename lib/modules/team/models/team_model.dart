import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for team sports types
enum SportType {
  cricket,
  football,
  soccer, // Same as football, kept for compatibility
  basketball,
  volleyball,
  tennis,
  badminton,
  hockey,
  rugby,
  baseball,
  swimming,
  running,
  cycling,
  other;

  String get displayName {
    switch (this) {
      case SportType.cricket:
        return 'Cricket';
      case SportType.football:
        return 'Football';
      case SportType.soccer:
        return 'Soccer';
      case SportType.basketball:
        return 'Basketball';
      case SportType.volleyball:
        return 'Volleyball';
      case SportType.tennis:
        return 'Tennis';
      case SportType.badminton:
        return 'Badminton';
      case SportType.hockey:
        return 'Hockey';
      case SportType.rugby:
        return 'Rugby';
      case SportType.baseball:
        return 'Baseball';
      case SportType.swimming:
        return 'Swimming';
      case SportType.running:
        return 'Running';
      case SportType.cycling:
        return 'Cycling';
      case SportType.other:
        return 'Other';
    }
  }
}

/// Enum for team member roles
enum TeamRole {
  owner,
  captain,
  viceCaptain,
  coach,
  member;

  String get displayName {
    switch (this) {
      case TeamRole.owner:
        return 'Owner';
      case TeamRole.captain:
        return 'Captain';
      case TeamRole.viceCaptain:
        return 'Vice Captain';
      case TeamRole.coach:
        return 'Coach';
      case TeamRole.member:
        return 'Member';
    }
  }
}

/// Model representing a team member
class TeamMember {
  final String userId;
  final String userName;
  final String? userEmail;
  final String? profileImageUrl;
  final TeamRole role;
  final DateTime joinedAt;
  final bool isActive;

  // Player-specific fields
  final String? position; // Player position (e.g., Forward, Defender, etc.)
  final int? jerseyNumber; // Player's jersey number
  final int trophies; // Number of trophies/achievements
  final double? rating; // Player rating (0-5 or 0-10 scale)

  const TeamMember({
    required this.userId,
    required this.userName,
    this.userEmail,
    this.profileImageUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
    this.position,
    this.jerseyNumber,
    this.trophies = 0,
    this.rating,
  });

  // Convenience getters for backward compatibility
  String get id => userId;
  String get name => userName;
  bool get isCaptain => role == TeamRole.captain;
  bool get isHeadCoach => role == TeamRole.coach;

  /// Get player stats (placeholder for now - can be expanded to include actual stats)
  Map<String, dynamic> get playerStats => {
        'position': position ?? 'N/A',
        'jerseyNumber': jerseyNumber ?? 0,
        'trophies': trophies,
        'rating': rating ?? 0.0,
        'matchesPlayed': 0, // Will be calculated from actual match data
        'goals': 0, // Will be calculated from actual match data
        'assists': 0, // Will be calculated from actual match data
      };

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'id': userId,
      'userName': userName,
      'name': userName,
      'userEmail': userEmail,
      'email': userEmail,
      'profileImageUrl': profileImageUrl,
      'avatarUrl': profileImageUrl,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'joinedAtIso': joinedAt.toIso8601String(),
      'isActive': isActive,
      'position': position,
      'jerseyNumber': jerseyNumber,
      'trophies': trophies,
      'rating': rating,
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    final rawRole = map['role'] ?? map['memberRole'] ?? map['type'];

    return TeamMember(
      userId: map['userId'] ?? map['id'] ?? '',
      userName: map['userName'] ?? map['name'] ?? 'Unknown Member',
      userEmail: map['userEmail'] ?? map['email'],
      profileImageUrl:
          map['profileImageUrl'] ?? map['avatarUrl'] ?? map['imageUrl'],
      role: TeamRole.values.firstWhere(
        (e) => e.name == rawRole,
        orElse: () {
          if (rawRole is String) {
            final normalised = rawRole.toLowerCase();
            if (normalised.contains('coach')) return TeamRole.coach;
            if (normalised.contains('captain')) return TeamRole.captain;
            if (normalised.contains('owner')) return TeamRole.owner;
            if (normalised.contains('vice')) return TeamRole.viceCaptain;
          }
          return TeamRole.member;
        },
      ),
      joinedAt: _parseDate(map['joinedAt']) ??
          _parseDate(map['joinedAtIso']) ??
          DateTime.now(),
      isActive: map['isActive'] ?? map['active'] ?? true,
      position: map['position'],
      jerseyNumber: (map['jerseyNumber'] ?? map['jersey']) as int?,
      trophies: (map['trophies'] ?? map['awards'] ?? 0) as int,
      rating: _parseDouble(map['rating'] ?? map['playerRating']),
    );
  }

  TeamMember copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? profileImageUrl,
    TeamRole? role,
    DateTime? joinedAt,
    bool? isActive,
    String? position,
    int? jerseyNumber,
    int? trophies,
    double? rating,
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      position: position ?? this.position,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      trophies: trophies ?? this.trophies,
      rating: rating ?? this.rating,
    );
  }
}

/// Model representing a team
class Team {
  final String id;
  final String name;
  final String description;
  final String? bio; // Detailed team description
  final SportType sportType;
  final String ownerId;
  final List<TeamMember> members;
  final int maxMembers;
  final bool isPublic;
  final String? teamImageUrl; // Profile picture
  final String? backgroundImageUrl; // Background/banner picture
  final String? location; // Team location/venue
  final String? coachId; // Assigned coach ID
  final String? coachName; // Assigned coach name
  final List<String> venuesPlayed; // Historical venues
  final List<String> tournamentsParticipated; // Tournament history
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const Team({
    required this.id,
    required this.name,
    required this.description,
    this.bio,
    required this.sportType,
    required this.ownerId,
    required this.members,
    this.maxMembers = 11,
    this.isPublic = true,
    this.teamImageUrl,
    this.backgroundImageUrl,
    this.location,
    this.coachId,
    this.coachName,
    this.venuesPlayed = const [],
    this.tournamentsParticipated = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    final players = members
        .where((member) => member.role != TeamRole.coach)
        .map((member) => member.toMap())
        .toList();

    final coaches = members
        .where((member) => member.role == TeamRole.coach)
        .map((member) => member.toMap())
        .toList();

    final currentStats = stat;
    final statMap = {
      'won': currentStats['matchesWon'] ?? 0,
      'lost': currentStats['matchesLost'] ?? 0,
      'draw': currentStats['matchesDrawn'] ?? 0,
      'played': currentStats['matchesPlayed'] ?? 0,
      'goalsScored': currentStats['goalsScored'] ?? 0,
      'goalsConceded': currentStats['goalsConceded'] ?? 0,
      'points': currentStats['totalPoints'] ?? 0,
    };

    return {
      'id': id,
      'name': name,
      'nameInitial': nameInitial,
      'nameLowercase': name.toLowerCase(),
      'description': description,
      'bio': bio,
      'sportType': sportType.name,
      'sportTypeLabel': sportType.displayName,
      'ownerId': ownerId,
      'createdBy': ownerId,
      'members': members.map((member) => member.toMap()).toList(),
      'players': players,
      'coaches': coaches,
      'memberIds':
          members.map((member) => member.userId).toList(), // For indexing
      'maxMembers': maxMembers,
      'maxPlayers': maxMembers,
      'maxRosterSize': maxMembers,
      'isPublic': isPublic,
      'isActive': isActive,
      'teamImageUrl': teamImageUrl,
      'profileImageUrl': teamImageUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'bannerImageUrl': backgroundImageUrl,
      'location': location,
      'city': location,
      'coachId': coachId,
      'coachName': coachName,
      'venuesPlayed': venuesPlayed,
      'venueIds': venuesPlayed,
      'tournamentsParticipated': tournamentsParticipated,
      'tournamentIds': tournamentsParticipated,
      'stat': statMap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': {
        ...?metadata,
        ...statMap,
        'stat': statMap,
      },
      // Search fields for indexing
      'searchName': name.toLowerCase(),
      'searchSport': sportType.displayName.toLowerCase(),
      'searchLocation': location?.toLowerCase(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    final membersList =
        (map['members'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final playersList =
        (map['players'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final coachesList =
        (map['coaches'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    final mergedMembers = <String, Map<String, dynamic>>{};

    void addMembers(List<Map<String, dynamic>> items, {TeamRole? defaultRole}) {
      for (final memberMap in items) {
        final normalised = Map<String, dynamic>.from(memberMap);
        if (defaultRole != null &&
            (normalised['role'] == null || normalised['role'] == '')) {
          normalised['role'] = defaultRole.name;
        }

        final memberId = normalised['userId'] ?? normalised['id'];
        if (memberId == null) continue;
        mergedMembers[memberId] = normalised;
      }
    }

    addMembers(membersList);
    addMembers(playersList, defaultRole: TeamRole.member);
    addMembers(coachesList, defaultRole: TeamRole.coach);

    final members = mergedMembers.values
        .map((memberMap) => TeamMember.fromMap(memberMap))
        .toList();

    final metadata = Map<String, dynamic>.from(map['metadata'] ?? {});
    final statFromDoc =
        Map<String, dynamic>.from(map['stat'] ?? metadata['stat'] ?? {});

    final matchesWon = _parseInt(statFromDoc['won'] ?? metadata['matchesWon']);
    final matchesLost =
        _parseInt(statFromDoc['lost'] ?? metadata['matchesLost']);
    final matchesDrawn =
        _parseInt(statFromDoc['draw'] ?? metadata['matchesDrawn']);
    final matchesPlayed =
        _parseInt(statFromDoc['played'] ?? metadata['matchesPlayed']);

    final updatedMetadata = {
      ...metadata,
      'matchesWon': matchesWon,
      'matchesLost': matchesLost,
      'matchesDrawn': matchesDrawn,
      'matchesPlayed': matchesPlayed,
      'goalsScored':
          _parseInt(statFromDoc['goalsScored'] ?? metadata['goalsScored']),
      'goalsConceded':
          _parseInt(statFromDoc['goalsConceded'] ?? metadata['goalsConceded']),
      'totalPoints':
          _parseInt(statFromDoc['points'] ?? metadata['totalPoints']),
      'winPercentage': matchesPlayed > 0
          ? (matchesWon / matchesPlayed) * 100
          : _parseDouble(metadata['winPercentage']) ?? 0.0,
      'stat': {
        ...statFromDoc,
        'won': matchesWon,
        'lost': matchesLost,
        'draw': matchesDrawn,
        'played': matchesPlayed,
      },
    };

    return Team(
      id: map['id'] ?? map['teamId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      bio: map['bio'],
      sportType: SportType.values.firstWhere(
        (e) => e.name == map['sportType'],
        orElse: () => SportType.other,
      ),
      ownerId: map['ownerId'] ?? map['createdBy'] ?? '',
      members: members,
      maxMembers:
          map['maxMembers'] ?? map['maxPlayers'] ?? map['maxRosterSize'] ?? 11,
      isPublic: map['isPublic'] ?? true,
      teamImageUrl:
          map['teamImageUrl'] ?? map['profileImageUrl'] ?? map['logoUrl'],
      backgroundImageUrl:
          map['backgroundImageUrl'] ?? map['bannerImageUrl'] ?? map['coverUrl'],
      location: map['location'] ?? map['city'],
      coachId: map['coachId'],
      coachName: map['coachName'],
      venuesPlayed: List<String>.from(
          map['venuesPlayed'] ?? map['venueIds'] ?? const <String>[]),
      tournamentsParticipated: List<String>.from(
          map['tournamentsParticipated'] ??
              map['tournamentIds'] ??
              const <String>[]),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      metadata: updatedMetadata,
    );
  }

  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? bio,
    SportType? sportType,
    String? ownerId,
    List<TeamMember>? members,
    int? maxMembers,
    bool? isPublic,
    String? teamImageUrl,
    String? backgroundImageUrl,
    String? location,
    String? coachId,
    String? coachName,
    List<String>? venuesPlayed,
    List<String>? tournamentsParticipated,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      bio: bio ?? this.bio,
      sportType: sportType ?? this.sportType,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      maxMembers: maxMembers ?? this.maxMembers,
      isPublic: isPublic ?? this.isPublic,
      teamImageUrl: teamImageUrl ?? this.teamImageUrl,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      location: location ?? this.location,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      venuesPlayed: venuesPlayed ?? this.venuesPlayed,
      tournamentsParticipated:
          tournamentsParticipated ?? this.tournamentsParticipated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get team captain
  TeamMember? get captain {
    try {
      return members.firstWhere((member) => member.role == TeamRole.captain);
    } catch (e) {
      return null;
    }
  }

  /// Get team vice captain
  TeamMember? get viceCaptain {
    try {
      return members
          .firstWhere((member) => member.role == TeamRole.viceCaptain);
    } catch (e) {
      return null;
    }
  }

  /// Check if team is full
  bool get isFull => members.length >= maxMembers;

  /// Get active members count
  int get activeMembersCount =>
      members.where((member) => member.isActive).length;

  /// Get total members count
  int get memberCount => members.length;

  // Backward compatibility getters
  String? get profileImageUrl => teamImageUrl;
  String? get bannerImageUrl => backgroundImageUrl;
  int get activePlayersCount => activeMembersCount;
  int get maxPlayers => maxMembers;
  int get totalMembersCount => memberCount;
  int get maxRosterSize => maxMembers;
  String? get city => location;
  String get nameInitial =>
      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '';

  // Get list of players (members who are not coaches)
  List<TeamMember> get players {
    return members.where((member) => member.role != TeamRole.coach).toList();
  }

  // Get list of coaches
  List<TeamMember> get coaches {
    return members.where((member) => member.role == TeamRole.coach).toList();
  }

  // Get createdBy for backward compatibility (same as ownerId)
  String get createdBy => ownerId;

  // Team stats placeholder (can be expanded later)
  Map<String, dynamic> get stat {
    final metaStat =
        (metadata?['stat'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return {
      'totalMembers': memberCount,
      'activeMembers': activeMembersCount,
      'maxMembers': maxMembers,
      'matchesWon': metadata?['matchesWon'] ?? metaStat['won'] ?? 0,
      'matchesLost': metadata?['matchesLost'] ?? metaStat['lost'] ?? 0,
      'matchesDrawn': metadata?['matchesDrawn'] ?? metaStat['draw'] ?? 0,
      'matchesPlayed': metadata?['matchesPlayed'] ?? metaStat['played'] ?? 0,
      'goalsScored': metadata?['goalsScored'] ?? metaStat['goalsScored'] ?? 0,
      'goalsConceded':
          metadata?['goalsConceded'] ?? metaStat['goalsConceded'] ?? 0,
      'totalPoints': metadata?['totalPoints'] ?? metaStat['points'] ?? 0,
      'winPercentage':
          metadata?['winPercentage'] ?? metaStat['winPercentage'] ?? 0.0,
    };
  }

  // fromJson factory for backward compatibility
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team.fromMap(json);
  }

  /// Check if user is admin (owner or captain)
  bool isAdminOrOwner(String? userId) {
    if (userId == null) return false;
    if (ownerId == userId) return true;
    return members.any((member) =>
        member.userId == userId &&
        (member.role == TeamRole.owner || member.role == TeamRole.captain));
  }

  /// Check if user is a member of the team
  bool isMember(String? userId) {
    if (userId == null) return false;
    return members.any((member) => member.userId == userId);
  }
}

// Type alias for backward compatibility
typedef TeamModel = Team;
typedef TeamPlayer = TeamMember;

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
