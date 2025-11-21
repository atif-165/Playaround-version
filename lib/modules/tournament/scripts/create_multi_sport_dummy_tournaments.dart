import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import '../models/tournament_match_model.dart';
import '../services/tournament_service.dart';
import '../services/tournament_match_service.dart';
import '../../team/models/team_model.dart';

/// Script to create dummy tournaments for all sports
class CreateMultiSportDummyTournaments {
  final TournamentService _tournamentService = TournamentService();
  final TournamentMatchService _matchService = TournamentMatchService();

  /// Create dummy tournaments for all sport types
  Future<List<String>> createAllSportsTournaments() async {
    final tournamentIds = <String>[];

    final sports = [
      SportType.cricket,
      SportType.football,
      SportType.basketball,
      SportType.tennis,
      SportType.badminton,
      SportType.volleyball,
      SportType.hockey,
      SportType.rugby,
      SportType.baseball,
      SportType.soccer,
    ];

    for (final sport in sports) {
      try {
        final tournamentId = await _createSportTournament(sport);
        tournamentIds.add(tournamentId);
        print('✅ Created ${sport.displayName} tournament: $tournamentId');
      } catch (e) {
        print('❌ Error creating ${sport.displayName} tournament: $e');
      }
    }

    return tournamentIds;
  }

  /// Create a single sport tournament with live matches
  Future<String> _createSportTournament(SportType sport) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final now = DateTime.now();

    // Sport-specific configurations
    final config = _getSportConfig(sport);

    // 1. Create the tournament
    final tournamentId = await _tournamentService.createTournament(
      name: config['name'] as String,
      format: TournamentFormat.league,
      sportType: sport,
      registrationStartDate: now,
      registrationEndDate: now.add(const Duration(days: 3)),
      startDate: now.add(const Duration(hours: 1)),
      endDate: now.add(const Duration(days: 30)),
      description: config['description'] as String,
      imageUrl: config['profileImage'] as String?,
      isPublic: true,
      maxTeams: 8,
      minTeams: 4,
      location: config['location'] as String,
      rules: config['rules'] as List<String>,
      prizes: {
        'first': '50,000 USD',
        'second': '25,000 USD',
        'third': '10,000 USD',
      },
      entryFee: 500.0,
    );

    // 2. Create sample teams
    final teams = config['teams'] as List<Map<String, String>>;

    // 3. Create matches
    final matches = [
      // Match 1: Completed
      {
        'matchNumber': 'Match 1',
        'team1': teams[0],
        'team2': teams[1],
        'team1Score': config['match1Score'][0] as int,
        'team2Score': config['match1Score'][1] as int,
        'status': TournamentMatchStatus.completed,
        'scheduledTime': now.subtract(const Duration(days: 2)),
        'result': config['match1Result'] as String,
        'winnerId': config['match1Winner'] as String,
        'commentary': config['match1Commentary'] as List,
      },
      // Match 2: Live
      {
        'matchNumber': 'Match 2',
        'team1': teams[2],
        'team2': teams[3],
        'team1Score': config['match2Score'][0] as int,
        'team2Score': config['match2Score'][1] as int,
        'status': TournamentMatchStatus.live,
        'scheduledTime': now.subtract(const Duration(hours: 1)),
        'result': null,
        'winnerId': null,
        'commentary': config['match2Commentary'] as List,
      },
      // Match 3: Scheduled
      {
        'matchNumber': 'Match 3',
        'team1': teams[4],
        'team2': teams[5],
        'team1Score': 0,
        'team2Score': 0,
        'status': TournamentMatchStatus.scheduled,
        'scheduledTime': now.add(const Duration(hours: 2)),
        'result': null,
        'winnerId': null,
        'commentary': [],
      },
      // Match 4: Scheduled
      {
        'matchNumber': 'Match 4',
        'team1': teams[0],
        'team2': teams[2],
        'team1Score': 0,
        'team2Score': 0,
        'status': TournamentMatchStatus.scheduled,
        'scheduledTime': now.add(const Duration(days: 1)),
        'result': null,
        'winnerId': null,
        'commentary': [],
      },
    ];

