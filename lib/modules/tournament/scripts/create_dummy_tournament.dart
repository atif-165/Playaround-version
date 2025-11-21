import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import '../models/tournament_match_model.dart';
import '../services/tournament_service.dart';
import '../services/tournament_match_service.dart';
import '../../team/models/team_model.dart';

/// Script to create a dummy tournament with sample data
/// This can be called from a debug screen or during development
class CreateDummyTournament {
  final TournamentService _tournamentService = TournamentService();
  final TournamentMatchService _matchService = TournamentMatchService();

  /// Create a complete dummy tournament with matches and commentary
  Future<String> createDummyTournament() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Create the tournament
      final now = DateTime.now();

      // Create with valid dates first, then update
      final tournamentId = await _tournamentService.createTournament(
        name: 'Premier Football League 2024',
        format: TournamentFormat.league,
        sportType: SportType.football,
        registrationStartDate: now,
        registrationEndDate: now.add(const Duration(days: 3)),
        startDate:
            now.add(const Duration(hours: 1)), // Valid future date initially
        endDate: now.add(const Duration(days: 30)),
        description:
            'An exciting football league tournament featuring top teams from across the region. Join us for action-packed matches and fierce competition!',
        imageUrl:
            'https://res.cloudinary.com/dlt281zr0/image/upload/v1234567890/tournaments/sample_profile.jpg',
        isPublic: true,
        maxTeams: 8,
        minTeams: 4,
        location: 'National Stadium, Capital City',
        rules: [
          'Each team must have 11 players (+ 3 substitutes)',
          'Standard FIFA rules apply',
          'Yellow and red cards will be tracked',
          'Match duration: 90 minutes (2 × 45 minutes)',
          'Fair play is mandatory',
        ],
        prizes: {
          'first': '50,000 USD',
          'second': '25,000 USD',
          'third': '10,000 USD',
          'goldenBoot': '5,000 USD',
        },
        entryFee: 500.0,
      );

      print('✅ Tournament created: $tournamentId');

      // 2. Create sample teams
      final teams = [
        {
          'id': 'team_red_lions',
          'name': 'Red Lions FC',
          'logo':
              'https://res.cloudinary.com/dlt281zr0/image/upload/v1234567890/teams/red_lions.jpg',
        },
        {
          'id': 'team_blue_tigers',
          'name': 'Blue Tigers United',
          'logo':
              'https://res.cloudinary.com/dlt281zr0/image/upload/v1234567890/teams/blue_tigers.jpg',
        },
        {
          'id': 'team_green_warriors',
          'name': 'Green Warriors',
          'logo':
              'https://res.cloudinary.com/dlt281zr0/image/upload/v1234567890/teams/green_warriors.jpg',
        },
        {
          'id': 'team_yellow_eagles',
          'name': 'Yellow Eagles SC',
          'logo':
              'https://res.cloudinary.com/dlt281zr0/image/upload/v1234567890/teams/yellow_eagles.jpg',
        },
        {
          'id': 'team_black_panthers',
          'name': 'Black Panthers FC',
          'logo':
              'https://res.cloudinary.com/dlt281zr0/image/upload/v1234567890/teams/black_panthers.jpg',
        },
        {
          'id': 'team_white_sharks',
          'name': 'White Sharks United',
          'logo':
              'https://res.cloudinary.com/dlt281zr0/image/upload/v1234567890/teams/white_sharks.jpg',
        },
      ];

