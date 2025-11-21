import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to generate demo matches for testing
/// This should be used ONLY for development/testing purposes
class DemoMatchGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create demo matches for Thunder Warriors team
  /// teamId should be the Thunder Warriors team ID
  Future<void> createDemoMatches(String teamId, String teamName) async {
    try {
      // Create 3 demo matches
      final now = DateTime.now();

      // Match 1: Completed match - Win
      await _createMatch(
        homeTeamId: teamId,
        homeTeamName: teamName,
        awayTeamId: 'demo_team_1',
        awayTeamName: 'Lightning Strikers',
        homeScore: 3,
        awayScore: 1,
        scheduledTime: now.subtract(const Duration(days: 7)),
        status: 'completed',
        result: '$teamName won by 2 goals',
        winnerTeamId: teamId,
      );

      // Match 2: Live match
      await _createMatch(
        homeTeamId: 'demo_team_2',
        homeTeamName: 'Phoenix Flames',
        awayTeamId: teamId,
        awayTeamName: teamName,
        homeScore: 2,
        awayScore: 2,
        scheduledTime: now,
        status: 'live',
        actualStartTime: now.subtract(const Duration(minutes: 45)),
      );

      // Match 3: Scheduled upcoming match
      await _createMatch(
        homeTeamId: teamId,
        homeTeamName: teamName,
        awayTeamId: 'demo_team_3',
        awayTeamName: 'Dragon Defenders',
        homeScore: 0,
        awayScore: 0,
        scheduledTime: now.add(const Duration(days: 3)),
        status: 'scheduled',
      );

      print('✅ Successfully created 3 demo matches for $teamName');
    } catch (e) {
      print('❌ Error creating demo matches: $e');
      rethrow;
    }
  }

  Future<void> _createMatch({
    required String homeTeamId,
    required String homeTeamName,
    required String awayTeamId,
    required String awayTeamName,
    required int homeScore,
    required int awayScore,
    required DateTime scheduledTime,
    required String status,
    String? result,
    String? winnerTeamId,
    DateTime? actualStartTime,
  }) async {
    final matchId = _firestore.collection('team_matches').doc().id;

    final matchData = {
      'id': matchId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeTeam': {
        'teamId': homeTeamId,
        'teamName': homeTeamName,
        'teamLogoUrl': null,
        'score': homeScore,
        'sportSpecificData': null,
      },
      'awayTeam': {
        'teamId': awayTeamId,
        'teamName': awayTeamName,
        'teamLogoUrl': null,
        'score': awayScore,
        'sportSpecificData': null,
      },
      'sportType': 'football',
      'matchType': 'friendly',
      'status': status,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'actualStartTime':
          actualStartTime != null ? Timestamp.fromDate(actualStartTime) : null,
      'actualEndTime': null,
      'tournamentId': null,
      'tournamentName': null,
      'venueId': null,
      'venueName': 'Demo Stadium',
      'venueLocation': 'Demo City',
      'result': result,
      'winnerTeamId': winnerTeamId,
      'notes': 'Demo match for testing purposes',
      'createdAt': Timestamp.now(),
      'createdBy': 'demo_system',
      'metadata': {},
    };

    await _firestore.collection('team_matches').doc(matchId).set(matchData);

    // Add match ID to both teams' matchIds array
    await _firestore.collection('teams').doc(homeTeamId).update({
      'matchIds': FieldValue.arrayUnion([matchId]),
    });

    // Note: For demo teams that don't exist, we skip updating them
    if (!awayTeamId.startsWith('demo_')) {
      await _firestore.collection('teams').doc(awayTeamId).update({
        'matchIds': FieldValue.arrayUnion([matchId]),
      });
    }
  }

  /// Delete all demo matches
  Future<void> deleteDemoMatches() async {
    try {
      final snapshot = await _firestore
          .collection('team_matches')
          .where('createdBy', isEqualTo: 'demo_system')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Successfully deleted all demo matches');
    } catch (e) {
      print('❌ Error deleting demo matches: $e');
      rethrow;
    }
  }
}
