import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling community notifications
class CommunityNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a notification for a new comment
  static Future<void> createCommentNotification({
    required String postId,
    required String postAuthorId,
    required String commenterName,
    required String commentContent,
    String? postOwnerId,
    String? fromUserId,
    String? fromUserNickname,
    String? fromUserProfilePicture,
    String? commentId,
    String? parentCommentId,
  }) async {
    try {
      final currentUserId = fromUserId ?? _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final targetUserId = postOwnerId ?? postAuthorId;
      final userName = fromUserNickname ?? commenterName;

      // Don't notify if user is commenting on their own post
      if (currentUserId == targetUserId) return;

      await _firestore.collection('notifications').add({
        'userId': targetUserId,
        'type': 'comment',
        'title': 'New Comment',
        'message': '$userName commented: ${_truncateText(commentContent, 50)}',
        'postId': postId,
        'commentId': commentId,
        'parentCommentId': parentCommentId,
        'fromUserId': currentUserId,
        'fromUserName': userName,
        'fromUserProfilePicture': fromUserProfilePicture,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - notifications are not critical
    }
  }

  /// Create a notification for a new like
  static Future<void> createLikeNotification({
    required String postId,
    required String postAuthorId,
    required String likerName,
    bool isLike = true,
    String? postOwnerId,
    String? fromUserId,
    String? fromUserNickname,
    String? fromUserProfilePicture,
  }) async {
    try {
      final currentUserId = fromUserId ?? _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final targetUserId = postOwnerId ?? postAuthorId;
      final userName = fromUserNickname ?? likerName;

      // Don't notify if user is liking their own post
      if (currentUserId == targetUserId) return;

      // Only create notification for likes, not dislikes (to avoid negative feelings)
      if (!isLike) return;

      await _firestore.collection('notifications').add({
        'userId': targetUserId,
        'type': 'like',
        'title': 'New Like',
        'message': '$userName liked your post',
        'postId': postId,
        'fromUserId': currentUserId,
        'fromUserName': userName,
        'fromUserProfilePicture': fromUserProfilePicture,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - notifications are not critical
    }
  }

  /// Create a notification for a new reply to a comment
  static Future<void> createReplyNotification({
    required String postId,
    required String commentId,
    required String commentAuthorId,
    required String replierName,
    required String replyContent,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Don't notify if user is replying to their own comment
      if (currentUserId == commentAuthorId) return;

      await _firestore.collection('notifications').add({
        'userId': commentAuthorId,
        'type': 'reply',
        'title': 'New Reply',
        'message': '$replierName replied: ${_truncateText(replyContent, 50)}',
        'postId': postId,
        'commentId': commentId,
        'fromUserId': currentUserId,
        'fromUserName': replierName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - notifications are not critical
    }
  }

  /// Get unread notification count for current user
  static Future<int> getUnreadNotificationCount() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 0;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Mark all notifications as read for current user
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      // Silently fail
    }
  }

  /// Delete old notifications (older than 30 days)
  static Future<void> deleteOldNotifications() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      // Silently fail
    }
  }

  /// Helper method to truncate text
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
