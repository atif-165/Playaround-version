import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for chat room types
enum ChatType {
  direct('direct'),
  group('group');

  const ChatType(this.value);
  final String value;

  static ChatType fromString(String value) {
    return ChatType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChatType.direct,
    );
  }
}

/// Model for chat room participants
class ChatParticipant {
  final String userId;
  final String name;
  final String? imageUrl;
  final String role; // 'admin', 'member' for groups
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final bool isActive;

  const ChatParticipant({
    required this.userId,
    required this.name,
    this.imageUrl,
    this.role = 'member',
    required this.joinedAt,
    this.lastReadAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastReadAt': lastReadAt != null ? Timestamp.fromDate(lastReadAt!) : null,
      'isActive': isActive,
    };
  }

  static ChatParticipant fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      userId: map['userId'] as String,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String?,
      role: map['role'] as String? ?? 'member',
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      lastReadAt: map['lastReadAt'] != null
          ? (map['lastReadAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  ChatParticipant copyWith({
    String? userId,
    String? name,
    String? imageUrl,
    String? role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    bool? isActive,
  }) {
    return ChatParticipant(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Chat room model for both direct and group chats
class ChatRoom {
  final String id;
  final ChatType type;
  final String? name; // For group chats
  final String? imageUrl; // For group chats
  final String? description; // For group chats
  final List<ChatParticipant> participants;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, int> unreadCounts; // userId -> unread count
  final String?
      relatedEntityType; // 'team', 'tournament' for auto-created groups
  final String? relatedEntityId;
  final Map<String, dynamic>?
      metadata; // Additional metadata (e.g., booking info)

  const ChatRoom({
    required this.id,
    required this.type,
    this.name,
    this.imageUrl,
    this.description,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.unreadCounts = const {},
    this.relatedEntityType,
    this.relatedEntityId,
    this.metadata,
  });

  /// Get display name for the chat room
  String getDisplayName(String currentUserId) {
    if (type == ChatType.group) {
      return name ?? 'Group Chat';
    }

    // For direct chats, return the other participant's name
    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.name;
  }

  /// Get display image for the chat room
  String? getDisplayImage(String currentUserId) {
    if (type == ChatType.group) {
      return imageUrl;
    }

    // For direct chats, return the other participant's image
    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.imageUrl;
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  /// Convenience getters for chat type checks
  bool get isGroupChat => type == ChatType.group;
  bool get isDirectChat => type == ChatType.direct;

  /// Check if user is admin (for group chats)
  bool isUserAdmin(String userId) {
    final participant =
        participants.where((p) => p.userId == userId).firstOrNull;
    return participant?.role == 'admin';
  }

  /// Get other participant in direct chat
  ChatParticipant? getOtherParticipant(String currentUserId) {
    if (type != ChatType.direct) return null;
    return participants.where((p) => p.userId != currentUserId).firstOrNull;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.value,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'participants': participants.map((p) => p.toMap()).toList(),
      'participantIds':
          participants.map((p) => p.userId).toList(), // Simple array for rules
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'unreadCounts': unreadCounts,
      'relatedEntityType': relatedEntityType,
      'relatedEntityId': relatedEntityId,
      'metadata': metadata,
    };
  }

  static ChatRoom? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    try {
      return ChatRoom(
        id: doc.id,
        type: ChatType.fromString(data['type'] as String),
        name: data['name'] as String?,
        imageUrl: data['imageUrl'] as String?,
        description: data['description'] as String?,
        participants: (data['participants'] as List<dynamic>?)
                ?.map((p) => ChatParticipant.fromMap(p as Map<String, dynamic>))
                .toList() ??
            [],
        lastMessage: data['lastMessage'] as String?,
        lastMessageSenderId: data['lastMessageSenderId'] as String?,
        lastMessageAt: data['lastMessageAt'] != null
            ? (data['lastMessageAt'] as Timestamp).toDate()
            : null,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        isActive: data['isActive'] as bool? ?? true,
        unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
        relatedEntityType: data['relatedEntityType'] as String?,
        relatedEntityId: data['relatedEntityId'] as String?,
        metadata: data['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return null;
    }
  }

  ChatRoom copyWith({
    String? id,
    ChatType? type,
    String? name,
    String? imageUrl,
    String? description,
    List<ChatParticipant>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, int>? unreadCounts,
    String? relatedEntityType,
    String? relatedEntityId,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoom &&
        other.id == id &&
        other.type == type &&
        other.name == name &&
        other.participants.length == participants.length;
  }

  @override
  int get hashCode {
    return id.hashCode ^ type.hashCode ^ name.hashCode;
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, type: ${type.value}, name: $name, '
        'participants: ${participants.length})';
  }
}
