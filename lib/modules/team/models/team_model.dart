import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for team sports types
enum SportType {
  cricket,
  football,
  basketball,
  volleyball,
  tennis,
  badminton,
  other;

  String get displayName {
    switch (this) {
      case SportType.cricket:
        return 'Cricket';
      case SportType.football:
        return 'Football';
      case SportType.basketball:
        return 'Basketball';
      case SportType.volleyball:
        return 'Volleyball';
      case SportType.tennis:
        return 'Tennis';
      case SportType.badminton:
        return 'Badminton';
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
  member;

  String get displayName {
    switch (this) {
      case TeamRole.owner:
        return 'Owner';
      case TeamRole.captain:
        return 'Captain';
      case TeamRole.viceCaptain:
        return 'Vice Captain';
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

  const TeamMember({
    required this.userId,
    required this.userName,
    this.userEmail,
    this.profileImageUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'],
      profileImageUrl: map['profileImageUrl'],
      role: TeamRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => TeamRole.member,
      ),
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
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
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
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
    return {
      'id': id,
      'name': name,
      'description': description,
      'bio': bio,
      'sportType': sportType.name,
      'ownerId': ownerId,
      'members': members.map((member) => member.toMap()).toList(),
      'memberIds': members.map((member) => member.userId).toList(), // For indexing
      'maxMembers': maxMembers,
      'isPublic': isPublic,
      'teamImageUrl': teamImageUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'location': location,
      'coachId': coachId,
      'coachName': coachName,
      'venuesPlayed': venuesPlayed,
      'tournamentsParticipated': tournamentsParticipated,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'metadata': metadata,
      // Search fields for indexing
      'searchName': name.toLowerCase(),
      'searchSport': sportType.displayName.toLowerCase(),
      'searchLocation': location?.toLowerCase(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      bio: map['bio'],
      sportType: SportType.values.firstWhere(
        (e) => e.name == map['sportType'],
        orElse: () => SportType.other,
      ),
      ownerId: map['ownerId'] ?? '',
      members: (map['members'] as List<dynamic>?)
              ?.map((memberMap) => TeamMember.fromMap(memberMap))
              .toList() ??
          [],
      maxMembers: map['maxMembers'] ?? 11,
      isPublic: map['isPublic'] ?? true,
      teamImageUrl: map['teamImageUrl'],
      backgroundImageUrl: map['backgroundImageUrl'],
      location: map['location'],
      coachId: map['coachId'],
      coachName: map['coachName'],
      venuesPlayed: List<String>.from(map['venuesPlayed'] ?? []),
      tournamentsParticipated: List<String>.from(map['tournamentsParticipated'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'],
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
      tournamentsParticipated: tournamentsParticipated ?? this.tournamentsParticipated,
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
      return members.firstWhere((member) => member.role == TeamRole.viceCaptain);
    } catch (e) {
      return null;
    }
  }

  /// Check if team is full
  bool get isFull => members.length >= maxMembers;

  /// Get active members count
  int get activeMembersCount => members.where((member) => member.isActive).length;
}
