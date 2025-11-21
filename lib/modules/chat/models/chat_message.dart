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
  tournament('tournament'),
  post('post'); // Community feed post

  const EntityType(this.value);
  final String value;

  static EntityType fromString(String value) {
    return EntityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EntityType.profile,
    );
  }
}

/// Enum describing attachment content types supported in chat
enum AttachmentType {
  image('image'),
  file('file');

  const AttachmentType(this.value);
  final String value;

  static AttachmentType fromString(String value) {
    return AttachmentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AttachmentType.file,
    );
  }
}

/// Metadata for a message attachment (images, files, etc.)
class ChatAttachment {
  final AttachmentType type;
  final String url;
  final String? thumbnailUrl;
  final String? name;
  final int? sizeInBytes;

  const ChatAttachment({
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.name,
    this.sizeInBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'name': name,
      'sizeInBytes': sizeInBytes,
    };
  }

  static ChatAttachment fromMap(Map<String, dynamic> map) {
    return ChatAttachment(
      type: AttachmentType.fromString(
          map['type'] as String? ?? AttachmentType.file.value),
      url: map['url'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      name: map['name'] as String?,
      sizeInBytes: map['sizeInBytes'] as int?,
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
  final Map<String, dynamic>?
      metadata; // Additional data like rating, price, etc.

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

/// Chat message model aligned with MVP requirements
class ChatMessage {
  final String id;
  final String chatId;
  final String fromId;
  final String? toId;
  final String? groupId;
  final String senderName;
  final String? senderImageUrl;
  final MessageType type;
  final String? text;
  final List<ChatAttachment> attachments;
  final SharedEntity? sharedEntity;
  final DateTime createdAt;
  final List<String> readBy;
  final bool isDeleted;
  final DateTime? editedAt;
  final String? editedBy;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.fromId,
    this.toId,
    this.groupId,
    required this.senderName,
    this.senderImageUrl,
    required this.type,
    this.text,
    this.attachments = const [],
    this.sharedEntity,
    required this.createdAt,
    this.readBy = const [],
    this.isDeleted = false,
    this.editedAt,
    this.editedBy,
  });

  /// Convenience getter preserved for legacy usages
  String get senderId => fromId;

  /// Primary image attachment if any
  String? get primaryImageUrl {
    if (attachments.isEmpty) return null;
    final imageAttachment = attachments.firstWhere(
      (attachment) => attachment.type == AttachmentType.image,
      orElse: () => attachments.first,
    );
    return imageAttachment.type == AttachmentType.image
        ? imageAttachment.url
        : null;
  }

  /// Backwards compatibility for older builds expecting single image url
  String? get imageUrl => primaryImageUrl;

  /// Check if message is read by specific user
  bool isReadBy(String userId) => readBy.contains(userId);

  /// Check if message is fully read (for direct chats)
  bool get isRead => readBy.isNotEmpty;

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
      'fromId': fromId,
      'toId': toId,
      'groupId': groupId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'type': type.value,
      'text': text,
      'attachments':
          attachments.map((attachment) => attachment.toMap()).toList(),
      'sharedEntity': sharedEntity?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'timestamp': Timestamp.fromDate(createdAt),
      'readBy': readBy,
      'isDeleted': isDeleted,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'editedBy': editedBy,
    };
  }

  static ChatMessage? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    try {
      final attachmentsData = (data['attachments'] as List<dynamic>?)
              ?.map((attachment) =>
                  ChatAttachment.fromMap(attachment as Map<String, dynamic>))
              .toList() ??
          [];

      // Backwards compatibility for legacy single image field
      if (attachmentsData.isEmpty &&
          data['imageUrl'] is String &&
          (data['imageUrl'] as String).isNotEmpty) {
        attachmentsData.add(
          ChatAttachment(
            type: AttachmentType.image,
            url: data['imageUrl'] as String,
          ),
        );
      }

      final timestamp = data['createdAt'] ?? data['timestamp'];

      return ChatMessage(
        id: doc.id,
        chatId: data['chatId'] as String? ?? '',
        fromId: data['fromId'] as String? ?? data['senderId'] as String? ?? '',
        toId: data['toId'] as String?,
        groupId: data['groupId'] as String?,
        senderName: data['senderName'] as String? ?? '',
        senderImageUrl: data['senderImageUrl'] as String?,
        type: MessageType.fromString(
            data['type'] as String? ?? MessageType.text.value),
        text: data['text'] as String?,
        attachments: attachmentsData,
        sharedEntity: data['sharedEntity'] != null
            ? SharedEntity.fromMap(data['sharedEntity'] as Map<String, dynamic>)
            : null,
        createdAt: timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now(),
        readBy: List<String>.from(data['readBy'] as List<dynamic>? ?? []),
        isDeleted: data['isDeleted'] as bool? ?? false,
        editedAt: data['editedAt'] is Timestamp
            ? (data['editedAt'] as Timestamp).toDate()
            : null,
        editedBy: data['editedBy'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? fromId,
    String? toId,
    String? groupId,
    String? senderName,
    String? senderImageUrl,
    MessageType? type,
    String? text,
    List<ChatAttachment>? attachments,
    SharedEntity? sharedEntity,
    DateTime? createdAt,
    List<String>? readBy,
    bool? isDeleted,
    DateTime? editedAt,
    String? editedBy,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      groupId: groupId ?? this.groupId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      type: type ?? this.type,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      sharedEntity: sharedEntity ?? this.sharedEntity,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
      editedBy: editedBy ?? this.editedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.chatId == chatId &&
        other.fromId == fromId &&
        other.type == type &&
        other.text == text &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        chatId.hashCode ^
        fromId.hashCode ^
        type.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, fromId: $fromId, type: ${type.value}, '
        'createdAt: $createdAt, readBy: ${readBy.length})';
  }
}
