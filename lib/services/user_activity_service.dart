import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../repositories/user_repository.dart';

/// Service for tracking user activity and managing activity-based features
class UserActivityService {
  static final UserActivityService _instance = UserActivityService._internal();
  factory UserActivityService() => _instance;
  UserActivityService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  /// Track user activity - call this on significant user actions
  Future<void> trackActivity() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _userRepository.updateUserLastActive(user.uid);

        if (kDebugMode) {
          debugPrint(
              '🔄 UserActivityService: Activity tracked for user ${user.uid}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserActivityService: Error tracking activity: $e');
      }
      // Don't throw - activity tracking shouldn't break app flow
    }
  }

  /// Track activity for specific user (for admin/system operations)
  Future<void> trackActivityForUser(String userId) async {
    try {
      await _userRepository.updateUserLastActive(userId);

      if (kDebugMode) {
        debugPrint('🔄 UserActivityService: Activity tracked for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ UserActivityService: Error tracking activity for user $userId: $e');
      }
      // Don't throw - activity tracking shouldn't break app flow
    }
  }

  /// Get user's last active timestamp
  Future<DateTime?> getLastActive([String? userId]) async {
    try {
      final targetUserId = userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) return null;

      return await _userRepository.getUserLastActive(targetUserId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserActivityService: Error getting last active: $e');
      }
      return null;
    }
  }

  /// Get days since user was last active
  Future<int> getDaysSinceLastActive([String? userId]) async {
    try {
      final lastActive = await getLastActive(userId);
      if (lastActive == null) {
        return 30; // Default to 30 days if no activity found
      }

      return DateTime.now().difference(lastActive).inDays;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ UserActivityService: Error calculating days since last active: $e');
      }
      return 30;
    }
  }

  /// Check if user is considered inactive
  Future<bool> isUserInactive([String? userId, int thresholdDays = 10]) async {
    try {
      final daysSinceActive = await getDaysSinceLastActive(userId);
      return daysSinceActive >= thresholdDays;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ UserActivityService: Error checking if user is inactive: $e');
      }
      return false;
    }
  }

  /// Get list of inactive users
  Future<List<String>> getInactiveUsers(int daysSinceLastActivity) async {
    try {
      return await _userRepository.getInactiveUsers(daysSinceLastActivity);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserActivityService: Error getting inactive users: $e');
      }
      return [];
    }
  }

  /// Initialize activity tracking for current user (call on app start)
  Future<void> initializeActivityTracking() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Check if user has lastActive field, if not, set it now
        final lastActive = await getLastActive();
        if (lastActive == null) {
          await trackActivity();

          if (kDebugMode) {
            debugPrint(
                '🔄 UserActivityService: Initialized activity tracking for user ${user.uid}');
          }
        } else {
          // Update activity on app start
          await trackActivity();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ UserActivityService: Error initializing activity tracking: $e');
      }
    }
  }
}

/// Mixin to easily add activity tracking to any service or screen
mixin ActivityTrackingMixin {
  final UserActivityService _activityService = UserActivityService();

  /// Track user activity - call this on significant user actions
  Future<void> trackUserActivity() async {
    await _activityService.trackActivity();
  }

  /// Track activity for specific user
  Future<void> trackUserActivityFor(String userId) async {
    await _activityService.trackActivityForUser(userId);
  }
}

/// Extension to add activity tracking to common actions
extension ActivityTrackingExtension on Object {
  /// Track activity and then execute the action
  Future<T> withActivityTracking<T>(Future<T> Function() action) async {
    final activityService = UserActivityService();
    await activityService.trackActivity();
    return await action();
  }
}
