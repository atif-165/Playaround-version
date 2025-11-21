import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../models/models.dart';
import '../models/team_match_model.dart';
import '../models/team_profile_models.dart';
import '../../chat/models/chat_message.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/services/chat_notification_service.dart';
import 'team_profile_repository.dart';

/// Service class for team management operations
class TeamService {
  static final TeamService _instance = TeamService._internal();
  factory TeamService() => _instance;
  TeamService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  final ChatNotificationService _chatNotificationService =
      ChatNotificationService();
  final TeamProfileRepository _profileRepository = TeamProfileRepository();

  // Collection references
  CollectionReference get _teamsCollection => _firestore.collection('teams');
  CollectionReference get _joinRequestsCollection =>
      _firestore.collection('team_join_requests');

  // -------------------- Team Profile Streams --------------------

  Stream<List<TeamOverviewCard>> watchTeamOverviewCards(String teamId) {
    return _profileRepository.overviewCards(teamId);
  }

  Stream<Team?> watchTeam(String teamId) {
    return _teamsCollection.doc(teamId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Team.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  Stream<List<TeamAchievement>> watchTeamAchievements(String teamId) {
    return _profileRepository.achievements(teamId);
  }

  Stream<List<TeamCustomStat>> watchTeamCustomStats(String teamId) {
    return _profileRepository.customStats(teamId);
  }

  Stream<TeamPerformance> watchTeamPerformance(String teamId) {
    return _profileRepository.teamPerformance(teamId);
  }

  Stream<List<PlayerHighlightStat>> watchPlayerHighlights(String teamId) {
    return _profileRepository.playerHighlights(teamId);
  }

  Stream<List<TeamMatch>> watchTeamScheduleMatches(String teamId) {
    return _profileRepository.scheduleMatches(teamId);
  }

  Stream<List<TeamHistoryEntry>> watchTeamHistory(
    String teamId, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) {
    return _profileRepository.historyEntries(
      teamId,
      startAfter: startAfter,
      limit: limit,
    );
  }

  Stream<List<TeamTournamentEntry>> watchTeamTournaments(String teamId) {
    return _profileRepository.tournamentEntries(teamId);
  }

  // -------------------- Team Profile Mutations --------------------

  Future<void> upsertTeamAchievement(
    String teamId,
    TeamAchievement achievement,
  ) {
    return _profileRepository.saveAchievement(teamId, achievement);
  }

  Future<void> deleteTeamAchievement(String teamId, String achievementId) {
    return _profileRepository.deleteAchievement(teamId, achievementId);
  }

  Future<void> upsertCustomStat(String teamId, TeamCustomStat stat) {
    return _profileRepository.saveCustomStat(teamId, stat);
  }

  Future<void> deleteCustomStat(String teamId, String statId) {
    return _profileRepository.deleteCustomStat(teamId, statId);
  }

  Future<void> upsertHistoryEntry(String teamId, TeamHistoryEntry entry) {
    return _profileRepository.saveHistoryEntry(teamId, entry);
  }

  Future<void> deleteHistoryEntry(String teamId, String entryId) {
    return _profileRepository.deleteHistoryEntry(teamId, entryId);
  }

  Future<void> upsertTournamentEntry(
    String teamId,
    TeamTournamentEntry entry,
  ) {
    return _profileRepository.saveTournamentEntry(teamId, entry);
  }

  Future<void> deleteTournamentEntry(String teamId, String entryId) {
    return _profileRepository.deleteTournamentEntry(teamId, entryId);
  }

  Future<void> upsertTeamMatch(String teamId, TeamMatch match) {
    return _profileRepository.saveTeamMatch(teamId, match);
  }

  Future<void> deleteTeamMatch(String teamId, String matchId) {
    return _profileRepository.deleteMatch(teamId, matchId);
  }

  Future<void> upsertTeamPerformance(
    String teamId,
    TeamPerformance performance,
  ) {
    return _profileRepository.saveTeamPerformance(teamId, performance);
  }

  /// Check if team name is unique
  Future<bool> isTeamNameUnique(String name) async {
    try {
      final query = await _teamsCollection
          .where('searchName', isEqualTo: name.toLowerCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check team name uniqueness: $e');
    }
  }

  /// Create a new team
  Future<String> createTeam({
    required String name,
    required String description,
    String? bio,
    required SportType sportType,
    int maxMembers = 11,
    bool isPublic = true,
    String? teamImageUrl,
    String? backgroundImageUrl,
    String? location,
    String? coachId,
    String? coachName,
    List<String>? initialMemberIds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check team name uniqueness
      final isUnique = await isTeamNameUnique(name);
      if (!isUnique) {
        throw Exception(
            'Team name already exists. Please choose a different name.');
      }

      final now = DateTime.now();
      final teamId = _teamsCollection.doc().id;

      // Create owner as first team member
      final owner = TeamMember(
        userId: user.uid,
        userName: user.displayName ?? 'Unknown User',
        userEmail: user.email,
        profileImageUrl: user.photoURL,
        role: TeamRole.owner,
        joinedAt: now,
      );

      // Add initial members if provided
      final members = <TeamMember>[owner];
      if (initialMemberIds != null && initialMemberIds.isNotEmpty) {
        for (final memberId in initialMemberIds) {
          if (memberId != user.uid) {
            // Don't add owner twice
            // TODO: Fetch user profile for member details
            members.add(TeamMember(
              userId: memberId,
              userName:
                  'Member', // Will be updated when user profile is fetched
              role: TeamRole.member,
              joinedAt: now,
            ));
          }
        }
      }

      final team = Team(
        id: teamId,
        name: name,
        description: description,
        bio: bio,
        sportType: sportType,
        ownerId: user.uid,
        members: members,
        maxMembers: maxMembers,
        isPublic: isPublic,
        teamImageUrl: teamImageUrl,
        backgroundImageUrl: backgroundImageUrl,
        location: location,
        coachId: coachId,
        coachName: coachName,
        createdAt: now,
        updatedAt: now,
        metadata: metadata,
      );

      await _teamsCollection.doc(teamId).set(team.toMap());

      // Create group chat for the team
      await _createTeamGroupChat(team);

      return teamId;
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  /// Get team by ID
  Future<Team?> getTeam(String teamId) async {
    try {
      final doc = await _teamsCollection.doc(teamId).get();
      if (doc.exists) {
        return Team.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get team: $e');
    }
  }

  /// Get team by ID (alias for getTeam)
  Future<Team?> getTeamById(String teamId) async {
    return getTeam(teamId);
  }

  /// Get upcoming events for a team
  Future<List<TeamScheduleEvent>> getUpcomingEvents(String teamId) async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection('team_schedule_events')
          .where('teamId', isEqualTo: teamId)
          .where('startTime', isGreaterThan: now)
          .orderBy('startTime')
          .limit(10)
          .get();

      return query.docs
          .map((doc) => TeamScheduleEvent.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming events: $e');
    }
  }

  /// Get teams for current user
  Stream<List<Team>> getUserTeams() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final query = _teamsCollection.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final teams = snapshot.docs
          .map((doc) => Team.fromMap(doc.data() as Map<String, dynamic>))
          .where((team) => team.isMember(user.uid))
          .where((team) => team.isActive)
          .toList();
      return teams;
    }).asBroadcastStream();
  }

  /// Get public teams for browsing
  Stream<List<Team>> getPublicTeams({
    SportType? sportType,
    int limit = 20,
  }) {
    Query query = _teamsCollection
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (sportType != null) {
      query = query.where('sportType', isEqualTo: sportType.name);
    }

    return query
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromMap(doc.data() as Map<String, dynamic>))
            .where((team) => team.isActive)
            .toList())
        .asBroadcastStream();
  }

