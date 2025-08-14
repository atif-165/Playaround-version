import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

/// Service for managing notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');

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

      await _notificationsCollection.doc(notificationId).set(notification.toFirestore());
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

      Query query = _notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
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
      await _notificationsCollection.doc(notification.id).set(notification.toFirestore());
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }
}
