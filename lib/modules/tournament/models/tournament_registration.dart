import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for registration status
enum RegistrationStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case RegistrationStatus.pending:
        return 'Pending';
      case RegistrationStatus.approved:
        return 'Approved';
      case RegistrationStatus.rejected:
        return 'Rejected';
      case RegistrationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

/// Model representing a tournament registration
class TournamentRegistration {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final String teamId;
  final String teamName;
  final String registeredBy;
  final String registeredByName;
  final RegistrationStatus status;
  final DateTime registeredAt;
  final DateTime? respondedAt;
  final String? respondedBy;
  final String? responseMessage;
  final Map<String, dynamic>? additionalInfo;

  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.teamId,
    required this.teamName,
    required this.registeredBy,
    required this.registeredByName,
    required this.status,
    required this.registeredAt,
    this.respondedAt,
    this.respondedBy,
    this.responseMessage,
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'tournamentName': tournamentName,
      'teamId': teamId,
      'teamName': teamName,
      'registeredBy': registeredBy,
      'registeredByName': registeredByName,
      'status': status.name,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedBy': respondedBy,
      'responseMessage': responseMessage,
      'additionalInfo': additionalInfo,
    };
  }

  factory TournamentRegistration.fromMap(Map<String, dynamic> map) {
    return TournamentRegistration(
      id: map['id'] ?? '',
      tournamentId: map['tournamentId'] ?? '',
      tournamentName: map['tournamentName'] ?? '',
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      registeredBy: map['registeredBy'] ?? '',
      registeredByName: map['registeredByName'] ?? '',
      status: RegistrationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RegistrationStatus.pending,
      ),
      registeredAt: (map['registeredAt'] as Timestamp).toDate(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
      respondedBy: map['respondedBy'],
      responseMessage: map['responseMessage'],
      additionalInfo: map['additionalInfo'],
    );
  }

  TournamentRegistration copyWith({
    String? id,
    String? tournamentId,
    String? tournamentName,
    String? teamId,
    String? teamName,
    String? registeredBy,
    String? registeredByName,
    RegistrationStatus? status,
    DateTime? registeredAt,
    DateTime? respondedAt,
    String? respondedBy,
    String? responseMessage,
    Map<String, dynamic>? additionalInfo,
  }) {
    return TournamentRegistration(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      registeredBy: registeredBy ?? this.registeredBy,
      registeredByName: registeredByName ?? this.registeredByName,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      responseMessage: responseMessage ?? this.responseMessage,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  /// Check if registration is pending
  bool get isPending => status == RegistrationStatus.pending;

  /// Check if registration is approved
  bool get isApproved => status == RegistrationStatus.approved;

  /// Check if registration is rejected
  bool get isRejected => status == RegistrationStatus.rejected;

  /// Check if registration is withdrawn
  bool get isWithdrawn => status == RegistrationStatus.withdrawn;
}
