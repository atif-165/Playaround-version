import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tournament_notification_service.dart';
import 'package:flutter/foundation.dart';
import '../../../services/notification_service.dart';
import '../../../models/listing_model.dart' as listing_models;
import '../models/models.dart';
import '../../team/models/models.dart';
import '../../team/services/team_service.dart';
import '../../skill_tracking/services/automated_skill_service.dart';
import '../../chat/services/chat_service.dart';

/// Service class for tournament management operations
class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  factory TournamentService() => _instance;
  TournamentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TeamService _teamService = TeamService();
  final NotificationService _notificationService = NotificationService();
  final TournamentNotificationService _tournamentNotificationService = TournamentNotificationService();
  final AutomatedSkillService _automatedSkillService = AutomatedSkillService();

  // Collection references
  CollectionReference get _tournamentsCollection => _firestore.collection('tournaments');
  CollectionReference get _registrationsCollection => _firestore.collection('tournament_registrations');

  /// Convert team SportType to listing SportType for skill tracking
  listing_models.SportType _convertSportType(SportType teamSportType) {
    switch (teamSportType) {
      case SportType.football:
        return listing_models.SportType.football;
      case SportType.basketball:
        return listing_models.SportType.basketball;
      case SportType.tennis:
        return listing_models.SportType.tennis;
      case SportType.badminton:
        return listing_models.SportType.badminton;
      case SportType.cricket:
        return listing_models.SportType.cricket;
      // Note: swimming, running, cycling are not in team SportType enum
      // case SportType.swimming:
      //   return listing_models.SportType.swimming;
      // case SportType.running:
      //   return listing_models.SportType.running;
      // case SportType.cycling:
      //   return listing_models.SportType.cycling;
      default:
        return listing_models.SportType.football; // Default fallback
    }
  }

  /// Create a new tournament
  Future<String> createTournament({
    required String name,
    required String description,
    required SportType sportType,
    required TournamentFormat format,
    required DateTime registrationStartDate,
    required DateTime registrationEndDate,
    required DateTime startDate,
    DateTime? endDate,
    required int maxTeams,
    int minTeams = 2,
    String? location,
    String? venueId,
    String? venueName,
    String? imageUrl,
    List<String> rules = const [],
    Map<String, dynamic>? prizes,
    bool isPublic = true,
    Map<String, dynamic>? metadata,
    // New parameters
    double? entryFee,
    double? winningPrize,
    List<String> qualifyingQuestions = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check for tournament name uniqueness per sport type
      await _checkTournamentNameUniqueness(name, sportType);

      final now = DateTime.now();
      final tournamentId = _tournamentsCollection.doc().id;

      final tournament = Tournament(
        id: tournamentId,
        name: name,
        description: description,
        sportType: sportType,
        format: format,
        status: TournamentStatus.upcoming,
        organizerId: user.uid,
        organizerName: user.displayName ?? 'Unknown Organizer',
        registrationStartDate: registrationStartDate,
        registrationEndDate: registrationEndDate,
        startDate: startDate,
        endDate: endDate,
        maxTeams: maxTeams,
        minTeams: minTeams,
        location: location,
        venueId: venueId,
        venueName: venueName,
        imageUrl: imageUrl,
        rules: rules,
        prizes: prizes,
        isPublic: isPublic,
        createdAt: now,
        updatedAt: now,
        metadata: metadata,
        // New fields
        entryFee: entryFee,
        winningPrize: winningPrize,
        qualifyingQuestions: qualifyingQuestions,
        allowTeamEditing: true,
        teamPoints: {},
        matches: [],
      );

      await _tournamentsCollection.doc(tournamentId).set(tournament.toMap());
      return tournamentId;
    } catch (e) {
      throw Exception('Failed to create tournament: $e');
    }
  }

  /// Check tournament name uniqueness per sport type
  Future<void> _checkTournamentNameUniqueness(String name, SportType sportType) async {
    final query = await _tournamentsCollection
        .where('name', isEqualTo: name)
        .where('sportType', isEqualTo: sportType.name)
        .where('status', whereIn: [
          TournamentStatus.upcoming.name,
          TournamentStatus.registrationOpen.name,
          TournamentStatus.registrationClosed.name,
          TournamentStatus.ongoing.name,
          TournamentStatus.inProgress.name,
        ])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      throw Exception('A tournament with this name already exists for ${sportType.displayName}. Please choose a different name.');
    }
  }

  /// Get tournament by ID
  Future<Tournament?> getTournament(String tournamentId) async {
    try {
      final doc = await _tournamentsCollection.doc(tournamentId).get();
      if (doc.exists) {
        return Tournament.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get tournament: $e');
    }
  }

  /// Get public tournaments for browsing
  Stream<List<Tournament>> getPublicTournaments({
    SportType? sportType,
    TournamentStatus? status,
    int limit = 20,
  }) {
    Query query = _tournamentsCollection
        .where('isPublic', isEqualTo: true)
        .orderBy('startDate', descending: false)
        .limit(limit);

    if (sportType != null) {
      query = query.where('sportType', isEqualTo: sportType.name);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Tournament.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Get tournaments where user's teams are registered
  Stream<List<Tournament>> getUserTournaments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _registrationsCollection
        .where('registeredBy', isEqualTo: user.uid)
        .where('status', isEqualTo: RegistrationStatus.approved.name)
        .snapshots()
        .asyncMap((snapshot) async {
          final tournamentIds = snapshot.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['tournamentId'] as String)
              .toSet()
              .toList();

          if (tournamentIds.isEmpty) return <Tournament>[];

          final tournaments = <Tournament>[];
          for (final tournamentId in tournamentIds) {
            final tournament = await getTournament(tournamentId);
            if (tournament != null) {
              tournaments.add(tournament);
            }
          }
          return tournaments;
        });
  }

  /// Register team for tournament
  Future<String> registerTeamForTournament({
    required String tournamentId,
    required String teamId,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament details
      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Check if registration is open
      if (!tournament.isRegistrationOpen) {
        throw Exception('Tournament registration is not open');
      }

      // Check if tournament is full
      if (tournament.isFull) {
        throw Exception('Tournament is full');
      }

      // Get team details
      final team = await _teamService.getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission to register team (owner or captain)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      if (userMember.role != TeamRole.owner && userMember.role != TeamRole.captain) {
        throw Exception('Only team owner or captain can register for tournaments');
      }

      // Check if team is already registered
      final existingRegistration = await _registrationsCollection
          .where('tournamentId', isEqualTo: tournamentId)
          .where('teamId', isEqualTo: teamId)
          .where('status', whereIn: [
            RegistrationStatus.pending.name,
            RegistrationStatus.approved.name,
          ])
          .get();

      if (existingRegistration.docs.isNotEmpty) {
        throw Exception('Team is already registered for this tournament');
      }

      final registrationId = _registrationsCollection.doc().id;
      final registration = TournamentRegistration(
        id: registrationId,
        tournamentId: tournamentId,
        tournamentName: tournament.name,
        teamId: teamId,
        teamName: team.name,
        registeredBy: user.uid,
        registeredByName: user.displayName ?? 'Unknown User',
        status: RegistrationStatus.pending,
        registeredAt: DateTime.now(),
        additionalInfo: additionalInfo,
      );

      await _registrationsCollection.doc(registrationId).set(registration.toMap());

      // Send notification to tournament organizer
      try {
        await _notificationService.createTournamentRegistrationNotification(
          organizerId: tournament.organizerId,
          tournamentName: tournament.name,
          teamName: team.name,
          tournamentId: tournamentId,
        );
      } catch (e) {
        // Log notification error but don't fail the registration
        // In production, use proper logging instead of print
        // print('Failed to send tournament registration notification: $e');
      }

      return registrationId;
    } catch (e) {
      throw Exception('Failed to register team for tournament: $e');
    }
  }

  /// Get tournament registrations (for tournament organizers)
  Stream<List<TournamentRegistration>> getTournamentRegistrations(String tournamentId) {
    return _registrationsCollection
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentRegistration.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get team's tournament registrations
  Stream<List<TournamentRegistration>> getTeamRegistrations(String teamId) {
    return _registrationsCollection
        .where('teamId', isEqualTo: teamId)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentRegistration.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get user's tournament registrations
  Stream<List<TournamentRegistration>> getUserRegistrations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _registrationsCollection
        .where('registeredBy', isEqualTo: user.uid)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentRegistration.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Approve tournament registration (for tournament organizers)
  Future<void> approveRegistration(String registrationId, {String? responseMessage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the registration
      final registrationDoc = await _registrationsCollection.doc(registrationId).get();
      if (!registrationDoc.exists) throw Exception('Registration not found');

      final registration = TournamentRegistration.fromMap(registrationDoc.data() as Map<String, dynamic>);

      // Get the tournament
      final tournament = await getTournament(registration.tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Check if user is the tournament organizer
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can approve registrations');
      }

      // Check if tournament is full
      if (tournament.isFull) throw Exception('Tournament is full');

      // Update registration and tournament in a batch
      final batch = _firestore.batch();

      batch.update(_registrationsCollection.doc(registrationId), {
        'status': RegistrationStatus.approved.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
        'respondedBy': user.uid,
        'responseMessage': responseMessage,
      });

      batch.update(_tournamentsCollection.doc(registration.tournamentId), {
        'currentTeamsCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to approve registration: $e');
    }
  }

  /// Reject tournament registration (for tournament organizers)
  Future<void> rejectRegistration(String registrationId, {String? responseMessage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the registration
      final registrationDoc = await _registrationsCollection.doc(registrationId).get();
      if (!registrationDoc.exists) throw Exception('Registration not found');

      final registration = TournamentRegistration.fromMap(registrationDoc.data() as Map<String, dynamic>);

      // Get the tournament
      final tournament = await getTournament(registration.tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Check if user is the tournament organizer
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can reject registrations');
      }

      await _registrationsCollection.doc(registrationId).update({
        'status': RegistrationStatus.rejected.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
        'respondedBy': user.uid,
        'responseMessage': responseMessage,
      });
    } catch (e) {
      throw Exception('Failed to reject registration: $e');
    }
  }

  /// Withdraw tournament registration (by team)
  Future<void> withdrawRegistration(String registrationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the registration
      final registrationDoc = await _registrationsCollection.doc(registrationId).get();
      if (!registrationDoc.exists) throw Exception('Registration not found');

      final registration = TournamentRegistration.fromMap(registrationDoc.data() as Map<String, dynamic>);

      // Check if user registered the team
      if (registration.registeredBy != user.uid) {
        throw Exception('Only the registering user can withdraw the registration');
      }

      // Check if registration can be withdrawn
      if (registration.status == RegistrationStatus.withdrawn) {
        throw Exception('Registration is already withdrawn');
      }

      // Update registration and tournament count if it was approved
      final batch = _firestore.batch();

      batch.update(_registrationsCollection.doc(registrationId), {
        'status': RegistrationStatus.withdrawn.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      // If registration was approved, decrement tournament count
      if (registration.status == RegistrationStatus.approved) {
        batch.update(_tournamentsCollection.doc(registration.tournamentId), {
          'currentTeamsCount': FieldValue.increment(-1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to withdraw registration: $e');
    }
  }

  /// Update tournament details (for tournament organizers)
  Future<void> updateTournament({
    required String tournamentId,
    String? name,
    String? description,
    SportType? sportType,
    TournamentFormat? format,
    TournamentStatus? status,
    DateTime? registrationStartDate,
    DateTime? registrationEndDate,
    DateTime? startDate,
    DateTime? endDate,
    int? maxTeams,
    int? minTeams,
    String? location,
    String? imageUrl,
    List<String>? rules,
    Map<String, dynamic>? prizes,
    bool? isPublic,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Check if user is the tournament organizer
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can update tournament details');
      }

      final updatedTournament = tournament.copyWith(
        name: name,
        description: description,
        sportType: sportType,
        format: format,
        status: status,
        registrationStartDate: registrationStartDate,
        registrationEndDate: registrationEndDate,
        startDate: startDate,
        endDate: endDate,
        maxTeams: maxTeams,
        minTeams: minTeams,
        location: location,
        imageUrl: imageUrl,
        rules: rules,
        prizes: prizes,
        isPublic: isPublic,
        metadata: metadata,
        updatedAt: DateTime.now(),
      );

      await _tournamentsCollection.doc(tournamentId).update(updatedTournament.toMap());
    } catch (e) {
      throw Exception('Failed to update tournament: $e');
    }
  }

  /// Update tournament status
  Future<void> updateTournamentStatus(String tournamentId, TournamentStatus status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Check if user is the tournament organizer
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can update tournament status');
      }

      await _tournamentsCollection.doc(tournamentId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update tournament status: $e');
    }
  }

  /// Cancel tournament (for tournament organizers)
  Future<void> cancelTournament(String tournamentId, {String? reason}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Check if user is the tournament organizer
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can cancel tournament');
      }

      // Update tournament status
      await _tournamentsCollection.doc(tournamentId).update({
        'status': TournamentStatus.cancelled.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          ...?tournament.metadata,
          'cancellationReason': reason,
          'cancelledAt': Timestamp.fromDate(DateTime.now()),
        },
      });

      // Update all pending registrations to rejected
      final pendingRegistrations = await _registrationsCollection
          .where('tournamentId', isEqualTo: tournamentId)
          .where('status', isEqualTo: RegistrationStatus.pending.name)
          .get();

      final batch = _firestore.batch();
      for (final doc in pendingRegistrations.docs) {
        batch.update(doc.reference, {
          'status': RegistrationStatus.rejected.name,
          'respondedAt': Timestamp.fromDate(DateTime.now()),
          'respondedBy': user.uid,
          'responseMessage': 'Tournament was cancelled${reason != null ? ': $reason' : ''}',
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cancel tournament: $e');
    }
  }

  /// Get tournaments organized by user
  Stream<List<Tournament>> getOrganizedTournaments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _tournamentsCollection
        .where('organizerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tournament.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Complete tournament and update skills for all participants
  Future<void> completeTournament({
    required String tournamentId,
    required String winnerTeamId,
    Map<String, dynamic>? results,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament details
      final tournamentDoc = await _tournamentsCollection.doc(tournamentId).get();
      if (!tournamentDoc.exists) throw Exception('Tournament not found');

      final tournamentData = tournamentDoc.data();
      if (tournamentData == null) throw Exception('Tournament data not found');
      final tournament = Tournament.fromMap(tournamentData as Map<String, dynamic>);

      // Only organizer can complete tournament
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can complete tournament');
      }

      // Update tournament status
      await _tournamentsCollection.doc(tournamentId).update({
        'status': TournamentStatus.completed.name,
        'endDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'winnerTeamId': winnerTeamId,
        'results': results,
      });

      // Get all registered teams and their members
      final registrationsQuery = await _registrationsCollection
          .where('tournamentId', isEqualTo: tournamentId)
          .where('status', isEqualTo: RegistrationStatus.approved.name)
          .get();

      // Update skills for all participants
      for (final regDoc in registrationsQuery.docs) {
        final registration = TournamentRegistration.fromMap(regDoc.data() as Map<String, dynamic>);
        final isWinner = registration.teamId == winnerTeamId;

        // Get team members
        final team = await _teamService.getTeam(registration.teamId);
        if (team != null) {
          for (final member in team.members) {
            try {
              await _automatedSkillService.onTournamentCompleted(
                tournamentId: tournamentId,
                userId: member.userId,
                sportType: _convertSportType(tournament.sportType),
                isTeamTournament: true,
                didWin: isWinner,
                tournamentName: tournament.name,
                additionalMetadata: {
                  'teamId': registration.teamId,
                  'teamName': registration.teamName,
                  'tournamentFormat': tournament.format.name,
                  'organizerId': tournament.organizerId,
                  'organizerName': tournament.organizerName,
                },
              );
            } catch (skillUpdateError) {
              // Log skill update error but continue with other participants
              if (kDebugMode) {
                debugPrint('⚠️ TournamentService: Skill update failed for user ${member.userId}: $skillUpdateError');
              }
            }
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ TournamentService: Tournament completed and skills updated for all participants');
      }
    } catch (e) {
      throw Exception('Failed to complete tournament: $e');
    }
  }

  /// Mark tournament match as completed (for individual matches within tournament)
  Future<void> completeMatch({
    required String tournamentId,
    required String matchId,
    required String winnerTeamId,
    required String loserTeamId,
    Map<String, dynamic>? matchResults,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament details
      final tournamentDoc = await _tournamentsCollection.doc(tournamentId).get();
      if (!tournamentDoc.exists) throw Exception('Tournament not found');

      final tournamentData = tournamentDoc.data();
      if (tournamentData == null) throw Exception('Tournament data not found');
      final tournament = Tournament.fromMap(tournamentData as Map<String, dynamic>);

      // Get teams involved in the match
      final winnerTeam = await _teamService.getTeam(winnerTeamId);
      final loserTeam = await _teamService.getTeam(loserTeamId);

      if (winnerTeam != null) {
        // Update skills for winning team members
        for (final member in winnerTeam.members) {
          try {
            await _automatedSkillService.onTournamentCompleted(
              tournamentId: tournamentId,
              userId: member.userId,
              sportType: _convertSportType(tournament.sportType),
              isTeamTournament: true,
              didWin: true,
              tournamentName: '${tournament.name} - Match Win',
              additionalMetadata: {
                'matchId': matchId,
                'teamId': winnerTeamId,
                'teamName': winnerTeam.name,
                'opponentTeamId': loserTeamId,
                'opponentTeamName': loserTeam?.name ?? 'Unknown',
                'matchResults': matchResults,
              },
            );
          } catch (skillUpdateError) {
            if (kDebugMode) {
              debugPrint('⚠️ TournamentService: Skill update failed for winner ${member.userId}: $skillUpdateError');
            }
          }
        }
      }

      if (loserTeam != null) {
        // Update skills for losing team members (participation bonus)
        for (final member in loserTeam.members) {
          try {
            await _automatedSkillService.onTournamentCompleted(
              tournamentId: tournamentId,
              userId: member.userId,
              sportType: _convertSportType(tournament.sportType),
              isTeamTournament: true,
              didWin: false,
              tournamentName: '${tournament.name} - Match Participation',
              additionalMetadata: {
                'matchId': matchId,
                'teamId': loserTeamId,
                'teamName': loserTeam.name,
                'opponentTeamId': winnerTeamId,
                'opponentTeamName': winnerTeam?.name ?? 'Unknown',
                'matchResults': matchResults,
              },
            );
          } catch (skillUpdateError) {
            if (kDebugMode) {
              debugPrint('⚠️ TournamentService: Skill update failed for participant ${member.userId}: $skillUpdateError');
            }
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ TournamentService: Match completed and skills updated for all participants');
      }
    } catch (e) {
      throw Exception('Failed to complete match: $e');
    }
  }

  // ============ TEAM REGISTRATION METHODS ============

  /// Submit team registration for tournament
  Future<String> submitTeamRegistration({
    required String tournamentId,
    required String teamId,
    required List<Map<String, String>> qualifyingAnswers, // question -> answer
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament details
      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Get team details
      final team = await _teamService.getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user is team captain
      if (team.ownerId != user.uid) {
        throw Exception('Only team captains can register teams for tournaments');
      }

      // Check if registration is open
      if (!tournament.isRegistrationOpen) {
        throw Exception('Tournament registration is not open');
      }

      // Check if tournament is full
      if (tournament.isFull) {
        throw Exception('Tournament is full');
      }

      // Check if team is already registered
      final existingRegistration = await _getTeamRegistration(tournamentId, teamId);
      if (existingRegistration != null) {
        throw Exception('Team is already registered for this tournament');
      }

      final now = DateTime.now();
      final registrationId = _firestore.collection('temp').doc().id;

      // Convert qualifying answers
      final qualifyingAnswersList = qualifyingAnswers.map((qa) =>
        QualifyingAnswer(question: qa['question']!, answer: qa['answer']!)
      ).toList();

      final registration = TournamentTeamRegistration(
        id: registrationId,
        tournamentId: tournamentId,
        tournamentName: tournament.name,
        teamId: teamId,
        teamName: team.name,
        captainId: user.uid,
        captainName: user.displayName ?? 'Unknown Captain',
        captainImageUrl: null, // TODO: Get from user profile
        teamMemberIds: team.members.map((m) => m.userId).toList(),
        teamMemberNames: team.members.map((m) => m.userName).toList(),
        status: TeamRegistrationStatus.pending,
        qualifyingAnswers: qualifyingAnswersList,
        registrationDate: now,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      // Save registration
      await _firestore
          .collection('tournament_registrations')
          .doc(registrationId)
          .set(registration.toMap());

      // Send notification to tournament organizer
      await _sendRegistrationNotification(tournament, team, registration);

      return registrationId;
    } catch (e) {
      throw Exception('Failed to submit team registration: $e');
    }
  }

  /// Get team registration for tournament
  Future<TournamentTeamRegistration?> _getTeamRegistration(String tournamentId, String teamId) async {
    try {
      final query = await _firestore
          .collection('tournament_registrations')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('teamId', isEqualTo: teamId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return TournamentTeamRegistration.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentService: Error getting team registration - $e');
      }
      return null;
    }
  }

  /// Send registration notification to tournament organizer
  Future<void> _sendRegistrationNotification(
    Tournament tournament,
    Team team,
    TournamentTeamRegistration registration,
  ) async {
    try {
      await _tournamentNotificationService.sendTeamRegistrationNotification(
        tournament: tournament,
        registration: registration,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ TournamentService: Failed to send registration notification - $e');
      }
    }
  }

  /// Approve team registration and add to tournament group chat
  Future<void> approveTeamRegistration({
    required String registrationId,
    required String tournamentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get registration details
      final registrationDoc = await _firestore
          .collection('tournament_registrations')
          .doc(registrationId)
          .get();

      if (!registrationDoc.exists) {
        throw Exception('Registration not found');
      }

      final registration = TournamentTeamRegistration.fromMap(
        registrationDoc.data() as Map<String, dynamic>
      );

      // Get tournament details
      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Only tournament organizer can approve
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can approve registrations');
      }

      // Update registration status
      await _firestore
          .collection('tournament_registrations')
          .doc(registrationId)
          .update({
        'status': TeamRegistrationStatus.approved.name,
        'approvalDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update tournament team count
      await _tournamentsCollection.doc(tournamentId).update({
        'currentTeamsCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create or update tournament group chat
      await _createOrUpdateTournamentGroupChat(tournament, registration);

      // Send approval notification to team captain
      await _sendApprovalNotification(tournament, registration);

      if (kDebugMode) {
        debugPrint('✅ TournamentService: Team ${registration.teamName} approved for tournament ${tournament.name}');
      }
    } catch (e) {
      throw Exception('Failed to approve team registration: $e');
    }
  }

  /// Create or update tournament group chat
  Future<void> _createOrUpdateTournamentGroupChat(
    Tournament tournament,
    TournamentTeamRegistration registration,
  ) async {
    try {
      final chatService = ChatService();

      // Check if tournament already has a group chat
      String? groupChatId = tournament.groupChatId;

      if (groupChatId == null) {
        // Create new tournament group chat
        final chatRoom = await chatService.createTournamentGroupChat(
          tournamentId: tournament.id,
          tournamentName: tournament.name,
          participantIds: [tournament.organizerId],
          participantNames: [tournament.organizerName],
        );

        if (chatRoom != null) {
          groupChatId = chatRoom.id;

          // Update tournament with group chat ID
          await _tournamentsCollection.doc(tournament.id).update({
            'groupChatId': groupChatId,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      if (groupChatId != null) {
        // Add team captain to group chat
        await chatService.addParticipantToGroupChat(
          chatId: groupChatId,
          userId: registration.captainId,
          userName: registration.captainName,
          userImageUrl: registration.captainImageUrl,
        );

        // Send welcome message
        await chatService.sendSystemMessage(
          chatId: groupChatId,
          message: '🎉 ${registration.teamName} has joined the tournament!',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ TournamentService: Failed to update group chat - $e');
      }
    }
  }

  /// Send approval notification
  Future<void> _sendApprovalNotification(
    Tournament tournament,
    TournamentTeamRegistration registration,
  ) async {
    try {
      await _tournamentNotificationService.sendTeamApprovalNotification(
        tournament: tournament,
        registration: registration,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ TournamentService: Failed to send approval notification - $e');
      }
    }
  }

  /// Remove team from tournament and group chat
  Future<void> removeTeamFromTournament({
    required String tournamentId,
    required String teamId,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament details
      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Only tournament organizer can remove teams
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can remove teams');
      }

      // Get team registration
      final registrationQuery = await _firestore
          .collection('tournament_registrations')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('teamId', isEqualTo: teamId)
          .where('status', isEqualTo: TeamRegistrationStatus.approved.name)
          .limit(1)
          .get();

      if (registrationQuery.docs.isEmpty) {
        throw Exception('Team registration not found');
      }

      final registrationDoc = registrationQuery.docs.first;
      final registration = TournamentTeamRegistration.fromMap(
        registrationDoc.data()
      );

      // Update registration status to withdrawn
      await registrationDoc.reference.update({
        'status': TeamRegistrationStatus.withdrawn.name,
        'rejectionReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update tournament team count
      await _tournamentsCollection.doc(tournamentId).update({
        'currentTeamsCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Remove from group chat
      if (tournament.groupChatId != null) {
        final chatService = ChatService();
        await chatService.removeParticipantFromGroupChat(
          chatId: tournament.groupChatId!,
          userId: registration.captainId,
        );

        // Send removal message
        await chatService.sendSystemMessage(
          chatId: tournament.groupChatId!,
          message: '👋 ${registration.teamName} has been removed from the tournament.',
        );
      }

      // Send removal notification
      await _sendRemovalNotification(tournament, registration, reason);

      if (kDebugMode) {
        debugPrint('✅ TournamentService: Team ${registration.teamName} removed from tournament ${tournament.name}');
      }
    } catch (e) {
      throw Exception('Failed to remove team from tournament: $e');
    }
  }

  /// Send removal notification
  Future<void> _sendRemovalNotification(
    Tournament tournament,
    TournamentTeamRegistration registration,
    String? reason,
  ) async {
    try {
      await _tournamentNotificationService.sendTeamRemovalNotification(
        tournament: tournament,
        registration: registration,
        reason: reason,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ TournamentService: Failed to send removal notification - $e');
      }
    }
  }

  // ============ MATCH MANAGEMENT METHODS ============

  /// Schedule a new match for the tournament
  Future<String> scheduleMatch({
    required String tournamentId,
    required String team1Id,
    required String team1Name,
    required String team2Id,
    required String team2Name,
    required DateTime scheduledDate,
    required String round,
    required int matchNumber,
    String? venueId,
    String? venueName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament details
      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Only tournament organizer can schedule matches
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can schedule matches');
      }

      final now = DateTime.now();
      final matchId = _firestore.collection('temp').doc().id;

      final match = TournamentMatch(
        id: matchId,
        tournamentId: tournamentId,
        team1Id: team1Id,
        team1Name: team1Name,
        team2Id: team2Id,
        team2Name: team2Name,
        scheduledDate: scheduledDate,
        status: MatchStatus.scheduled,
        round: round,
        matchNumber: matchNumber,
        venueId: venueId,
        venueName: venueName,
        createdAt: now,
        updatedAt: now,
      );

      // Add match to tournament
      await _tournamentsCollection.doc(tournamentId).update({
        'matches': FieldValue.arrayUnion([match.toMap()]),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Send notifications to participants
      final participantIds = await _tournamentNotificationService.getTournamentParticipantIds(tournamentId);
      await _tournamentNotificationService.sendMatchScheduleNotification(
        tournament: tournament,
        match: match,
        participantIds: participantIds,
      );

      if (kDebugMode) {
        debugPrint('✅ TournamentService: Match scheduled - ${team1Name} vs ${team2Name}');
      }

      return matchId;
    } catch (e) {
      throw Exception('Failed to schedule match: $e');
    }
  }

  /// Update match score and determine winner
  Future<void> updateMatchScore({
    required String tournamentId,
    required String matchId,
    required int team1Score,
    required int team2Score,
    String? winnerTeamId,
    String? winnerTeamName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament details
      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Only tournament organizer can update scores
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can update match scores');
      }

      final now = DateTime.now();

      // Find and update the match in the tournament
      final updatedMatches = tournament.matches.map((match) {
        if (match.id == matchId) {
          return TournamentMatch(
            id: match.id,
            tournamentId: match.tournamentId,
            team1Id: match.team1Id,
            team1Name: match.team1Name,
            team2Id: match.team2Id,
            team2Name: match.team2Name,
            scheduledDate: match.scheduledDate,
            status: MatchStatus.completed,
            team1Score: team1Score,
            team2Score: team2Score,
            winnerTeamId: winnerTeamId,
            winnerTeamName: winnerTeamName,
            round: match.round,
            matchNumber: match.matchNumber,
            venueId: match.venueId,
            venueName: match.venueName,
            createdAt: match.createdAt,
            updatedAt: now,
            metadata: match.metadata,
          );
        }
        return match;
      }).toList();

      // Update tournament with new match data
      await _tournamentsCollection.doc(tournamentId).update({
        'matches': updatedMatches.map((m) => m.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update team points if there's a winner
      if (winnerTeamId != null) {
        final currentPoints = tournament.teamPoints[winnerTeamId] ?? 0;
        final updatedTeamPoints = Map<String, int>.from(tournament.teamPoints);
        updatedTeamPoints[winnerTeamId] = currentPoints + 3; // 3 points for a win

        await _tournamentsCollection.doc(tournamentId).update({
          'teamPoints': updatedTeamPoints,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Send notifications to participants
      final updatedMatch = updatedMatches.firstWhere((m) => m.id == matchId);
      final participantIds = await _tournamentNotificationService.getTournamentParticipantIds(tournamentId);
      await _tournamentNotificationService.sendScoreUpdateNotification(
        tournament: tournament,
        match: updatedMatch,
        participantIds: participantIds,
      );

      if (kDebugMode) {
        debugPrint('✅ TournamentService: Match score updated - $team1Score:$team2Score');
      }
    } catch (e) {
      throw Exception('Failed to update match score: $e');
    }
  }

  /// Declare tournament winner and complete tournament
  Future<void> declareWinner({
    required String tournamentId,
    required String winnerTeamId,
    required String winnerTeamName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get tournament details
      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Only tournament organizer can declare winner
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can declare winner');
      }

      final now = DateTime.now();

      // Update tournament with winner and completion status
      await _tournamentsCollection.doc(tournamentId).update({
        'winnerTeamId': winnerTeamId,
        'winnerTeamName': winnerTeamName,
        'status': TournamentStatus.completed.name,
        'endDate': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Send winner declaration notifications
      final participantIds = await _tournamentNotificationService.getTournamentParticipantIds(tournamentId);
      final updatedTournament = tournament.copyWith(
        winnerTeamId: winnerTeamId,
        winnerTeamName: winnerTeamName,
        status: TournamentStatus.completed,
        endDate: now,
      );

      await _tournamentNotificationService.sendWinnerDeclarationNotification(
        tournament: updatedTournament,
        allParticipantIds: participantIds,
      );

      if (kDebugMode) {
        debugPrint('✅ TournamentService: Winner declared - $winnerTeamName won $tournamentId');
      }
    } catch (e) {
      throw Exception('Failed to declare winner: $e');
    }
  }

  /// Get tournament team registrations with status filter
  Future<List<TournamentTeamRegistration>> getTournamentTeamRegistrations({
    required String tournamentId,
    TeamRegistrationStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('tournament_registrations')
          .where('tournamentId', isEqualTo: tournamentId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TournamentTeamRegistration.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentService: Error getting tournament registrations - $e');
      }
      return [];
    }
  }

  /// Reject team registration
  Future<void> rejectTeamRegistration({
    required String registrationId,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get registration details
      final registrationDoc = await _firestore
          .collection('tournament_registrations')
          .doc(registrationId)
          .get();

      if (!registrationDoc.exists) {
        throw Exception('Registration not found');
      }

      final registration = TournamentTeamRegistration.fromMap(
        registrationDoc.data() as Map<String, dynamic>
      );

      // Get tournament details
      final tournament = await getTournament(registration.tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Only tournament organizer can reject
      if (tournament.organizerId != user.uid) {
        throw Exception('Only tournament organizer can reject registrations');
      }

      // Update registration status
      await _firestore
          .collection('tournament_registrations')
          .doc(registrationId)
          .update({
        'status': TeamRegistrationStatus.rejected.name,
        'rejectionReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send rejection notification
      await _tournamentNotificationService.sendTeamRejectionNotification(
        tournament: tournament,
        registration: registration,
        reason: reason,
      );

      if (kDebugMode) {
        debugPrint('✅ TournamentService: Team registration rejected - ${registration.teamName}');
      }
    } catch (e) {
      throw Exception('Failed to reject team registration: $e');
    }
  }
}
