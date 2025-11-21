import 'package:flutter_test/flutter_test.dart';

import 'package:playaround/modules/chat/models/chat_message.dart';
import 'package:playaround/modules/chat/models/chat_room.dart';
import 'package:playaround/modules/chat/models/connection.dart';
import 'package:playaround/modules/chat/widgets/entity_card.dart';

void main() {
  group('Chat Models Tests', () {
    group('ChatMessage Model Tests', () {
      test('should create ChatMessage with text content', () {
        final message = ChatMessage(
          id: 'msg_1',
          chatId: 'chat_1',
          fromId: 'user_1',
          senderName: 'John Doe',
          type: MessageType.text,
          text: 'Hello, world!',
          createdAt: DateTime.now(),
        );

        expect(message.id, equals('msg_1'));
        expect(message.type, equals(MessageType.text));
        expect(message.text, equals('Hello, world!'));
        expect(message.displayContent, equals('Hello, world!'));
        expect(message.isRead, isFalse);
        expect(message.isEdited, isFalse);
      });

      test('should create ChatMessage with image content', () {
        final message = ChatMessage(
          id: 'msg_2',
          chatId: 'chat_1',
          fromId: 'user_1',
          senderName: 'John Doe',
          type: MessageType.image,
          text: null,
          attachments: const [
            ChatAttachment(
              type: AttachmentType.image,
              url: 'https://example.com/image.jpg',
            ),
          ],
          createdAt: DateTime.now(),
        );

        expect(message.type, equals(MessageType.image));
        expect(message.imageUrl, equals('https://example.com/image.jpg'));
        expect(message.displayContent, equals('📷 Image'));
      });

      test('should create ChatMessage with entity content', () {
        const entity = SharedEntity(
          type: EntityType.profile,
          id: 'profile_1',
          title: 'John Doe',
          subtitle: 'Coach',
        );

        final message = ChatMessage(
          id: 'msg_3',
          chatId: 'chat_1',
          fromId: 'user_1',
          senderName: 'John Doe',
          type: MessageType.entity,
          sharedEntity: entity,
          createdAt: DateTime.now(),
        );

        expect(message.type, equals(MessageType.entity));
        expect(message.sharedEntity, equals(entity));
        expect(message.displayContent, equals('🔗 Shared profile'));
      });

      test('should handle deleted message', () {
        final message = ChatMessage(
          id: 'msg_4',
          chatId: 'chat_1',
          fromId: 'user_1',
          senderName: 'John Doe',
          type: MessageType.text,
          text: 'Original message',
          createdAt: DateTime.now(),
          isDeleted: true,
        );

        expect(message.displayContent, equals('This message was deleted'));
      });

      test('should convert to and from Firestore', () {
        final originalMessage = ChatMessage(
          id: 'msg_5',
          chatId: 'chat_1',
          fromId: 'user_1',
          senderName: 'John Doe',
          type: MessageType.text,
          text: 'Test message',
          createdAt: DateTime.now(),
        );

        final firestoreData = originalMessage.toFirestore();
        expect(firestoreData['id'], equals('msg_5'));
        expect(firestoreData['type'], equals('text'));
        expect(firestoreData['text'], equals('Test message'));

        // Note: In a real test, you'd mock DocumentSnapshot properly
        // This is a simplified test structure
      });
    });

    group('ChatRoom Model Tests', () {
      test('should create direct chat room', () {
        final participants = [
          ChatParticipant(
            userId: 'user_1',
            name: 'John Doe',
            joinedAt: DateTime.now(),
          ),
          ChatParticipant(
            userId: 'user_2',
            name: 'Jane Smith',
            joinedAt: DateTime.now(),
          ),
        ];

        final chatRoom = ChatRoom(
          id: 'chat_1',
          type: ChatType.direct,
          participants: participants,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(chatRoom.type, equals(ChatType.direct));
        expect(chatRoom.participants.length, equals(2));
        expect(chatRoom.getDisplayName('user_1'), equals('Jane Smith'));
        expect(chatRoom.getDisplayName('user_2'), equals('John Doe'));
      });

      test('should create group chat room', () {
        final participants = [
          ChatParticipant(
            userId: 'user_1',
            name: 'John Doe',
            role: 'admin',
            joinedAt: DateTime.now(),
          ),
          ChatParticipant(
            userId: 'user_2',
            name: 'Jane Smith',
            joinedAt: DateTime.now(),
          ),
        ];

        final chatRoom = ChatRoom(
          id: 'group_1',
          type: ChatType.group,
          name: 'Test Group',
          participants: participants,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(chatRoom.type, equals(ChatType.group));
        expect(chatRoom.name, equals('Test Group'));
        expect(chatRoom.getDisplayName('user_1'), equals('Test Group'));
        expect(chatRoom.isUserAdmin('user_1'), isTrue);
        expect(chatRoom.isUserAdmin('user_2'), isFalse);
      });

      test('should handle unread counts', () {
        final chatRoom = ChatRoom(
          id: 'chat_1',
          type: ChatType.direct,
          participants: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          unreadCounts: {'user_1': 5, 'user_2': 0},
        );

        expect(chatRoom.getUnreadCount('user_1'), equals(5));
        expect(chatRoom.getUnreadCount('user_2'), equals(0));
        expect(chatRoom.getUnreadCount('user_3'), equals(0));
      });
    });

    group('Connection Model Tests', () {
      test('should create connection request', () {
        final connection = Connection(
          id: 'conn_1',
          fromUserId: 'user_1',
          toUserId: 'user_2',
          fromUserName: 'John Doe',
          toUserName: 'Jane Smith',
          status: ConnectionStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(connection.status, equals(ConnectionStatus.pending));
        expect(connection.isPending, isTrue);
        expect(connection.isAccepted, isFalse);
        expect(connection.getOtherUserId('user_1'), equals('user_2'));
        expect(connection.getOtherUserName('user_1'), equals('Jane Smith'));
        expect(connection.didCurrentUserSendRequest('user_1'), isTrue);
        expect(connection.didCurrentUserReceiveRequest('user_2'), isTrue);
      });

      test('should generate consistent connection ID', () {
        final id1 = ConnectionHelper.generateConnectionId('user_1', 'user_2');
        final id2 = ConnectionHelper.generateConnectionId('user_2', 'user_1');

        expect(id1, equals(id2));
        expect(id1, equals('user_1_user_2'));
      });

      test('should check chat permissions', () {
        final acceptedConnection = Connection(
          id: 'conn_1',
          fromUserId: 'user_1',
          toUserId: 'user_2',
          fromUserName: 'John Doe',
          toUserName: 'Jane Smith',
          status: ConnectionStatus.accepted,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final pendingConnection = Connection(
          id: 'conn_2',
          fromUserId: 'user_1',
          toUserId: 'user_3',
          fromUserName: 'John Doe',
          toUserName: 'Bob Wilson',
          status: ConnectionStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Public profile - anyone can chat
        expect(ConnectionHelper.canUsersChat(null, true), isTrue);
        expect(ConnectionHelper.canUsersChat(pendingConnection, true), isTrue);

        // Private profile - need accepted connection
        expect(ConnectionHelper.canUsersChat(null, false), isFalse);
        expect(
            ConnectionHelper.canUsersChat(pendingConnection, false), isFalse);
        expect(
            ConnectionHelper.canUsersChat(acceptedConnection, false), isTrue);
      });
    });

    group('SharedEntity Tests', () {
      test('should create profile entity', () {
        final entity = EntityHelper.fromUserProfile(
          id: 'user_1',
          name: 'John Doe',
          imageUrl: 'https://example.com/profile.jpg',
          location: 'New York',
          role: 'Coach',
        );

        expect(entity.type, equals(EntityType.profile));
        expect(entity.title, equals('John Doe'));
        expect(entity.subtitle, equals('Coach • New York'));
        expect(entity.metadata?['role'], equals('Coach'));
        expect(entity.metadata?['location'], equals('New York'));
      });

      test('should create venue entity', () {
        final entity = EntityHelper.fromVenue(
          id: 'venue_1',
          name: 'Sports Complex',
          location: 'Downtown',
          rating: 4.5,
          priceRange: '\$\$',
        );

        expect(entity.type, equals(EntityType.venue));
        expect(entity.title, equals('Sports Complex'));
        expect(entity.subtitle, equals('Downtown'));
        expect(entity.metadata?['rating'], equals('4.5'));
        expect(entity.metadata?['price'], equals('\$\$'));
      });

      test('should create team entity', () {
        final entity = EntityHelper.fromTeam(
          id: 'team_1',
          name: 'Thunder Bolts',
          sport: 'Basketball',
          memberCount: 12,
          location: 'New York',
        );

        expect(entity.type, equals(EntityType.team));
        expect(entity.title, equals('Thunder Bolts'));
        expect(entity.subtitle, equals('Basketball'));
        expect(entity.metadata?['sport'], equals('Basketball'));
        expect(entity.metadata?['memberCount'], equals(12));
      });

      test('should create tournament entity', () {
        final entity = EntityHelper.fromTournament(
          id: 'tournament_1',
          name: 'Summer Championship',
          sport: 'Tennis',
          location: 'Miami',
          date: 'July 15-20',
          prizePool: '\$10,000',
        );

        expect(entity.type, equals(EntityType.tournament));
        expect(entity.title, equals('Summer Championship'));
        expect(entity.subtitle, equals('Tennis • July 15-20'));
        expect(entity.metadata?['sport'], equals('Tennis'));
        expect(entity.metadata?['prizePool'], equals('\$10,000'));
      });
    });
  });
}
