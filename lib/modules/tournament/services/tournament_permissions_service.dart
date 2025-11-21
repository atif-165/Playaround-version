import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';

/// Service for checking tournament-related permissions
class TournamentPermissionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  /// Check if current user can create tournaments
  /// Only coaches, venue owners, and team owners can create tournaments
  Future<bool> canCreateTournaments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get user profile to check role
      final userProfile = await _userRepository.getUserProfile(user.uid);
      if (userProfile == null) return false;

      // Check if user is a coach
      if (userProfile.role == UserRole.coach) {
        if (kDebugMode) {
          debugPrint('✅ User can create tournaments: Is a coach');
        }
        return true;
      }

      // Check if user owns any venues
      final venuesQuery = await _firestore
          .collection('venues')
          .where('ownerId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (venuesQuery.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ User can create tournaments: Owns venues');
        }
        return true;
      }

      // Check if user owns or is captain of any teams
      final teamsQuery = await _firestore
          .collection('teams')
          .where('createdBy', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (teamsQuery.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ User can create tournaments: Owns teams');
        }
        return true;
      }

      // Check if user is owner/captain in any team
      final teamsAsPlayerQuery = await _firestore.collection('teams').get();

      for (final doc in teamsAsPlayerQuery.docs) {
        final data = doc.data();
        final players = data['players'] as List<dynamic>? ?? [];

        final isOwnerOrCaptain = players.any((player) =>
            player['id'] == user.uid &&
            (player['role'] == 'owner' || player['role'] == 'captain'));

        if (isOwnerOrCaptain) {
          if (kDebugMode) {
            debugPrint('✅ User can create tournaments: Is team owner/captain');
          }
          return true;
        }
      }

      if (kDebugMode) {
        debugPrint(
            '❌ User cannot create tournaments: Not a coach, venue owner, or team owner');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking tournament creation permissions: $e');
      }
      return false;
    }
  }

  /// Get reason why user cannot create tournaments (for UI messages)
  Future<String> getCreationRestrictionReason() async {
    final canCreate = await canCreateTournaments();

    if (canCreate) {
      return 'You have permission to create tournaments';
    }

    try {
      final user = _auth.currentUser;
      if (user == null) return 'You must be logged in';

      final userProfile = await _userRepository.getUserProfile(user.uid);
      if (userProfile == null) return 'Profile not found';

      return 'Only coaches, venue owners, and team owners can create tournaments.\n\n'
          'To create tournaments, you need to:\n'
          '• Be a coach, OR\n'
          '• Own a venue, OR\n'
          '• Own or be captain of a team';
    } catch (e) {
      return 'Error checking permissions';
    }
  }

  /// Cache permissions for better performance
  static bool? _cachedPermission;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<bool> canCreateTournamentsCached() async {
    if (_cachedPermission != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedPermission!;
    }

    final result = await canCreateTournaments();
    _cachedPermission = result;
    _cacheTime = DateTime.now();
    return result;
  }

  /// Clear cache (call when user's roles/ownership changes)
  static void clearCache() {
    _cachedPermission = null;
    _cacheTime = null;
  }
}
