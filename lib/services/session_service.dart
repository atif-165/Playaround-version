import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/listing_model.dart';
import '../models/notification_model.dart';
import '../models/session_model.dart';
import 'notification_service.dart';

/// Service responsible for managing coaching sessions in Firestore.
class SessionService {
  SessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _notificationService = notificationService ??
            NotificationService(firestore: firestore, auth: auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;

  CollectionReference<Map<String, dynamic>> get _sessionsCollection =>
      _firestore.collection('sessions').withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => Map<String, dynamic>.from(
                snapshot.data() ?? <String, dynamic>{}),
            toFirestore: (value, _) => value,
          );

  Future<String> createSession({
    required DateTime date,
    required TimeOfDay time,
    required SportType sport,
    required List<String> participantIdentifiers,
    required String description,
    int durationMinutes = 60,
    String? testCoachId,
  }) async {
    final user = _auth.currentUser;
    final coachId = user?.uid ?? testCoachId;
    if (coachId == null) throw Exception('User not authenticated');

    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final participants = await _resolveParticipants(participantIdentifiers);
    final participantMap = <String, SessionParticipant>{};
    for (final participant in participants) {
      final key = participant.userId ?? participant.email.toLowerCase();
      participantMap[key] = participant;
    }
    final uniqueParticipants = participantMap.values.toList();

    final sessionId = _sessionsCollection.doc().id;
    final now = DateTime.now();

    final session = SessionModel(
      id: sessionId,
      coachId: coachId,
      coachName: user?.displayName ?? 'Coach',
      sport: sport,
      startTime: startTime,
      durationMinutes: durationMinutes,
      status: SessionStatus.scheduled,
      description: description,
      participants: uniqueParticipants,
      createdAt: now,
      updatedAt: now,
    );

    await _sessionsCollection.doc(sessionId).set(session.toFirestore());

    await _notifyParticipants(
      session: session,
      type: NotificationType.sessionCreated,
      title: 'New Session Scheduled',
      messageBuilder: (participant) => _sessionMessage(
        prefix: 'You have been added to a session',
        session: session,
      ),
    );

    if (kDebugMode) {
      debugPrint(
        'SessionService: created session $sessionId with ${uniqueParticipants.length} participants',
      );
    }

    return sessionId;
  }

  Future<void> cancelSession(
    String sessionId, {
    String? reason,
    String? testCoachId,
  }) async {
    final user = _auth.currentUser;
    final coachId = user?.uid ?? testCoachId;
    if (coachId == null) throw Exception('User not authenticated');

    final doc = await _sessionsCollection.doc(sessionId).get();
    if (!doc.exists) throw Exception('Session not found');

    final session = SessionModel.fromFirestore(doc);
    if (session.coachId != coachId) {
      throw Exception('Only the coach can cancel this session');
    }
    if (session.isCancelled) return;

    await _sessionsCollection.doc(sessionId).update({
      'status': SessionStatus.cancelled.name,
      'cancellationReason': reason,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _notifyParticipants(
      session: session,
      type: NotificationType.sessionCancelled,
      title: 'Session Cancelled',
      messageBuilder: (participant) => _sessionMessage(
        prefix: 'A session was cancelled',
        session: session,
      ),
      extraData: {'cancellationReason': reason},
    );
  }

  Future<void> markCompleted(String sessionId) async {
    await _sessionsCollection.doc(sessionId).update({
      'status': SessionStatus.completed.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<SessionModel>> watchCoachSessions(String coachId) {
    return _sessionsCollection
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: SessionStatus.scheduled.name)
        .snapshots()
        .map(_mapSessions);
  }

  Stream<List<SessionModel>> watchParticipantSessions(String userId) {
    return _sessionsCollection
        .where('participantIds', arrayContains: userId)
        .where('status', isEqualTo: SessionStatus.scheduled.name)
        .snapshots()
        .map(_mapSessions);
  }

  Future<SessionModel?> getSessionById(String sessionId) async {
    final doc = await _sessionsCollection.doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromFirestore(doc);
  }

  List<SessionModel> _mapSessions(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    final sessions = snapshot.docs
        .map((doc) =>
            SessionModel.fromMap(Map<String, dynamic>.from(doc.data())))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }

  Future<List<SessionParticipant>> _resolveParticipants(
      List<String> identifiers) async {
    final List<SessionParticipant> participants = [];
    for (final raw in identifiers) {
      final value = raw.trim();
      if (value.isEmpty) continue;

      SessionParticipant? participant;

      // Try as user ID
      final userDoc = await _firestore.collection('users').doc(value).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        participant = SessionParticipant(
          userId: userDoc.id,
          email: (data['email'] as String?) ?? value,
          displayName: data['fullName'] as String?,
        );
      } else {
        // Try by email
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: value)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final data = doc.data();
          participant = SessionParticipant(
            userId: doc.id,
            email: data['email'] as String? ?? value,
            displayName: data['fullName'] as String?,
          );
        }
      }

      participant ??= SessionParticipant(
          userId: null, email: value, displayName: value.split('@').first);

      participants.add(participant);
    }

    return participants;
  }

  Future<void> _notifyParticipants({
    required SessionModel session,
    required NotificationType type,
    required String title,
    required String Function(SessionParticipant participant) messageBuilder,
    Map<String, dynamic>? extraData,
  }) async {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    for (final participant in session.participants) {
      final userId = participant.userId;
      if (userId == null) continue;

      await _notificationService.createNotification(
        userId: userId,
        type: type,
        title: title,
        message: messageBuilder(participant),
        data: {
          'sessionId': session.id,
          'coachId': session.coachId,
          'coachName': session.coachName,
          'sport': session.sport.displayName,
          'startTime': session.startTime.toIso8601String(),
          'durationMinutes': session.durationMinutes,
          'formattedTime': dateFormat.format(session.startTime),
          if (extraData != null) ...extraData,
        },
      );
    }
  }

  String _sessionMessage({
    required String prefix,
    required SessionModel session,
  }) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    return '$prefix with ${session.coachName} (${session.sport.displayName}) on ${dateFormat.format(session.startTime)}';
  }
}
