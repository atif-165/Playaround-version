import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/chat_room.dart';

/// Service for handling chat-specific push notifications
class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize chat notifications
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Handle app launch from notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      if (kDebugMode) {
        debugPrint('✅ ChatNotificationService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatNotificationService: Error initializing - $e');
      }
    }
  }

  /// Send push notification for new chat message
  Future<void> sendMessageNotification({
    required ChatMessage message,
    required ChatRoom chatRoom,
    required List<String> recipientTokens,
  }) async {
    try {
      if (recipientTokens.isEmpty) return;

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Don't send notification to sender
      final filteredTokens = recipientTokens.where((token) => token.isNotEmpty).toList();
      if (filteredTokens.isEmpty) return;

      final title = chatRoom.type == ChatType.group
          ? chatRoom.name ?? 'Group Chat'
          : message.senderName;

      final body = _getNotificationBody(message);

      final data = {
        'type': 'chat_message',
        'chatId': chatRoom.id,
        'messageId': message.id,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'chatType': chatRoom.type.value,
      };

      // Send to multiple tokens
      for (final token in filteredTokens) {
        await _sendNotificationToToken(
          token: token,
          title: title,
          body: body,
          data: data,
        );
      }

      if (kDebugMode) {
        debugPrint('✅ ChatNotificationService: Sent notifications to ${filteredTokens.length} recipients');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatNotificationService: Error sending message notification - $e');
      }
    }
  }

  /// Send push notification for connection request
  Future<void> sendConnectionRequestNotification({
    required String recipientToken,
    required String senderName,
    String? message,
  }) async {
    try {
      if (recipientToken.isEmpty) return;

      const title = 'New Connection Request';
      final body = '$senderName wants to connect with you';

      final data = {
        'type': 'connection_request',
        'senderName': senderName,
        'message': message ?? '',
      };

      await _sendNotificationToToken(
        token: recipientToken,
        title: title,
        body: body,
        data: data,
      );

      if (kDebugMode) {
        debugPrint('✅ ChatNotificationService: Sent connection request notification');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatNotificationService: Error sending connection request notification - $e');
      }
    }
  }

  /// Get FCM tokens for chat participants
  Future<List<String>> getParticipantTokens(List<String> userIds) async {
    try {
      final tokens = <String>[];
      final currentUserId = _auth.currentUser?.uid;

      for (final userId in userIds) {
        // Skip current user
        if (userId == currentUserId) continue;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        
        if (userData != null && userData['fcmToken'] != null) {
          final token = userData['fcmToken'] as String;
          if (token.isNotEmpty) {
            tokens.add(token);
          }
        }
      }

      return tokens;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatNotificationService: Error getting participant tokens - $e');
      }
      return [];
    }
  }

  /// Send notification to a specific FCM token
  Future<void> _sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // This is a simplified version. In production, you'd use Firebase Admin SDK
      // or a cloud function to send notifications securely
      
      const serverKey = 'YOUR_SERVER_KEY'; // This should be stored securely
      const fcmUrl = 'https://fcm.googleapis.com/fcm/send';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };

      final payload = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data,
        'priority': 'high',
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ ChatNotificationService: Notification sent successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ ChatNotificationService: Failed to send notification - ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatNotificationService: Error sending notification to token - $e');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📱 ChatNotificationService: Received foreground message');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');
    }

    // You can show in-app notification here
    // For example, using a snackbar or custom notification widget
  }

  /// Handle message tap (when user taps notification)
  void _handleMessageTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('👆 ChatNotificationService: User tapped notification');
      debugPrint('   Data: ${message.data}');
    }

    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'chat_message':
        _handleChatMessageTap(data);
        break;
      case 'connection_request':
        _handleConnectionRequestTap(data);
        break;
    }
  }

  /// Handle chat message notification tap
  void _handleChatMessageTap(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    if (chatId != null) {
      // Navigate to chat screen
      // This would typically use a navigation service or global navigator
      if (kDebugMode) {
        debugPrint('🔄 ChatNotificationService: Should navigate to chat: $chatId');
      }
    }
  }

  /// Handle connection request notification tap
  void _handleConnectionRequestTap(Map<String, dynamic> data) {
    // Navigate to connection requests screen
    if (kDebugMode) {
      debugPrint('🔄 ChatNotificationService: Should navigate to connection requests');
    }
  }

  /// Get notification body text based on message type
  String _getNotificationBody(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return message.text ?? '';
      case MessageType.image:
        return '📷 Image';
      case MessageType.entity:
        return '🔗 Shared ${message.sharedEntity?.type.value ?? 'item'}';
    }
  }

  /// Update user's FCM token
  Future<void> updateUserToken(String token) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          debugPrint('✅ ChatNotificationService: Updated user FCM token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatNotificationService: Error updating user token - $e');
      }
    }
  }

  /// Clear user's FCM token (on logout)
  Future<void> clearUserToken() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'fcmToken': FieldValue.delete(),
        });

        if (kDebugMode) {
          debugPrint('✅ ChatNotificationService: Cleared user FCM token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatNotificationService: Error clearing user token - $e');
      }
    }
  }
}
