import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model for coach associations with venues, teams, and players
class CoachAssociations {
  final String coachId;
  final List<CoachVenueAssociation> venues;
  final List<CoachTeamAssociation> teams;
  final List<CoachPlayerAssociation> players;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoachAssociations({
    required this.coachId,
    this.venues = const [],
    this.teams = const [],
    this.players = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'coachId': coachId,
      'venues': venues.map((v) => v.toMap()).toList(),
      'teams': teams.map((t) => t.toMap()).toList(),
      'players': players.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory CoachAssociations.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoachAssociations.fromMap(data);
  }

  /// Create from Map
  factory CoachAssociations.fromMap(Map<String, dynamic> map) {
    return CoachAssociations(
      coachId: map['coachId'] as String,
      venues: (map['venues'] as List<dynamic>?)
              ?.map((v) =>
                  CoachVenueAssociation.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      teams: (map['teams'] as List<dynamic>?)
              ?.map((t) =>
                  CoachTeamAssociation.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      players: (map['players'] as List<dynamic>?)
              ?.map((p) =>
                  CoachPlayerAssociation.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Create a copy with updated fields
  CoachAssociations copyWith({
    String? coachId,
    List<CoachVenueAssociation>? venues,
    List<CoachTeamAssociation>? teams,
    List<CoachPlayerAssociation>? players,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachAssociations(
      coachId: coachId ?? this.coachId,
      venues: venues ?? this.venues,
      teams: teams ?? this.teams,
      players: players ?? this.players,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Association between coach and venue
class CoachVenueAssociation {
  final String venueId;
  final String venueName;
  final String venueOwnerId;
  final AssociationStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  CoachVenueAssociation({
    required this.venueId,
    required this.venueName,
    required this.venueOwnerId,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'venueName': venueName,
      'venueOwnerId': venueOwnerId,
      'status': status.value,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  factory CoachVenueAssociation.fromMap(Map<String, dynamic> map) {
    return CoachVenueAssociation(
      venueId: map['venueId'] as String,
      venueName: map['venueName'] as String,
      venueOwnerId: map['venueOwnerId'] as String,
      status: AssociationStatus.fromString(map['status'] as String),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: map['rejectedAt'] != null
          ? (map['rejectedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }
}

/// Association between coach and team
class CoachTeamAssociation {
  final String teamId;
  final String teamName;
  final String teamCaptainId;
  final AssociationStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  CoachTeamAssociation({
    required this.teamId,
    required this.teamName,
    required this.teamCaptainId,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'teamCaptainId': teamCaptainId,
      'status': status.value,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  factory CoachTeamAssociation.fromMap(Map<String, dynamic> map) {
    return CoachTeamAssociation(
      teamId: map['teamId'] as String,
      teamName: map['teamName'] as String,
      teamCaptainId: map['teamCaptainId'] as String,
      status: AssociationStatus.fromString(map['status'] as String),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: map['rejectedAt'] != null
          ? (map['rejectedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }
}

/// Association between coach and player
class CoachPlayerAssociation {
  final String playerId;
  final String playerName;
  final AssociationStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  CoachPlayerAssociation({
    required this.playerId,
    required this.playerName,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'status': status.value,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  factory CoachPlayerAssociation.fromMap(Map<String, dynamic> map) {
    return CoachPlayerAssociation(
      playerId: map['playerId'] as String,
      playerName: map['playerName'] as String,
      status: AssociationStatus.fromString(map['status'] as String),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: map['rejectedAt'] != null
          ? (map['rejectedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }
}

/// Status of association requests
enum AssociationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const AssociationStatus(this.value);
  final String value;

  static AssociationStatus fromString(String value) {
    return AssociationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AssociationStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case AssociationStatus.pending:
        return 'Pending';
      case AssociationStatus.approved:
        return 'Approved';
      case AssociationStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case AssociationStatus.pending:
        return Colors.orange;
      case AssociationStatus.approved:
        return Colors.green;
      case AssociationStatus.rejected:
        return Colors.red;
    }
  }
}
