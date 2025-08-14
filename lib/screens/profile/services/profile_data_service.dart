import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/models.dart';
import '../../../modules/chat/models/connection.dart';

/// Service to fetch comprehensive profile data including connections, teams, and tournaments
class ProfileDataService {
  static final ProfileDataService _instance = ProfileDataService._internal();
  factory ProfileDataService() => _instance;
  ProfileDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user connections (coaches and other players)
  Future<List<Connection>> getUserConnections() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final connectionsQuery = await _firestore
          .collection('connections')
          .where('status', isEqualTo: 'accepted')
          .where('fromUserId', isEqualTo: user.uid)
          .get();

      final connectionsQuery2 = await _firestore
          .collection('connections')
          .where('status', isEqualTo: 'accepted')
          .where('toUserId', isEqualTo: user.uid)
          .get();

      final connections = <Connection>[];
      
      // Add connections where user is the sender
      for (final doc in connectionsQuery.docs) {
        try {
          final connection = Connection.fromFirestore(doc);
          if (connection != null) {
            connections.add(connection);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing connection: $e');
          }
        }
      }

      // Add connections where user is the receiver
      for (final doc in connectionsQuery2.docs) {
        try {
          final connection = Connection.fromFirestore(doc);
          if (connection != null) {
            connections.add(connection);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing connection: $e');
          }
        }
      }

      return connections;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user connections: $e');
      }
      return [];
    }
  }

  /// Get teams where user is a member
  Future<List<Team>> getUserTeams() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Use array-contains-any query to find teams where user is a member
      // This query respects the security rules
      final teamsQuery = await _firestore
          .collection('teams')
          .where('members', arrayContainsAny: [
            {'userId': user.uid}
          ])
          .where('isActive', isEqualTo: true)
          .get();

      final teams = <Team>[];

      for (final doc in teamsQuery.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Add document ID to data
          final team = Team.fromMap(data);

          // Double-check if user is an active member
          final isMember = team.members.any((member) =>
            member.userId == user.uid && member.isActive);

          if (isMember) {
            teams.add(team);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing team: $e');
          }
        }
      }

      return teams;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user teams: $e');
      }
      return [];
    }
  }

  /// Get tournaments user has participated in (past tournaments)
  Future<List<Tournament>> getUserPastTournaments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();

      // Get tournament registrations for the current user only
      final registrationsQuery = await _firestore
          .collection('tournament_registrations')
          .where('registeredBy', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .get();

      final tournamentIds = <String>[];

      // Extract tournament IDs from user's registrations
      for (final doc in registrationsQuery.docs) {
        try {
          final data = doc.data();
          tournamentIds.add(data['tournamentId'] as String);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing registration: $e');
          }
        }
      }

      if (tournamentIds.isEmpty) return [];

      final tournaments = <Tournament>[];

      // Fetch tournaments in batches (Firestore 'in' query limit is 10)
      for (int i = 0; i < tournamentIds.length; i += 10) {
        final batch = tournamentIds.skip(i).take(10).toList();

        final tournamentsQuery = await _firestore
            .collection('tournaments')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in tournamentsQuery.docs) {
          try {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID to data
            final tournament = Tournament.fromMap(data);

            // Check if tournament has ended
            final endDate = tournament.endDate ?? tournament.startDate;
            if (endDate.isBefore(now)) {
              tournaments.add(tournament);
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error parsing past tournament: $e');
            }
          }
        }
      }

      // Sort by end date (most recent first)
      tournaments.sort((a, b) => (b.endDate ?? b.startDate).compareTo(a.endDate ?? a.startDate));

      return tournaments;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user past tournaments: $e');
      }
      return [];
    }
  }

  /// Get upcoming tournaments user is registered for
  Future<List<Tournament>> getUserUpcomingTournaments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();

      // Get tournament registrations for the current user only
      final registrationsQuery = await _firestore
          .collection('tournament_registrations')
          .where('registeredBy', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .get();

      final tournamentIds = <String>[];

      // Extract tournament IDs from user's registrations
      for (final doc in registrationsQuery.docs) {
        try {
          final data = doc.data();
          tournamentIds.add(data['tournamentId'] as String);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing registration: $e');
          }
        }
      }

      if (tournamentIds.isEmpty) return [];

      final tournaments = <Tournament>[];

      // Fetch tournaments in batches (Firestore 'in' query limit is 10)
      for (int i = 0; i < tournamentIds.length; i += 10) {
        final batch = tournamentIds.skip(i).take(10).toList();

        final tournamentsQuery = await _firestore
            .collection('tournaments')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in tournamentsQuery.docs) {
          try {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID to data
            final tournament = Tournament.fromMap(data);

            // Check if tournament is upcoming (starts in the future)
            if (tournament.startDate.isAfter(now)) {
              tournaments.add(tournament);
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error parsing upcoming tournament: $e');
            }
          }
        }
      }

      // Sort by start date (earliest first)
      tournaments.sort((a, b) => a.startDate.compareTo(b.startDate));

      return tournaments;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user upcoming tournaments: $e');
      }
      return [];
    }
  }

  /// Get coaches connected to the user
  Future<List<UserProfile>> getConnectedCoaches() async {
    try {
      final connections = await getUserConnections();
      final user = _auth.currentUser;
      if (user == null) return [];

      final coachIds = <String>[];
      
      for (final connection in connections) {
        // Get the other user's ID (not the current user)
        final otherUserId = connection.fromUserId == user.uid 
            ? connection.toUserId 
            : connection.fromUserId;
        coachIds.add(otherUserId);
      }

      if (coachIds.isEmpty) return [];

      final coaches = <UserProfile>[];
      
      // Fetch user profiles in batches
      for (int i = 0; i < coachIds.length; i += 10) {
        final batch = coachIds.skip(i).take(10).toList();
        
        final coachesQuery = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .where('role', isEqualTo: 'coach')
            .get();

        for (final doc in coachesQuery.docs) {
          try {
            final data = doc.data();
            if (data['role'] == 'coach') {
              final coach = CoachProfile.fromFirestore(doc);
              if (coach != null) {
                coaches.add(coach);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error parsing coach profile: $e');
            }
          }
        }
      }

      return coaches;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching connected coaches: $e');
      }
      return [];
    }
  }

  /// Get all connected users (players and coaches)
  Future<List<UserProfile>> getAllConnectedUsers() async {
    try {
      final connections = await getUserConnections();
      final user = _auth.currentUser;
      if (user == null) return [];

      final userIds = <String>[];
      
      for (final connection in connections) {
        // Get the other user's ID (not the current user)
        final otherUserId = connection.fromUserId == user.uid 
            ? connection.toUserId 
            : connection.fromUserId;
        userIds.add(otherUserId);
      }

      if (userIds.isEmpty) return [];

      final users = <UserProfile>[];
      
      // Fetch user profiles in batches
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        
        final usersQuery = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in usersQuery.docs) {
          try {
            final data = doc.data();
            if (data['role'] == 'coach') {
              final coach = CoachProfile.fromFirestore(doc);
              if (coach != null) {
                users.add(coach);
              }
            } else if (data['role'] == 'player') {
              final player = PlayerProfile.fromFirestore(doc);
              if (player != null) {
                users.add(player);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error parsing user profile: $e');
            }
          }
        }
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching connected users: $e');
      }
      return [];
    }
  }
}
