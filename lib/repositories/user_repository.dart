import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_cache_service.dart';

/// Repository class for managing user profile data in Firestore
class UserRepository {
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinaryService;
  final FirestoreCacheService _cacheService;

  static const String _usersCollection = 'users';

  UserRepository({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinaryService,
    FirestoreCacheService? cacheService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cloudinaryService = cloudinaryService ?? CloudinaryService(),
        _cacheService = cacheService ?? FirestoreCacheService.instance;

  /// Get user profile by UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 UserRepository: Getting profile for UID: $uid');
      }

      final cached = await _cacheService.getDocument(
        collection: FirestoreCacheCollection.users,
        docId: uid,
        maxAge: const Duration(minutes: 20),
      );
      if (cached != null) {
        final cachedProfile = _createProfileFromData(cached);
        if (cachedProfile != null) {
          if (kDebugMode) {
            debugPrint('📦 UserRepository: Returning cached profile for $uid');
          }
          return cachedProfile;
        }
      }

      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('❌ UserRepository: No document found for UID: $uid');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('📄 UserRepository: Document exists, data: ${doc.data()}');
      }

      final profile = _createProfileFromDocument(doc);

      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        data['uid'] ??= doc.id;
        unawaited(_cacheService.cacheDocument(
          collection: FirestoreCacheCollection.users,
          docId: uid,
          data: data,
        ));
      }

      if (kDebugMode) {
        debugPrint('✅ UserRepository: Profile parsed successfully');
        debugPrint('   - Name: ${profile?.fullName}');
        debugPrint('   - Role: ${profile?.role}');
        debugPrint('   - Complete: ${profile?.isProfileComplete}');
      }

      return profile;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '💥 UserRepository: Firebase error getting user profile: ${e.message}');
      }
      throw _handleFirebaseException(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 UserRepository: Error getting user profile: $e');
      }
      throw Exception('Failed to retrieve user profile');
    }
  }

  /// Save user profile to Firestore
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));

      unawaited(_cacheService.cacheDocument(
        collection: FirestoreCacheCollection.users,
        docId: profile.uid,
        data: profile.toFirestore(),
      ));

      if (kDebugMode) {
        debugPrint('User profile saved successfully for UID: ${profile.uid}');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error saving user profile: ${e.message}');
      }
      throw _handleFirebaseException(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving user profile: $e');
      }
      throw Exception('Failed to save user profile');
    }
  }

  /// Update specific fields of user profile
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      // Add updated timestamp
      updates['updatedAt'] = Timestamp.now();

      await _firestore.collection(_usersCollection).doc(uid).update(updates);

      unawaited(_cacheService.mergeDocument(
        collection: FirestoreCacheCollection.users,
        docId: uid,
        updates: {
          ...updates,
          'uid': uid,
        },
      ));

      if (kDebugMode) {
        debugPrint('User profile updated successfully for UID: $uid');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error updating user profile: ${e.message}');
      }
      throw _handleFirebaseException(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating user profile: $e');
      }
      throw Exception('Failed to update user profile');
    }
  }

  /// Upload profile image to Cloudinary
  Future<String> uploadProfileImage(File imageFile, String uid) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 UserRepository: Starting image upload for user: $uid');
      }

      final imageUrl =
          await _cloudinaryService.uploadProfileImage(imageFile, uid);

      if (kDebugMode) {
        debugPrint(
            '✅ UserRepository: Profile image uploaded successfully to Cloudinary');
        debugPrint('🔗 UserRepository: Image URL: $imageUrl');
      }

      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ UserRepository: Error uploading profile image to Cloudinary: $e');
      }
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Delete profile image from Cloudinary
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      await _cloudinaryService.deleteProfileImage(imageUrl);

      if (kDebugMode) {
        debugPrint(
            'Profile image deleted successfully from Cloudinary: $imageUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting profile image from Cloudinary: $e');
      }
      // Don't throw error for image deletion failures
      // as it's not critical for the user experience
    }
  }

  /// Check if user profile exists and is complete
  Future<bool> isProfileComplete(String uid) async {
    try {
      final profile = await getUserProfile(uid);
      return profile?.isProfileComplete ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking profile completion: $e');
      }
      return false;
    }
  }

  /// Get users by role (for future features like finding coaches/players)
  Future<List<UserProfile>> getUsersByRole(UserRole role,
      {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: role.value)
          .limit(limit)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        data['uid'] ??= doc.id;
        unawaited(_cacheService.cacheDocument(
          collection: FirestoreCacheCollection.users,
          docId: doc.id,
          data: data,
        ));
      }

      return query.docs
          .map((doc) => _createProfileFromDocument(doc))
          .where((profile) => profile != null)
          .cast<UserProfile>()
          .toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error getting users by role: ${e.message}');
      }
      throw _handleFirebaseException(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting users by role: $e');
      }
      throw Exception('Failed to retrieve users');
    }
  }

  /// Create profile from Firestore document based on role
  UserProfile? _createProfileFromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;
    data['uid'] ??= doc.id;
    return _createProfileFromData(data);
  }

  UserProfile? _createProfileFromData(Map<String, dynamic> data) {
    final roleString = data['role'] as String?;
    if (roleString == null) return null;

    final role = UserRole.fromString(roleString);

    switch (role) {
      case UserRole.player:
        return PlayerProfile.fromMap(data);
      case UserRole.coach:
        return CoachProfile.fromMap(data);
      case UserRole.admin:
        return CoachProfile.fromMap(data); // Admin uses coach profile structure
    }

    return null;
  }

  /// Handle Firebase exceptions and provide user-friendly error messages
  Exception _handleFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('You do not have permission to perform this action');
      case 'unavailable':
        return Exception(
            'Service is currently unavailable. Please try again later');
      case 'deadline-exceeded':
        return Exception(
            'Request timed out. Please check your connection and try again');
      case 'not-found':
        return Exception('Requested data not found');
      case 'already-exists':
        return Exception('Data already exists');
      case 'resource-exhausted':
        return Exception('Service quota exceeded. Please try again later');
      case 'cancelled':
        return Exception('Operation was cancelled');
      case 'data-loss':
        return Exception('Data loss occurred. Please try again');
      case 'unauthenticated':
        return Exception('Authentication required. Please sign in again');
      case 'invalid-argument':
        return Exception('Invalid data provided');
      case 'out-of-range':
        return Exception('Data is out of valid range');
      case 'unimplemented':
        return Exception('Feature not implemented');
      case 'internal':
        return Exception('Internal server error. Please try again');
      case 'aborted':
        return Exception('Operation was aborted. Please try again');
      default:
        return Exception('An unexpected error occurred: ${e.message}');
    }
  }

  /// Update user's last active timestamp
  Future<void> updateUserLastActive(String uid) async {
    try {
      final lastActiveUpdate = {
        'lastActive': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(lastActiveUpdate);

      unawaited(_cacheService.mergeDocument(
        collection: FirestoreCacheCollection.users,
        docId: uid,
        updates: {
          'uid': uid,
          ...lastActiveUpdate,
        },
      ));

      if (kDebugMode) {
        debugPrint('User last active updated for UID: $uid');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error updating user last active: ${e.message}');
      }
      // Don't throw - activity tracking shouldn't break app flow
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating user last active: $e');
      }
      // Don't throw - activity tracking shouldn't break app flow
    }
  }

  /// Get user's last active timestamp
  Future<DateTime?> getUserLastActive(String uid) async {
    try {
      final cached = await _cacheService.getDocument(
        collection: FirestoreCacheCollection.users,
        docId: uid,
        maxAge: const Duration(hours: 1),
      );
      if (cached != null) {
        final cachedValue = cached['lastActive'];
        DateTime? cachedDate;
        if (cachedValue is Timestamp) {
          cachedDate = cachedValue.toDate();
        } else if (cachedValue is DateTime) {
          cachedDate = cachedValue;
        } else if (cachedValue is String) {
          cachedDate = DateTime.tryParse(cachedValue);
        }
        if (cachedDate != null) {
          return cachedDate;
        }
      }

      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lastActiveTimestamp = data['lastActive'] as Timestamp?;

        unawaited(_cacheService.mergeDocument(
          collection: FirestoreCacheCollection.users,
          docId: uid,
          updates: {
            'uid': uid,
            ...data,
          },
        ));

        return lastActiveTimestamp?.toDate();
      }

      return null;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error getting user last active: ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user last active: $e');
      }
      return null;
    }
  }

  /// Get users who haven't been active for specified days
  Future<List<String>> getInactiveUsers(int daysSinceLastActivity) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysSinceLastActivity));

      final query = await _firestore
          .collection(_usersCollection)
          .where('lastActive', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      return query.docs.map((doc) => doc.id).toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error getting inactive users: ${e.message}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting inactive users: $e');
      }
      return [];
    }
  }
}
