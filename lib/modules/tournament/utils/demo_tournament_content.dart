import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/player_match_stats.dart';
import '../models/tournament_match_model.dart';
import '../models/tournament_model.dart';
import '../../team/models/team_model.dart';

/// Builds richly populated demo content for tournaments when Firestore data
/// isn't available. Each sport type receives sport-specific teams, commentary,
/// and stats so QA can exercise every screen end-to-end.
class DemoTournamentContent {
  static final Map<SportType, List<String>> _teamNameMap = {
    SportType.football: [
      'Karachi Royals',
      'Islamabad Warriors',
      'Lahore Lightning',
      'Multan Mavericks',
      'Quetta Chargers',
      'Peshawar Falcons',
    ],
    SportType.soccer: [
      'Riverfront United',
      'Metro City FC',
      'Northern Wolves',
      'Desert Stallions',
      'East Bay Mariners',
      'Liberty Greens',
    ],
    SportType.cricket: [
      'Royal Challengers',
      'Mumbai Warriors',
      'Chennai Champions',
      'Delhi Capitals',
      'Punjab Kings',
      'Hyderabad Suns',
    ],
    SportType.basketball: [
      'Neon Dunkers',
      'Skyline Hoopers',
      'Baseline Bruisers',
      'Metro Rim Lords',
      'Sunset Shooters',
      'Court Commanders',
    ],
    SportType.tennis: [
      'Rafael Storm',
      'Federer Aces',
      'Djokovic Drivers',
      'Murray Masters',
      'Tsitsipas Tops',
      'Thiem Thunder',
    ],
    SportType.badminton: [
      'Smash Masters',
      'Net Ninjas',
      'Drop Shot Pros',
      'Feather Flyers',
      'Court Crushers',
      'Rally Rebels',
    ],
    SportType.volleyball: [
      'Spike Squad',
      'Block Busters',
      'Net Guardians',
      'Dig Masters',
      'Serve Storm',
      'Coastline Aces',
    ],
    SportType.hockey: [
      'Ice Breakers',
      'Puck Masters',
      'Goal Hunters',
      'Stick Warriors',
      'Blade Runners',
      'Rink Titans',
    ],
    SportType.rugby: [
      'Scrum Titans',
      'Try Machines',
      'Ruck Raiders',
      'Pitch Panthers',
      'Pack Chargers',
      'Capital Cleavers',
    ],
    SportType.baseball: [
      'Diamond Knights',
      'Harbor Hawks',
      'Summit Sluggers',
      'Metro Mavericks',
      'River City Runners',
      'Outfield Outlaws',
    ],
    SportType.cycling: [
      'Velocity Vortex',
      'Peloton Prime',
      'Summit Spinners',
      'Rapid Rollers',
      'Coastal Climbers',
      'Crit Circuit Crew',
    ],
  };

  static List<String> _teamsForSport(SportType sport) {
    return _teamNameMap[sport] ??
        [
          'Aurora Alphas',
          'Nebula Nomads',
          'Zenith Zephyrs',
          'Orbit Owls',
          'Lunar Lynx',
          'Cosmo Coyotes',
        ];
  }

  static List<TournamentMatch> generateMatches(Tournament tournament) {
    final teams = _teamsForSport(tournament.sportType);
    final now = DateTime.now();
    final String venue = tournament.venueName ?? tournament.location ?? 'Main Arena';

    TournamentMatch createMatch({
      required String id,
      required String matchNumber,
      required int team1Index,
      required int team2Index,
      required TournamentMatchStatus status,
      required DateTime scheduledTime,
      DateTime? actualStart,
      DateTime? actualEnd,
      int team1Score = 0,
      int team2Score = 0,
      String? result,
      List<CommentaryEntry> commentary = const [],
    }) {
      final team1Name = teams[team1Index % teams.length];
      final team2Name = teams[team2Index % teams.length];
      return TournamentMatch(
        id: id,
        tournamentId: tournament.id,
        tournamentName: tournament.name,
        sportType: tournament.sportType,
        matchNumber: matchNumber,
        round: _roundLabelForSport(tournament.sportType),
        scheduledTime: scheduledTime,
        actualStartTime: actualStart,
        actualEndTime: actualEnd,
        status: status,
        result: result,
        commentary: commentary,
        team1: TeamMatchScore(
          teamId: '${tournament.id}_${team1Index + 1}',
          teamName: team1Name,
          score: team1Score,
        ),
        team2: TeamMatchScore(
          teamId: '${tournament.id}_${team2Index + 1}',
          teamName: team2Name,
          score: team2Score,
        ),
        team1PlayerStats: _buildPlayerStats(team1Name, tournament.sportType, team1Score),
        team2PlayerStats: _buildPlayerStats(team2Name, tournament.sportType, team2Score),
        venueName: venue,
        venueLocation: tournament.location ?? 'Pakistan',
      );
    }

    return [
      createMatch(
        id: '${tournament.id}-live',
        matchNumber: 'Match 1',
        team1Index: 0,
        team2Index: 1,
        status: TournamentMatchStatus.live,
        team1Score: 2,
        team2Score: 1,
        scheduledTime: now.subtract(const Duration(minutes: 75)),
        actualStart: now.subtract(const Duration(minutes: 75)),
        commentary: _buildCommentary(
          teams[0],
          teams[1],
          tournament.sportType,
          isLive: true,
        ),
        result: _liveStatusLabel(tournament.sportType),
      ),
      createMatch(
        id: '${tournament.id}-upcoming',
        matchNumber: 'Match 2',
        team1Index: 2,
        team2Index: 3,
        status: TournamentMatchStatus.scheduled,
        scheduledTime: now.add(const Duration(hours: 5)),
        result:
            'Kick-off at ${DateFormat('h:mm a').format(now.add(const Duration(hours: 5)))}',
      ),
      createMatch(
        id: '${tournament.id}-completed',
        matchNumber: 'Match 3',
        team1Index: 4,
        team2Index: 5,
        status: TournamentMatchStatus.completed,
        team1Score: 3,
        team2Score: 2,
        scheduledTime: now.subtract(const Duration(days: 1)),
        actualStart: now.subtract(const Duration(days: 1)),
        actualEnd: now.subtract(const Duration(days: 1)).add(const Duration(minutes: 95)),
        commentary: _buildCommentary(
          teams[4],
          teams[5],
          tournament.sportType,
          isLive: false,
        ),
        result: '${teams[4]} edged ${teams[5]} 3-2',
      ),
    ];
  }

