import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:playaround/models/listing_model.dart';
import 'package:playaround/models/session_model.dart';
import 'package:playaround/services/notification_service.dart';
import 'package:playaround/services/session_service.dart';
import 'package:playaround/services/local_notification_service.dart';

class _MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(<String, dynamic>{});
  });

  tearDown(() {
    NotificationService.resetInstance();
  });

  group('SessionService', () {
    test('createSession writes session document and notification', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();

      await firestore.collection('users').doc('athlete-1').set({
        'email': 'athlete@example.com',
        'fullName': 'Athlete One',
      });

      final local = _MockLocalNotificationService();
      final notificationService = NotificationService(
        firestore: firestore,
        auth: auth,
        localNotificationService: local,
      );

      final sessionService = SessionService(
        firestore: firestore,
        auth: auth,
        notificationService: notificationService,
      );

      final sessionId = await sessionService.createSession(
        date: DateTime(2030, 5, 10),
        time: const TimeOfDay(hour: 10, minute: 30),
        sport: SportType.basketball,
        participantIdentifiers: const ['athlete@example.com'],
        description: 'Dribbling drills and shooting practice',
        durationMinutes: 90,
        testCoachId: 'coach-1',
      );

      final sessionDoc =
          await firestore.collection('sessions').doc(sessionId).get();
      expect(sessionDoc.exists, isTrue);
      final sessionData = sessionDoc.data()!;
      expect(sessionData['coachId'], 'coach-1');
      expect(sessionData['participantIds'], contains('athlete-1'));
      expect(sessionData['sport'], SportType.basketball.name);

      final notifications = await firestore.collection('notifications').get();
      expect(notifications.docs, isNotEmpty);
      final notificationData = notifications.docs.first.data();
      expect(notificationData['userId'], 'athlete-1');
      expect(notificationData['type'], 'session_created');
    });

    test('cancelSession updates status and notifies participants', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();

      await firestore.collection('users').doc('athlete-1').set({
        'email': 'athlete@example.com',
        'fullName': 'Athlete One',
      });

      final local = _MockLocalNotificationService();
      final notificationService = NotificationService(
        firestore: firestore,
        auth: auth,
        localNotificationService: local,
      );

      final sessionService = SessionService(
        firestore: firestore,
        auth: auth,
        notificationService: notificationService,
      );

      final sessionId = await sessionService.createSession(
        date: DateTime(2030, 5, 10),
        time: const TimeOfDay(hour: 10, minute: 30),
        sport: SportType.football,
        participantIdentifiers: const ['athlete@example.com'],
        description: 'Warm up and scrimmage',
        durationMinutes: 60,
        testCoachId: 'coach-1',
      );

      await sessionService.cancelSession(
        sessionId,
        reason: 'Coach unavailable',
        testCoachId: 'coach-1',
      );

      final sessionDoc =
          await firestore.collection('sessions').doc(sessionId).get();
      expect(sessionDoc.data()?['status'], SessionStatus.cancelled.name);
      expect(sessionDoc.data()?['cancellationReason'], 'Coach unavailable');

      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: 'athlete-1')
          .orderBy('createdAt')
          .get();
      expect(notifications.docs.length, 2);
      final lastNotification = notifications.docs.last.data();
      expect(lastNotification['type'], 'session_cancelled');
    });
  });
}
