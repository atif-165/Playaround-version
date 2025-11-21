import 'package:cloud_firestore/cloud_firestore.dart';

import 'listing_model.dart';

/// Status for a scheduled coaching session.
enum SessionStatus {
  scheduled,
  cancelled,
  completed;

  String get displayName {
    switch (this) {
      case SessionStatus.scheduled:
        return 'Scheduled';
      case SessionStatus.cancelled:
        return 'Cancelled';
      case SessionStatus.completed:
        return 'Completed';
    }
  }

  static SessionStatus fromString(String value) {
    return SessionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SessionStatus.scheduled,
    );
  }
}

/// Participant metadata stored with a session.
class SessionParticipant {
  const SessionParticipant({
    required this.email,
    this.userId,
    this.displayName,
  });

  final String? userId;
  final String email;
  final String? displayName;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
    };
  }

  factory SessionParticipant.fromMap(Map<String, dynamic> map) {
    return SessionParticipant(
      userId: map['userId'] as String?,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
    );
  }
}

/// Coaching/training session created by a coach.
class SessionModel {
  const SessionModel({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.sport,
    required this.startTime,
    required this.durationMinutes,
    required this.status,
    required this.description,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.cancellationReason,
  });

  final String id;
  final String coachId;
  final String coachName;
  final SportType sport;
  final DateTime startTime;
  final int durationMinutes;
  final SessionStatus status;
  final String description;
  final List<SessionParticipant> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancellationReason;

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  bool get isCancelled => status == SessionStatus.cancelled;

  bool get isCompleted => status == SessionStatus.completed;

  bool get isUpcoming => !isCancelled && endTime.isAfter(DateTime.now());

  List<String> get participantIds => participants
      .where((p) => p.userId != null)
      .map((p) => p.userId!)
      .toList();

  List<String> get participantEmails =>
      participants.map((p) => p.email).toList();

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'coachId': coachId,
      'coachName': coachName,
      'sport': sport.name,
      'sportDisplayName': sport.displayName,
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': durationMinutes,
      'status': status.name,
      'description': description,
      'participants': participants.map((p) => p.toMap()).toList(),
      'participantIds': participantIds,
      'participantEmails': participantEmails,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cancellationReason': cancellationReason,
    };
  }

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel.fromMap(data);
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String? ?? '',
      coachId: map['coachId'] as String? ?? '',
      coachName: map['coachName'] as String? ?? '',
      sport: SportType.fromString(map['sport'] as String? ?? ''),
      startTime: (map['startTime'] as Timestamp).toDate(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      status: SessionStatus.fromString(
          map['status'] as String? ?? SessionStatus.scheduled.name),
      description: map['description'] as String? ?? '',
      participants: (map['participants'] as List<dynamic>? ?? [])
          .map(
            (item) => SessionParticipant.fromMap(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancellationReason: map['cancellationReason'] as String?,
    );
  }

  SessionModel copyWith({
    String? id,
    String? coachId,
    String? coachName,
    SportType? sport,
    DateTime? startTime,
    int? durationMinutes,
    SessionStatus? status,
    String? description,
    List<SessionParticipant>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancellationReason,
  }) {
    return SessionModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      sport: sport ?? this.sport,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
