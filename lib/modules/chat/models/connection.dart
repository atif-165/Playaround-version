import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for connection status
enum ConnectionStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  blocked('blocked');

  const ConnectionStatus(this.value);
  final String value;

  static ConnectionStatus fromString(String value) {
    return ConnectionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ConnectionStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ConnectionStatus.pending:
        return 'Pending';
      case ConnectionStatus.accepted:
        return 'Connected';
      case ConnectionStatus.rejected:
        return 'Rejected';
      case ConnectionStatus.blocked:
        return 'Blocked';
    }
  }
}

/// Model for user connections (LinkedIn-like system)
class Connection {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String toUserName;
  final String? fromUserImageUrl;
  final String? toUserImageUrl;
  final ConnectionStatus status;
  final String? message; // Optional message when sending connection request
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;

  const Connection({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.toUserName,
    this.fromUserImageUrl,
    this.toUserImageUrl,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
  });

  /// Check if connection is accepted
  bool get isAccepted => status == ConnectionStatus.accepted;

  /// Check if connection is pending
  bool get isPending => status == ConnectionStatus.pending;

  /// Check if connection is rejected
  bool get isRejected => status == ConnectionStatus.rejected;

  /// Check if connection is blocked
  bool get isBlocked => status == ConnectionStatus.blocked;

  /// Get the other user's ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == fromUserId ? toUserId : fromUserId;
  }

  /// Get the other user's name
  String getOtherUserName(String currentUserId) {
    return currentUserId == fromUserId ? toUserName : fromUserName;
  }

  /// Get the other user's image URL
  String? getOtherUserImageUrl(String currentUserId) {
    return currentUserId == fromUserId ? toUserImageUrl : fromUserImageUrl;
  }

  /// Check if current user sent the request
  bool didCurrentUserSendRequest(String currentUserId) {
    return fromUserId == currentUserId;
  }

  /// Check if current user received the request
  bool didCurrentUserReceiveRequest(String currentUserId) {
    return toUserId == currentUserId;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'fromUserImageUrl': fromUserImageUrl,
      'toUserImageUrl': toUserImageUrl,
      'status': status.value,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  static Connection? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    try {
      return Connection(
        id: doc.id,
        fromUserId: data['fromUserId'] as String,
        toUserId: data['toUserId'] as String,
        fromUserName: data['fromUserName'] as String,
        toUserName: data['toUserName'] as String,
        fromUserImageUrl: data['fromUserImageUrl'] as String?,
        toUserImageUrl: data['toUserImageUrl'] as String?,
        status: ConnectionStatus.fromString(data['status'] as String),
        message: data['message'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        respondedAt: data['respondedAt'] != null
            ? (data['respondedAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  Connection copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? toUserName,
    String? fromUserImageUrl,
    String? toUserImageUrl,
    ConnectionStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? respondedAt,
  }) {
    return Connection(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      fromUserImageUrl: fromUserImageUrl ?? this.fromUserImageUrl,
      toUserImageUrl: toUserImageUrl ?? this.toUserImageUrl,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Connection &&
        other.id == id &&
        other.fromUserId == fromUserId &&
        other.toUserId == toUserId &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fromUserId.hashCode ^
        toUserId.hashCode ^
        status.hashCode;
  }

  @override
  String toString() {
    return 'Connection(id: $id, from: $fromUserName, to: $toUserName, '
        'status: ${status.value})';
  }
}

/// Helper class for connection-related operations
class ConnectionHelper {
  /// Generate a unique connection ID from two user IDs
  static String generateConnectionId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Check if two users can chat based on connection status
  static bool canUsersChat(Connection? connection, bool isProfilePublic) {
    // If profile is public, anyone can chat
    if (isProfilePublic) return true;

    // If no connection exists, can't chat with private profile
    if (connection == null) return false;

    // Can only chat if connection is accepted
    return connection.isAccepted;
  }

  /// Get connection status display text
  static String getStatusDisplayText(
      ConnectionStatus status, bool isSentByCurrentUser) {
    switch (status) {
      case ConnectionStatus.pending:
        return isSentByCurrentUser ? 'Request Sent' : 'Pending Response';
      case ConnectionStatus.accepted:
        return 'Connected';
      case ConnectionStatus.rejected:
        return 'Request Rejected';
      case ConnectionStatus.blocked:
        return 'Blocked';
    }
  }
}
