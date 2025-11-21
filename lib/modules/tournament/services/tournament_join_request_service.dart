import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_profile.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../team/models/team_model.dart' as core_team;
import '../../team/services/team_service.dart';
import '../models/tournament_match_model.dart';
import '../models/tournament_model.dart';

/// Buckets for tournament join requests stored under the tournament document.
enum TournamentJoinRequestBucket { individual, team }

class TournamentJoinRequestService {
  TournamentJoinRequestService({
    FirebaseFirestore? firestore,
    TeamService? teamService,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _teamService = teamService ?? TeamService(),
        _notificationService =
            notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final TeamService _teamService;
  final NotificationService _notificationService;

  static const _tournamentsCollection = 'tournaments';
  static const _individualCollection = 'joinRequests_individual';
  static const _teamCollection = 'joinRequests_team';

  CollectionReference<TournamentJoinRequest> _individualRef(
    String tournamentId,
  ) {
    return _firestore
        .collection(_tournamentsCollection)
        .doc(tournamentId)
        .collection(_individualCollection)
        .withConverter<TournamentJoinRequest>(
          fromFirestore: TournamentJoinRequest.fromFireStore,
          toFirestore: (req, _) => req.toJson(),
        );
  }

  CollectionReference<TournamentJoinRequest> _teamRef(String tournamentId) {
    return _firestore
        .collection(_tournamentsCollection)
        .doc(tournamentId)
        .collection(_teamCollection)
        .withConverter<TournamentJoinRequest>(
          fromFirestore: TournamentJoinRequest.fromFireStore,
          toFirestore: (req, _) => req.toJson(),
        );
  }

  /// Stream individual join requests scoped to a tournament.
  Stream<List<TournamentJoinRequest>> watchIndividualRequests(
      String tournamentId) {
    return _individualRef(tournamentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Stream team join requests scoped to a tournament.
  Stream<List<TournamentJoinRequest>> watchTeamRequests(
      String tournamentId) {
    return _teamRef(tournamentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Submit an individual join request and return the stored entity.
  Future<TournamentJoinRequest> submitIndividualRequest({
    required Tournament tournament,
    required UserProfile requester,
    required Map<String, dynamic> formFields,
  }) async {
    final docRef = _individualRef(tournament.id).doc(requester.uid);
    final now = DateTime.now();

    final request = TournamentJoinRequest(
      id: docRef.id,
      tournamentId: tournament.id,
      requesterId: requester.uid,
      requesterName: requester.fullName,
      requesterProfileUrl: requester.profilePictureUrl,
      isTeamRequest: false,
      sport: tournament.sportType.displayName,
      position: formFields['playingPosition']?.toString(),
      skillLevel: _asInt(formFields['skillLevel']),
      bio: formFields['experience']?.toString(),
      metadata: _buildMetadata(
        formFields: formFields,
        extras: {
          'email': formFields['email'] ?? '',
          'city': formFields['city'] ?? requester.location,
          'contact': formFields['contactNumber'] ?? '',
          'selfRating': formFields['selfRating'],
          'source': 'individual_form',
        },
      ),
      createdAt: now,
    );

    await docRef.set(request);
    return request;
  }

  /// Submit a team join request and notify the team owner.
  Future<TournamentJoinRequest> submitTeamRequest({
    required Tournament tournament,
    required UserProfile requester,
    required core_team.Team team,
    required Map<String, dynamic> formFields,
  }) async {
    final docRef = _teamRef(tournament.id).doc(team.id);
    final now = DateTime.now();

    final request = TournamentJoinRequest(
      id: docRef.id,
      tournamentId: tournament.id,
      requesterId: requester.uid,
      requesterName: requester.fullName,
      requesterProfileUrl: requester.profilePictureUrl,
      isTeamRequest: true,
      teamId: team.id,
      teamName: team.name,
      teamLogoUrl: team.teamImageUrl,
      sport: team.sportType.displayName,
      metadata: _buildMetadata(
        formFields: formFields,
        extras: {
          'teamSkillRating': formFields['teamSkillRating'],
          'submittedBy': requester.fullName,
          'source': 'team_form',
        },
      ),
      createdAt: now,
    );

    await docRef.set(request);

    await _notifyTeamOwner(
      teamOwnerId: team.ownerId,
      tournamentName: tournament.name,
      teamName: team.name,
      submittedBy: requester.fullName,
      metadata: {
        'tournamentId': tournament.id,
        'teamId': team.id,
      },
    );

    return request;
  }

  /// Review (approve/reject) a join request.
  Future<void> reviewRequest({
    required String tournamentId,
    required String requestId,
    required TournamentJoinRequestBucket bucket,
    required bool accept,
    String? reviewerId,
    String? reviewNote,
  }) async {
    final ref =
        bucket == TournamentJoinRequestBucket.individual ? _individualRef : _teamRef;
    final docRef = ref(tournamentId).doc(requestId);
    await docRef.update({
      'status': accept ? 'accepted' : 'rejected',
      'reviewedBy': reviewerId,
      'reviewNote': reviewNote,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic> _buildMetadata({
    required Map<String, dynamic> formFields,
    Map<String, dynamic>? extras,
  }) {
    final result = <String, dynamic>{};
    formFields.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      result[key] = value;
    });
    if (extras != null) {
      extras.forEach((key, value) {
        if (value == null) return;
        result[key] = value;
      });
    }
    return result;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<void> _notifyTeamOwner({
    required String teamOwnerId,
    required String tournamentName,
    required String teamName,
    required String submittedBy,
    Map<String, dynamic>? metadata,
  }) async {
    if (teamOwnerId.isEmpty) return;
    await _notificationService.createNotification(
      userId: teamOwnerId,
      type: NotificationType.tournamentUpdate,
      title: 'Tournament join request',
      message:
          '$submittedBy submitted $teamName to $tournamentName.',
      data: metadata,
    );
  }

  /// Convenience helper to fetch a team by ID.
  Future<core_team.Team?> getTeam(String teamId) async {
    return _teamService.getTeam(teamId);
  }
}