    for (final matchData in matches) {
      final team1Data = matchData['team1'] as Map<String, String>;
      final team2Data = matchData['team2'] as Map<String, String>;

      final matchId = await _matchService.createMatch(
        tournamentId: tournamentId,
        tournamentName: config['name'] as String,
        sportType: sport,
        team1: TeamMatchScore(
          teamId: team1Data['id']!,
          teamName: team1Data['name']!,
        ),
        team2: TeamMatchScore(
          teamId: team2Data['id']!,
          teamName: team2Data['name']!,
        ),
        matchNumber: matchData['matchNumber'] as String,
        round: 'League Stage',
        scheduledTime: matchData['scheduledTime'] as DateTime,
        venueName: config['location'] as String,
      );

      // Update match status and scores
      if (matchData['status'] != TournamentMatchStatus.scheduled) {
        await _matchService.updateMatchScore(
          matchId: matchId,
          team1Score: matchData['team1Score'] as int,
          team2Score: matchData['team2Score'] as int,
        );

        await _matchService.updateMatch(
          matchId: matchId,
          status: matchData['status'] as TournamentMatchStatus,
          actualStartTime: (matchData['scheduledTime'] as DateTime)
              .add(const Duration(minutes: 5)),
          actualEndTime: matchData['status'] == TournamentMatchStatus.completed
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
      }
    }

    // 4. Update tournament to running
    await _tournamentService.updateTournament(
      tournamentId: tournamentId,
      startDate: now.subtract(const Duration(days: 7)),
    );

    await _tournamentService.updateTournamentStatus(
      tournamentId,
      TournamentStatus.running,
    );

    return tournamentId;
  }