  /// Search teams by name
  Future<List<Team>> searchTeamsByName(
    String searchQuery, {
    SportType? sportType,
    String? location,
    int limit = 20,
  }) async {
    try {
      final trimmed = searchQuery.trim();
      if (trimmed.isEmpty) {
        return [];
      }

      final searchTerm = trimmed.toLowerCase();

      Query baseQuery = _teamsCollection.where('isPublic', isEqualTo: true);

      if (sportType != null) {
        baseQuery = baseQuery.where('sportType', isEqualTo: sportType.name);
      }

      if (location != null && location.isNotEmpty) {
        baseQuery = baseQuery.where('searchLocation',
            isEqualTo: location.toLowerCase());
      }

      List<QueryDocumentSnapshot> docs;
      try {
        docs = (await baseQuery.orderBy('nameLowercase').limit(limit * 5).get())
            .docs;
      } on FirebaseException catch (error) {
        if (error.code == 'failed-precondition') {
          docs = (await baseQuery.limit(limit * 5).get()).docs;
        } else {
          rethrow;
        }
      }

      final filtered = docs
          .map(_decodeTeamDoc)
          .where((data) => _matchesTeamSearch(data, searchTerm))
          .take(limit)
          .toList();

      final teams =
          filtered.map(Team.fromMap).where((team) => team.isActive).toList();

      teams.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return teams;
    } catch (e) {
      throw Exception('Failed to search teams: $e');
    }
  }

  /// Get teams with real-time search
  Stream<List<Team>> searchTeamsStream(
    String searchQuery, {
    SportType? sportType,
    String? location,
    int limit = 20,
  }) {
    final trimmed = searchQuery.trim();
    if (trimmed.isEmpty) {
      return getPublicTeams(sportType: sportType, limit: limit);
    }

    final lowerTerm = trimmed.toLowerCase();

    Query query = _teamsCollection.where('isPublic', isEqualTo: true);

    if (sportType != null) {
      query = query.where('sportType', isEqualTo: sportType.name);
    }

    if (location != null && location.isNotEmpty) {
      query = query.where('searchLocation', isEqualTo: location.toLowerCase());
    }

    query = query.limit(limit * 5);

    return query.snapshots().map((snapshot) {
      final teams = snapshot.docs
          .map(_decodeTeamDoc)
          .where((data) => _matchesTeamSearch(data, lowerTerm))
          .map(Team.fromMap)
          .where((team) => team.isActive)
          .take(limit)
          .toList();
      teams.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return teams;
    }).asBroadcastStream();
  }

  Map<String, dynamic> _decodeTeamDoc(QueryDocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic>
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    data.putIfAbsent('id', () => doc.id);
    return data;
  }

  bool _matchesTeamSearch(Map<String, dynamic> data, String lowerTerm) {
    if (lowerTerm.isEmpty) return true;
    final candidates = <String?>[
      data['searchName']?.toString(),
      data['nameLowercase']?.toString(),
      data['name']?.toString(),
      data['location']?.toString(),
      data['city']?.toString(),
      data['sportType']?.toString(),
    ];

    for (final candidate in candidates) {
      if (candidate == null || candidate.isEmpty) continue;
      if (candidate.toLowerCase().contains(lowerTerm)) {
        return true;
      }
    }
    return false;
  }

  /// Create join request (alias for sendJoinRequest)
  Future<String> createJoinRequest({
    required String teamId,
    String? message,
  }) async {
    return sendJoinRequest(teamId: teamId, message: message);
  }

