import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/coach_profile.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';

/// Service for managing coach-related operations
class CoachService {
  static final CoachService _instance = CoachService._internal();
  factory CoachService() => _instance;
  CoachService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  static const String _usersCollection = 'users';

  /// Get all coaches with optional filters
  Stream<List<CoachProfile>> getCoaches({
    String? searchQuery,
    List<String>? sportFilters,
    String? locationFilter,
    int limit = 20,
  }) {
    try {
      Query query = _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'coach')
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit);

      // Apply location filter if provided
      if (locationFilter != null && locationFilter.isNotEmpty) {
        query = query.where('location', isEqualTo: locationFilter);
      }

      return query.snapshots().map((snapshot) {
        List<CoachProfile> coaches = snapshot.docs
            .map((doc) => CoachProfile.fromFirestore(doc))
            .where((coach) => coach != null)
            .map((coach) => coach!)
            .toList();

        // Apply search filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          coaches = coaches.where((coach) {
            final query = searchQuery.toLowerCase();
            return coach.fullName.toLowerCase().contains(query) ||
                   (coach.bio?.toLowerCase().contains(query) ?? false) ||
                   coach.specializationSports.any((sport) => 
                       sport.toLowerCase().contains(query));
          }).toList();
        }

        // Apply sport filters
        if (sportFilters != null && sportFilters.isNotEmpty) {
          coaches = coaches.where((coach) {
            return coach.specializationSports.any((sport) => 
                sportFilters.contains(sport));
          }).toList();
        }

        // Sort by rating (assuming we'll add this field later)
        coaches.sort((a, b) => b.fullName.compareTo(a.fullName));

        return coaches;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting coaches: $e');
      }
      return Stream.value([]);
    }
  }

  /// Get a specific coach by ID
  Future<CoachProfile?> getCoach(String coachId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(coachId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data?['role'] != 'coach') return null;

      return CoachProfile.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting coach: $e');
      }
      return null;
    }
  }

  /// Get coaches by sport type
  Stream<List<CoachProfile>> getCoachesBySport(String sport, {int limit = 10}) {
    try {
      return _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'coach')
          .where('isProfileComplete', isEqualTo: true)
          .where('specializationSports', arrayContains: sport)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => CoachProfile.fromFirestore(doc))
            .where((coach) => coach != null)
            .map((coach) => coach!)
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting coaches by sport: $e');
      }
      return Stream.value([]);
    }
  }

  /// Search coaches by name
  Future<List<CoachProfile>> searchCoachesByName(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'coach')
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit)
          .get();

      final coaches = snapshot.docs
          .map((doc) => CoachProfile.fromFirestore(doc))
          .where((coach) => coach != null)
          .cast<CoachProfile>()
          .toList();

      // Filter by name (client-side filtering for better search)
      final filteredCoaches = coaches.where((coach) {
        return coach.fullName.toLowerCase().contains(query.toLowerCase());
      }).toList();

      return filteredCoaches;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching coaches by name: $e');
      }
      return [];
    }
  }

  /// Get current user's coach profile if they are a coach
  Future<CoachProfile?> getCurrentUserCoachProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userProfile = await _userRepository.getUserProfile(user.uid);
      if (userProfile == null || userProfile.role != UserRole.coach) {
        return null;
      }

      return userProfile as CoachProfile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting current user coach profile: $e');
      }
      return null;
    }
  }

  /// Check if current user is a coach
  Future<bool> isCurrentUserCoach() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userProfile = await _userRepository.getUserProfile(user.uid);
      return userProfile?.role == UserRole.coach;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking if current user is coach: $e');
      }
      return false;
    }
  }

  /// Update coach profile
  Future<bool> updateCoachProfile(CoachProfile updatedProfile) async {
    try {
      await _userRepository.updateUserProfile(updatedProfile.uid, updatedProfile.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating coach profile: $e');
      }
      return false;
    }
  }

  /// Get available sports for filtering
  Future<List<String>> getAvailableSports() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'coach')
          .where('isProfileComplete', isEqualTo: true)
          .get();

      final Set<String> sports = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final specializationSports = data['specializationSports'] as List<dynamic>?;
        if (specializationSports != null) {
          sports.addAll(specializationSports.cast<String>());
        }
      }

      final sortedSports = sports.toList()..sort();
      return sortedSports;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting available sports: $e');
      }
      return [];
    }
  }

  /// Get featured coaches (top-rated or most popular)
  Future<List<CoachProfile>> getFeaturedCoaches({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'coach')
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CoachProfile.fromFirestore(doc))
          .where((coach) => coach != null)
          .cast<CoachProfile>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting featured coaches: $e');
      }
      return [];
    }
  }

  /// Get venues owned by a specific coach
  Future<List<dynamic>> getCoachVenues(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('venues')
          .where('ownerId', isEqualTo: coachId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['title'] ?? 'Unknown Venue',
        'location': doc.data()['location'] ?? 'Unknown Location',
        'sportType': doc.data()['sportType'] ?? 'Unknown Sport',
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting coach venues: $e');
      }
      return [];
    }
  }

  /// Get teams managed by a specific coach
  Future<List<dynamic>> getCoachTeams(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('teams')
          .where('isActive', isEqualTo: true)
          .get();

      final coachTeams = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final members = data['members'] as List<dynamic>? ?? [];

        // Check if coach is owner
        if (data['ownerId'] == coachId) {
          coachTeams.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Team',
            'memberCount': members.length,
            'maxMembers': data['maxMembers'] ?? 0,
            'sportType': data['sportType'] ?? 'Unknown Sport',
          });
          continue;
        }

        // Check if coach is a member with captain role
        final isCoach = members.any((member) =>
          member['userId'] == coachId &&
          (member['role'] == 'captain' || member['role'] == 'owner')
        );

        if (isCoach) {
          coachTeams.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Team',
            'memberCount': members.length,
            'maxMembers': data['maxMembers'] ?? 0,
            'sportType': data['sportType'] ?? 'Unknown Sport',
          });
        }
      }

      return coachTeams;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting coach teams: $e');
      }
      return [];
    }
  }
}
