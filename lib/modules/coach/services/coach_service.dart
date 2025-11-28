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
    int limit = 500, // Increased limit significantly to show all coaches
  }) {
    try {
      Query query = _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'coach')
          .limit(limit * 2); // Fetch more than needed to account for filtering

      // Apply location filter if provided (server-side)
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
                coach.specializationSports
                    .any((sport) => sport.toLowerCase().contains(query));
          }).toList();
        }

        // Apply sport filters
        if (sportFilters != null && sportFilters.isNotEmpty) {
          coaches = coaches.where((coach) {
            return coach.specializationSports
                .any((sport) => sportFilters.contains(sport));
          }).toList();
        }

        // Sort by updatedAt descending (most recently updated first)
        // This ensures newly created/updated profiles like "farhat" appear at the top
        coaches.sort((a, b) {
          // Primary sort: by updatedAt (most recent first)
          final dateComparison = b.updatedAt.compareTo(a.updatedAt);
          if (dateComparison != 0) return dateComparison;
          // Secondary sort: by name (alphabetical) if dates are equal
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        });

        // Apply limit after sorting
        if (coaches.length > limit) {
          coaches = coaches.take(limit).toList();
        }

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
      final doc =
          await _firestore.collection(_usersCollection).doc(coachId).get();

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
  /// Uses similar approach to teams/players search for consistency
  Future<List<CoachProfile>> searchCoachesByName(String query,
      {int limit = 50}) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return [];

      if (kDebugMode) {
        debugPrint('🔍 Searching coaches with query: "$trimmed"');
      }

      final searchTerm = trimmed.toLowerCase();

      // Fetch more coaches to have better search results (similar to teams/players)
      Query baseQuery = _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'coach')
          .where('isProfileComplete', isEqualTo: true);

      List<QueryDocumentSnapshot> docs;
      try {
        // Try to order by fullName for better results
        docs = (await baseQuery.orderBy('fullName').limit(limit * 5).get()).docs;
      } on FirebaseException catch (error) {
        if (error.code == 'failed-precondition') {
          // Fallback if index doesn't exist
          if (kDebugMode) {
            debugPrint('⚠️ Index not found, using fallback query');
          }
          docs = (await baseQuery.limit(limit * 5).get()).docs;
        } else {
          rethrow;
        }
      }

      if (kDebugMode) {
        debugPrint('📊 Found ${docs.length} coach profiles from database');
      }

      // Filter coaches by search term
      final filteredDocs = docs
          .where((doc) {
            final raw = doc.data();
            final data = raw is Map<String, dynamic>
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{};
            data['uid'] = doc.id;
            return _matchesCoachSearch(data, searchTerm);
          })
          .take(limit)
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Filtered to ${filteredDocs.length} coaches matching "$trimmed"');
      }

      // Convert to CoachProfile using DocumentSnapshot
      final coaches = <CoachProfile>[];
      for (var doc in filteredDocs) {
        try {
          final coach = CoachProfile.fromFirestore(doc);
          if (coach != null) {
            coaches.add(coach);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error parsing coach ${doc.id}: $e');
          }
          continue;
        }
      }

      // Sort by name
      coaches.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

      if (kDebugMode) {
        debugPrint('🎯 Returning ${coaches.length} coaches');
        if (coaches.isNotEmpty) {
          debugPrint('   Found coaches: ${coaches.map((c) => c.fullName).join(", ")}');
        }
      }

      return coaches;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching coaches: $e');
        debugPrint('   Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  /// Match coach search - checks multiple fields
  bool _matchesCoachSearch(Map<String, dynamic> data, String lowerTerm) {
    if (lowerTerm.isEmpty) return true;
    
    final candidates = <String?>[
      data['fullName'] as String?,
      data['nickname'] as String?,
      data['name'] as String?,
      data['location'] as String?,
      data['bio'] as String?,
    ];

    // Also check specializationSports array
    final sports = data['specializationSports'] as List<dynamic>?;
    if (sports != null) {
      for (final sport in sports) {
        if (sport.toString().toLowerCase().contains(lowerTerm)) {
          return true;
        }
      }
    }

    return candidates.any((candidate) {
      if (candidate == null) return false;
      return candidate.toLowerCase().contains(lowerTerm);
    });
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
      await _userRepository.updateUserProfile(
          updatedProfile.uid, updatedProfile.toFirestore());
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
          .get();

      final Set<String> sports = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final specializationSports =
            data['specializationSports'] as List<dynamic>?;
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

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['title'] ?? 'Unknown Venue',
                'location': doc.data()['location'] ?? 'Unknown Location',
                'sportType': doc.data()['sportType'] ?? 'Unknown Sport',
              })
          .toList();
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
        const allowedRoles = {
          'coach',
          'head_coach',
          'headcoach',
          'captain',
          'owner',
        };

        final isCoach = members.any((member) {
          final memberId = member['userId'] ?? member['id'];
          final role =
              (member['role'] ?? member['memberRole'] ?? '').toString().toLowerCase();
          return memberId == coachId && allowedRoles.contains(role);
        });

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

  /// Get unique players coached by the specified coach across all linked teams.
  Future<List<Map<String, dynamic>>> getCoachPlayers(String coachId) async {
    try {
      final query = await _firestore
          .collection('teams')
          .where('isActive', isEqualTo: true)
          .where('memberIds', arrayContains: coachId)
          .limit(25)
          .get();

      final players = <Map<String, dynamic>>[];
      final seenPlayerIds = <String>{};

      for (final doc in query.docs) {
        final data = doc.data();
        final members = (data['members'] as List<dynamic>? ?? [])
            .map<Map<String, dynamic>>((member) {
          if (member is Map<String, dynamic>) return Map<String, dynamic>.from(member);
          if (member is Map) {
            return member.map((key, value) => MapEntry(key.toString(), value));
          }
          return <String, dynamic>{};
        }).toList();

        final isCoachLinked = data['ownerId'] == coachId ||
            members.any((member) {
              final memberId = member['userId'] ?? member['id'];
              if (memberId != coachId) return false;
              final role = (member['role'] ?? member['memberRole'] ?? '')
                  .toString()
                  .toLowerCase();
              return role.contains('coach') ||
                  role.contains('owner') ||
                  role.contains('captain');
            });

        if (!isCoachLinked) continue;

        final teamName = (data['name'] ?? 'Team ${doc.id}').toString();
        final sportType =
            (data['sportType'] ?? data['sport'])?.toString() ?? 'Sport';

        for (final member in members) {
          final playerId = (member['userId'] ?? member['id'])?.toString();
          if (playerId == null ||
              playerId.isEmpty ||
              playerId == coachId ||
              seenPlayerIds.contains(playerId)) {
            continue;
          }

          final role =
              (member['role'] ?? member['memberRole'] ?? 'player').toString();
          if (role.toLowerCase().contains('coach')) continue;

          seenPlayerIds.add(playerId);

          final sessionsCompletedValue =
              member['sessionsCompleted'] ?? member['matchesPlayed'] ?? 0;
          final sessionsCompleted = sessionsCompletedValue is int
              ? sessionsCompletedValue
              : int.tryParse(sessionsCompletedValue.toString()) ?? 0;

          players.add({
            'uid': playerId,
            'name': (member['userName'] ?? member['name'] ?? 'Athlete')
                .toString(),
            'avatar': member['profileImageUrl'] ??
                member['avatarUrl'] ??
                member['imageUrl'],
            'teamId': doc.id,
            'teamName': teamName,
            'sport': sportType,
            'position': member['position']?.toString(),
            'sessionsCompleted': sessionsCompleted,
            'achievement': member['highlight']?.toString() ??
                'Key contributor for $teamName',
            'progress': member['progress']?.toString() ??
                'Training with $teamName',
            'role': role.isNotEmpty ? role : 'Player',
          });
        }
      }

      return players;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting coach players: $e');
      }
      return [];
    }
  }
}
