import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling community user-related operations
class CommunityUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's nickname
  static Future<String> getCurrentUserNickname() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 'Anonymous';

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 'User';

      final data = userDoc.data();

      // Try different possible field names for nickname
      return data?['nickname'] as String? ??
          data?['nickName'] as String? ??
          data?['displayName'] as String? ??
          data?['fullName'] as String? ??
          'User';
    } catch (e) {
      return 'User';
    }
  }

  /// Get current user's initial (first character of name)
  static Future<String> getCurrentUserInitial() async {
    try {
      final nickname = await getCurrentUserNickname();
      return nickname.isNotEmpty ? nickname[0].toUpperCase() : 'U';
    } catch (e) {
      return 'U';
    }
  }

  /// Get current user's profile picture URL
  static Future<String?> getCurrentUserProfilePicture() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      // First try public_profiles collection (where profile picture is usually stored)
      final publicProfileDoc = await _firestore.collection('public_profiles').doc(userId).get();
      if (publicProfileDoc.exists) {
        final publicData = publicProfileDoc.data();
        final profilePic = publicData?['profilePictureUrl'] as String? ??
            publicData?['profilePicture'] as String?;
        if (profilePic != null && profilePic.isNotEmpty) {
          return profilePic;
        }
      }

      // Fallback to users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        // Try different possible field names for profile picture
        return data?['profilePictureUrl'] as String? ??
            data?['profilePicture'] as String? ??
            data?['photoUrl'] as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if current user is the owner of a post
  static bool isCurrentUserPostOwner(String postAuthorId) {
    final currentUserId = getCurrentUserId();
    return currentUserId != null && currentUserId == postAuthorId;
  }

  /// Check if current user is the owner of a comment
  static bool isCurrentUserCommentOwner(String commentAuthorId) {
    final currentUserId = getCurrentUserId();
    return currentUserId != null && currentUserId == commentAuthorId;
  }

  /// Get user nickname by user ID
  static Future<String> getUserNickname(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 'User';

      final data = userDoc.data();

      return data?['nickname'] as String? ??
          data?['nickName'] as String? ??
          data?['displayName'] as String? ??
          data?['fullName'] as String? ??
          'User';
    } catch (e) {
      return 'User';
    }
  }

  /// Get user profile picture by user ID
  static Future<String?> getUserProfilePicture(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data();

      return data?['profilePictureUrl'] as String? ??
          data?['profilePicture'] as String? ??
          data?['photoUrl'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Update user's last activity timestamp
  static Future<void> updateLastActivity() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Check if user exists
  static Future<bool> userExists(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get user's full name
  static Future<String> getUserFullName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 'Unknown User';

      final data = userDoc.data();

      return data?['fullName'] as String? ??
          data?['displayName'] as String? ??
          data?['nickname'] as String? ??
          'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }
}