      // 3. Create matches
      final matches = [
        // Match 1 - Completed (5 days ago)
        {
          'team1': teams[0],
          'team2': teams[1],
          'matchNumber': 'Match 1 - Group Stage',
          'round': 'Group Stage',
          'scheduledTime': now.subtract(const Duration(days: 5, hours: 14)),
          'team1Score': 3,
          'team2Score': 1,
          'status': TournamentMatchStatus.completed,
          'result': 'Red Lions FC won by 2 goals',
          'winnerId': 'team_red_lions',
          'commentary': [
            {
              'minute': '5\'',
              'text':
                  'GOAL! Amazing strike from outside the box by John Smith! Red Lions FC take the lead!',
              'playerName': 'John Smith',
              'eventType': 'goal',
            },
            {
              'minute': '23\'',
              'text': 'Yellow card for rough tackle on midfielder.',
              'eventType': 'foul',
            },
            {
              'minute': '35\'',
              'text':
                  'GOAL! Blue Tigers equalize with a header from corner kick!',
              'playerName': 'Mike Johnson',
              'eventType': 'goal',
            },
            {
              'minute': '52\'',
              'text': 'GOAL! Red Lions back in front! Beautiful team play!',
              'playerName': 'David Lee',
              'eventType': 'goal',
            },
            {
              'minute': '78\'',
              'text':
                  'GOAL! Red Lions seal the victory with a counter-attack goal!',
              'playerName': 'John Smith',
              'eventType': 'goal',
            },
          ],
        },
        // Match 2 - Completed (5 days ago, different time)
        {
          'team1': teams[2],
          'team2': teams[3],
          'matchNumber': 'Match 2 - Group Stage',
          'round': 'Group Stage',
          'scheduledTime': now.subtract(const Duration(days: 5, hours: 11)),
          'team1Score': 2,
          'team2Score': 2,
          'status': TournamentMatchStatus.completed,
          'result': 'Match drawn',
          'winnerId': null,
          'commentary': [
            {
              'minute': '12\'',
              'text': 'GOAL! Green Warriors strike first!',
              'playerName': 'Alex Brown',
              'eventType': 'goal',
            },
            {
              'minute': '28\'',
              'text': 'GOAL! Yellow Eagles equalize! Great finish!',
              'playerName': 'Sam Wilson',
              'eventType': 'goal',
            },
            {
              'minute': '55\'',
              'text': 'GOAL! Green Warriors regain the lead!',
              'playerName': 'Chris Taylor',
              'eventType': 'goal',
            },
            {
              'minute': '89\'',
              'text':
                  'GOAL! Last-minute equalizer by Yellow Eagles! Incredible drama!',
              'playerName': 'Tom Anderson',
              'eventType': 'goal',
            },
          ],
        },
        // Match 3 - LIVE (started 45 minutes ago)
        {
          'team1': teams[4],
          'team2': teams[5],
          'matchNumber': 'Match 3 - Group Stage (LIVE)',
          'round': 'Group Stage',
          'scheduledTime': now.subtract(const Duration(minutes: 45)),
          'team1Score': 1,
          'team2Score': 0,
          'status': TournamentMatchStatus.live,
          'result': null,
          'winnerId': null,
          'commentary': [
            {
              'minute': '15\'',
              'text':
                  'GOAL! Black Panthers take the lead with a powerful shot!',
              'playerName': 'Robert King',
              'eventType': 'goal',
            },
            {
              'minute': '28\'',
              'text':
                  'Close call! White Sharks almost equalize but shot goes wide!',
              'eventType': null,
            },
            {
              'minute': '35\'',
              'text':
                  'Half-time whistle! Black Panthers leading 1-0 at the break.',
              'eventType': null,
            },
            {
              'minute': '52\'',
              'text':
                  'Second half underway! White Sharks pushing forward looking for the equalizer.',
              'eventType': null,
            },
            {
              'minute': '58\'',
              'text': 'Close! Header from White Sharks just over the bar!',
              'eventType': null,
            },
          ],
        },
        // Match 4 - Scheduled (in 2 days)
        {
          'team1': teams[0],
          'team2': teams[2],
          'matchNumber': 'Match 4 - Group Stage',
          'round': 'Group Stage',
          'scheduledTime': now.add(const Duration(days: 2, hours: 15)),
          'team1Score': 0,
          'team2Score': 0,
          'status': TournamentMatchStatus.scheduled,
          'result': null,
          'winnerId': null,
          'commentary': [],
        },
        // Match 5 - Scheduled (in 2 days, different time)
        {
          'team1': teams[1],
          'team2': teams[3],
          'matchNumber': 'Match 5 - Group Stage',
          'round': 'Group Stage',
          'scheduledTime': now.add(const Duration(days: 2, hours: 18)),
          'team1Score': 0,
          'team2Score': 0,
          'status': TournamentMatchStatus.scheduled,
          'result': null,
          'winnerId': null,
          'commentary': [],
        },
        // Match 6 - Scheduled (in 5 days)
        {
          'team1': teams[4],
          'team2': teams[0],
          'matchNumber': 'Match 6 - Semi Final',
          'round': 'Semi Finals',
          'scheduledTime': now.add(const Duration(days: 5, hours: 16)),
          'team1Score': 0,
          'team2Score': 0,
          'status': TournamentMatchStatus.scheduled,
          'result': null,
          'winnerId': null,
          'commentary': [],
        },
      ];

