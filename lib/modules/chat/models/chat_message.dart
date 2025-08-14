import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for message content types
enum MessageType {
  text('text'),
  image('image'),
  entity('entity'); // For sharing profiles, venues, teams, tournaments

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Enum for entity types that can be shared
enum EntityType {
  profile('profile'),
  venue('venue'),
  team('team'),
  tournament('tournament');

  const EntityType(this.value);
  final String value;

  static EntityType fromString(String value) {
    return EntityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EntityType.profile,
    );
  }
}

/// Model for shared entities in chat
class SharedEntity {
  final EntityType type;
  final String id;
  final String title;
  final String? imageUrl;
  final String? subtitle; // Location for venues, sport for teams, etc.
  final Map<String, dynamic>? metadata; // Additional data like rating, price, etc.

  const SharedEntity({
    required this.type,
    required this.id,
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'subtitle': subtitle,
      'metadata': metadata,
    };
  }

  static SharedEntity fromMap(Map<String, dynamic> map) {
    return SharedEntity(
      type: EntityType.fromString(map['type'] as String),
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String?,
      subtitle: map['subtitle'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Chat message model adapted from ApnaChat with PlayAround-specific features
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final MessageType type;
  final String? text;
  final String? imageUrl;
  final SharedEntity? sharedEntity;
  final DateTime timestamp;
  final DateTime? readAt;
  final bool isDeleted;
  final DateTime? editedAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.type,
    this.text,
    this.imageUrl,
    this.sharedEntity,
    required this.timestamp,
    this.readAt,
    this.isDeleted = false,
    this.editedAt,
  });

  /// Check if message is read
  bool get isRead => readAt != null;

  /// Check if message is edited
  bool get isEdited => editedAt != null;

  /// Get display content based on message type
  String get displayContent {
    if (isDeleted) return 'This message was deleted';
    
    switch (type) {
      case MessageType.text:
        return text ?? '';
      case MessageType.image:
        return '📷 Image';
      case MessageType.entity:
        return '🔗 Shared ${sharedEntity?.type.value ?? 'item'}';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'type': type.value,
      'text': text,
      'imageUrl': imageUrl,
      'sharedEntity': sharedEntity?.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isDeleted': isDeleted,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  static ChatMessage? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    try {
      return ChatMessage(
        id: doc.id,
        chatId: data['chatId'] as String,
        senderId: data['senderId'] as String,
        senderName: data['senderName'] as String,
        senderImageUrl: data['senderImageUrl'] as String?,
        type: MessageType.fromString(data['type'] as String),
        text: data['text'] as String?,
        imageUrl: data['imageUrl'] as String?,
        sharedEntity: data['sharedEntity'] != null 
            ? SharedEntity.fromMap(data['sharedEntity'] as Map<String, dynamic>)
            : null,
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        readAt: data['readAt'] != null 
            ? (data['readAt'] as Timestamp).toDate() 
            : null,
        isDeleted: data['isDeleted'] as bool? ?? false,
        editedAt: data['editedAt'] != null 
            ? (data['editedAt'] as Timestamp).toDate() 
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderImageUrl,
    MessageType? type,
    String? text,
    String? imageUrl,
    SharedEntity? sharedEntity,
    DateTime? timestamp,
    DateTime? readAt,
    bool? isDeleted,
    DateTime? editedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      type: type ?? this.type,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      sharedEntity: sharedEntity ?? this.sharedEntity,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.type == type &&
        other.text == text &&
        other.imageUrl == imageUrl &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        chatId.hashCode ^
        senderId.hashCode ^
        type.hashCode ^
        timestamp.hashCode;
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, type: ${type.value}, '
        'timestamp: $timestamp, isRead: $isRead)';
  }
}
