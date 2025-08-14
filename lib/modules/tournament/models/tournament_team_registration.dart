import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for team registration status
enum TeamRegistrationStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case TeamRegistrationStatus.pending:
        return 'Pending';
      case TeamRegistrationStatus.approved:
        return 'Approved';
      case TeamRegistrationStatus.rejected:
        return 'Rejected';
      case TeamRegistrationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

/// Model for qualifying question and answer
class QualifyingAnswer {
  final String question;
  final String answer;

  const QualifyingAnswer({
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
    };
  }

  factory QualifyingAnswer.fromMap(Map<String, dynamic> map) {
    return QualifyingAnswer(
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }
}

/// Model representing a team's registration for a tournament
class TournamentTeamRegistration {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final String teamId;
  final String teamName;
  final String captainId;
  final String captainName;
  final String? captainImageUrl;
  final List<String> teamMemberIds;
  final List<String> teamMemberNames;
  final TeamRegistrationStatus status;
  final List<QualifyingAnswer> qualifyingAnswers;
  final DateTime registrationDate;
  final DateTime? approvalDate;
  final String? rejectionReason;
  final String? notes; // Additional notes from captain
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const TournamentTeamRegistration({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.teamId,
    required this.teamName,
    required this.captainId,
    required this.captainName,
    this.captainImageUrl,
    required this.teamMemberIds,
    required this.teamMemberNames,
    required this.status,
    required this.qualifyingAnswers,
    required this.registrationDate,
    this.approvalDate,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'tournamentName': tournamentName,
      'teamId': teamId,
      'teamName': teamName,
      'captainId': captainId,
      'captainName': captainName,
      'captainImageUrl': captainImageUrl,
      'teamMemberIds': teamMemberIds,
      'teamMemberNames': teamMemberNames,
      'status': status.name,
      'qualifyingAnswers': qualifyingAnswers.map((answer) => answer.toMap()).toList(),
      'registrationDate': Timestamp.fromDate(registrationDate),
      'approvalDate': approvalDate != null ? Timestamp.fromDate(approvalDate!) : null,
      'rejectionReason': rejectionReason,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  factory TournamentTeamRegistration.fromMap(Map<String, dynamic> map) {
    return TournamentTeamRegistration(
      id: map['id'] ?? '',
      tournamentId: map['tournamentId'] ?? '',
      tournamentName: map['tournamentName'] ?? '',
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      captainId: map['captainId'] ?? '',
      captainName: map['captainName'] ?? '',
      captainImageUrl: map['captainImageUrl'],
      teamMemberIds: List<String>.from(map['teamMemberIds'] ?? []),
      teamMemberNames: List<String>.from(map['teamMemberNames'] ?? []),
      status: TeamRegistrationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TeamRegistrationStatus.pending,
      ),
      qualifyingAnswers: (map['qualifyingAnswers'] as List<dynamic>?)
          ?.map((answerMap) => QualifyingAnswer.fromMap(answerMap as Map<String, dynamic>))
          .toList() ?? [],
      registrationDate: (map['registrationDate'] as Timestamp).toDate(),
      approvalDate: map['approvalDate'] != null 
          ? (map['approvalDate'] as Timestamp).toDate() 
          : null,
      rejectionReason: map['rejectionReason'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }

  TournamentTeamRegistration copyWith({
    String? id,
    String? tournamentId,
    String? tournamentName,
    String? teamId,
    String? teamName,
    String? captainId,
    String? captainName,
    String? captainImageUrl,
    List<String>? teamMemberIds,
    List<String>? teamMemberNames,
    TeamRegistrationStatus? status,
    List<QualifyingAnswer>? qualifyingAnswers,
    DateTime? registrationDate,
    DateTime? approvalDate,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TournamentTeamRegistration(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      captainImageUrl: captainImageUrl ?? this.captainImageUrl,
      teamMemberIds: teamMemberIds ?? this.teamMemberIds,
      teamMemberNames: teamMemberNames ?? this.teamMemberNames,
      status: status ?? this.status,
      qualifyingAnswers: qualifyingAnswers ?? this.qualifyingAnswers,
      registrationDate: registrationDate ?? this.registrationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if registration is pending approval
  bool get isPending => status == TeamRegistrationStatus.pending;

  /// Check if registration is approved
  bool get isApproved => status == TeamRegistrationStatus.approved;

  /// Check if registration is rejected
  bool get isRejected => status == TeamRegistrationStatus.rejected;

  /// Check if registration is withdrawn
  bool get isWithdrawn => status == TeamRegistrationStatus.withdrawn;

  /// Get team member count
  int get memberCount => teamMemberIds.length;
}
