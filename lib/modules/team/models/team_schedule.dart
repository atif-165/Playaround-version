import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for schedule event types
enum ScheduleEventType {
  practice,
  match,
  tournament,
  meeting,
  other;

  String get displayName {
    switch (this) {
      case ScheduleEventType.practice:
        return 'Practice';
      case ScheduleEventType.match:
        return 'Match';
      case ScheduleEventType.tournament:
        return 'Tournament';
      case ScheduleEventType.meeting:
        return 'Meeting';
      case ScheduleEventType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ScheduleEventType.practice:
        return '🏃';
      case ScheduleEventType.match:
        return '⚽';
      case ScheduleEventType.tournament:
        return '🏆';
      case ScheduleEventType.meeting:
        return '👥';
      case ScheduleEventType.other:
        return '📅';
    }
  }
}

/// Model for team schedule events
class TeamScheduleEvent {
  final String id;
  final String teamId;
  final String title;
  final String? description;
  final ScheduleEventType type;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? venueId;
  final String? venueName;
  final List<String> requiredMembers; // Member IDs who must attend
  final List<String> optionalMembers; // Member IDs who can attend
  final String? createdBy; // Member ID who created the event
  final String? createdByName;
  final bool isRecurring;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly'
  final DateTime? recurrenceEndDate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamScheduleEvent({
    required this.id,
    required this.teamId,
    required this.title,
    this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.location,
    this.venueId,
    this.venueName,
    this.requiredMembers = const [],
    this.optionalMembers = const [],
    this.createdBy,
    this.createdByName,
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceEndDate,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'title': title,
      'description': description,
      'type': type.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'venueId': venueId,
      'venueName': venueName,
      'requiredMembers': requiredMembers,
      'optionalMembers': optionalMembers,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'recurrenceEndDate': recurrenceEndDate != null 
          ? Timestamp.fromDate(recurrenceEndDate!) 
          : null,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TeamScheduleEvent.fromMap(Map<String, dynamic> map) {
    return TeamScheduleEvent(
      id: map['id'] ?? '',
      teamId: map['teamId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      type: ScheduleEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ScheduleEventType.other,
      ),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      location: map['location'],
      venueId: map['venueId'],
      venueName: map['venueName'],
      requiredMembers: List<String>.from(map['requiredMembers'] ?? []),
      optionalMembers: List<String>.from(map['optionalMembers'] ?? []),
      createdBy: map['createdBy'],
      createdByName: map['createdByName'],
      isRecurring: map['isRecurring'] ?? false,
      recurrencePattern: map['recurrencePattern'],
      recurrenceEndDate: map['recurrenceEndDate'] != null 
          ? (map['recurrenceEndDate'] as Timestamp).toDate() 
          : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  TeamScheduleEvent copyWith({
    String? id,
    String? teamId,
    String? title,
    String? description,
    ScheduleEventType? type,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? venueId,
    String? venueName,
    List<String>? requiredMembers,
    List<String>? optionalMembers,
    String? createdBy,
    String? createdByName,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? recurrenceEndDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamScheduleEvent(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      requiredMembers: requiredMembers ?? this.requiredMembers,
      optionalMembers: optionalMembers ?? this.optionalMembers,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if event is happening today
  bool get isToday {
    final now = DateTime.now();
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    final today = DateTime(now.year, now.month, now.day);
    return eventDate.isAtSameMomentAs(today);
  }

  /// Check if event is in the past
  bool get isPast {
    return endTime.isBefore(DateTime.now());
  }

  /// Check if event is in the future
  bool get isFuture {
    return startTime.isAfter(DateTime.now());
  }

  /// Get duration of the event
  Duration get duration {
    return endTime.difference(startTime);
  }

  /// Get formatted duration string
  String get durationString {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Model for member attendance
class MemberAttendance {
  final String eventId;
  final String memberId;
  final String memberName;
  final AttendanceStatus status;
  final String? reason; // For absence or late arrival
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime updatedAt;

  const MemberAttendance({
    required this.eventId,
    required this.memberId,
    required this.memberName,
    required this.status,
    this.reason,
    this.checkInTime,
    this.checkOutTime,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'memberId': memberId,
      'memberName': memberName,
      'status': status.name,
      'reason': reason,
      'checkInTime': checkInTime != null 
          ? Timestamp.fromDate(checkInTime!) 
          : null,
      'checkOutTime': checkOutTime != null 
          ? Timestamp.fromDate(checkOutTime!) 
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MemberAttendance.fromMap(Map<String, dynamic> map) {
    return MemberAttendance(
      eventId: map['eventId'] ?? '',
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.pending,
      ),
      reason: map['reason'],
      checkInTime: map['checkInTime'] != null 
          ? (map['checkInTime'] as Timestamp).toDate() 
          : null,
      checkOutTime: map['checkOutTime'] != null 
          ? (map['checkOutTime'] as Timestamp).toDate() 
          : null,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}

/// Enum for attendance status
enum AttendanceStatus {
  pending,
  present,
  absent,
  late,
  excused;

  String get displayName {
    switch (this) {
      case AttendanceStatus.pending:
        return 'Pending';
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  String get icon {
    switch (this) {
      case AttendanceStatus.pending:
        return '⏳';
      case AttendanceStatus.present:
        return '✅';
      case AttendanceStatus.absent:
        return '❌';
      case AttendanceStatus.late:
        return '⏰';
      case AttendanceStatus.excused:
        return '📝';
    }
  }
}