  static List<TournamentTeam> generateTeams(Tournament tournament) {
    final teams = _teamsForSport(tournament.sportType);
    final List<TournamentTeam> standings = [];
    for (var i = 0; i < teams.length && i < 4; i++) {
      standings.add(
        TournamentTeam(
          id: '${tournament.id}_team_$i',
          tournamentId: tournament.id,
          name: teams[i],
          wins: (4 - i).clamp(0, 5),
          draws: i % 2,
          losses: i,
          points: ((4 - i).clamp(0, 5) * 3) + (i % 2),
          goalsFor: 12 - i * 2,
          goalsAgainst: 5 + i,
          playerNames: [
            '${teams[i].split(' ').first} Captain',
            '${teams[i].split(' ').last} Striker',
            'Utility Player ${i + 1}',
          ],
        ),
      );
    }
    return standings;
  }

  static String _roundLabelForSport(SportType sport) {
    switch (sport) {
      case SportType.cricket:
        return 'League Stage';
      case SportType.cycling:
        return 'Stage Race';
      case SportType.tennis:
      case SportType.badminton:
        return 'Center Court';
      case SportType.basketball:
      case SportType.football:
      case SportType.soccer:
        return 'Matchday';
      case SportType.rugby:
      case SportType.hockey:
      case SportType.baseball:
        return 'Regular Season';
      default:
        return 'Main Draw';
    }
  }

  static String _liveStatusLabel(SportType sport) {
    switch (sport) {
      case SportType.cricket:
        return 'Live • 15.2 overs';
      case SportType.cycling:
        return 'Live • Peloton at 62km';
      case SportType.tennis:
        return 'Live • Set 2';
      case SportType.basketball:
        return 'Live • Q3 04:12';
      default:
        return 'Live • Second Half';
    }
  }

  static List<CommentaryEntry> _buildCommentary(
    String team1,
    String team2,
    SportType sport, {
    required bool isLive,
  }) {
    final now = DateTime.now();
    final String play = switch (sport) {
      SportType.cricket => 'smashes a boundary for',
      SportType.cycling => 'accelerates off the front with',
      SportType.basketball => 'drops a three for',
      SportType.tennis => 'aces the serve for',
      SportType.badminton => 'finishes the rally for',
      SportType.football ||
      SportType.soccer => 'slots it home for',
      SportType.hockey => 'nets the puck for',
      SportType.rugby => 'dives over the line for',
      SportType.baseball => 'launches a homer for',
      SportType.volleyball => 'crushes the spike for',
      _ => 'delivers a highlight play for',
    };

    return [
      CommentaryEntry(
        id: '${team1}_c1_${isLive ? 'live' : 'full'}',
        text: '$team1 $play the lead!',
        minute: isLive ? '72\'' : '90+1\'',
        timestamp: now.subtract(Duration(minutes: isLive ? 8 : 120)),
        eventType: 'highlight',
        playerName: '${team1.split(' ').first} Star',
      ),
      CommentaryEntry(
        id: '${team2}_c2_${isLive ? 'live' : 'full'}',
        text: '$team2 respond with relentless pressure.',
        minute: isLive ? '75\'' : '90+3\'',
        timestamp: now.subtract(Duration(minutes: isLive ? 4 : 118)),
        eventType: 'pressure',
        playerName: '${team2.split(' ').first} Captain',
      ),
    ];
  }

  static List<PlayerMatchStats> _buildPlayerStats(
    String teamName,
    SportType sport,
    int score,
  ) {
    final primary = PlayerMatchStats(
      playerId: '${teamName}_star',
      playerName: '${teamName.split(' ').first} Star',
      goals: sport == SportType.cricket ? 0 : score.clamp(0, 5),
      points: sport == SportType.basketball ? score * 2 : 0,
      runs: sport == SportType.cricket ? score * 12 : 0,
      wickets: sport == SportType.cricket ? (score / 2).floor() : 0,
      assists: score > 0 ? 1 : 0,
    );

    final support = PlayerMatchStats(
      playerId: '${teamName}_playmaker',
      playerName: '${teamName.split(' ').last} Playmaker',
      goals: score > 1 ? 1 : 0,
      assists: score.clamp(0, 3),
      points: sport == SportType.basketball ? score : 0,
      runs: sport == SportType.cricket ? score * 8 : 0,
    );

    return [primary, support];
  }
}


