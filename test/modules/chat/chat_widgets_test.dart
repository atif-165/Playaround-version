import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:playaround/modules/chat/models/chat_message.dart';
import 'package:playaround/modules/chat/models/chat_room.dart';
import 'package:playaround/modules/chat/widgets/message_bubble.dart';
import 'package:playaround/modules/chat/widgets/chat_room_card.dart';
import 'package:playaround/modules/chat/widgets/entity_card.dart';

void main() {
  group('Chat Widget Tests', () {
    // Helper function to create a test app wrapper
    Widget createTestApp(Widget child) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: Scaffold(body: child),
        ),
        child: child,
      );
    }

    group('MessageBubble Tests', () {
      testWidgets('should display text message correctly',
          (WidgetTester tester) async {
        final message = ChatMessage(
          id: 'msg_1',
          chatId: 'chat_1',
          fromId: 'user_1',
          senderName: 'John Doe',
          type: MessageType.text,
          text: 'Hello, world!',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          createTestApp(
            MessageBubble(
              message: message,
              isMe: true,
            ),
          ),
        );

        expect(find.text('Hello, world!'), findsOneWidget);
      });

      testWidgets('should display image message correctly',
          (WidgetTester tester) async {
        final message = ChatMessage(
          id: 'msg_2',
          chatId: 'chat_1',
          fromId: 'user_1',
          senderName: 'John Doe',
          type: MessageType.image,
          attachments: const [
            ChatAttachment(
              type: AttachmentType.image,
              url: 'https://example.com/image.jpg',
            ),
          ],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          createTestApp(
            MessageBubble(
              message: message,
              isMe: false,
            ),
          ),
        );

        // Should find the image widget (CachedNetworkImage)
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('should display entity message correctly',
          (WidgetTester tester) async {
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

        await tester.pumpWidget(
          createTestApp(
            MessageBubble(
              message: message,
              isMe: true,
            ),
          ),
        );

        expect(find.text('PROFILE'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Coach'), findsOneWidget);
        expect(find.text('Tap to view'), findsOneWidget);
      });

      testWidgets('should show sender info for group messages',
          (WidgetTester tester) async {
        final message = ChatMessage(
          id: 'msg_4',
          chatId: 'group_1',
          fromId: 'user_2',
          senderName: 'Jane Smith',
          type: MessageType.text,
          text: 'Group message',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          createTestApp(
            MessageBubble(
              message: message,
              isMe: false,
              showSenderInfo: true,
            ),
          ),
        );

        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Group message'), findsOneWidget);
      });

      testWidgets('should show read status for sent messages',
          (WidgetTester tester) async {
        final message = ChatMessage(
          id: 'msg_5',
          chatId: 'chat_1',
          fromId: 'user_1',
          senderName: 'John Doe',
          type: MessageType.text,
          text: 'Read message',
          createdAt: DateTime.now(),
          readBy: const ['user_1', 'user_2'],
        );

        await tester.pumpWidget(
          createTestApp(
            MessageBubble(
              message: message,
              isMe: true,
            ),
          ),
        );

        // Should show double check mark for read message
        expect(find.byIcon(Icons.done_all), findsOneWidget);
      });
    });

    group('ChatRoomCard Tests', () {
      testWidgets('should display direct chat correctly',
          (WidgetTester tester) async {
        final participants = [
          ChatParticipant(
            userId: 'user_1',
            name: 'John Doe',
            joinedAt: DateTime.now(),
          ),
          ChatParticipant(
            userId: 'user_2',
            name: 'Jane Smith',
            imageUrl: 'https://example.com/jane.jpg',
            joinedAt: DateTime.now(),
          ),
        ];

        final chatRoom = ChatRoom(
          id: 'chat_1',
          type: ChatType.direct,
          participants: participants,
          lastMessage: 'Hello there!',
          lastMessageAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          unreadCounts: {'user_1': 2},
        );

        await tester.pumpWidget(
          createTestApp(
            ChatRoomCard(
              chatRoom: chatRoom,
              onTap: () {},
              onDelete: () {},
              currentUserId: 'user_1',
            ),
          ),
        );

        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Hello there!'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // Unread count
      });

      testWidgets('should display group chat correctly',
          (WidgetTester tester) async {
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
          ChatParticipant(
            userId: 'user_3',
            name: 'Bob Wilson',
            joinedAt: DateTime.now(),
          ),
        ];

        final chatRoom = ChatRoom(
          id: 'group_1',
          type: ChatType.group,
          name: 'Team Chat',
          participants: participants,
          lastMessage: 'Group message',
          lastMessageAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          createTestApp(
            ChatRoomCard(
              chatRoom: chatRoom,
              onTap: () {},
              onDelete: () {},
              currentUserId: 'user_1',
            ),
          ),
        );

        expect(find.text('Team Chat'), findsOneWidget);
        expect(find.text('Group message'), findsOneWidget);
        expect(find.text('3 members'), findsOneWidget);
        expect(find.byIcon(Icons.group), findsOneWidget);
      });

      testWidgets('should handle swipe to delete', (WidgetTester tester) async {
        final chatRoom = ChatRoom(
          id: 'chat_1',
          type: ChatType.direct,
          participants: [
            ChatParticipant(
              userId: 'user_1',
              name: 'John Doe',
              joinedAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        bool deleteCallbackCalled = false;

        await tester.pumpWidget(
          createTestApp(
            ChatRoomCard(
              chatRoom: chatRoom,
              onTap: () {},
              onDelete: () {
                deleteCallbackCalled = true;
              },
              currentUserId: 'user_1',
            ),
          ),
        );

        // Find the dismissible widget and trigger dismiss
        final dismissible = find.byType(Dismissible);
        expect(dismissible, findsOneWidget);

        // Simulate a complete dismissal
        await tester.fling(dismissible, const Offset(-500, 0), 1000);
        await tester.pumpAndSettle();

        expect(deleteCallbackCalled, isTrue);
      });
    });

    group('EntityCard Tests', () {
      testWidgets('should display profile entity correctly',
          (WidgetTester tester) async {
        const entity = SharedEntity(
          type: EntityType.profile,
          id: 'profile_1',
          title: 'John Doe',
          subtitle: 'Coach • New York',
          imageUrl: 'https://example.com/profile.jpg',
          metadata: {
            'role': 'Coach',
            'location': 'New York',
          },
        );

        await tester.pumpWidget(
          createTestApp(
            const EntityCard(entity: entity),
          ),
        );

        expect(find.text('PROFILE'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Coach • New York'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('should display venue entity correctly',
          (WidgetTester tester) async {
        const entity = SharedEntity(
          type: EntityType.venue,
          id: 'venue_1',
          title: 'Sports Complex',
          subtitle: 'Downtown',
          metadata: {
            'rating': '4.5',
            'price': '\$\$',
            'location': 'Downtown',
          },
        );

        await tester.pumpWidget(
          createTestApp(
            const EntityCard(entity: entity),
          ),
        );

        expect(find.text('VENUE'), findsOneWidget);
        expect(find.text('Sports Complex'), findsOneWidget);
        expect(find.text('Downtown'), findsAtLeastNWidgets(1));
        expect(find.text('4.5'), findsOneWidget);
        expect(find.text('\$\$'), findsOneWidget);
        expect(find.byIcon(Icons.location_city), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.attach_money), findsOneWidget);
      });

      testWidgets('should display team entity correctly',
          (WidgetTester tester) async {
        const entity = SharedEntity(
          type: EntityType.team,
          id: 'team_1',
          title: 'Thunder Bolts',
          subtitle: 'Basketball',
          metadata: {
            'sport': 'Basketball',
            'memberCount': 12,
            'location': 'New York',
          },
        );

        await tester.pumpWidget(
          createTestApp(
            const EntityCard(entity: entity),
          ),
        );

        expect(find.text('TEAM'), findsOneWidget);
        expect(find.text('Thunder Bolts'), findsOneWidget);
        expect(find.text('Basketball'), findsAtLeastNWidgets(1));
        expect(find.text('12 members'), findsOneWidget);
        expect(find.byIcon(Icons.group), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.sports), findsOneWidget);
      });

      testWidgets('should display tournament entity correctly',
          (WidgetTester tester) async {
        const entity = SharedEntity(
          type: EntityType.tournament,
          id: 'tournament_1',
          title: 'Summer Championship',
          subtitle: 'Tennis • July 15-20',
          metadata: {
            'sport': 'Tennis',
            'location': 'Miami',
            'date': 'July 15-20',
            'prizePool': '\$10,000',
          },
        );

        await tester.pumpWidget(
          createTestApp(
            const EntityCard(entity: entity),
          ),
        );

        expect(find.text('TOURNAMENT'), findsOneWidget);
        expect(find.text('Summer Championship'), findsOneWidget);
        expect(find.text('Tennis • July 15-20'), findsOneWidget);
        expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      });

      testWidgets('should handle tap callback', (WidgetTester tester) async {
        const entity = SharedEntity(
          type: EntityType.profile,
          id: 'profile_1',
          title: 'John Doe',
        );

        bool tapCallbackCalled = false;

        await tester.pumpWidget(
          createTestApp(
            EntityCard(
              entity: entity,
              onTap: () {
                tapCallbackCalled = true;
              },
            ),
          ),
        );

        await tester.tap(find.byType(EntityCard));
        await tester.pumpAndSettle();

        expect(tapCallbackCalled, isTrue);
      });
    });
  });
}
