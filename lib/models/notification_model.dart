import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for notification types
enum NotificationType {
  venueBooking('venue_booking'),
  tournamentRegistration('tournament_registration'),
  tournamentApproval('tournament_approval'),
  tournamentRejection('tournament_rejection'),
  tournamentRemoval('tournament_removal'),
  tournamentTeamUpdate('tournament_team_update'),
  matchScheduled('match_scheduled'),
  scoreUpdate('score_update'),
  tournamentComplete('tournament_complete'),
  teamInvite('team_invite'),
  ratingReceived('rating_received'),
  ratingRequest('rating_request'),
  profileLike('profile_like'),
  profileComment('profile_comment'),
  userMatch('user_match'),
  general('general');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.general,
    );
  }

  String get displayName {
    switch (this) {
      case NotificationType.venueBooking:
        return 'Venue Booking';
      case NotificationType.tournamentRegistration:
        return 'Tournament Registration';
      case NotificationType.tournamentApproval:
        return 'Tournament Approval';
      case NotificationType.tournamentRejection:
        return 'Tournament Rejection';
      case NotificationType.tournamentRemoval:
        return 'Tournament Removal';
      case NotificationType.tournamentTeamUpdate:
        return 'Tournament Team Update';
      case NotificationType.matchScheduled:
        return 'Match Scheduled';
      case NotificationType.scoreUpdate:
        return 'Score Update';
      case NotificationType.tournamentComplete:
        return 'Tournament Complete';
      case NotificationType.teamInvite:
        return 'Team Invite';
      case NotificationType.ratingReceived:
        return 'Rating Received';
      case NotificationType.ratingRequest:
        return 'Rating Request';
      case NotificationType.profileLike:
        return 'Profile Like';
      case NotificationType.profileComment:
        return 'Profile Comment';
      case NotificationType.userMatch:
        return 'Match';
      case NotificationType.general:
        return 'General';
    }
  }
}

/// Model for notifications
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Additional data for navigation
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(data);
  }

  /// Create from Map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: NotificationType.fromString(map['type'] as String),
      title: map['title'] as String,
      message: map['message'] as String,
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      readAt: map['readAt'] != null 
          ? (map['readAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, isRead: $isRead)';
  }
}