      // Create matches in Firestore
      for (final matchData in matches) {
        final team1Data = matchData['team1'] as Map<String, String>;
        final team2Data = matchData['team2'] as Map<String, String>;

        final matchId = await _matchService.createMatch(
          tournamentId: tournamentId,
          tournamentName: 'Premier Football League 2024',
          sportType: SportType.football,
          team1: TeamMatchScore(
            teamId: team1Data['id']!,
            teamName: team1Data['name']!,
            teamLogoUrl: team1Data['logo'],
            score: matchData['team1Score'] as int,
          ),
          team2: TeamMatchScore(
            teamId: team2Data['id']!,
            teamName: team2Data['name']!,
            teamLogoUrl: team2Data['logo'],
            score: matchData['team2Score'] as int,
          ),
          matchNumber: matchData['matchNumber'] as String,
          round: matchData['round'] as String?,
          scheduledTime: matchData['scheduledTime'] as DateTime,
          venueName: 'National Stadium',
          venueLocation: 'Capital City',
        );

        print('✅ Match created: ${matchData['matchNumber']}');

        // Update match status and add commentary if needed
        if (matchData['status'] != TournamentMatchStatus.scheduled) {
          await _matchService.updateMatch(
            matchId: matchId,
            status: matchData['status'] as TournamentMatchStatus,
            actualStartTime: (matchData['scheduledTime'] as DateTime)
                .add(const Duration(minutes: 5)),
            actualEndTime:
                matchData['status'] == TournamentMatchStatus.completed
                    ? (matchData['scheduledTime'] as DateTime)
                        .add(const Duration(minutes: 95))
                    : null,
            result: matchData['result'] as String?,
            winnerTeamId: matchData['winnerId'] as String?,
          );

          // Add commentary
          final commentaryList = matchData['commentary'] as List;
          for (final comment in commentaryList) {
            await _matchService.addCommentary(
              matchId: matchId,
              text: comment['text'] as String,
              minute: comment['minute'] as String?,
              playerName: comment['playerName'] as String?,
              eventType: comment['eventType'] as String?,
            );
          }

          print('✅ Added commentary for ${matchData['matchNumber']}');
        }
      }

      // 4. Update tournament to have past start date (for realistic "running" state)
      await _tournamentService.updateTournament(
        tournamentId: tournamentId,
        startDate: now.subtract(const Duration(days: 7)), // Started 7 days ago
      );

      print('✅ Tournament dates updated');

      // 5. Create some join requests
      await _createDummyJoinRequests(tournamentId);

      // 6. Update tournament status to running
      await _tournamentService.updateTournamentStatus(
        tournamentId,
        TournamentStatus.running,
      );

      print('✅ Tournament status updated to RUNNING');
      print('🎉 Dummy tournament created successfully!');
      print('📝 Tournament ID: $tournamentId');

      return tournamentId;
    } catch (e) {
      print('❌ Error creating dummy tournament: $e');
      rethrow;
    }
  }

  Future<void> _createDummyJoinRequests(String tournamentId) async {
    try {
      final requests = [
        {
          'isTeam': false,
          'sport': 'Football',
          'position': 'Striker',
          'skillLevel': 8,
          'bio':
              'Experienced forward with 5 years of competitive football. Looking to join a competitive team!',
        },
        {
          'isTeam': false,
          'sport': 'Football',
          'position': 'Midfielder',
          'skillLevel': 7,
          'bio':
              'Creative midfielder with excellent passing skills and vision.',
        },
        {
          'isTeam': true,
          'teamName': 'Rising Stars FC',
          'bio': 'Young and energetic team looking for tournament experience.',
        },
      ];

      for (final request in requests) {
        final isTeam = request['isTeam'] as bool;
        final bio = request['bio'] as String;
        final formResponses = <String, dynamic>{
          'Bio': bio,
          if (request['sport'] != null) 'Sport': request['sport'],
          if (request['position'] != null) 'Preferred Position': request['position'],
          if (request['skillLevel'] != null)
            'Skill Rating': '${request['skillLevel']}/10',
        };

        await _matchService.createJoinRequest(
          tournamentId: tournamentId,
          isTeamRequest: isTeam,
          teamName: request['teamName'] as String?,
          sport: request['sport'] as String?,
          position: request['position'] as String?,
          skillLevel: request['skillLevel'] as int?,
          bio: bio,
          formResponses: formResponses,
        );
      }

      print('✅ Created ${requests.length} join requests');
    } catch (e) {
      print('⚠️ Error creating join requests: $e');
    }
  }

  /// Delete the dummy tournament (for cleanup)
  Future<void> deleteDummyTournament(String tournamentId) async {
    try {
      // Delete all matches
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('tournament_matches')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      for (final doc in matchesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all join requests (new nested structure)
      final tournamentDoc =
          FirebaseFirestore.instance.collection('tournaments').doc(tournamentId);
      final individualSnapshot =
          await tournamentDoc.collection('joinRequests_individual').get();
      for (final doc in individualSnapshot.docs) {
        await doc.reference.delete();
      }
      final teamSnapshot =
          await tournamentDoc.collection('joinRequests_team').get();
      for (final doc in teamSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete tournament
      await _tournamentService.deleteTournament(tournamentId);

      print('✅ Dummy tournament deleted successfully');
    } catch (e) {
      print('❌ Error deleting dummy tournament: $e');
      rethrow;
    }
  }
}