  /// Get sport-specific configuration
  Map<String, dynamic> _getSportConfig(SportType sport) {
    switch (sport) {
      case SportType.cricket:
        return {
          'name': 'Premier Cricket Championship 2024',
          'description':
              'Elite cricket tournament featuring the best teams. Experience thrilling matches with top-class cricket action!',
          'location': 'National Cricket Stadium',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            '20 overs per innings',
            'Standard ICC cricket rules apply',
            'Power play in first 6 overs',
            'Each team must have 11 players',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Royal Challengers'},
            {'id': 'team_2', 'name': 'Mumbai Warriors'},
            {'id': 'team_3', 'name': 'Chennai Champions'},
            {'id': 'team_4', 'name': 'Delhi Capitals'},
            {'id': 'team_5', 'name': 'Kolkata Knights'},
            {'id': 'team_6', 'name': 'Punjab Kings'},
          ],
          'match1Score': [165, 158],
          'match1Result': 'Royal Challengers won by 7 runs',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'Match completed! Royal Challengers win by 7 runs',
              'minute': '20',
              'playerName': null,
              'eventType': 'score'
            },
            {
              'text': 'SIX! What a shot!',
              'minute': '18.3',
              'playerName': 'Virat Sharma',
              'eventType': 'score'
            },
            {
              'text': 'WICKET! Clean bowled!',
              'minute': '15.2',
              'playerName': 'Rohit Kumar',
              'eventType': 'wicket'
            },
          ],
          'match2Score': [142, 118],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'FOUR! Great timing',
              'minute': '12.4',
              'playerName': 'MS Patel',
              'eventType': 'score'
            },
            {
              'text': 'Chennai struggling at 118/5',
              'minute': '12',
              'playerName': null,
              'eventType': null
            },
          ],
        };

      case SportType.football:
        return {
          'name': 'Premier Football League 2024',
          'description':
              'Top-tier football tournament with the best teams competing for glory!',
          'location': 'National Football Stadium',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            'Each team must have 11 players (+ 3 substitutes)',
            'Standard FIFA rules apply',
            'Match duration: 90 minutes (2 × 45 minutes)',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Red Lions'},
            {'id': 'team_2', 'name': 'Blue Tigers'},
            {'id': 'team_3', 'name': 'Green Warriors'},
            {'id': 'team_4', 'name': 'Yellow Eagles'},
            {'id': 'team_5', 'name': 'Black Panthers'},
            {'id': 'team_6', 'name': 'White Sharks'},
          ],
          'match1Score': [3, 1],
          'match1Result': 'Red Lions won by 2 goals',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'Full time! Red Lions win 3-1',
              'minute': '90',
              'playerName': null,
              'eventType': 'score'
            },
            {
              'text': 'GOAL! Amazing strike!',
              'minute': '78',
              'playerName': 'John Smith',
              'eventType': 'goal'
            },
            {
              'text': 'GOAL! Header from corner',
              'minute': '45',
              'playerName': 'Mike Johnson',
              'eventType': 'goal'
            },
          ],
          'match2Score': [2, 1],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'GOAL! Green Warriors take the lead!',
              'minute': '58',
              'playerName': 'David Lee',
              'eventType': 'goal'
            },
            {
              'text': 'Intense battle at 2-1',
              'minute': '55',
              'playerName': null,
              'eventType': null
            },
          ],
        };

      case SportType.basketball:
        return {
          'name': 'Elite Basketball Championship 2024',
          'description':
              'High-flying basketball action with the best teams in the league!',
          'location': 'Central Basketball Arena',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            '4 quarters of 10 minutes each',
            'NBA standard rules',
            'Shot clock: 24 seconds',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Phoenix Suns'},
            {'id': 'team_2', 'name': 'Miami Heat'},
            {'id': 'team_3', 'name': 'Boston Celtics'},
            {'id': 'team_4', 'name': 'LA Lakers'},
            {'id': 'team_5', 'name': 'Chicago Bulls'},
            {'id': 'team_6', 'name': 'Golden Warriors'},
          ],
          'match1Score': [108, 95],
          'match1Result': 'Phoenix Suns won by 13 points',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'Game over! Phoenix wins 108-95',
              'minute': 'Q4 0:00',
              'playerName': null,
              'eventType': 'score'
            },
            {
              'text': 'THREE POINTER!',
              'minute': 'Q4 2:30',
              'playerName': 'LeBron James',
              'eventType': 'score'
            },
          ],
          'match2Score': [76, 68],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'AND ONE! Great play!',
              'minute': 'Q3 5:20',
              'playerName': 'Kevin Durant',
              'eventType': 'score'
            },
            {
              'text': 'Boston leading 76-68',
              'minute': 'Q3 4:00',
              'playerName': null,
              'eventType': null
            },
          ],
        };

      case SportType.tennis:
        return {
          'name': 'Grand Tennis Open 2024',
          'description':
              'Professional tennis tournament featuring top-ranked players!',
          'location': 'Central Tennis Complex',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            'Best of 3 sets',
            'Tiebreak at 6-6',
            'Standard ATP/WTA rules',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Rafael Nadal'},
            {'id': 'team_2', 'name': 'Roger Federer'},
            {'id': 'team_3', 'name': 'Novak Djokovic'},
            {'id': 'team_4', 'name': 'Andy Murray'},
            {'id': 'team_5', 'name': 'Dominic Thiem'},
            {'id': 'team_6', 'name': 'Stefanos Tsitsipas'},
          ],
          'match1Score': [2, 1],
          'match1Result': 'Rafael Nadal won 2-1 sets',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'Match point! Nadal wins',
              'minute': 'Set 3',
              'playerName': 'Rafael Nadal',
              'eventType': 'score'
            },
            {
              'text': 'ACE!',
              'minute': 'Set 2',
              'playerName': 'Roger Federer',
              'eventType': 'score'
            },
          ],
          'match2Score': [1, 1],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'Great rally!',
              'minute': 'Set 2',
              'playerName': 'Novak Djokovic',
              'eventType': null
            },
          ],
        };

      case SportType.badminton:
        return {
          'name': 'International Badminton Masters 2024',
          'description':
              'Elite badminton tournament with world-class shuttlers!',
          'location': 'Sports Complex Badminton Hall',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            'Best of 3 games to 21 points',
            'BWF regulations apply',
            'Service rules strictly enforced',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Smash Masters'},
            {'id': 'team_2', 'name': 'Net Ninjas'},
            {'id': 'team_3', 'name': 'Shuttle Kings'},
            {'id': 'team_4', 'name': 'Court Crushers'},
            {'id': 'team_5', 'name': 'Racket Rockets'},
            {'id': 'team_6', 'name': 'Drop Shot Pros'},
          ],
          'match1Score': [2, 0],
          'match1Result': 'Smash Masters won 2-0',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'Match won! Perfect smash!',
              'minute': 'Game 2',
              'playerName': null,
              'eventType': 'score'
            },
            {
              'text': 'Brilliant cross-court drop!',
              'minute': 'Game 1',
              'playerName': null,
              'eventType': 'score'
            },
          ],
          'match2Score': [1, 1],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'Long rally! Amazing defense!',
              'minute': 'Game 2',
              'playerName': null,
              'eventType': null
            },
          ],
        };

      case SportType.volleyball:
        return {
          'name': 'Volleyball Premier League 2024',
          'description': 'High-energy volleyball competition with top teams!',
          'location': 'Indoor Volleyball Arena',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            'Best of 5 sets to 25 points',
            'FIVB rules apply',
            'Rally point system',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Spike Squad'},
            {'id': 'team_2', 'name': 'Block Busters'},
            {'id': 'team_3', 'name': 'Serve Aces'},
            {'id': 'team_4', 'name': 'Net Guardians'},
            {'id': 'team_5', 'name': 'Dig Masters'},
            {'id': 'team_6', 'name': 'Set Shooters'},
          ],
          'match1Score': [3, 1],
          'match1Result': 'Spike Squad won 3-1',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'Powerful spike wins the match!',
              'minute': 'Set 4',
              'playerName': null,
              'eventType': 'score'
            },
            {
              'text': 'Perfect block!',
              'minute': 'Set 3',
              'playerName': null,
              'eventType': 'score'
            },
          ],
          'match2Score': [2, 1],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'Amazing dig and recovery!',
              'minute': 'Set 3',
              'playerName': null,
              'eventType': null
            },
          ],
        };

      case SportType.hockey:
        return {
          'name': 'National Hockey Championship 2024',
          'description': 'Fast-paced hockey tournament with elite teams!',
          'location': 'Ice Hockey Rink',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            '3 periods of 20 minutes',
            'Standard NHL rules',
            'Penalty box for infractions',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Ice Breakers'},
            {'id': 'team_2', 'name': 'Puck Masters'},
            {'id': 'team_3', 'name': 'Goal Hunters'},
            {'id': 'team_4', 'name': 'Stick Warriors'},
            {'id': 'team_5', 'name': 'Rink Rulers'},
            {'id': 'team_6', 'name': 'Blade Runners'},
          ],
          'match1Score': [5, 3],
          'match1Result': 'Ice Breakers won by 2 goals',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'GOAL! Amazing shot!',
              'minute': 'P3 15:22',
              'playerName': 'Wayne Gretzky',
              'eventType': 'goal'
            },
            {
              'text': 'Power play goal!',
              'minute': 'P2 10:45',
              'playerName': null,
              'eventType': 'goal'
            },
          ],
          'match2Score': [3, 2],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'Short-handed goal!',
              'minute': 'P2 8:30',
              'playerName': null,
              'eventType': 'goal'
            },
          ],
        };

      case SportType.rugby:
        return {
          'name': 'Elite Rugby Championship 2024',
          'description':
              'Intense rugby competition featuring the toughest teams!',
          'location': 'National Rugby Stadium',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            '2 halves of 40 minutes',
            'World Rugby regulations',
            'Scrums and lineouts',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Thunder Ruggers'},
            {'id': 'team_2', 'name': 'Scrum Force'},
            {'id': 'team_3', 'name': 'Try Masters'},
            {'id': 'team_4', 'name': 'Tackle Titans'},
            {'id': 'team_5', 'name': 'Maul Makers'},
            {'id': 'team_6', 'name': 'Ruck Raiders'},
          ],
          'match1Score': [28, 21],
          'match1Result': 'Thunder Ruggers won by 7 points',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'TRY! Converted!',
              'minute': '75',
              'playerName': 'John Smith',
              'eventType': 'score'
            },
            {
              'text': 'Penalty kick successful!',
              'minute': '52',
              'playerName': null,
              'eventType': 'score'
            },
          ],
          'match2Score': [14, 10],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'Strong scrum by Try Masters!',
              'minute': '42',
              'playerName': null,
              'eventType': null
            },
          ],
        };

      case SportType.baseball:
        return {
          'name': 'Baseball Super League 2024',
          'description':
              'America\'s favorite pastime with top teams competing!',
          'location': 'Baseball Diamond Stadium',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            '9 innings',
            'MLB standard rules',
            'Strike zone enforced',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'Diamond Aces'},
            {'id': 'team_2', 'name': 'Home Run Heroes'},
            {'id': 'team_3', 'name': 'Strike Kings'},
            {'id': 'team_4', 'name': 'Base Stealers'},
            {'id': 'team_5', 'name': 'Pitch Perfect'},
            {'id': 'team_6', 'name': 'Grand Slammers'},
          ],
          'match1Score': [7, 4],
          'match1Result': 'Diamond Aces won by 3 runs',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'HOME RUN! Out of the park!',
              'minute': 'Inning 8',
              'playerName': 'Babe Ruth Jr',
              'eventType': 'score'
            },
            {
              'text': 'Double play!',
              'minute': 'Inning 5',
              'playerName': null,
              'eventType': null
            },
          ],
          'match2Score': [5, 3],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'Triple! Bases loaded!',
              'minute': 'Inning 6',
              'playerName': null,
              'eventType': 'score'
            },
          ],
        };

      case SportType.soccer:
        return {
          'name': 'International Soccer Cup 2024',
          'description': 'Global soccer tournament with world-class teams!',
          'location': 'International Soccer Stadium',
          'profileImage': null,
          'bannerImage': null,
          'rules': [
            'Each team must have 11 players',
            'FIFA regulations apply',
            'Match duration: 90 minutes',
          ],
          'teams': [
            {'id': 'team_1', 'name': 'FC Barcelona'},
            {'id': 'team_2', 'name': 'Real Madrid'},
            {'id': 'team_3', 'name': 'Manchester United'},
            {'id': 'team_4', 'name': 'Bayern Munich'},
            {'id': 'team_5', 'name': 'Juventus'},
            {'id': 'team_6', 'name': 'PSG'},
          ],
          'match1Score': [2, 1],
          'match1Result': 'FC Barcelona won by 1 goal',
          'match1Winner': 'team_1',
          'match1Commentary': [
            {
              'text': 'GOAL! Messi magic!',
              'minute': '85',
              'playerName': 'Lionel Messi',
              'eventType': 'goal'
            },
            {
              'text': 'GOAL! From free kick!',
              'minute': '67',
              'playerName': 'Cristiano Ronaldo',
              'eventType': 'goal'
            },
          ],
          'match2Score': [1, 1],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [
            {
              'text': 'Close! Hit the crossbar!',
              'minute': '60',
              'playerName': null,
              'eventType': null
            },
          ],
        };

      default:
        return {
          'name': 'Multi-Sport Championship 2024',
          'description': 'Diverse sports competition!',
          'location': 'Multi-Purpose Stadium',
          'profileImage': null,
          'bannerImage': null,
          'rules': ['Standard rules apply'],
          'teams': [
            {'id': 'team_1', 'name': 'Team Alpha'},
            {'id': 'team_2', 'name': 'Team Beta'},
            {'id': 'team_3', 'name': 'Team Gamma'},
            {'id': 'team_4', 'name': 'Team Delta'},
            {'id': 'team_5', 'name': 'Team Epsilon'},
            {'id': 'team_6', 'name': 'Team Zeta'},
          ],
          'match1Score': [3, 2],
          'match1Result': 'Team Alpha won',
          'match1Winner': 'team_1',
          'match1Commentary': [],
          'match2Score': [2, 1],
          'match2Result': null,
          'match2Winner': null,
          'match2Commentary': [],
        };
    }
  }
}
