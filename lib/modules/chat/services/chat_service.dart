import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart';

import '../../../models/user_profile.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../repositories/user_repository.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/connection.dart';
import 'chat_notification_service.dart';

/// Service for chat functionality with Firestore integration
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Timer? _debounceTimer;

  @visibleForTesting
  void overrideDependencies({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseMessaging? messaging,
    FirebaseStorage? storage,
    ChatNotificationService? notificationService,
    UserRepository? userRepository,
  }) {
    if (firestore != null) _firestore = firestore;
    if (auth != null) _auth = auth;
    if (messaging != null) _messaging = messaging;
    if (storage != null) _storage = storage;
    if (notificationService != null) _notificationService = notificationService;
    if (userRepository != null) _userRepository = userRepository;
  }

  /// Utility to build canonical team chat id.
  String teamChatId(String teamId) => 'team_$teamId';

  @visibleForTesting
  void resetDependencies() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _messaging = FirebaseMessaging.instance;
    _storage = FirebaseStorage.instance;
    _notificationService = ChatNotificationService();
    _userRepository = UserRepository();
  }

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseMessaging _messaging = FirebaseMessaging.instance;
  UserRepository _userRepository = UserRepository();
  FirebaseStorage _storage = FirebaseStorage.instance;
  ChatNotificationService _notificationService = ChatNotificationService();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection('chats').withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) =>
                Map<String, dynamic>.from(snapshot.data() ?? const {}),
            toFirestore: (value, _) => value,
          );
  CollectionReference<Map<String, dynamic>> get _connectionsCollection =>
      _firestore.collection('connections').withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) =>
                Map<String, dynamic>.from(snapshot.data() ?? const {}),
            toFirestore: (value, _) => value,
          );
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users').withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) =>
                Map<String, dynamic>.from(snapshot.data() ?? const {}),
            toFirestore: (value, _) => value,
          );

  /// Initialize chat service and request notification permissions
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get and store FCM token
      final token = await _messaging.getToken();
      if (token != null && _auth.currentUser != null) {
        await _updateUserFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_updateUserFCMToken);

      // Initialize notification service
      await _notificationService.initialize();

      if (kDebugMode) {
        debugPrint('✅ ChatService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error initializing - $e');
      }
    }
  }

  /// Update user's FCM token in Firestore
  Future<void> _updateUserFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _usersCollection.doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error updating FCM token - $e');
      }
    }
  }

  Map<String, dynamic>? _getNonConnectionMetadata(ChatRoom chatRoom) {
    final metadata = chatRoom.metadata;
    if (metadata == null) return null;
    final nonConnection = metadata['nonConnection'];
    if (nonConnection is Map<String, dynamic>) {
      return Map<String, dynamic>.from(nonConnection);
    }
    return null;
  }

  String? _validateNonConnectionSend(ChatRoom chatRoom, String senderId) {
    final meta = _getNonConnectionMetadata(chatRoom);
    if (meta == null) return null;

    final status = (meta['status'] as String?)?.toLowerCase() ?? 'pending';
    final initiatorId = meta['initiatorId'] as String?;
    final allowedMessages =
        meta['allowedMessages'] is int ? meta['allowedMessages'] as int : 1;
    final sentCount = meta['initiatorMessageCount'] is int
        ? meta['initiatorMessageCount'] as int
        : 0;

    switch (status) {
      case 'accepted':
        return null;
      case 'pending':
        if (initiatorId == null) return 'invalid_metadata';
        if (senderId == initiatorId) {
          if (allowedMessages <= 0) return 'initiator_limit_reached';
          if (sentCount >= allowedMessages) {
            return 'initiator_limit_reached';
          }
          return null;
        }
        return 'receiver_not_allowed';
      case 'blocked':
        return 'chat_blocked';
      case 'reported':
        return 'chat_reported';
      default:
        return null;
    }
  }

  Future<void> _recordNonConnectionMessageSend(
      ChatRoom chatRoom, String senderId) async {
    final meta = _getNonConnectionMetadata(chatRoom);
    if (meta == null) return;
    final status = (meta['status'] as String?)?.toLowerCase() ?? 'pending';
    if (status != 'pending') return;

    final initiatorId = meta['initiatorId'] as String?;
    if (initiatorId == null) return;

    try {
      final updateData = <String, dynamic>{
        'metadata.nonConnection.lastMessageAt': FieldValue.serverTimestamp(),
      };

      if (senderId == initiatorId) {
        updateData['metadata.nonConnection.initiatorMessageCount'] =
            FieldValue.increment(1);
      }

      await _chatsCollection.doc(chatRoom.id).update(updateData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error recording non-connection message send - $e');
      }
    }
  }

  /// Create a direct chat room between two users (alias for getOrCreateDirectChat)
  Future<ChatRoom?> createDirectChat(String otherUserId) async {
    return getOrCreateDirectChat(otherUserId);
  }

  /// Get or create a direct chat room between two users
  Future<ChatRoom?> getOrCreateDirectChat(
    String otherUserId, {
    String? otherUserName,
    String? otherUserImageUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Generate consistent chat ID
      final chatId = _generateDirectChatId(currentUser.uid, otherUserId);

      // Check if chat already exists
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (chatDoc.exists) {
        return ChatRoom.fromFirestore(chatDoc);
      }

      // Get user profiles
      final currentUserProfile =
          await _userRepository.getUserProfile(currentUser.uid);
      final otherUserProfile =
          await _userRepository.getUserProfile(otherUserId);

      final now = DateTime.now();
      final participants = [
        _buildParticipant(
          userId: currentUser.uid,
          profile: currentUserProfile,
          fallbackName: currentUser.displayName ?? currentUser.email ?? 'You',
          fallbackImageUrl: currentUser.photoURL,
          joinedAt: now,
          defaultName: 'You',
        ),
        _buildParticipant(
          userId: otherUserId,
          profile: otherUserProfile,
          fallbackName: otherUserName,
          fallbackImageUrl: otherUserImageUrl,
          joinedAt: now,
          defaultName: 'Player',
        ),
      ];

      final chatRoom = ChatRoom(
        id: chatId,
        type: ChatType.direct,
        participants: participants,
        createdAt: now,
        updatedAt: now,
      );

      await _chatsCollection.doc(chatId).set(chatRoom.toFirestore());
      return chatRoom;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error creating direct chat - $e');
      }
      return null;
    }
  }

  Future<ChatRoom?> startNonConnectionChat(
    String otherUserId, {
    String? otherUserName,
    String? otherUserImageUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final chatRoom = await getOrCreateDirectChat(
        otherUserId,
        otherUserName: otherUserName,
        otherUserImageUrl: otherUserImageUrl,
      );
      if (chatRoom == null) return null;

      final existingMeta = _getNonConnectionMetadata(chatRoom);
      final chatRef = _chatsCollection.doc(chatRoom.id);

      if (existingMeta == null) {
        await chatRef.update({
          'metadata.nonConnection': {
            'status': 'pending',
            'initiatorId': currentUser.uid,
            'allowedMessages': 1,
            'initiatorMessageCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          },
        });
      } else {
        final status =
            (existingMeta['status'] as String?)?.toLowerCase() ?? 'pending';
        final initiatorId = existingMeta['initiatorId'] as String?;
        final allowedMessages = existingMeta['allowedMessages'] is int
            ? existingMeta['allowedMessages'] as int
            : 1;

        if (status == 'accepted' && initiatorId != null) {
          return chatRoom;
        }

        if (initiatorId != currentUser.uid || status != 'pending') {
          await chatRef.update({
            'metadata.nonConnection.status': 'pending',
            'metadata.nonConnection.initiatorId': currentUser.uid,
            'metadata.nonConnection.allowedMessages': allowedMessages,
            'metadata.nonConnection.initiatorMessageCount': 0,
            'metadata.nonConnection.createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return await getChatRoom(chatRoom.id) ?? chatRoom;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error starting non-connection chat - $e');
      }
      return null;
    }
  }

  /// Generate consistent chat ID for direct chats
  String _generateDirectChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'direct_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Send a text message
  Future<bool> sendTextMessage({
    required String chatId,
    required String text,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userProfile = await _userRepository.getUserProfile(currentUser.uid);
      if (userProfile == null) return false;

      final chatRoom = await getChatRoom(chatId);
      if (chatRoom == null) return false;

      final restriction = _validateNonConnectionSend(chatRoom, currentUser.uid);
      if (restriction != null) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ ChatService: Text message blocked ($restriction) for chat $chatId');
        }
        return false;
      }

      final messageId = _firestore.collection('temp').doc().id;
      final now = DateTime.now();
      final targetUserId = chatRoom.isGroupChat
          ? null
          : chatRoom.participants
              .where((participant) => participant.userId != currentUser.uid)
              .firstOrNull
              ?.userId;

      final message = ChatMessage(
        id: messageId,
        chatId: chatId,
        fromId: currentUser.uid,
        toId: targetUserId,
        groupId: chatRoom.isGroupChat ? chatRoom.id : null,
        senderName: userProfile.fullName,
        senderImageUrl: userProfile.profilePictureUrl,
        type: MessageType.text,
        text: text,
        attachments: const [],
        createdAt: now,
        readBy: [currentUser.uid],
      );

      final messageData = message.toFirestore();
      messageData['createdAt'] = FieldValue.serverTimestamp();
      messageData['timestamp'] = FieldValue.serverTimestamp();
      messageData['readBy'] = [currentUser.uid];

      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update chat room with last message
      await _updateChatRoomLastMessage(chatId, text, currentUser.uid, now);

      await _recordNonConnectionMessageSend(chatRoom, currentUser.uid);

      // Send push notifications
      await _sendMessageNotifications(message, chatId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error sending text message - $e');
      }
      return false;
    }
  }

  /// Send an image message using Cloudinary
  Future<bool> sendImageMessage({
    required String chatId,
    required File imageFile,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userProfile = await _userRepository.getUserProfile(currentUser.uid);
      if (userProfile == null) return false;

      final chatRoom = await getChatRoom(chatId);
      if (chatRoom == null) return false;

      final restriction = _validateNonConnectionSend(chatRoom, currentUser.uid);
      if (restriction != null) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ ChatService: Image message blocked ($restriction) for chat $chatId');
        }
        return false;
      }

      final messageId = _firestore.collection('temp').doc().id;
      final now = DateTime.now();
      final attachment = await _uploadImageAttachment(
        chatId: chatId,
        messageId: messageId,
        imageFile: imageFile,
      );

      if (attachment == null) return false;

      final message = ChatMessage(
        id: messageId,
        chatId: chatId,
        fromId: currentUser.uid,
        toId: chatRoom.isGroupChat
            ? null
            : chatRoom.participants
                .where((participant) => participant.userId != currentUser.uid)
                .firstOrNull
                ?.userId,
        groupId: chatRoom.isGroupChat ? chatRoom.id : null,
        senderName: userProfile.fullName,
        senderImageUrl: userProfile.profilePictureUrl,
        type: MessageType.image,
        attachments: [attachment],
        createdAt: now,
        readBy: [currentUser.uid],
      );

      final messageData = message.toFirestore();
      messageData['createdAt'] = FieldValue.serverTimestamp();
      messageData['timestamp'] = FieldValue.serverTimestamp();
      messageData['readBy'] = [currentUser.uid];

      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update chat room with last message
      await _updateChatRoomLastMessage(
          chatId, '📷 Image', currentUser.uid, now);

      await _recordNonConnectionMessageSend(chatRoom, currentUser.uid);

      // Send push notifications
      await _sendMessageNotifications(message, chatId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error sending image message - $e');
      }
      return false;
    }
  }

  /// Send an entity (profile, venue, team, tournament) message
  Future<bool> sendEntityMessage({
    required String chatId,
    required SharedEntity entity,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userProfile = await _userRepository.getUserProfile(currentUser.uid);
      if (userProfile == null) return false;

      final chatRoom = await getChatRoom(chatId);
      if (chatRoom == null) return false;

      final restriction = _validateNonConnectionSend(chatRoom, currentUser.uid);
      if (restriction != null) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ ChatService: Entity message blocked ($restriction) for chat $chatId');
        }
        return false;
      }

      final messageId = _firestore.collection('temp').doc().id;
      final now = DateTime.now();

      final message = ChatMessage(
        id: messageId,
        chatId: chatId,
        fromId: currentUser.uid,
        toId: chatRoom.isGroupChat
            ? null
            : chatRoom.participants
                .where((participant) => participant.userId != currentUser.uid)
                .firstOrNull
                ?.userId,
        groupId: chatRoom.isGroupChat ? chatRoom.id : null,
        senderName: userProfile.fullName,
        senderImageUrl: userProfile.profilePictureUrl,
        type: MessageType.entity,
        sharedEntity: entity,
        createdAt: now,
        readBy: [currentUser.uid],
      );

      final messageData = message.toFirestore();
      messageData['createdAt'] = FieldValue.serverTimestamp();
      messageData['timestamp'] = FieldValue.serverTimestamp();
      messageData['readBy'] = [currentUser.uid];

      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update chat room with last message
      await _updateChatRoomLastMessage(
        chatId,
        '🔗 Shared ${entity.type.value}',
        currentUser.uid,
        now,
      );

      await _recordNonConnectionMessageSend(chatRoom, currentUser.uid);

      // Send push notifications
      await _sendMessageNotifications(message, chatId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error sending entity message - $e');
      }
      return false;
    }
  }

  Future<ChatAttachment?> _uploadImageAttachment({
    required String chatId,
    required String messageId,
    required File imageFile,
  }) async {
    try {
      final fileName = imageFile.uri.pathSegments.isNotEmpty
          ? imageFile.uri.pathSegments.last
          : '$messageId.jpg';
      final sanitizedFileName =
          fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final reference = _storage
          .ref()
          .child('chat_media/$chatId/$messageId/$sanitizedFileName');

      final contentType = _inferImageContentType(fileName);

      final uploadTask = await reference.putFile(
        imageFile,
        SettableMetadata(contentType: contentType),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return ChatAttachment(
        type: AttachmentType.image,
        url: downloadUrl,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error uploading image attachment - $e');
      }
      return null;
    }
  }

  String _inferImageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  /// Update chat room's last message info
  Future<void> _updateChatRoomLastMessage(
    String chatId,
    String lastMessage,
    String senderId,
    DateTime timestamp,
  ) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'lastMessage': lastMessage,
        'lastMessageSenderId': senderId,
        'lastMessageAt': Timestamp.fromDate(timestamp),
        'updatedAt': Timestamp.fromDate(timestamp),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error updating last message - $e');
      }
    }
  }

  /// Get chat rooms for current user
  Stream<List<ChatRoom>> getUserChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: No authenticated user for getUserChatRooms');
      }
      return Stream.value([]);
    }

    try {
      return _chatsCollection
          .where('participantIds', arrayContains: currentUser.uid)
          .snapshots()
          .handleError((error) {
        if (kDebugMode) {
          debugPrint(
              '❌ ChatService: Error in getUserChatRooms stream - $error');
        }
      }).asyncMap((snapshot) async {
        if (_debounceTimer != null && _debounceTimer!.isActive) {
          _debounceTimer!.cancel();
        }
        final completer = Completer<QuerySnapshot<Map<String, dynamic>>>();
        _debounceTimer = Timer(const Duration(milliseconds: 250), () {
          if (!completer.isCompleted) {
            completer.complete(snapshot);
          }
        });
        final debouncedSnapshot = await completer.future;

        try {
          final rooms = debouncedSnapshot.docs
              .map((doc) {
                try {
                  return ChatRoom.fromFirestore(doc);
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint(
                        '❌ ChatService: Error parsing chat room ${doc.id} - $e');
                  }
                  return null;
                }
              })
              .where((room) => room != null)
              .cast<ChatRoom>()
              .toList();

          rooms.sort(
            (a, b) => b.updatedAt.compareTo(a.updatedAt),
          );
          return rooms;
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ ChatService: Error processing chat rooms snapshot - $e');
          }
          return <ChatRoom>[];
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error setting up getUserChatRooms stream - $e');
      }
      return Stream.value([]);
    }
  }

  /// Get messages for a specific chat (latest [limit] messages by default)
  Stream<List<ChatMessage>> getChatMessages(String chatId, {int limit = 50}) {
    try {
      return _chatsCollection
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .handleError((error) {
        if (kDebugMode) {
          debugPrint(
              '❌ ChatService: Error in getChatMessages stream for chat $chatId - $error');
        }
      }).map((snapshot) {
        try {
          return snapshot.docs
              .map((doc) {
                try {
                  return ChatMessage.fromFirestore(doc);
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint(
                        '❌ ChatService: Error parsing message ${doc.id} - $e');
                  }
                  return null;
                }
              })
              .where((message) => message != null && !message.isDeleted)
              .cast<ChatMessage>()
              .toList();
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ ChatService: Error processing messages snapshot for chat $chatId - $e');
          }
          return <ChatMessage>[];
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error setting up getChatMessages stream for chat $chatId - $e');
      }
      return Stream.value([]);
    }
  }

  /// Fetch older messages for pagination
  Future<List<ChatMessage>> fetchOlderMessages(
    String chatId,
    ChatMessage lastMessage, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfter([Timestamp.fromDate(lastMessage.createdAt)])
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .where((message) => message != null && !message!.isDeleted)
          .cast<ChatMessage>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error fetching older messages for chat $chatId - $e');
      }
      return [];
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([currentUser.uid]),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error marking message as read - $e');
      }
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error deleting message - $e');
      }
      return false;
    }
  }

  /// Send push notifications for a new message
  Future<void> _sendMessageNotifications(
      ChatMessage message, String chatId) async {
    try {
      // Get chat room to find participants
      final chatDoc = await _chatsCollection.doc(chatId).get();
      final chatRoom = ChatRoom.fromFirestore(chatDoc);

      if (chatRoom == null) return;

      // Get participant user IDs (excluding sender)
      final participantIds = chatRoom.participants
          .where((p) => p.userId != message.fromId)
          .map((p) => p.userId)
          .toList();

      if (participantIds.isEmpty) return;

      // Get FCM tokens for participants
      final tokens =
          await _notificationService.getParticipantTokens(participantIds);

      var notificationMessage = message;
      final nonConnectionMeta = _getNonConnectionMetadata(chatRoom);
      final status =
          (nonConnectionMeta?['status'] as String?)?.toLowerCase() ?? 'none';
      final initiatorId = nonConnectionMeta?['initiatorId'] as String?;
      if (status == 'pending' && initiatorId == message.fromId) {
        if (message.type == MessageType.text) {
          final base = message.text != null && message.text!.isNotEmpty
              ? message.text!
              : 'New message';
          notificationMessage = message.copyWith(
            text: 'Message request: $base',
          );
        } else {
          notificationMessage = message.copyWith(
            text: 'Message request from ${message.senderName}',
          );
        }
      }

      if (tokens.isNotEmpty) {
        await _notificationService.sendMessageNotification(
          message: notificationMessage,
          chatRoom: chatRoom,
          recipientTokens: tokens,
        );
      }

      // Also save notifications to notifications collection for in-app notifications
      try {
        final notificationService = NotificationService();
        final messageText = _getMessagePreview(notificationMessage);
        
        for (final participantId in participantIds) {
          await notificationService.createNotification(
            userId: participantId,
            type: NotificationType.newMessage,
            title: chatRoom.isGroupChat 
                ? (chatRoom.name ?? 'Group Chat')
                : message.senderName,
            message: chatRoom.isGroupChat 
                ? '${message.senderName}: $messageText'
                : messageText,
            data: {
              'chatId': chatId,
              'messageId': message.id,
              'senderId': message.fromId,
              'senderName': message.senderName,
              'chatType': chatRoom.isGroupChat ? 'group' : 'direct',
            },
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ChatService: Error creating in-app message notifications: $e');
        }
        // Don't fail the message send if notification creation fails
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error sending message notifications - $e');
      }
    }
  }

  /// Get a preview text for the message notification
  String _getMessagePreview(ChatMessage message) {
    if (message.text != null && message.text!.isNotEmpty) {
      return message.text!.length > 50 
          ? '${message.text!.substring(0, 50)}...' 
          : message.text!;
    } else if (message.type == MessageType.image) {
      return '📷 Sent an image';
    } else if (message.type == MessageType.entity && message.sharedEntity != null) {
      return '🔗 Shared ${message.sharedEntity!.type.value}';
    } else {
      return 'New message';
    }
  }

  Future<bool> acceptNonConnectionChat(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      await _chatsCollection.doc(chatId).update({
        'metadata.nonConnection.status': 'accepted',
        'metadata.nonConnection.acceptedBy': currentUser.uid,
        'metadata.nonConnection.acceptedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error accepting non-connection chat - $e');
      }
      return false;
    }
  }

  Future<bool> blockNonConnectionChat({
    required String chatId,
    required String otherUserId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final batch = _firestore.batch();
      final chatRef = _chatsCollection.doc(chatId);

      batch.update(chatRef, {
        'metadata.nonConnection.status': 'blocked',
        'metadata.nonConnection.closedBy': currentUser.uid,
        'metadata.nonConnection.closedAt': FieldValue.serverTimestamp(),
      });

      final blockRef = _firestore
          .collection('user_blocks')
          .doc(currentUser.uid)
          .collection('blocked')
          .doc(otherUserId);

      batch.set(
        blockRef,
        {
          'blockedUserId': otherUserId,
          'blockedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      await _deleteChatDocument(chatId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error blocking non-connection chat - $e');
      }
      return false;
    }
  }

  Future<bool> reportNonConnectionChat({
    required String chatId,
    required String otherUserId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      await _firestore.collection('user_reports').add({
        'chatId': chatId,
        'reportedUserId': otherUserId,
        'reporterUserId': currentUser.uid,
        'reason': 'non_connection_message',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _chatsCollection.doc(chatId).update({
        'metadata.nonConnection.status': 'reported',
        'metadata.nonConnection.closedBy': currentUser.uid,
        'metadata.nonConnection.closedAt': FieldValue.serverTimestamp(),
      });

      await _deleteChatDocument(chatId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error reporting non-connection chat - $e');
      }
      return false;
    }
  }

  // ============ CONNECTION MANAGEMENT ============

  /// Send a connection request
  Future<bool> sendConnectionRequest({
    required String toUserId,
    String? message,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final currentUserProfile =
          await _userRepository.getUserProfile(currentUser.uid);
      final targetUserProfile = await _userRepository.getUserProfile(toUserId);

      if (currentUserProfile == null || targetUserProfile == null) {
        return false;
      }

      final connectionId =
          ConnectionHelper.generateConnectionId(currentUser.uid, toUserId);
      final now = DateTime.now();

      final connection = Connection(
        id: connectionId,
        fromUserId: currentUser.uid,
        toUserId: toUserId,
        fromUserName: currentUserProfile.fullName,
        toUserName: targetUserProfile.fullName,
        fromUserImageUrl: currentUserProfile.profilePictureUrl,
        toUserImageUrl: targetUserProfile.profilePictureUrl,
        status: ConnectionStatus.pending,
        message: message,
        createdAt: now,
        updatedAt: now,
      );

      await _connectionsCollection
          .doc(connectionId)
          .set(connection.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error sending connection request - $e');
      }
      return false;
    }
  }

  Future<void> _deleteChatDocument(String chatId) async {
    const batchSize = 100;
    try {
      while (true) {
        final snapshot = await _chatsCollection
            .doc(chatId)
            .collection('messages')
            .limit(batchSize)
            .get();
        if (snapshot.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      await _chatsCollection.doc(chatId).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error deleting chat document - $e');
      }
    }
  }

  /// Respond to a connection request
  Future<bool> respondToConnectionRequest({
    required String connectionId,
    required ConnectionStatus response,
  }) async {
    try {
      final now = DateTime.now();
      await _connectionsCollection.doc(connectionId).update({
        'status': response.value,
        'updatedAt': Timestamp.fromDate(now),
        'respondedAt': Timestamp.fromDate(now),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error responding to connection request - $e');
      }
      return false;
    }
  }

  /// Get connection between two users
  Future<Connection?> getConnection(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final connectionId =
          ConnectionHelper.generateConnectionId(currentUser.uid, otherUserId);
      final doc = await _connectionsCollection.doc(connectionId).get();

      return Connection.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error getting connection - $e');
      }
      return null;
    }
  }

  /// Get user's connections
  Stream<List<Connection>> getUserConnections() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: No authenticated user for getUserConnections');
      }
      return Stream.value([]);
    }

    try {
      // Create streams for both fromUserId and toUserId queries
      final fromStream = _connectionsCollection
          .where('status', isEqualTo: ConnectionStatus.accepted.value)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .snapshots()
          .handleError((error) {
        if (kDebugMode) {
          debugPrint(
              '❌ ChatService: Error in getUserConnections fromUserId stream - $error');
        }
      });

      final toStream = _connectionsCollection
          .where('status', isEqualTo: ConnectionStatus.accepted.value)
          .where('toUserId', isEqualTo: currentUser.uid)
          .snapshots()
          .handleError((error) {
        if (kDebugMode) {
          debugPrint(
              '❌ ChatService: Error in getUserConnections toUserId stream - $error');
        }
      });

      // Combine both streams
      StreamController<List<Connection>>? controller;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? fromSub;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? toSub;

      controller = StreamController<List<Connection>>.broadcast(
        onListen: () {
          final Map<String, Connection> connectionsMap = {};
          QuerySnapshot<Map<String, dynamic>>? lastFromSnapshot;
          QuerySnapshot<Map<String, dynamic>>? lastToSnapshot;

          void updateConnections() {
            // Merge both snapshots
            final allDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
            
            if (lastFromSnapshot != null) {
              for (final doc in lastFromSnapshot!.docs) {
                allDocs[doc.id] = doc;
              }
              if (kDebugMode) {
                debugPrint(
                    '✅ ChatService: Found ${lastFromSnapshot!.docs.length} connections where user is sender');
              }
            }
            
            if (lastToSnapshot != null) {
              for (final doc in lastToSnapshot!.docs) {
                allDocs[doc.id] = doc;
              }
              if (kDebugMode) {
                debugPrint(
                    '✅ ChatService: Found ${lastToSnapshot!.docs.length} connections where user is receiver');
              }
            }

            // Parse all connections
            final connections = allDocs.values
                .map((doc) {
                  try {
                    return Connection.fromFirestore(doc);
                  } catch (e) {
                    if (kDebugMode) {
                      debugPrint(
                          '❌ ChatService: Error parsing connection ${doc.id} - $e');
                    }
                    return null;
                  }
                })
                .where((connection) => connection != null)
                .cast<Connection>()
                .toList();

            if (kDebugMode) {
              debugPrint(
                  '✅ ChatService: Total accepted connections: ${connections.length}');
            }

            if (!controller!.isClosed) {
              controller!.add(connections);
            }
          }

          fromSub = fromStream.listen((fromSnapshot) {
            lastFromSnapshot = fromSnapshot;
            updateConnections();
          });

          toSub = toStream.listen((toSnapshot) {
            lastToSnapshot = toSnapshot;
            updateConnections();
          });
        },
        onCancel: () {
          fromSub?.cancel();
          toSub?.cancel();
          controller?.close();
        },
      );

      return controller.stream;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error setting up getUserConnections stream - $e');
      }
      return Stream.value([]);
    }
  }

  /// Get pending connection requests received by current user
  Stream<List<Connection>> getPendingConnectionRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: No authenticated user for getPendingConnectionRequests');
      }
      return Stream.value([]);
    }

    try {
      return _connectionsCollection
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: ConnectionStatus.pending.value)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
        if (kDebugMode) {
          debugPrint(
              '❌ ChatService: Error in getPendingConnectionRequests stream - $error');
        }
      }).map((snapshot) {
        try {
          return snapshot.docs
              .map((doc) {
                try {
                  return Connection.fromFirestore(doc);
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint(
                        '❌ ChatService: Error parsing connection ${doc.id} - $e');
                  }
                  return null;
                }
              })
              .where((connection) => connection != null)
              .cast<Connection>()
              .toList();
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '❌ ChatService: Error processing connections snapshot - $e');
          }
          return <Connection>[];
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error setting up getPendingConnectionRequests stream - $e');
      }
      return Stream.value([]);
    }
  }

  /// Check if users can chat (based on connection status and profile privacy)
  Future<bool> canUsersChat(String otherUserId) async {
    try {
      // Get other user's profile to check if it's public
      final otherUserProfile =
          await _userRepository.getUserProfile(otherUserId);
      if (otherUserProfile == null) return false;

      // For now, assume all profiles are public (can be extended later)
      // In a real implementation, you'd check a 'isPublic' field from the profile
      // Using a variable instead of const to avoid dead code warning
      final isProfilePublic = otherUserProfile.profilePictureUrl !=
          null; // Simplified logic for demo

      if (isProfilePublic) return true;

      // If profile is private, check connection status
      final connection = await getConnection(otherUserId);
      return ConnectionHelper.canUsersChat(connection, isProfilePublic);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error checking chat permission - $e');
      }
      return false;
    }
  }

  /// Search users for starting new chats
  Future<List<UserProfile>> searchUsers({
    String? query,
    List<String>? sports,
    String? location,
    int limit = 20,
  }) async {
    try {
      Query searchQuery = _usersCollection
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit);

      // Add filters based on search criteria
      if (location != null && location.isNotEmpty) {
        searchQuery = searchQuery.where('location', isEqualTo: location);
      }

      final snapshot = await searchQuery.get();
      final profiles = <UserProfile>[];

      for (final doc in snapshot.docs) {
        final profile = await _userRepository.getUserProfile(doc.id);
        if (profile != null) {
          // Apply additional filters
          bool matches = true;

          // Filter by name if query provided
          if (query != null && query.isNotEmpty) {
            matches = matches &&
                profile.fullName.toLowerCase().contains(query.toLowerCase());
          }

          // Filter by sports (this would need to be implemented based on profile structure)
          if (sports != null && sports.isNotEmpty) {
            // This would need to be implemented based on how sports are stored in profiles
            // For now, we'll skip this filter
          }

          if (matches) {
            profiles.add(profile);
          }
        }
      }

      return profiles;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error searching users - $e');
      }
      return [];
    }
  }

  // ============ GROUP CHAT MANAGEMENT ============

  /// Create a group chat for a team
  Future<ChatRoom?> createTeamGroupChat({
    required String teamId,
    required String teamName,
    String? teamImageUrl,
    required List<String> memberIds,
    required List<String> memberNames,
    List<String>? memberImageUrls,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final chatId = teamChatId(teamId);
      final now = DateTime.now();

      // Create participants list
      final participants = <ChatParticipant>[];
      for (int i = 0; i < memberIds.length; i++) {
        final isOwner = memberIds[i] == currentUser.uid;
        participants.add(ChatParticipant(
          userId: memberIds[i],
          name: memberNames[i],
          imageUrl: memberImageUrls != null && i < memberImageUrls.length
              ? memberImageUrls[i]
              : null,
          role: isOwner ? 'admin' : 'member',
          joinedAt: now,
        ));
      }

      final chatRoom = ChatRoom(
        id: chatId,
        type: ChatType.group,
        name: teamName,
        imageUrl: teamImageUrl,
        description: 'Team chat for $teamName',
        participants: participants,
        createdAt: now,
        updatedAt: now,
        relatedEntityType: 'team',
        relatedEntityId: teamId,
      );

      await _chatsCollection.doc(chatId).set(chatRoom.toFirestore());
      return chatRoom;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error creating team group chat - $e');
      }
      return null;
    }
  }

  /// Create a group chat for a tournament
  Future<ChatRoom?> createTournamentGroupChat({
    required String tournamentId,
    required String tournamentName,
    String? tournamentImageUrl,
    required List<String> participantIds,
    required List<String> participantNames,
    List<String>? participantImageUrls,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final chatId = 'tournament_$tournamentId';
      final now = DateTime.now();

      // Create participants list
      final participants = <ChatParticipant>[];
      for (int i = 0; i < participantIds.length; i++) {
        final isOrganizer = participantIds[i] == currentUser.uid;
        participants.add(ChatParticipant(
          userId: participantIds[i],
          name: participantNames[i],
          imageUrl:
              participantImageUrls != null && i < participantImageUrls.length
                  ? participantImageUrls[i]
                  : null,
          role: isOrganizer ? 'admin' : 'member',
          joinedAt: now,
        ));
      }

      final chatRoom = ChatRoom(
        id: chatId,
        type: ChatType.group,
        name: tournamentName,
        imageUrl: tournamentImageUrl,
        description: 'Tournament chat for $tournamentName',
        participants: participants,
        createdAt: now,
        updatedAt: now,
        relatedEntityType: 'tournament',
        relatedEntityId: tournamentId,
      );

      await _chatsCollection.doc(chatId).set(chatRoom.toFirestore());
      return chatRoom;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error creating tournament group chat - $e');
      }
      return null;
    }
  }

  /// Add member to group chat
  Future<bool> addMemberToGroupChat({
    required String chatId,
    required String userId,
    required String userName,
    String? userImageUrl,
  }) async {
    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      final chatRoom = ChatRoom.fromFirestore(chatDoc);

      if (chatRoom == null || chatRoom.type != ChatType.group) {
        return false;
      }

      // Check if user is already a member
      final existingMember =
          chatRoom.participants.where((p) => p.userId == userId).firstOrNull;

      if (existingMember != null) {
        return true; // Already a member
      }

      final newParticipant = ChatParticipant(
        userId: userId,
        name: userName,
        imageUrl: userImageUrl,
        joinedAt: DateTime.now(),
      );

      final updatedParticipants = [...chatRoom.participants, newParticipant];

      await _chatsCollection.doc(chatId).update({
        'participants': updatedParticipants.map((p) => p.toMap()).toList(),
        'participantIds': updatedParticipants.map((p) => p.userId).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error adding member to group chat - $e');
      }
      return false;
    }
  }

  /// Remove member from group chat
  Future<bool> removeMemberFromGroupChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      final chatRoom = ChatRoom.fromFirestore(chatDoc);

      if (chatRoom == null || chatRoom.type != ChatType.group) {
        return false;
      }

      final updatedParticipants =
          chatRoom.participants.where((p) => p.userId != userId).toList();

      await _chatsCollection.doc(chatId).update({
        'participants': updatedParticipants.map((p) => p.toMap()).toList(),
        'participantIds': updatedParticipants.map((p) => p.userId).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error removing member from group chat - $e');
      }
      return false;
    }
  }

  /// Update group chat info
  Future<bool> updateGroupChatInfo({
    required String chatId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;

      await _chatsCollection.doc(chatId).update(updates);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error updating group chat info - $e');
      }
      return false;
    }
  }

  /// Get group chat by related entity
  Future<ChatRoom?> getGroupChatByEntity({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final chatId = '${entityType}_$entityId';
      final doc = await _chatsCollection.doc(chatId).get();
      return ChatRoom.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error getting group chat by entity - $e');
      }
      return null;
    }
  }

  /// Add participant to group chat
  Future<bool> addParticipantToGroupChat({
    required String chatId,
    required String userId,
    required String userName,
    String? userImageUrl,
    String role = 'member',
  }) async {
    try {
      final now = DateTime.now();
      final participant = ChatParticipant(
        userId: userId,
        name: userName,
        imageUrl: userImageUrl,
        role: role,
        joinedAt: now,
      );

      await _chatsCollection.doc(chatId).update({
        'participants': FieldValue.arrayUnion([participant.toMap()]),
        'updatedAt': Timestamp.fromDate(now),
      });

      if (kDebugMode) {
        debugPrint('✅ ChatService: Added $userName to group chat $chatId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error adding participant to group chat - $e');
      }
      return false;
    }
  }

  /// Remove participant from group chat
  Future<bool> removeParticipantFromGroupChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) return false;

      final chatRoom = ChatRoom.fromFirestore(chatDoc);
      final updatedParticipants = chatRoom?.participants
              .where((p) => p.userId != userId)
              .map((p) => p.toMap())
              .toList() ??
          [];

      await _chatsCollection.doc(chatId).update({
        'participants': updatedParticipants,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        debugPrint(
            '✅ ChatService: Removed user $userId from group chat $chatId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ ChatService: Error removing participant from group chat - $e');
      }
      return false;
    }
  }

  /// Send system message to chat
  Future<bool> sendSystemMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      final messageId = _firestore.collection('temp').doc().id;
      final now = DateTime.now();

      final systemMessage = ChatMessage(
        id: messageId,
        chatId: chatId,
        fromId: 'system',
        groupId: chatId,
        senderName: 'System',
        type: MessageType.text,
        text: message,
        createdAt: now,
        readBy: const ['system'],
      );

      final messageData = systemMessage.toFirestore();
      messageData['createdAt'] = FieldValue.serverTimestamp();
      messageData['timestamp'] = FieldValue.serverTimestamp();
      messageData['readBy'] = ['system'];

      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update chat room with last message
      await _updateChatRoomLastMessage(
        chatId,
        message,
        'system',
        now,
      );

      if (kDebugMode) {
        debugPrint('✅ ChatService: System message sent to chat $chatId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error sending system message - $e');
      }
      return false;
    }
  }

  /// Get a chat room by ID
  Future<ChatRoom?> getChatRoom(String chatId) async {
    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (chatDoc.exists) {
        return ChatRoom.fromFirestore(chatDoc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error getting chat room - $e');
      }
      return null;
    }
  }

  Stream<ChatRoom?> watchChatRoom(String chatId) {
    try {
      return _chatsCollection.doc(chatId).snapshots().map((snapshot) {
        if (!snapshot.exists) return null;
        return ChatRoom.fromFirestore(snapshot);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error watching chat room - $e');
      }
      return Stream.value(null);
    }
  }

  /// Delete a chat room (soft delete by removing current user from participants)
  Future<bool> deleteChatRoom(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) return false;

      final chatRoom = ChatRoom.fromFirestore(chatDoc);
      if (chatRoom == null) return false;

      // For group chats, remove the user from participants
      if (chatRoom.isGroupChat) {
        return await removeParticipantFromGroupChat(
          chatId: chatId,
          userId: currentUser.uid,
        );
      }

      // For direct chats, mark as deleted for this user
      await _chatsCollection.doc(chatId).update({
        'deletedBy.${currentUser.uid}': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error deleting chat room - $e');
      }
      return false;
    }
  }
}

  ChatParticipant _buildParticipant({
    required String userId,
    required DateTime joinedAt,
    required String defaultName,
    UserProfile? profile,
    String? fallbackName,
    String? fallbackImageUrl,
  }) {
    final sanitizedFallbackName =
        (fallbackName != null && fallbackName.trim().isNotEmpty)
            ? fallbackName
            : null;
    final resolvedName =
        profile?.fullName ?? sanitizedFallbackName ?? defaultName;

    final sanitizedFallbackImage =
        (fallbackImageUrl != null && fallbackImageUrl.trim().isNotEmpty)
            ? fallbackImageUrl
            : null;
    final resolvedImage =
        profile?.profilePictureUrl ?? sanitizedFallbackImage;

    return ChatParticipant(
      userId: userId,
      name: resolvedName,
      imageUrl: resolvedImage,
      joinedAt: joinedAt,
    );
}
