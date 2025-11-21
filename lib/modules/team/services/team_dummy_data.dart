import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class TeamDummyDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates a complete dummy team with players, coaches, matches, and stats
  Future<String> createFullDummyTeam() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to create dummy team');
    }

    // Step 1: Create the team
    final teamId = await _createDummyTeam(currentUser.uid);

    // Step 2: Add dummy players
    await _addDummyPlayers(teamId, currentUser.uid);

    // Step 3: Add dummy coaches
    await _addDummyCoaches(teamId);

    // Step 4: Create opponent teams
    final opponentIds = await _createOpponentTeams();

    // Step 5: Add dummy matches
    await _addDummyMatches(teamId, opponentIds);

    // Step 6: Add join requests
    await _addDummyJoinRequests(teamId);

    return teamId;
  }

  Future<String> _createDummyTeam(String ownerId) async {
    // Create a document reference first to get the ID
    final docRef = _firestore.collection('teams').doc();

    final team = {
      'id': docRef.id,
      'name': 'Thunder Warriors FC',
      'nameLowercase': 'thunder warriors fc',
      'nameInitial': 'TW',
      'description': 'Elite football team competing at the highest level',
      'bio':
          'Founded in 2020, Thunder Warriors FC has quickly become one of the most competitive teams in the region. We focus on teamwork, discipline, and excellence both on and off the field. Our mission is to develop skilled athletes while promoting sportsmanship and community engagement.',
      'sportType': SportType.football.name,
      'city': 'Lahore',
      'createdBy': ownerId,
      'profileImageUrl': null,
      'bannerImageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'isPublic': true,
      'maxPlayers': 11,
      'maxRosterSize': 20,
      'venueIds': [],
      'tournamentIds': [],
      'matchIds': [],
      'stat': {
        'matchesPlayed': 15,
        'matchesWon': 10,
        'matchesLost': 3,
        'matchesDrawn': 2,
        'tournamentWins': 0,
        'totalPoints': 32,
        'winPercentage': 66.7,
        'sportSpecificStats': {
          'goalsScored': 35,
          'goalsConceded': 18,
        },
      },
      'players': [
        {
          'id': ownerId,
          'name': 'Team Owner',
          'profileImageUrl': null,
          'role': 'member',
          'isActive': true,
          'position': 'Forward',
          'jerseyNumber': 10,
          'isCaptain': true,
          'isHeadCoach': false,
          'joinedAt': Timestamp.now(),
          'playerStats': {},
        }
      ],
      'coaches': [],
      'metadata': {},
    };

    await docRef.set(team);
    return docRef.id;
  }

  Future<void> _addDummyPlayers(String teamId, String ownerId) async {
    final positions = [
      'Goalkeeper',
      'Defender',
      'Defender',
      'Defender',
      'Defender',
      'Midfielder',
      'Midfielder',
      'Midfielder',
      'Midfielder',
      'Forward',
      'Forward',
    ];

    final names = [
      'Ahmed Khan',
      'Ali Raza',
      'Hassan Abbas',
      'Usman Tariq',
      'Bilal Sheikh',
      'Hamza Malik',
      'Fahad Iqbal',
      'Asad Mahmood',
      'Kamran Siddiqui',
      'Zain Ahmed',
      'Omer Farooq',
    ];

    final teamRef = _firestore.collection('teams').doc(teamId);
    final teamDoc = await teamRef.get();
    final players =
        List<Map<String, dynamic>>.from(teamDoc.data()?['players'] ?? []);

    for (int i = 0; i < positions.length; i++) {
      players.add({
        'id': 'dummy_player_${i + 1}',
        'name': names[i],
        'profileImageUrl': null,
        'role': 'member',
        'isActive': true,
        'position': positions[i],
        'jerseyNumber': i + 1,
        'isCaptain': false,
        'isHeadCoach': false,
        'joinedAt': Timestamp.now(),
        'playerStats': {},
      });
    }

    await teamRef.update({'players': players});
  }

  Future<void> _addDummyCoaches(String teamId) async {
    final coaches = [
      {
        'id': 'dummy_coach_1',
        'name': 'Coach Muhammad Saeed',
        'profileImageUrl': null,
        'role': 'coach',
        'isActive': true,
        'position': 'Head Coach',
        'jerseyNumber': null,
        'isCaptain': false,
        'isHeadCoach': true,
        'joinedAt': Timestamp.now(),
        'playerStats': {},
      },
      {
        'id': 'dummy_coach_2',
        'name': 'Coach Tariq Jameel',
        'profileImageUrl': null,
        'role': 'coach',
        'isActive': true,
        'position': 'Assistant Coach',
        'jerseyNumber': null,
        'isCaptain': false,
        'isHeadCoach': false,
        'joinedAt': Timestamp.now(),
        'playerStats': {},
      },
      {
        'id': 'dummy_coach_3',
        'name': 'Coach Imran Yousaf',
        'profileImageUrl': null,
        'role': 'coach',
        'isActive': true,
        'position': 'Goalkeeper Coach',
        'jerseyNumber': null,
        'isCaptain': false,
        'isHeadCoach': false,
        'joinedAt': Timestamp.now(),
        'playerStats': {},
      },
    ];

    final teamRef = _firestore.collection('teams').doc(teamId);
    await teamRef.update({'coaches': coaches});
  }

  Future<List<String>> _createOpponentTeams() async {
    final currentUser = _auth.currentUser;
    final dummyOwnerId = currentUser?.uid ?? 'dummy_owner';

    final opponents = [
      {
        'name': 'Lions FC',
        'nameLowercase': 'lions fc',
        'nameInitial': 'LF',
        'description': 'Strong defensive team',
        'sportType': SportType.football.name,
        'city': 'Karachi',
        'createdBy': dummyOwnerId,
        'profileImageUrl': null,
        'bannerImageUrl': null,
        'bio': null,
        'isPublic': true,
        'maxPlayers': 11,
        'maxRosterSize': 20,
        'venueIds': [],
        'tournamentIds': [],
        'matchIds': [],
        'players': [],
        'coaches': [],
        'stat': {
          'matchesPlayed': 0,
          'matchesWon': 0,
          'matchesLost': 0,
          'matchesDrawn': 0,
          'tournamentWins': 0,
          'totalPoints': 0,
          'winPercentage': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {},
      },
      {
        'name': 'Eagles United',
        'nameLowercase': 'eagles united',
        'nameInitial': 'EU',
        'description': 'Fast-paced attacking team',
        'sportType': SportType.football.name,
        'city': 'Islamabad',
        'createdBy': dummyOwnerId,
        'profileImageUrl': null,
        'bannerImageUrl': null,
        'bio': null,
        'isPublic': true,
        'maxPlayers': 11,
        'maxRosterSize': 20,
        'venueIds': [],
        'tournamentIds': [],
        'matchIds': [],
        'players': [],
        'coaches': [],
        'stat': {
          'matchesPlayed': 0,
          'matchesWon': 0,
          'matchesLost': 0,
          'matchesDrawn': 0,
          'tournamentWins': 0,
          'totalPoints': 0,
          'winPercentage': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {},
      },
      {
        'name': 'Panthers SC',
        'nameLowercase': 'panthers sc',
        'nameInitial': 'PS',
        'description': 'Technical and skilled players',
        'sportType': SportType.football.name,
        'city': 'Faisalabad',
        'createdBy': dummyOwnerId,
        'profileImageUrl': null,
        'bannerImageUrl': null,
        'bio': null,
        'isPublic': true,
        'maxPlayers': 11,
        'maxRosterSize': 20,
        'venueIds': [],
        'tournamentIds': [],
        'matchIds': [],
        'players': [],
        'coaches': [],
        'stat': {
          'matchesPlayed': 0,
          'matchesWon': 0,
          'matchesLost': 0,
          'matchesDrawn': 0,
          'tournamentWins': 0,
          'totalPoints': 0,
          'winPercentage': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {},
      },
    ];

    List<String> opponentIds = [];
    for (var opponentData in opponents) {
      final docRef = _firestore.collection('teams').doc();
      opponentData['id'] = docRef.id;
      await docRef.set(opponentData);
      opponentIds.add(docRef.id);
    }

    return opponentIds;
  }

  Future<void> _addDummyMatches(String teamId, List<String> opponentIds) async {
    final now = DateTime.now();

    // Past completed matches
    final completedMatches = [
      {
        'homeTeamId': teamId,
        'awayTeamId': opponentIds[0],
        'homeTeam': {
          'id': teamId,
          'name': 'Thunder Warriors FC',
          'score': 3,
          'logoUrl': null,
        },
        'awayTeam': {
          'id': opponentIds[0],
          'name': 'Lions FC',
          'score': 1,
          'logoUrl': null,
        },
        'sportType': SportType.football.name,
        'status': 'completed',
        'matchType': 'friendly',
        'scheduledTime':
            Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'actualStartTime':
            Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'actualEndTime': Timestamp.fromDate(
            now.subtract(const Duration(days: 7, hours: -2))),
        'venueName': 'Thunder Stadium',
        'venueLocation': 'Lahore',
        'result': 'Thunder Warriors FC won 3-1',
        'winnerTeamId': teamId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'homeTeamId': opponentIds[1],
        'awayTeamId': teamId,
        'homeTeam': {
          'id': opponentIds[1],
          'name': 'Eagles United',
          'score': 2,
          'logoUrl': null,
        },
        'awayTeam': {
          'id': teamId,
          'name': 'Thunder Warriors FC',
          'score': 2,
          'logoUrl': null,
        },
        'sportType': SportType.football.name,
        'status': 'completed',
        'matchType': 'friendly',
        'scheduledTime':
            Timestamp.fromDate(now.subtract(const Duration(days: 14))),
        'actualStartTime':
            Timestamp.fromDate(now.subtract(const Duration(days: 14))),
        'actualEndTime': Timestamp.fromDate(
            now.subtract(const Duration(days: 14, hours: -2))),
        'venueName': 'Eagles Arena',
        'venueLocation': 'Islamabad',
        'result': 'Draw 2-2',
        'winnerTeamId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    // Live ongoing match
    final liveMatch = {
      'homeTeamId': teamId,
      'awayTeamId': opponentIds[2],
      'homeTeam': {
        'id': teamId,
        'name': 'Thunder Warriors FC',
        'score': 1,
        'logoUrl': null,
      },
      'awayTeam': {
        'id': opponentIds[2],
        'name': 'Panthers SC',
        'score': 1,
        'logoUrl': null,
      },
      'sportType': SportType.football.name,
      'status': 'live',
      'matchType': 'friendly',
      'scheduledTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      'actualStartTime':
          Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      'actualEndTime': null,
      'venueName': 'Thunder Stadium',
      'venueLocation': 'Lahore',
      'result': null,
      'winnerTeamId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Upcoming scheduled match
    final upcomingMatch = {
      'homeTeamId': teamId,
      'awayTeamId': opponentIds[0],
      'homeTeam': {
        'id': teamId,
        'name': 'Thunder Warriors FC',
        'score': 0,
        'logoUrl': null,
      },
      'awayTeam': {
        'id': opponentIds[0],
        'name': 'Lions FC',
        'score': 0,
        'logoUrl': null,
      },
      'sportType': SportType.football.name,
      'status': 'scheduled',
      'matchType': 'friendly',
      'scheduledTime': Timestamp.fromDate(now.add(const Duration(days: 5))),
      'actualStartTime': null,
      'actualEndTime': null,
      'venueName': 'Thunder Stadium',
      'venueLocation': 'Lahore',
      'result': null,
      'winnerTeamId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Add all matches
    final matchesRef = _firestore.collection('team_matches');
    List<String> matchIds = [];

    for (var match in completedMatches) {
      final docRef = await matchesRef.add(match);
      matchIds.add(docRef.id);
    }

    final liveDocRef = await matchesRef.add(liveMatch);
    matchIds.add(liveDocRef.id);

    final upcomingDocRef = await matchesRef.add(upcomingMatch);
    matchIds.add(upcomingDocRef.id);

    // Update team with match IDs
    await _firestore.collection('teams').doc(teamId).update({
      'matchIds': matchIds,
    });
  }

  Future<void> _addDummyJoinRequests(String teamId) async {
    final requests = [
      {
        'teamId': teamId,
        'teamName': 'Thunder Warriors FC',
        'userId': 'dummy_request_user_1',
        'userName': 'Saad Malik',
        'userProfileImageUrl': null,
        'requestedRole': 'player',
        'proposedPosition': 'Midfielder',
        'message':
            'I have 5 years of experience playing midfield. Would love to join your team!',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'respondedBy': null,
        'rejectionReason': null,
      },
      {
        'teamId': teamId,
        'teamName': 'Thunder Warriors FC',
        'userId': 'dummy_request_user_2',
        'userName': 'Raza Ahmed',
        'userProfileImageUrl': null,
        'requestedRole': 'player',
        'proposedPosition': 'Defender',
        'message':
            'Strong defender with good tactical awareness. Ready to contribute to the team.',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'respondedBy': null,
        'rejectionReason': null,
      },
      {
        'teamId': teamId,
        'teamName': 'Thunder Warriors FC',
        'userId': 'dummy_request_user_3',
        'userName': 'Coach Arif Khan',
        'userProfileImageUrl': null,
        'requestedRole': 'coach',
        'proposedPosition': 'Fitness Coach',
        'message':
            'UEFA B licensed coach with 10 years of experience in player development and fitness training.',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'respondedBy': null,
        'rejectionReason': null,
      },
    ];

    final requestsRef = _firestore.collection('team_join_requests');
    for (var request in requests) {
      await requestsRef.add(request);
    }
  }

  /// Delete all dummy data (cleanup)
  Future<void> deleteDummyData(String teamId) async {
    // Delete join requests
    final joinRequests = await _firestore
        .collection('team_join_requests')
        .where('teamId', isEqualTo: teamId)
        .get();

    for (var doc in joinRequests.docs) {
      await doc.reference.delete();
    }

    // Delete matches
    final teamDoc = await _firestore.collection('teams').doc(teamId).get();
    final matchIds = List<String>.from(teamDoc.data()?['matchIds'] ?? []);

    for (var matchId in matchIds) {
      await _firestore.collection('team_matches').doc(matchId).delete();
    }

    // Delete the team
    await _firestore.collection('teams').doc(teamId).delete();

    // Note: We're keeping opponent teams as they might be referenced elsewhere
  }
}