  /// Send join request to team
  Future<String> sendJoinRequest({
    required String teamId,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if team exists
      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user is already a member
      final isAlreadyMember =
          team.members.any((member) => member.userId == user.uid);
      if (isAlreadyMember) throw Exception('User is already a team member');

      // Check if team is full
      if (team.isFull) throw Exception('Team is full');

      // Check if there's already a pending request
      final existingRequest = await _joinRequestsCollection
          .where('teamId', isEqualTo: teamId)
          .where('requesterId', isEqualTo: user.uid)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Join request already pending');
      }

      final requestId = _joinRequestsCollection.doc().id;
      final joinRequest = TeamJoinRequest(
        id: requestId,
        teamId: teamId,
        teamName: team.name,
        requesterId: user.uid,
        requesterName: user.displayName ?? 'Unknown User',
        requesterEmail: user.email,
        requesterProfileImageUrl: user.photoURL,
        message: message,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _joinRequestsCollection.doc(requestId).set(joinRequest.toMap());
      return requestId;
    } catch (e) {
      throw Exception('Failed to send join request: $e');
    }
  }

  /// Get join requests for a team (for team owners/captains)
  Stream<List<TeamJoinRequest>> getTeamJoinRequests(String teamId) {
    return _joinRequestsCollection
        .where('teamId', isEqualTo: teamId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TeamJoinRequest.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get user's join requests
  Stream<List<TeamJoinRequest>> getUserJoinRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _joinRequestsCollection
        .where('requesterId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TeamJoinRequest.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Approve join request
  Future<void> approveJoinRequest(String requestId,
      {String? responseMessage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the join request
      final requestDoc = await _joinRequestsCollection.doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Join request not found');

      final joinRequest =
          TeamJoinRequest.fromMap(requestDoc.data() as Map<String, dynamic>);

      // Get the team
      final team = await getTeam(joinRequest.teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission to approve (owner or captain)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () =>
            throw Exception('User not authorized to approve requests'),
      );

      if (!AppConfig.enablePublicTeamAdmin &&
          userMember.role != TeamRole.owner &&
          userMember.role != TeamRole.captain) {
        throw Exception('Only team owner or captain can approve requests');
      }

      // Check if team is full
      if (team.isFull) throw Exception('Team is full');

      // Add member to team
      final newMember = TeamMember(
        userId: joinRequest.requesterId,
        userName: joinRequest.requesterName,
        userEmail: joinRequest.requesterEmail,
        profileImageUrl: joinRequest.requesterProfileImageUrl,
        role: TeamRole.member,
        joinedAt: DateTime.now(),
      );

      final updatedMembers = [...team.members, newMember];
      final updatedTeam = team.copyWith(
        members: updatedMembers,
        updatedAt: DateTime.now(),
      );

      // Update team and join request in a batch
      final batch = _firestore.batch();

      batch.update(
          _teamsCollection.doc(joinRequest.teamId), updatedTeam.toMap());

      batch.update(_joinRequestsCollection.doc(requestId), {
        'status': JoinRequestStatus.approved.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
        'respondedBy': user.uid,
        'responseMessage': responseMessage,
      });

      await batch.commit();

      // Add member to group chat
      try {
        await _chatService.addMemberToGroupChat(
          chatId: 'team_${joinRequest.teamId}',
          userId: joinRequest.requesterId,
          userName: joinRequest.requesterName,
          userImageUrl: joinRequest.requesterProfileImageUrl,
        );
      } catch (e) {
        // Log error but don't fail the approval
        // Log error but don't fail the approval
      }
    } catch (e) {
      throw Exception('Failed to approve join request: $e');
    }
  }

  /// Reject join request
  Future<void> rejectJoinRequest(String requestId,
      {String? responseMessage, String? reason}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the join request
      final requestDoc = await _joinRequestsCollection.doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Join request not found');

      final joinRequest =
          TeamJoinRequest.fromMap(requestDoc.data() as Map<String, dynamic>);

      // Get the team
      final team = await getTeam(joinRequest.teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission to reject (owner or captain)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not authorized to reject requests'),
      );

      if (!AppConfig.enablePublicTeamAdmin &&
          userMember.role != TeamRole.owner &&
          userMember.role != TeamRole.captain) {
        throw Exception('Only team owner or captain can reject requests');
      }

      await _joinRequestsCollection.doc(requestId).update({
        'status': JoinRequestStatus.rejected.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
        'respondedBy': user.uid,
        'responseMessage': responseMessage,
      });
    } catch (e) {
      throw Exception('Failed to reject join request: $e');
    }
  }

  /// Cancel join request (by requester)
  Future<void> cancelJoinRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the join request
      final requestDoc = await _joinRequestsCollection.doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Join request not found');

      final joinRequest =
          TeamJoinRequest.fromMap(requestDoc.data() as Map<String, dynamic>);

      // Check if user is the requester
      if (joinRequest.requesterId != user.uid) {
        throw Exception('Only the requester can cancel the request');
      }

      // Check if request is still pending
      if (joinRequest.status != JoinRequestStatus.pending) {
        throw Exception('Can only cancel pending requests');
      }

      await _joinRequestsCollection.doc(requestId).update({
        'status': JoinRequestStatus.cancelled.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to cancel join request: $e');
    }
  }

  /// Remove member from team
  Future<void> removeMember(String teamId, String memberId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission (owner or captain, or removing themselves)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      final canRemove = userMember.role == TeamRole.owner ||
          userMember.role == TeamRole.captain ||
          user.uid == memberId;

      if (!canRemove) {
        throw Exception('Not authorized to remove this member');
      }

      // Cannot remove owner
      final memberToRemove = team.members.firstWhere(
        (member) => member.userId == memberId,
        orElse: () => throw Exception('Member not found'),
      );

      if (memberToRemove.role == TeamRole.owner) {
        throw Exception('Cannot remove team owner');
      }

      final updatedMembers =
          team.members.where((member) => member.userId != memberId).toList();
      final updatedTeam = team.copyWith(
        members: updatedMembers,
        updatedAt: DateTime.now(),
      );

      await _teamsCollection.doc(teamId).update(updatedTeam.toMap());
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Update team member role
  Future<void> updateMemberRole(
      String teamId, String memberId, TeamRole newRole) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Only owner can change roles
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      if (!AppConfig.enablePublicTeamAdmin &&
          userMember.role != TeamRole.owner) {
        throw Exception('Only team owner can change member roles');
      }

      // Cannot change owner role
      if (newRole == TeamRole.owner) {
        throw Exception('Cannot assign owner role to another member');
      }

      final updatedMembers = team.members.map((member) {
        if (member.userId == memberId) {
          return member.copyWith(role: newRole);
        }
        return member;
      }).toList();

      final updatedTeam = team.copyWith(
        members: updatedMembers,
        updatedAt: DateTime.now(),
      );

      await _teamsCollection.doc(teamId).update(updatedTeam.toMap());
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  /// Transfer team ownership to another member
  /// This makes the new member the permanent Team Admin/Owner in the backend
  Future<void> transferTeamOwnership(
      String teamId, String newOwnerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Only current owner can transfer ownership
      if (team.ownerId != user.uid) {
        throw Exception('Only team owner can transfer ownership');
      }

      // Check if new owner is a team member
      final newOwnerMember = team.members.firstWhere(
        (member) => member.userId == newOwnerId,
        orElse: () => throw Exception('New owner must be a team member'),
      );

      // Update members: make current owner a member, make new owner the owner
      final updatedMembers = team.members.map((member) {
        if (member.userId == user.uid) {
          // Current owner becomes a member
          return member.copyWith(role: TeamRole.member);
        } else if (member.userId == newOwnerId) {
          // New owner gets owner role
          return member.copyWith(role: TeamRole.owner);
        }
        return member;
      }).toList();

      // Update team with new owner
      final updatedTeam = team.copyWith(
        ownerId: newOwnerId,
        members: updatedMembers,
        updatedAt: DateTime.now(),
      );

      await _teamsCollection.doc(teamId).update(updatedTeam.toMap());
    } catch (e) {
      throw Exception('Failed to transfer team ownership: $e');
    }
  }

  /// Update team details
  Future<void> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? bio,
    String? location,
    SportType? sportType,
    int? maxMembers,
    bool? isPublic,
    String? teamImageUrl,
    String? bannerImageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission (owner or captain)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      if (!AppConfig.enablePublicTeamAdmin &&
          userMember.role != TeamRole.owner &&
          userMember.role != TeamRole.captain) {
        throw Exception('Only team owner or captain can update team details');
      }

      final updatedTeam = team.copyWith(
        name: name ?? team.name,
        description: description ?? team.description,
        bio: bio ?? team.bio,
        location: location ?? team.location,
        sportType: sportType ?? team.sportType,
        maxMembers: maxMembers ?? team.maxMembers,
        isPublic: isPublic ?? team.isPublic,
        teamImageUrl: teamImageUrl ?? team.teamImageUrl,
        backgroundImageUrl: bannerImageUrl ?? team.backgroundImageUrl,
        metadata: metadata ?? team.metadata,
        updatedAt: DateTime.now(),
      );

      await _teamsCollection.doc(teamId).update(updatedTeam.toMap());
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  /// Delete team (only owner)
  Future<void> deleteTeam(String teamId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Only owner can delete team
      if (!AppConfig.enablePublicTeamAdmin && team.ownerId != user.uid) {
        throw Exception('Only team owner can delete the team');
      }

      // Soft delete by setting isActive to false
      await _teamsCollection.doc(teamId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Cancel all pending join requests for this team
      final pendingRequests = await _joinRequestsCollection
          .where('teamId', isEqualTo: teamId)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .get();

      final batch = _firestore.batch();
      for (final doc in pendingRequests.docs) {
        batch.update(doc.reference, {
          'status': JoinRequestStatus.cancelled.name,
          'respondedAt': Timestamp.fromDate(DateTime.now()),
          'responseMessage': 'Team was deleted',
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }

  /// Create group chat for team
  Future<void> _createTeamGroupChat(Team team) async {
    try {
      final memberIds = team.members.map((member) => member.userId).toList();
      final memberNames =
          team.members.map((member) => member.userName).toList();
      final memberImageUrls =
          team.members.map((member) => member.profileImageUrl ?? '').toList();

      await _chatService.createTeamGroupChat(
        teamId: team.id,
        teamName: team.name,
        teamImageUrl: team.teamImageUrl,
        memberIds: memberIds,
        memberNames: memberNames,
        memberImageUrls: memberImageUrls,
      );
    } catch (e) {
      // Log error but don't fail team creation
      // Log error but don't fail team creation
    }
  }

  /// Add member to team and group chat
  Future<bool> addMemberToTeam({
    required String teamId,
    required String userId,
    required String userName,
    String? userImageUrl,
    TeamRole role = TeamRole.member,
  }) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) return false;

      // Check if user is already a member
      final existingMember =
          team.members.where((member) => member.userId == userId).firstOrNull;

      if (existingMember != null) {
        return true; // Already a member
      }

      // Check if team is full
      if (team.isFull) {
        throw Exception('Team is full');
      }

      final newMember = TeamMember(
        userId: userId,
        userName: userName,
        profileImageUrl: userImageUrl,
        role: role,
        joinedAt: DateTime.now(),
      );

      final updatedMembers = [...team.members, newMember];

      // Update team in Firestore
      await _teamsCollection.doc(teamId).update({
        ..._serializeMembers(updatedMembers),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Add member to group chat
      await _chatService.addMemberToGroupChat(
        chatId: 'team_$teamId',
        userId: userId,
        userName: userName,
        userImageUrl: userImageUrl,
      );

      return true;
    } catch (e) {
      throw Exception('Failed to add member to team: $e');
    }
  }

  /// Remove member from team and group chat
  Future<bool> removeMemberFromTeam({
    required String teamId,
    required String userId,
  }) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) return false;

      // Don't allow removing the owner
      if (team.ownerId == userId) {
        throw Exception('Cannot remove team owner');
      }

      final updatedMembers =
          team.members.where((member) => member.userId != userId).toList();

      // Update team in Firestore
      await _teamsCollection.doc(teamId).update({
        ..._serializeMembers(updatedMembers),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Remove member from group chat
      await _chatService.removeMemberFromGroupChat(
        chatId: 'team_$teamId',
        userId: userId,
      );

      return true;
    } catch (e) {
      throw Exception('Failed to remove member from team: $e');
    }
  }

  /// Get team group chat ID
  String getTeamChatId(String teamId) {
    return 'team_$teamId';
  }

  /// Check if team has group chat
  Future<bool> hasTeamGroupChat(String teamId) async {
    try {
      final chatRoom = await _chatService.getGroupChatByEntity(
        entityType: 'team',
        entityId: teamId,
      );
      return chatRoom != null;
    } catch (e) {
      return false;
    }
  }

  /// Ensure a team group chat exists and is synced with current members.
  Future<String> ensureTeamGroupChat(String teamId) async {
    final team = await getTeam(teamId);
    if (team == null) {
      throw Exception('Team not found');
    }

    final existingChat = await _chatService.getGroupChatByEntity(
      entityType: 'team',
      entityId: teamId,
    );
    if (existingChat == null) {
      await _createTeamGroupChat(team);
      return _chatService.teamChatId(teamId);
    }

    // Sync members
    final existingParticipantIds = existingChat.participants
        .map((participant) => participant.userId)
        .toSet();
    for (final member in team.members) {
      if (!existingParticipantIds.contains(member.userId)) {
        await _chatService.addMemberToGroupChat(
          chatId: existingChat.id,
          userId: member.userId,
          userName: member.userName,
          userImageUrl: member.profileImageUrl,
        );
      }
    }

    return existingChat.id;
  }

  /// Register a live video meeting entry and notify all members.
  Future<String> startTeamVideoMeeting(
    String teamId, {
    String callType = 'video',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final team = await getTeam(teamId);
    if (team == null) {
      throw Exception('Team not found');
    }

    final chatId = await ensureTeamGroupChat(teamId);
    final meetingDoc = _firestore
        .collection('teams')
        .doc(teamId)
        .collection('video_meetings')
        .doc();

    final channelId = 'team_${teamId}_${meetingDoc.id}';

    await meetingDoc.set({
      'id': meetingDoc.id,
      'teamId': teamId,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'createdBy': user.uid,
      'status': 'active',
      'channelId': channelId,
      'callType': callType,
    });

    const notificationMessage = 'Team meeting has started. Please join.';
    await _chatService.sendSystemMessage(
      chatId: chatId,
      message: notificationMessage,
    );

    try {
      final chatRoom = await _chatService.getChatRoom(chatId) ??
          await _chatService.getGroupChatByEntity(
            entityType: 'team',
            entityId: teamId,
          );
      if (chatRoom != null) {
        final tokens = await _chatNotificationService.getParticipantTokens(
          chatRoom.participants
              .map((participant) => participant.userId)
              .toList(),
        );
        if (tokens.isNotEmpty) {
          final messageId = meetingDoc.id;
          final chatMessage = ChatMessage(
            id: messageId,
            chatId: chatId,
            fromId: 'system',
            groupId: chatId,
            senderName: team.name,
            type: MessageType.text,
            text: notificationMessage,
            createdAt: DateTime.now(),
          );

          await _chatNotificationService.sendMessageNotification(
            message: chatMessage,
            chatRoom: chatRoom,
            recipientTokens: tokens,
          );
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to send meeting notification: $error');
      }
    }
    return channelId;
  }

  // ============ CAPTAIN VOTING SYSTEM ============

  /// Initiate captain voting (only current captain can initiate)
  Future<String> initiateCaptainVoting({
    required String teamId,
    required String candidateId,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user is current captain
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      if (userMember.role != TeamRole.captain &&
          userMember.role != TeamRole.owner) {
        throw Exception('Only current captain or owner can initiate voting');
      }

      // Check if candidate is a team member
      final candidate = team.members.firstWhere(
        (member) => member.userId == candidateId,
        orElse: () => throw Exception('Candidate is not a team member'),
      );

      // Create voting document
      final votingId = _firestore.collection('temp').doc().id;
      final voting = {
        'id': votingId,
        'teamId': teamId,
        'candidateId': candidateId,
        'candidateName': candidate.userName,
        'initiatedBy': user.uid,
        'initiatedByName': userMember.userName,
        'reason': reason,
        'votes': <String, bool>{}, // userId -> vote (true/false)
        'status': 'active', // active, completed, cancelled
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      };

      await _firestore.collection('captain_votes').doc(votingId).set(voting);
      return votingId;
    } catch (e) {
      throw Exception('Failed to initiate captain voting: $e');
    }
  }

  /// Vote for captain change
  Future<void> voteForCaptain({
    required String votingId,
    required bool approve,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final votingDoc =
          await _firestore.collection('captain_votes').doc(votingId).get();
      if (!votingDoc.exists) throw Exception('Voting not found');

      final votingData = votingDoc.data() as Map<String, dynamic>;
      final teamId = votingData['teamId'] as String;

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user is a team member
      team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      // Check if voting is still active
      final expiresAt = (votingData['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('Voting has expired');
      }

      if (votingData['status'] != 'active') {
        throw Exception('Voting is not active');
      }

      // Update vote
      await _firestore.collection('captain_votes').doc(votingId).update({
        'votes.${user.uid}': approve,
      });

      // Check if voting should be completed
      await _checkAndCompleteCaptainVoting(votingId);
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  /// Check and complete captain voting if conditions are met
  Future<void> _checkAndCompleteCaptainVoting(String votingId) async {
    try {
      final votingDoc =
          await _firestore.collection('captain_votes').doc(votingId).get();
      if (!votingDoc.exists) return;

      final votingData = votingDoc.data() as Map<String, dynamic>;
      final teamId = votingData['teamId'] as String;
      final candidateId = votingData['candidateId'] as String;

      final team = await getTeam(teamId);
      if (team == null) return;

      final votes = Map<String, bool>.from(votingData['votes'] ?? {});
      final totalMembers = team.members.length;
      final votesCount = votes.length;
      final approveCount = votes.values.where((vote) => vote).length;

      // Need majority vote (more than 50% of team members)
      final requiredVotes = (totalMembers / 2).ceil();

      if (approveCount >= requiredVotes) {
        // Voting passed - change captain
        await _changeCaptain(teamId, candidateId);

        await _firestore.collection('captain_votes').doc(votingId).update({
          'status': 'completed',
          'result': 'approved',
          'completedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else if (votesCount >= totalMembers) {
        // All members voted but didn't reach majority
        await _firestore.collection('captain_votes').doc(votingId).update({
          'status': 'completed',
          'result': 'rejected',
          'completedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      // Error checking captain voting
    }
  }

  /// Change team captain
  Future<void> _changeCaptain(String teamId, String newCaptainId) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) return;

      final updatedMembers = team.members.map((member) {
        if (member.role == TeamRole.captain) {
          // Demote current captain to member
          return member.copyWith(role: TeamRole.member);
        } else if (member.userId == newCaptainId) {
          // Promote new captain
          return member.copyWith(role: TeamRole.captain);
        }
        return member;
      }).toList();

      await _teamsCollection.doc(teamId).update({
        ..._serializeMembers(updatedMembers),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to change captain: $e');
    }
  }

  /// Get active captain voting for team
  Stream<Map<String, dynamic>?> getActiveCaptainVoting(String teamId) {
    return _firestore
        .collection('captain_votes')
        .where('teamId', isEqualTo: teamId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    });
  }

  /// Manually assign member role (owner only)
  Future<void> assignMemberRole({
    required String teamId,
    required String memberId,
    required TeamRole newRole,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user is team owner
      if (!AppConfig.enablePublicTeamAdmin && team.ownerId != user.uid) {
        throw Exception('Only team owner can assign roles');
      }

      // Can't change owner role
      if (newRole == TeamRole.owner) {
        throw Exception('Cannot assign owner role');
      }

      final updatedMembers = team.members.map((member) {
        if (member.userId == memberId) {
          return member.copyWith(role: newRole);
        }
        return member;
      }).toList();

      await _teamsCollection.doc(teamId).update({
        ..._serializeMembers(updatedMembers),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to assign role: $e');
    }
  }

  // ============ PERFORMANCE TRACKING ============

  /// Get player performance for a team
  Future<PlayerPerformance?> getPlayerPerformance(
      String teamId, String playerId) async {
    try {
      final doc = await _firestore
          .collection('team_performance')
          .doc('${teamId}_$playerId')
          .get();

      if (doc.exists) {
        return PlayerPerformance.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get player performance: $e');
    }
  }

  /// Get all player performances for a team
  Stream<List<PlayerPerformance>> getTeamPlayerPerformances(String teamId) {
    return _firestore
        .collection('team_performance')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                PlayerPerformance.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Update player performance
  Future<void> updatePlayerPerformance(PlayerPerformance performance) async {
    try {
      await _firestore
          .collection('team_performance')
          .doc('${performance.teamId}_${performance.playerId}')
          .set(performance.toMap());
    } catch (e) {
      throw Exception('Failed to update player performance: $e');
    }
  }

  /// Get team performance
  Future<TeamPerformance?> getTeamPerformance(String teamId) async {
    try {
      final doc = await _firestore
          .collection('team_performance')
          .doc('${teamId}_team')
          .get();

      if (doc.exists) {
        return TeamPerformance.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get team performance: $e');
    }
  }

  /// Update team performance
  Future<void> updateTeamPerformance(TeamPerformance performance) async {
    try {
      await _firestore
          .collection('team_performance')
          .doc('${performance.teamId}_team')
          .set(performance.toMap());
    } catch (e) {
      throw Exception('Failed to update team performance: $e');
    }
  }

  /// Add team achievement
  Future<void> addTeamAchievement(TeamAchievement achievement) async {
    try {
      await _firestore
          .collection('team_achievements')
          .doc(achievement.id)
          .set(achievement.toMap());
    } catch (e) {
      throw Exception('Failed to add team achievement: $e');
    }
  }

  /// Get team achievements
  Stream<List<TeamAchievement>> getTeamAchievements(String teamId) {
    return _firestore
        .collection('team_achievements')
        .where('teamId', isEqualTo: teamId)
        .orderBy('achievedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TeamAchievement.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ============ SCHEDULING ============

  /// Create a team schedule event
  Future<String> createScheduleEvent(TeamScheduleEvent event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(event.teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission to create events
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      if (!AppConfig.enablePublicTeamAdmin &&
          userMember.role != TeamRole.owner &&
          userMember.role != TeamRole.captain) {
        throw Exception('Only team owner or captain can create events');
      }

      await _firestore
          .collection('team_schedule')
          .doc(event.id)
          .set(event.toMap());

      return event.id;
    } catch (e) {
      throw Exception('Failed to create schedule event: $e');
    }
  }

  /// Get team schedule events
  Stream<List<TeamScheduleEvent>> getTeamSchedule(
    String teamId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection('team_schedule')
        .where('teamId', isEqualTo: teamId)
        .orderBy('startTime');

    if (startDate != null) {
      query = query.where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            TeamScheduleEvent.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Update schedule event
  Future<void> updateScheduleEvent(TeamScheduleEvent event) async {
    try {
      await _firestore
          .collection('team_schedule')
          .doc(event.id)
          .update(event.toMap());
    } catch (e) {
      throw Exception('Failed to update schedule event: $e');
    }
  }

  /// Delete schedule event
  Future<void> deleteScheduleEvent(String eventId) async {
    try {
      await _firestore.collection('team_schedule').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete schedule event: $e');
    }
  }

  /// Mark member attendance for an event
  Future<void> markAttendance({
    required String eventId,
    required String memberId,
    required String memberName,
    required AttendanceStatus status,
    String? reason,
  }) async {
    try {
      final attendance = MemberAttendance(
        eventId: eventId,
        memberId: memberId,
        memberName: memberName,
        status: status,
        reason: reason,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('team_attendance')
          .doc('${eventId}_$memberId')
          .set(attendance.toMap());
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  /// Get attendance for an event
  Stream<List<MemberAttendance>> getEventAttendance(String eventId) {
    return _firestore
        .collection('team_attendance')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                MemberAttendance.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get member's attendance history
  Stream<List<MemberAttendance>> getMemberAttendanceHistory(
    String memberId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection('team_attendance')
        .where('memberId', isEqualTo: memberId)
        .orderBy('updatedAt', descending: true);

    if (startDate != null) {
      query = query.where('updatedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('updatedAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            MemberAttendance.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  // ============ TEAM MATCHES ============

  /// Get team matches stream
  Stream<List<TeamMatch>> getTeamMatchesStream(String teamId) {
    return _firestore
        .collection('team_matches')
        .where('homeTeamId', isEqualTo: teamId)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .asyncMap((homeSnapshot) async {
      // Also get matches where team is away team
      final awaySnapshot = await _firestore
          .collection('team_matches')
          .where('awayTeamId', isEqualTo: teamId)
          .orderBy('scheduledTime', descending: true)
          .get();

      final homeMatches = homeSnapshot.docs
          .map((doc) => TeamMatch.fromFireStore(doc, null))
          .toList();

      final awayMatches = awaySnapshot.docs
          .map((doc) => TeamMatch.fromFireStore(doc, null))
          .toList();

      // Combine and sort by scheduled time
      final allMatches = [...homeMatches, ...awayMatches];
      allMatches.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

      return allMatches;
    });
  }

  /// Get match by ID
  Future<TeamMatch?> getMatchById(String matchId) async {
    try {
      final doc =
          await _firestore.collection('team_matches').doc(matchId).get();
      if (doc.exists) {
        return TeamMatch.fromFireStore(doc, null);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get match: $e');
    }
  }

  /// Create a team match
  Future<String> createTeamMatch({
    required String homeTeamId,
    required String awayTeamId,
    required TeamScore homeTeam,
    required TeamScore awayTeam,
    required SportType sportType,
    required DateTime scheduledTime,
    TeamMatchType matchType = TeamMatchType.friendly,
    String? tournamentId,
    String? tournamentName,
    String? venueId,
    String? venueName,
    String? venueLocation,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final matchId = _firestore.collection('team_matches').doc().id;
      final now = DateTime.now();

      final match = TeamMatch(
        id: matchId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        sportType: sportType,
        matchType: matchType,
        status: TeamMatchStatus.scheduled,
        scheduledTime: scheduledTime,
        tournamentId: tournamentId,
        tournamentName: tournamentName,
        venueId: venueId,
        venueName: venueName,
        venueLocation: venueLocation,
        notes: notes,
        createdAt: now,
        createdBy: user.uid,
        metadata: metadata,
      );

      await _firestore
          .collection('team_matches')
          .doc(matchId)
          .set(match.toJson());
      return matchId;
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }

  /// Update match visibility in metadata
  Future<void> updateMatchVisibility(String matchId, bool isVisible) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('team_matches').doc(matchId).update({
        'metadata.isVisible': isVisible,
      });
    } catch (e) {
      throw Exception('Failed to update match visibility: $e');
    }
  }

  // ============ PLAYER MANAGEMENT ============

  /// Update player details (position, jersey number, etc.)
  Future<void> updatePlayerDetails({
    required String teamId,
    required String playerId,
    String? position,
    int? jerseyNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission (owner, captain, or updating own details)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      final canUpdate = userMember.role == TeamRole.owner ||
          userMember.role == TeamRole.captain ||
          user.uid == playerId;

      if (!canUpdate) {
        throw Exception('Not authorized to update player details');
      }

      // Update player in team members list
      final updatedMembers = team.members.map((member) {
        if (member.userId == playerId) {
          return member.copyWith(
            position: position,
            jerseyNumber: jerseyNumber,
          );
        }
        return member;
      }).toList();

      await _teamsCollection.doc(teamId).update({
        ..._serializeMembers(updatedMembers),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update player details: $e');
    }
  }

  /// Update player rating and trophies
  Future<void> updatePlayerRatingAndTrophies({
    required String teamId,
    required String playerId,
    double? rating,
    int? trophies,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Only owner or captain can update ratings and trophies
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      if (!AppConfig.enablePublicTeamAdmin &&
          userMember.role != TeamRole.owner &&
          userMember.role != TeamRole.captain) {
        throw Exception('Only team owner or captain can update ratings');
      }

      // Update player in team members list
      final updatedMembers = team.members.map((member) {
        if (member.userId == playerId) {
          return member.copyWith(
            rating: rating,
            trophies: trophies,
          );
        }
        return member;
      }).toList();

      await _teamsCollection.doc(teamId).update({
        ..._serializeMembers(updatedMembers),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update player rating: $e');
    }
  }

  // ============ COACH MANAGEMENT ============

  /// Update coach details
  Future<void> updateCoachDetails({
    required String teamId,
    required String coachId,
    String? specialization,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission (owner or the coach themselves)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not a team member'),
      );

      final canUpdate =
          userMember.role == TeamRole.owner || user.uid == coachId;

      if (!canUpdate) {
        throw Exception('Not authorized to update coach details');
      }

      // Update coach in team members list
      final updatedMembers = team.members.map((member) {
        if (member.userId == coachId && member.role == TeamRole.coach) {
          return member; // Can add coach-specific fields here if needed
        }
        return member;
      }).toList();

      await _teamsCollection.doc(teamId).update({
        ..._serializeMembers(updatedMembers),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update coach details: $e');
    }
  }

  /// Update coach rating
  Future<void> updateCoachRating({
    required String teamId,
    required String coachId,
    required double rating,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final team = await getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Only owner can update coach rating
      if (!AppConfig.enablePublicTeamAdmin && team.ownerId != user.uid) {
        throw Exception('Only team owner can update coach rating');
      }

      // Update coach in team members list
      final updatedMembers = team.members.map((member) {
        if (member.userId == coachId && member.role == TeamRole.coach) {
          return member.copyWith(rating: rating);
        }
        return member;
      }).toList();

      await _teamsCollection.doc(teamId).update({
        ..._serializeMembers(updatedMembers),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update coach rating: $e');
    }
  }

  // ============ BACKWARD COMPATIBILITY ALIASES ============

  /// Alias for removeMemberFromTeam (for players)
  Future<bool> removePlayerFromTeam({
    required String teamId,
    required String playerId,
  }) async {
    return removeMemberFromTeam(teamId: teamId, userId: playerId);
  }

  /// Alias for removeMemberFromTeam (for coaches)
  Future<bool> removeCoachFromTeam({
    required String teamId,
    required String coachId,
  }) async {
    return removeMemberFromTeam(teamId: teamId, userId: coachId);
  }

  /// Alias for getTeamJoinRequests with Stream suffix
  Stream<List<TeamJoinRequest>> getTeamJoinRequestsStream(String teamId) {
    return getTeamJoinRequests(teamId);
  }

  Stream<List<Team>> getTeamsStream({
    SportType? sportType,
    String? city,
    bool? isPublic,
    int limit = 20,
  }) {
    Query query = _teamsCollection.orderBy('createdAt', descending: true);

    if (isPublic != null) {
      query = query.where('isPublic', isEqualTo: isPublic);
    }

    if (sportType != null) {
      query = query.where('sportType', isEqualTo: sportType.name);
    }

    if (city != null && city.isNotEmpty) {
      query = query.where('searchLocation', isEqualTo: city.toLowerCase());
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      final teams = snapshot.docs
          .map((doc) => Team.fromMap(doc.data() as Map<String, dynamic>))
          .where((team) => team.isActive)
          .toList();
      return teams;
    }).asBroadcastStream();
  }

  /// Alias for getUserTeams with userId parameter
  Stream<List<Team>> getUserTeamsStream(String userId) {
    return _teamsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromMap(doc.data() as Map<String, dynamic>))
            .where((team) => team.isActive)
            .where((team) => team.isMember(userId))
            .toList())
        .asBroadcastStream();
  }

  /// Alias for searchTeamsByName
  Future<List<Team>> searchTeams(
    String searchQuery, {
    SportType? sportType,
    String? location,
    int limit = 20,
  }) async {
    return searchTeamsByName(searchQuery,
        sportType: sportType, location: location, limit: limit);
  }

  /// Alias for addMemberToTeam with player-specific parameters
  Future<void> addPlayerToTeam({
    required String teamId,
    required String playerId,
    required String playerName,
    String? profileImageUrl,
    TeamRole role = TeamRole.member,
  }) async {
    await addMemberToTeam(
      teamId: teamId,
      userId: playerId,
      userName: playerName,
      userImageUrl: profileImageUrl,
      role: role,
    );
  }
}

Map<String, dynamic> _serializeMembers(List<TeamMember> members) {
  final players = members
      .where((member) => member.role != TeamRole.coach)
      .map((member) => member.toMap())
      .toList();

  final coaches = members
      .where((member) => member.role == TeamRole.coach)
      .map((member) => member.toMap())
      .toList();

  return {
    'members': members.map((member) => member.toMap()).toList(),
    'players': players,
    'coaches': coaches,
    'memberIds': members.map((member) => member.userId).toList(),
  };
}
