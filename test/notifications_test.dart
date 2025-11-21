import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:playaround/models/notification_model.dart';
import 'package:playaround/services/local_notification_service.dart';
import 'package:playaround/services/notification_service.dart';

class _MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  tearDown(() {
    NotificationService.resetInstance();
  });

  group('NotificationService', () {
    test(
        'startRealtimeListener forwards new notifications to local notifications',
        () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();
      final local = _MockLocalNotificationService();

      when(() => local.initialize()).thenAnswer((_) async {});
      when(
        () => local.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final service = NotificationService(
        firestore: firestore,
        auth: auth,
        localNotificationService: local,
      );

      await service.startRealtimeListener(
        forceRestart: true,
        testUserId: 'user-123',
      );

      final createdAt = Timestamp.fromDate(
          DateTime.now().add(const Duration(milliseconds: 10)));
      await firestore.collection('notifications').doc('notif-1').set({
        'id': 'notif-1',
        'userId': 'user-123',
        'type': NotificationType.bookingUpdate.value,
        'title': 'Booking Updated',
        'message': 'Your booking status changed.',
        'isRead': false,
        'createdAt': createdAt,
      });

      await pumpEventQueue(times: 5);

      verify(
        () => local.showNotification(
          id: any(named: 'id'),
          title: 'Booking Updated',
          body: 'Your booking status changed.',
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('createNotification persists document in Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'user-123', email: 'user@example.com'),
      );
      final local = _MockLocalNotificationService();

      when(() => local.initialize()).thenAnswer((_) async {});
      when(
        () => local.showNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final service = NotificationService(
        firestore: firestore,
        auth: auth,
        localNotificationService: local,
      );

      final notificationId = await service.createNotification(
        userId: 'user-123',
        type: NotificationType.bookingUpdate,
        title: 'Test Notification',
        message: 'This is only a drill.',
      );

      final snapshot =
          await firestore.collection('notifications').doc(notificationId).get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['title'], 'Test Notification');
      expect(snapshot.data()?['type'], NotificationType.bookingUpdate.value);
    });
  });
}
