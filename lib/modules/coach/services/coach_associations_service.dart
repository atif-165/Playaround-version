import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/coach_associations.dart';
import '../../../models/venue_model.dart';
import '../../../models/player_profile.dart';
import '../../../modules/team/models/team_model.dart';
import '../../../services/notification_service.dart';
import '../../../models/notification_model.dart';

/// Service for managing coach associations with venues, teams, and players
class CoachAssociationsService {
  static final CoachAssociationsService _instance =
      CoachAssociationsService._internal();
  factory CoachAssociationsService() => _instance;
  CoachAssociationsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection references
  CollectionReference get _associationsCollection =>
      _firestore.collection('coach_associations');
  CollectionReference get _venuesCollection => _firestore.collection('venues');
  CollectionReference get _teamsCollection => _firestore.collection('teams');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get coach associations
  Future<CoachAssociations?> getCoachAssociations(String coachId) async {
    try {
      final doc = await _associationsCollection.doc(coachId).get();
      if (doc.exists) {
        return CoachAssociations.fromFirestore(doc);
      }

      // Create empty associations if none exist
      final newAssociations = CoachAssociations(
        coachId: coachId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(newAssociations.toFirestore());
      return newAssociations;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting coach associations: $e');
      }
      return null;
    }
  }

  /// Search venues for adding to coach profile
  Future<List<VenueModel>> searchVenues(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _venuesCollection
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      final venues =
          snapshot.docs.map((doc) => VenueModel.fromFirestore(doc)).toList();

      // Filter by name (client-side filtering for better search)
      final filteredVenues = venues.where((venue) {
        return venue.title.toLowerCase().contains(query.toLowerCase()) ||
            venue.location.toLowerCase().contains(query.toLowerCase());
      }).toList();

      return filteredVenues;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching venues: $e');
      }
      return [];
    }
  }

  /// Search teams for adding to coach profile
  /// Uses the same search logic as TeamService for consistency
  Future<List<TeamModel>> searchTeams(String query, {int limit = 50}) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return [];

      if (kDebugMode) {
        debugPrint('🔍 Searching teams with query: "$trimmed"');
      }

      final searchTerm = trimmed.toLowerCase();

      // Use the same query structure as TeamService.searchTeams
      Query baseQuery = _teamsCollection.where('isPublic', isEqualTo: true);

      List<QueryDocumentSnapshot> docs;
      try {
        // Try to order by nameLowercase for better search results
        docs = (await baseQuery.orderBy('nameLowercase').limit(limit * 5).get()).docs;
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
        debugPrint('📊 Found ${docs.length} teams from database');
      }

      // Decode and filter teams
      final filtered = docs
          .map((doc) {
            final raw = doc.data();
            final data = raw is Map<String, dynamic>
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{};
            data['id'] = doc.id;
            return data;
          })
          .where((data) => _matchesTeamSearch(data, searchTerm))
          .take(limit)
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Filtered to ${filtered.length} teams matching "$trimmed"');
      }

      // Convert to TeamModel
      final teams = <TeamModel>[];
      for (var data in filtered) {
        try {
          final team = TeamModel.fromJson(data);
          if (team.isActive) {
            teams.add(team);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error parsing team ${data['id']}: $e');
          }
          continue;
        }
      }

      // Sort by name
      teams.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      if (kDebugMode) {
        debugPrint('🎯 Returning ${teams.length} active teams');
        if (teams.isNotEmpty) {
          debugPrint('   Found teams: ${teams.map((t) => t.name).join(", ")}');
        }
      }

      return teams;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching teams: $e');
        debugPrint('   Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  /// Match team search - same logic as TeamService._matchesTeamSearch
  bool _matchesTeamSearch(Map<String, dynamic> data, String lowerTerm) {
    if (lowerTerm.isEmpty) return true;
    
    final candidates = <String?>[
      data['name'] as String?,
      data['nameLowercase'] as String?,
      data['location'] as String?,
      data['city'] as String?,
      data['searchLocation'] as String?,
      data['description'] as String?,
      data['bio'] as String?,
    ];

    return candidates.any((candidate) {
      if (candidate == null) return false;
      return candidate.toLowerCase().contains(lowerTerm);
    });
  }

  /// Search players for adding to coach profile
  /// Uses similar approach to teams search for consistency
  Future<List<PlayerProfile>> searchPlayers(String query,
      {int limit = 50}) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return [];

      if (kDebugMode) {
        debugPrint('🔍 Searching players with query: "$trimmed"');
      }

      final searchTerm = trimmed.toLowerCase();

      // Fetch more players to have better search results (similar to teams)
      // Don't filter by isProfileComplete - coaches should be able to find all players
      Query baseQuery = _usersCollection.where('role', isEqualTo: 'player');
      
      final queryToUse = baseQuery;

      List<QueryDocumentSnapshot> docs;
      try {
        // Try to order by fullName for better results
        docs = (await queryToUse.orderBy('fullName').limit(limit * 5).get()).docs;
      } on FirebaseException catch (error) {
        if (error.code == 'failed-precondition') {
          // Fallback if index doesn't exist - try without orderBy
          if (kDebugMode) {
            debugPrint('⚠️ Index not found, using fallback query without orderBy');
          }
          try {
            docs = (await queryToUse.limit(limit * 5).get()).docs;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Fallback query also failed, trying with just role filter');
            }
            // Last resort: just get players by role
            docs = (await _usersCollection
                .where('role', isEqualTo: 'player')
                .limit(limit * 5)
                .get()).docs;
          }
        } else {
          rethrow;
        }
      }

      if (kDebugMode) {
        debugPrint('📊 Found ${docs.length} player profiles from database');
      }

      // Decode and filter players
      final filtered = docs
          .map((doc) {
            final raw = doc.data();
            final data = raw is Map<String, dynamic>
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{};
            data['uid'] = doc.id;
            return data;
          })
          .where((data) {
            // Don't filter by isProfileComplete - allow coaches to find all players
            return _matchesPlayerSearch(data, searchTerm);
          })
          .take(limit)
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Filtered to ${filtered.length} players matching "$trimmed"');
        if (filtered.isNotEmpty) {
          debugPrint('   Sample players: ${filtered.take(3).map((d) => d['fullName'] ?? d['name'] ?? 'Unknown').join(", ")}');
        }
      }

      // Convert to PlayerProfile
      final players = <PlayerProfile>[];
      for (var data in filtered) {
        try {
          final player = PlayerProfile.fromMap(data);
          if (player != null) {
            players.add(player);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error parsing player ${data['uid']}: $e');
            debugPrint('   Data keys: ${data.keys.join(", ")}');
          }
          continue;
        }
      }

      // Sort by name
      players.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

      if (kDebugMode) {
        debugPrint('🎯 Returning ${players.length} players');
        if (players.isNotEmpty) {
          debugPrint('   Found players: ${players.map((p) => p.fullName).join(", ")}');
        } else {
          debugPrint('   ⚠️ No players returned after filtering');
        }
      }

      return players;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error searching players: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
      return [];
    }
  }

  /// Match player search - checks multiple fields
  bool _matchesPlayerSearch(Map<String, dynamic> data, String lowerTerm) {
    if (lowerTerm.isEmpty) return true;
    
    final candidates = <String?>[
      data['fullName'] as String?,
      data['nickname'] as String?,
      data['name'] as String?,
      data['location'] as String?,
      data['bio'] as String?,
    ];

    return candidates.any((candidate) {
      if (candidate == null) return false;
      return candidate.toLowerCase().contains(lowerTerm);
    });
  }

  /// Request to add venue to coach profile
  Future<bool> requestVenueAssociation(
      String coachId, String coachName, VenueModel venue) async {
    try {
      final associations = await getCoachAssociations(coachId);
      if (associations == null) return false;

      // Check if already associated
      final existingAssociation = associations.venues.firstWhere(
        (v) => v.venueId == venue.id,
        orElse: () => CoachVenueAssociation(
          venueId: '',
          venueName: '',
          venueOwnerId: '',
          status: AssociationStatus.pending,
          requestedAt: DateTime.now(),
        ),
      );

      if (existingAssociation.venueId.isNotEmpty) {
        // Already associated
        return false;
      }

      // Create new association
      final newAssociation = CoachVenueAssociation(
        venueId: venue.id,
        venueName: venue.title,
        venueOwnerId: venue.ownerId,
        status: AssociationStatus.pending,
        requestedAt: DateTime.now(),
      );

      final updatedAssociations = associations.copyWith(
        venues: [...associations.venues, newAssociation],
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(updatedAssociations.toFirestore());

      // Send notification to venue owner
      try {
        await _notificationService.createNotification(
          userId: venue.ownerId,
          type: NotificationType.coachVenueRequest,
          title: 'Coach Venue Request',
          message:
              '$coachName wants to add your venue "${venue.title}" to their profile',
          data: {
            'coachId': coachId,
            'coachName': coachName,
            'venueId': venue.id,
            'venueName': venue.title,
          },
        );
      } catch (notificationError) {
        if (kDebugMode) {
          debugPrint('Error sending venue association notification: $notificationError');
        }
        // Don't fail the request if notification fails
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting venue association: $e');
      }
      return false;
    }
  }

  /// Request to add team to coach profile
  Future<bool> requestTeamAssociation(
      String coachId, String coachName, TeamModel team) async {
    try {
      final associations = await getCoachAssociations(coachId);
      if (associations == null) return false;

      // Check if already associated
      final existingAssociation = associations.teams.firstWhere(
        (t) => t.teamId == team.id,
        orElse: () => CoachTeamAssociation(
          teamId: '',
          teamName: '',
          teamCaptainId: '',
          status: AssociationStatus.pending,
          requestedAt: DateTime.now(),
        ),
      );

      if (existingAssociation.teamId.isNotEmpty) {
        // Already associated
        return false;
      }

      // Create new association
      final newAssociation = CoachTeamAssociation(
        teamId: team.id,
        teamName: team.name,
        teamCaptainId: team.createdBy, // Team creator is the captain
        status: AssociationStatus.pending,
        requestedAt: DateTime.now(),
      );

      final updatedAssociations = associations.copyWith(
        teams: [...associations.teams, newAssociation],
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(updatedAssociations.toFirestore());

      // Send notification to team captain
      try {
        await _notificationService.createNotification(
          userId: team.createdBy,
          type: NotificationType.coachTeamRequest,
          title: 'Coach Team Request',
          message:
              '$coachName wants to add your team "${team.name}" to their profile',
          data: {
            'coachId': coachId,
            'coachName': coachName,
            'teamId': team.id,
            'teamName': team.name,
          },
        );
      } catch (notificationError) {
        if (kDebugMode) {
          debugPrint('Error sending team association notification: $notificationError');
        }
        // Don't fail the request if notification fails
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting team association: $e');
      }
      return false;
    }
  }

  /// Request to add player to coach profile
  Future<bool> requestPlayerAssociation(
      String coachId, String coachName, PlayerProfile player) async {
    try {
      final associations = await getCoachAssociations(coachId);
      if (associations == null) return false;

      // Check if already associated
      final existingAssociation = associations.players.firstWhere(
        (p) => p.playerId == player.uid,
        orElse: () => CoachPlayerAssociation(
          playerId: '',
          playerName: '',
          status: AssociationStatus.pending,
          requestedAt: DateTime.now(),
        ),
      );

      if (existingAssociation.playerId.isNotEmpty) {
        // Already associated
        return false;
      }

      // Create new association
      final newAssociation = CoachPlayerAssociation(
        playerId: player.uid,
        playerName: player.fullName,
        status: AssociationStatus.pending,
        requestedAt: DateTime.now(),
      );

      final updatedAssociations = associations.copyWith(
        players: [...associations.players, newAssociation],
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(updatedAssociations.toFirestore());

      // Send notification to player
      try {
        await _notificationService.createNotification(
          userId: player.uid,
          type: NotificationType.coachPlayerRequest,
          title: 'Coach Request',
          message: '$coachName wants to add you to their coaching profile',
          data: {
            'coachId': coachId,
            'coachName': coachName,
            'playerId': player.uid,
            'playerName': player.fullName,
          },
        );
      } catch (notificationError) {
        if (kDebugMode) {
          debugPrint('Error sending player association notification: $notificationError');
        }
        // Don't fail the request if notification fails
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting player association: $e');
      }
      return false;
    }
  }

  /// Remove venue association
  Future<bool> removeVenueAssociation(String coachId, String venueId) async {
    try {
      final associations = await getCoachAssociations(coachId);
      if (associations == null) return false;

      final updatedVenues =
          associations.venues.where((v) => v.venueId != venueId).toList();

      final updatedAssociations = associations.copyWith(
        venues: updatedVenues,
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(updatedAssociations.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing venue association: $e');
      }
      return false;
    }
  }

  /// Remove team association
  Future<bool> removeTeamAssociation(String coachId, String teamId) async {
    try {
      final associations = await getCoachAssociations(coachId);
      if (associations == null) return false;

      final updatedTeams =
          associations.teams.where((t) => t.teamId != teamId).toList();

      final updatedAssociations = associations.copyWith(
        teams: updatedTeams,
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(updatedAssociations.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing team association: $e');
      }
      return false;
    }
  }

  /// Remove player association
  Future<bool> removePlayerAssociation(String coachId, String playerId) async {
    try {
      final associations = await getCoachAssociations(coachId);
      if (associations == null) return false;

      final updatedPlayers =
          associations.players.where((p) => p.playerId != playerId).toList();

      final updatedAssociations = associations.copyWith(
        players: updatedPlayers,
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(updatedAssociations.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing player association: $e');
      }
      return false;
    }
  }

  /// Approve player association request (called by player)
  Future<bool> approvePlayerAssociation(
    String coachId,
    String playerId,
    String playerName,
  ) async {
    try {
      final associations = await getCoachAssociations(coachId);
      if (associations == null) {
        if (kDebugMode) {
          debugPrint('Coach associations not found for coachId: $coachId');
        }
        return false;
      }

      // Find the player association
      final playerIndex = associations.players.indexWhere(
        (p) => p.playerId == playerId,
      );

      if (playerIndex == -1) {
        if (kDebugMode) {
          debugPrint('Player association not found for playerId: $playerId');
        }
        return false;
      }

      final existingAssociation = associations.players[playerIndex];

      // Check if already processed
      if (existingAssociation.status != AssociationStatus.pending) {
        if (kDebugMode) {
          debugPrint('Player association already processed: ${existingAssociation.status}');
        }
        return false;
      }

      // Update the association status
      final updatedAssociation = CoachPlayerAssociation(
        playerId: existingAssociation.playerId,
        playerName: existingAssociation.playerName,
        status: AssociationStatus.approved,
        requestedAt: existingAssociation.requestedAt,
        approvedAt: DateTime.now(),
        rejectedAt: null,
        rejectionReason: null,
      );

      final updatedPlayers = List<CoachPlayerAssociation>.from(associations.players);
      updatedPlayers[playerIndex] = updatedAssociation;

      final updatedAssociations = associations.copyWith(
        players: updatedPlayers,
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(updatedAssociations.toFirestore());

      // Send notification to coach
      try {
        final coachDoc = await _usersCollection.doc(coachId).get();
        final coachData = coachDoc.data() as Map<String, dynamic>?;
        final coachName = coachData?['fullName'] ?? coachData?['name'] ?? 'Coach';

        await _notificationService.createNotification(
          userId: coachId,
          type: NotificationType.general,
          title: 'Request Approved',
          message: '$playerName has approved your request to add them to your coaching profile',
          data: {
            'coachId': coachId,
            'playerId': playerId,
            'playerName': playerName,
            'status': 'approved',
          },
        );
      } catch (notificationError) {
        if (kDebugMode) {
          debugPrint('Error sending approval notification: $notificationError');
        }
        // Don't fail the approval if notification fails
      }

      if (kDebugMode) {
        debugPrint('✅ Player association approved: $playerId -> $coachId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error approving player association: $e');
      }
      return false;
    }
  }

  /// Reject player association request (called by player)
  Future<bool> rejectPlayerAssociation(
    String coachId,
    String playerId,
    String playerName, {
    String? rejectionReason,
  }) async {
    try {
      final associations = await getCoachAssociations(coachId);
      if (associations == null) {
        if (kDebugMode) {
          debugPrint('Coach associations not found for coachId: $coachId');
        }
        return false;
      }

      // Find the player association
      final playerIndex = associations.players.indexWhere(
        (p) => p.playerId == playerId,
      );

      if (playerIndex == -1) {
        if (kDebugMode) {
          debugPrint('Player association not found for playerId: $playerId');
        }
        return false;
      }

      final existingAssociation = associations.players[playerIndex];

      // Check if already processed
      if (existingAssociation.status != AssociationStatus.pending) {
        if (kDebugMode) {
          debugPrint('Player association already processed: ${existingAssociation.status}');
        }
        return false;
      }

      // Update the association status
      final updatedAssociation = CoachPlayerAssociation(
        playerId: existingAssociation.playerId,
        playerName: existingAssociation.playerName,
        status: AssociationStatus.rejected,
        requestedAt: existingAssociation.requestedAt,
        approvedAt: null,
        rejectedAt: DateTime.now(),
        rejectionReason: rejectionReason,
      );

      final updatedPlayers = List<CoachPlayerAssociation>.from(associations.players);
      updatedPlayers[playerIndex] = updatedAssociation;

      final updatedAssociations = associations.copyWith(
        players: updatedPlayers,
        updatedAt: DateTime.now(),
      );

      await _associationsCollection
          .doc(coachId)
          .set(updatedAssociations.toFirestore());

      // Send notification to coach
      try {
        final coachDoc = await _usersCollection.doc(coachId).get();
        final coachData = coachDoc.data() as Map<String, dynamic>?;
        final coachName = coachData?['fullName'] ?? coachData?['name'] ?? 'Coach';

        await _notificationService.createNotification(
          userId: coachId,
          type: NotificationType.general,
          title: 'Request Rejected',
          message: '$playerName has rejected your request to add them to your coaching profile',
          data: {
            'coachId': coachId,
            'playerId': playerId,
            'playerName': playerName,
            'status': 'rejected',
            'rejectionReason': rejectionReason,
          },
        );
      } catch (notificationError) {
        if (kDebugMode) {
          debugPrint('Error sending rejection notification: $notificationError');
        }
        // Don't fail the rejection if notification fails
      }

      if (kDebugMode) {
        debugPrint('❌ Player association rejected: $playerId -> $coachId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error rejecting player association: $e');
      }
      return false;
    }
  }
}
