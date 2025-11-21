import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import 'local_notification_service.dart';

/// Service for managing notifications
class NotificationService {
  NotificationService._internal({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    LocalNotificationService? localNotificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localNotificationService =
            localNotificationService ?? LocalNotificationService();

  static NotificationService? _instance;
  factory NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    LocalNotificationService? localNotificationService,
  }) {
    _instance ??= NotificationService._internal(
      firestore: firestore,
      auth: auth,
      localNotificationService: localNotificationService,
    );
    return _instance!;
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalNotificationService _localNotificationService;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _realtimeSubscription;
  bool _processedInitialSnapshot = false;
  final Set<String> _deliveredNotificationIds = <String>{};

  @visibleForTesting
  static void resetInstance() {
    _instance?._dispose();
    _instance = null;
  }

  void _dispose() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _processedInitialSnapshot = false;
    _deliveredNotificationIds.clear();
  }

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore
          .collection('notifications')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => Map<String, dynamic>.from(
                snapshot.data() ?? <String, dynamic>{}),
            toFirestore: (value, _) => value,
          );

  /// Create a new notification
  Future<String> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId = _notificationsCollection.doc().id;
      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
        createdAt: DateTime.now(),
      );

      await _notificationsCollection
          .doc(notificationId)
          .set(notification.toFirestore());
      return notificationId;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get notifications for current user
  Stream<List<NotificationModel>> getUserNotifications({int? limit}) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query<Map<String, dynamic>> query = _notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) =>
              NotificationModel.fromMap(Map<String, dynamic>.from(doc.data())))
          .toList());
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  /// Get unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    try {
      final user = _auth.currentUser;
      if (user == null) return Stream.value(0);

      return _notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final unreadNotifications = await _notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      final now = Timestamp.fromDate(DateTime.now());

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': now,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Create venue booking notification
  Future<void> createVenueBookingNotification({
    required String venueOwnerId,
    required String venueTitle,
    required String bookerName,
    required String bookingId,
  }) async {
    await createNotification(
      userId: venueOwnerId,
      type: NotificationType.venueBooking,
      title: 'New Venue Booking',
      message: '$bookerName has booked your venue "$venueTitle"',
      data: {
        'bookingId': bookingId,
        'venueTitle': venueTitle,
        'bookerName': bookerName,
      },
    );
  }

  /// Create tournament registration notification
  Future<void> createTournamentRegistrationNotification({
    required String organizerId,
    required String tournamentName,
    required String teamName,
    required String tournamentId,
  }) async {
    await createNotification(
      userId: organizerId,
      type: NotificationType.tournamentRegistration,
      title: 'New Tournament Registration',
      message: 'Team "$teamName" has registered for "$tournamentName"',
      data: {
        'tournamentId': tournamentId,
        'tournamentName': tournamentName,
        'teamName': teamName,
      },
    );
  }

  /// Create team invite notification
  Future<void> createTeamInviteNotification({
    required String userId,
    required String teamName,
    required String inviterName,
    required String teamId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.teamInvite,
      title: 'Team Invitation',
      message: '$inviterName invited you to join "$teamName"',
      data: {
        'teamId': teamId,
        'teamName': teamName,
        'inviterName': inviterName,
      },
    );
  }

  /// Create general notification
  Future<void> createGeneralNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.general,
      title: title,
      message: message,
      data: data,
    );
  }

  /// Send notification (alias for createNotification with NotificationModel)
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _notificationsCollection
          .doc(notification.id)
          .set(notification.toFirestore());
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  /// Start listening to Firestore notifications and mirror them as local notifications.
  Future<void> startRealtimeListener(
      {bool forceRestart = false, String? testUserId}) async {
    if (!forceRestart && _realtimeSubscription != null) return;

    final user = _auth.currentUser;
    final effectiveUserId = user?.uid ?? testUserId;
    if (effectiveUserId == null) throw Exception('User not authenticated');

    if (forceRestart) {
      await _realtimeSubscription?.cancel();
      _processedInitialSnapshot = false;
      _deliveredNotificationIds.clear();
    }

    await _localNotificationService.initialize();

    final query = _notificationsCollection
        .where('userId', isEqualTo: effectiveUserId)
        .orderBy('createdAt', descending: true)
        .limit(25);

    _realtimeSubscription = query.snapshots().listen((snapshot) {
      if (!_processedInitialSnapshot) {
        for (final doc in snapshot.docs) {
          _deliveredNotificationIds.add(doc.id);
        }
        _processedInitialSnapshot = true;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        if (change.doc.metadata.hasPendingWrites) continue;

        final data = change.doc.data();
        if (data == null) continue;

        try {
          final notification = NotificationModel.fromMap(
            Map<String, dynamic>.from(data),
          );
          if (_deliveredNotificationIds.contains(notification.id)) {
            continue;
          }
          _deliveredNotificationIds.add(notification.id);

          unawaited(_localNotificationService.showNotification(
            id: notification.id.hashCode,
            title: notification.title,
            body: notification.message,
            payload: {
              'notificationId': notification.id,
              'type': notification.type.value,
              'createdAt': notification.createdAt.toIso8601String(),
              if (notification.data != null) 'data': notification.data,
            },
          ));
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'NotificationService: failed to deliver local notification - $e');
          }
        }
      }
    });
  }

  /// Stop listening to realtime Firestore notifications.
  Future<void> stopRealtimeListener() async {
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _processedInitialSnapshot = false;
    _deliveredNotificationIds.clear();
  }

  @visibleForTesting
  bool get isListening => _realtimeSubscription != null;
}
