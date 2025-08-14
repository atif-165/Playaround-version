import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for join request status
enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  cancelled;

  String get displayName {
    switch (this) {
      case JoinRequestStatus.pending:
        return 'Pending';
      case JoinRequestStatus.approved:
        return 'Approved';
      case JoinRequestStatus.rejected:
        return 'Rejected';
      case JoinRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Model representing a team join request
class TeamJoinRequest {
  final String id;
  final String teamId;
  final String teamName;
  final String requesterId;
  final String requesterName;
  final String? requesterEmail;
  final String? requesterProfileImageUrl;
  final String? message;
  final JoinRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? respondedBy;
  final String? responseMessage;

  const TeamJoinRequest({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.requesterId,
    required this.requesterName,
    this.requesterEmail,
    this.requesterProfileImageUrl,
    this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.respondedBy,
    this.responseMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'teamName': teamName,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'requesterProfileImageUrl': requesterProfileImageUrl,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedBy': respondedBy,
      'responseMessage': responseMessage,
    };
  }

  factory TeamJoinRequest.fromMap(Map<String, dynamic> map) {
    return TeamJoinRequest(
      id: map['id'] ?? '',
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterEmail: map['requesterEmail'],
      requesterProfileImageUrl: map['requesterProfileImageUrl'],
      message: map['message'],
      status: JoinRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JoinRequestStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      respondedAt: map['respondedAt'] != null 
          ? (map['respondedAt'] as Timestamp).toDate() 
          : null,
      respondedBy: map['respondedBy'],
      responseMessage: map['responseMessage'],
    );
  }

  TeamJoinRequest copyWith({
    String? id,
    String? teamId,
    String? teamName,
    String? requesterId,
    String? requesterName,
    String? requesterEmail,
    String? requesterProfileImageUrl,
    String? message,
    JoinRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? respondedBy,
    String? responseMessage,
  }) {
    return TeamJoinRequest(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterProfileImageUrl: requesterProfileImageUrl ?? this.requesterProfileImageUrl,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      responseMessage: responseMessage ?? this.responseMessage,
    );
  }

  /// Check if request is still pending
  bool get isPending => status == JoinRequestStatus.pending;

  /// Check if request was approved
  bool get isApproved => status == JoinRequestStatus.approved;

  /// Check if request was rejected
  bool get isRejected => status == JoinRequestStatus.rejected;

  /// Check if request was cancelled
  bool get isCancelled => status == JoinRequestStatus.cancelled;
}
