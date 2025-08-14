import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';

import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/cloudinary_service.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/connection.dart';
import 'chat_notification_service.dart';

/// Service for chat functionality with Firestore integration
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final UserRepository _userRepository = UserRepository();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ChatNotificationService _notificationService = ChatNotificationService();

  // Collection references
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _connectionsCollection => _firestore.collection('connections');
  CollectionReference get _usersCollection => _firestore.collection('users');

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

  /// Create a direct chat room between two users (alias for getOrCreateDirectChat)
  Future<ChatRoom?> createDirectChat(String otherUserId) async {
    return getOrCreateDirectChat(otherUserId);
  }

  /// Get or create a direct chat room between two users
  Future<ChatRoom?> getOrCreateDirectChat(String otherUserId) async {
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
      final currentUserProfile = await _userRepository.getUserProfile(currentUser.uid);
      final otherUserProfile = await _userRepository.getUserProfile(otherUserId);

      if (currentUserProfile == null || otherUserProfile == null) {
        throw Exception('User profiles not found');
      }

      // Create new chat room
      final now = DateTime.now();
      final participants = [
        ChatParticipant(
          userId: currentUser.uid,
          name: currentUserProfile.fullName,
          imageUrl: currentUserProfile.profilePictureUrl,
          joinedAt: now,
        ),
        ChatParticipant(
          userId: otherUserId,
          name: otherUserProfile.fullName,
          imageUrl: otherUserProfile.profilePictureUrl,
          joinedAt: now,
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

      final messageId = _firestore.collection('temp').doc().id;
      final now = DateTime.now();

      final message = ChatMessage(
        id: messageId,
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: userProfile.fullName,
        senderImageUrl: userProfile.profilePictureUrl,
        type: MessageType.text,
        text: text,
        timestamp: now,
      );



      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Update chat room with last message
      await _updateChatRoomLastMessage(chatId, text, currentUser.uid, now);

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

      // Upload image to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folder: 'chat_images',
      );

      final messageId = _firestore.collection('temp').doc().id;
      final now = DateTime.now();

      final message = ChatMessage(
        id: messageId,
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: userProfile.fullName,
        senderImageUrl: userProfile.profilePictureUrl,
        type: MessageType.image,
        imageUrl: imageUrl,
        timestamp: now,
      );

      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Update chat room with last message
      await _updateChatRoomLastMessage(chatId, '📷 Image', currentUser.uid, now);

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

      final messageId = _firestore.collection('temp').doc().id;
      final now = DateTime.now();

      final message = ChatMessage(
        id: messageId,
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: userProfile.fullName,
        senderImageUrl: userProfile.profilePictureUrl,
        type: MessageType.entity,
        sharedEntity: entity,
        timestamp: now,
      );

      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Update chat room with last message
      await _updateChatRoomLastMessage(
        chatId,
        '🔗 Shared ${entity.type.value}',
        currentUser.uid,
        now,
      );

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
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .handleError((error) {
            if (kDebugMode) {
              debugPrint('❌ ChatService: Error in getUserChatRooms stream - $error');
            }
          })
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    try {
                      return ChatRoom.fromFirestore(doc);
                    } catch (e) {
                      if (kDebugMode) {
                        debugPrint('❌ ChatService: Error parsing chat room ${doc.id} - $e');
                      }
                      return null;
                    }
                  })
                  .where((room) => room != null)
                  .cast<ChatRoom>()
                  .toList();
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ ChatService: Error processing chat rooms snapshot - $e');
              }
              return <ChatRoom>[];
            }
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error setting up getUserChatRooms stream - $e');
      }
      return Stream.value([]);
    }
  }

  /// Get messages for a specific chat
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    try {
      return _chatsCollection
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            if (kDebugMode) {
              debugPrint('❌ ChatService: Error in getChatMessages stream for chat $chatId - $error');
            }
          })
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    try {
                      return ChatMessage.fromFirestore(doc);
                    } catch (e) {
                      if (kDebugMode) {
                        debugPrint('❌ ChatService: Error parsing message ${doc.id} - $e');
                      }
                      return null;
                    }
                  })
                  .where((message) => message != null && !message.isDeleted)
                  .cast<ChatMessage>()
                  .toList();
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ ChatService: Error processing messages snapshot for chat $chatId - $e');
              }
              return <ChatMessage>[];
            }
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error setting up getChatMessages stream for chat $chatId - $e');
      }
      return Stream.value([]);
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readAt': FieldValue.serverTimestamp(),
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
  Future<void> _sendMessageNotifications(ChatMessage message, String chatId) async {
    try {
      // Get chat room to find participants
      final chatDoc = await _chatsCollection.doc(chatId).get();
      final chatRoom = ChatRoom.fromFirestore(chatDoc);

      if (chatRoom == null) return;

      // Get participant user IDs (excluding sender)
      final participantIds = chatRoom.participants
          .where((p) => p.userId != message.senderId)
          .map((p) => p.userId)
          .toList();

      if (participantIds.isEmpty) return;

      // Get FCM tokens for participants
      final tokens = await _notificationService.getParticipantTokens(participantIds);

      if (tokens.isNotEmpty) {
        await _notificationService.sendMessageNotification(
          message: message,
          chatRoom: chatRoom,
          recipientTokens: tokens,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error sending message notifications - $e');
      }
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

      final currentUserProfile = await _userRepository.getUserProfile(currentUser.uid);
      final targetUserProfile = await _userRepository.getUserProfile(toUserId);

      if (currentUserProfile == null || targetUserProfile == null) {
        return false;
      }

      final connectionId = ConnectionHelper.generateConnectionId(currentUser.uid, toUserId);
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

      await _connectionsCollection.doc(connectionId).set(connection.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error sending connection request - $e');
      }
      return false;
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
        debugPrint('❌ ChatService: Error responding to connection request - $e');
      }
      return false;
    }
  }

  /// Get connection between two users
  Future<Connection?> getConnection(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final connectionId = ConnectionHelper.generateConnectionId(currentUser.uid, otherUserId);
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
        debugPrint('❌ ChatService: No authenticated user for getUserConnections');
      }
      return Stream.value([]);
    }

    try {
      return _connectionsCollection
          .where('status', isEqualTo: ConnectionStatus.accepted.value)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .snapshots()
          .handleError((error) {
            if (kDebugMode) {
              debugPrint('❌ ChatService: Error in getUserConnections stream - $error');
            }
          })
          .asyncMap((fromSnapshot) async {
            try {
              final toSnapshot = await _connectionsCollection
                  .where('status', isEqualTo: ConnectionStatus.accepted.value)
                  .where('toUserId', isEqualTo: currentUser.uid)
                  .get();

              final allDocs = [...fromSnapshot.docs, ...toSnapshot.docs];
              return allDocs
                  .map((doc) {
                    try {
                      return Connection.fromFirestore(doc);
                    } catch (e) {
                      if (kDebugMode) {
                        debugPrint('❌ ChatService: Error parsing connection ${doc.id} - $e');
                      }
                      return null;
                    }
                  })
                  .where((connection) => connection != null)
                  .cast<Connection>()
                  .toList();
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ ChatService: Error processing connections - $e');
              }
              return <Connection>[];
            }
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error setting up getUserConnections stream - $e');
      }
      return Stream.value([]);
    }
  }

  /// Get pending connection requests received by current user
  Stream<List<Connection>> getPendingConnectionRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: No authenticated user for getPendingConnectionRequests');
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
              debugPrint('❌ ChatService: Error in getPendingConnectionRequests stream - $error');
            }
          })
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    try {
                      return Connection.fromFirestore(doc);
                    } catch (e) {
                      if (kDebugMode) {
                        debugPrint('❌ ChatService: Error parsing connection ${doc.id} - $e');
                      }
                      return null;
                    }
                  })
                  .where((connection) => connection != null)
                  .cast<Connection>()
                  .toList();
            } catch (e) {
              if (kDebugMode) {
                debugPrint('❌ ChatService: Error processing connections snapshot - $e');
              }
              return <Connection>[];
            }
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error setting up getPendingConnectionRequests stream - $e');
      }
      return Stream.value([]);
    }
  }

  /// Check if users can chat (based on connection status and profile privacy)
  Future<bool> canUsersChat(String otherUserId) async {
    try {
      // Get other user's profile to check if it's public
      final otherUserProfile = await _userRepository.getUserProfile(otherUserId);
      if (otherUserProfile == null) return false;

      // For now, assume all profiles are public (can be extended later)
      // In a real implementation, you'd check a 'isPublic' field from the profile
      // Using a variable instead of const to avoid dead code warning
      final isProfilePublic = otherUserProfile.profilePictureUrl != null; // Simplified logic for demo

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

      final chatId = 'team_$teamId';
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
          imageUrl: participantImageUrls != null && i < participantImageUrls.length
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
      final existingMember = chatRoom.participants
          .where((p) => p.userId == userId)
          .firstOrNull;

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

      final updatedParticipants = chatRoom.participants
          .where((p) => p.userId != userId)
          .toList();

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
        debugPrint('❌ ChatService: Error adding participant to group chat - $e');
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
          .toList() ?? [];

      await _chatsCollection.doc(chatId).update({
        'participants': updatedParticipants,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        debugPrint('✅ ChatService: Removed user $userId from group chat $chatId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatService: Error removing participant from group chat - $e');
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
        senderId: 'system',
        senderName: 'System',
        type: MessageType.text,
        text: message,
        timestamp: now,
      );

      // Add message to subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(systemMessage.toFirestore());

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
}
