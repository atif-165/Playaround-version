import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../../chat/services/chat_service.dart';

/// Service class for team management operations
class TeamService {
  static final TeamService _instance = TeamService._internal();
  factory TeamService() => _instance;
  TeamService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();

  // Collection references
  CollectionReference get _teamsCollection => _firestore.collection('teams');
  CollectionReference get _joinRequestsCollection => _firestore.collection('team_join_requests');

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
        throw Exception('Team name already exists. Please choose a different name.');
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
          if (memberId != user.uid) { // Don't add owner twice
            // TODO: Fetch user profile for member details
            members.add(TeamMember(
              userId: memberId,
              userName: 'Member', // Will be updated when user profile is fetched
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

  /// Get teams for current user
  Stream<List<Team>> getUserTeams() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _teamsCollection
        .where('members', arrayContainsAny: [
          {'userId': user.uid}
        ])
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromMap(doc.data() as Map<String, dynamic>))
            .toList())
        .asBroadcastStream();
  }

  /// Get public teams for browsing
  Stream<List<Team>> getPublicTeams({
    SportType? sportType,
    int limit = 20,
  }) {
    Query query = _teamsCollection
        .where('isPublic', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (sportType != null) {
      query = query.where('sportType', isEqualTo: sportType.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Team.fromMap(doc.data() as Map<String, dynamic>))
        .toList())
        .asBroadcastStream();
  }

  /// Search teams by name
  Future<List<Team>> searchTeamsByName(String searchQuery, {
    SportType? sportType,
    String? location,
    int limit = 20,
  }) async {
    try {
      if (searchQuery.trim().isEmpty) {
        return [];
      }

      final searchTerm = searchQuery.toLowerCase();

      Query query = _teamsCollection
          .where('isPublic', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('searchName', isGreaterThanOrEqualTo: searchTerm)
          .where('searchName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .limit(limit);

      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType.name);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('searchLocation', isEqualTo: location.toLowerCase());
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Team.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search teams: $e');
    }
  }

  /// Get teams with real-time search
  Stream<List<Team>> searchTeamsStream(String searchQuery, {
    SportType? sportType,
    String? location,
    int limit = 20,
  }) {
    if (searchQuery.trim().isEmpty) {
      return getPublicTeams(sportType: sportType, limit: limit);
    }

    final searchTerm = searchQuery.toLowerCase();

    Query query = _teamsCollection
        .where('isPublic', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('searchName', isGreaterThanOrEqualTo: searchTerm)
        .where('searchName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .limit(limit);

    if (sportType != null) {
      query = query.where('sportType', isEqualTo: sportType.name);
    }

    if (location != null && location.isNotEmpty) {
      query = query.where('searchLocation', isEqualTo: location.toLowerCase());
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Team.fromMap(doc.data() as Map<String, dynamic>))
        .toList())
        .asBroadcastStream();
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
      final isAlreadyMember = team.members.any((member) => member.userId == user.uid);
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
            .map((doc) => TeamJoinRequest.fromMap(doc.data() as Map<String, dynamic>))
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
            .map((doc) => TeamJoinRequest.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Approve join request
  Future<void> approveJoinRequest(String requestId, {String? responseMessage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the join request
      final requestDoc = await _joinRequestsCollection.doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Join request not found');

      final joinRequest = TeamJoinRequest.fromMap(requestDoc.data() as Map<String, dynamic>);

      // Get the team
      final team = await getTeam(joinRequest.teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission to approve (owner or captain)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not authorized to approve requests'),
      );

      if (userMember.role != TeamRole.owner && userMember.role != TeamRole.captain) {
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

      batch.update(_teamsCollection.doc(joinRequest.teamId), updatedTeam.toMap());

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
        print('Warning: Failed to add member to team group chat: $e');
      }
    } catch (e) {
      throw Exception('Failed to approve join request: $e');
    }
  }

  /// Reject join request
  Future<void> rejectJoinRequest(String requestId, {String? responseMessage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the join request
      final requestDoc = await _joinRequestsCollection.doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Join request not found');

      final joinRequest = TeamJoinRequest.fromMap(requestDoc.data() as Map<String, dynamic>);

      // Get the team
      final team = await getTeam(joinRequest.teamId);
      if (team == null) throw Exception('Team not found');

      // Check if user has permission to reject (owner or captain)
      final userMember = team.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw Exception('User not authorized to reject requests'),
      );

      if (userMember.role != TeamRole.owner && userMember.role != TeamRole.captain) {
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

      final joinRequest = TeamJoinRequest.fromMap(requestDoc.data() as Map<String, dynamic>);

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

      final updatedMembers = team.members.where((member) => member.userId != memberId).toList();
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
  Future<void> updateMemberRole(String teamId, String memberId, TeamRole newRole) async {
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

      if (userMember.role != TeamRole.owner) {
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

  /// Update team details
  Future<void> updateTeam({
    required String teamId,
    String? name,
    String? description,
    SportType? sportType,
    int? maxMembers,
    bool? isPublic,
    String? teamImageUrl,
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

      if (userMember.role != TeamRole.owner && userMember.role != TeamRole.captain) {
        throw Exception('Only team owner or captain can update team details');
      }

      final updatedTeam = team.copyWith(
        name: name,
        description: description,
        sportType: sportType,
        maxMembers: maxMembers,
        isPublic: isPublic,
        teamImageUrl: teamImageUrl,
        metadata: metadata,
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
      if (team.ownerId != user.uid) {
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
      final memberNames = team.members.map((member) => member.userName).toList();
      final memberImageUrls = team.members
          .map((member) => member.profileImageUrl ?? '')
          .toList();

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
      print('Warning: Failed to create team group chat: $e');
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
      final existingMember = team.members
          .where((member) => member.userId == userId)
          .firstOrNull;

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
        'members': updatedMembers.map((member) => member.toMap()).toList(),
        'memberIds': updatedMembers.map((member) => member.userId).toList(),
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

      final updatedMembers = team.members
          .where((member) => member.userId != userId)
          .toList();

      // Update team in Firestore
      await _teamsCollection.doc(teamId).update({
        'members': updatedMembers.map((member) => member.toMap()).toList(),
        'memberIds': updatedMembers.map((member) => member.userId).toList(),
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

      if (userMember.role != TeamRole.captain && userMember.role != TeamRole.owner) {
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
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
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

      final votingDoc = await _firestore.collection('captain_votes').doc(votingId).get();
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
      final votingDoc = await _firestore.collection('captain_votes').doc(votingId).get();
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
      print('Error checking captain voting: $e');
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
        'members': updatedMembers.map((member) => member.toMap()).toList(),
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
      if (team.ownerId != user.uid) {
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
        'members': updatedMembers.map((member) => member.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to assign role: $e');
    }
  }
}
