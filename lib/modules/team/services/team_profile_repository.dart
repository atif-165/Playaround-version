import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../models/team_profile_models.dart';
import '../models/team_match_model.dart';
import '../models/team_performance.dart';

/// Repository that exposes all team profile data from Firestore with dummy fallbacks.
class TeamProfileRepository {
  TeamProfileRepository._();

  static final TeamProfileRepository _instance = TeamProfileRepository._();

  factory TeamProfileRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _teamDoc(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('_meta');
  }

  CollectionReference<Map<String, dynamic>> _subCollection(
    String teamId,
    String path,
  ) {
    return _firestore.collection('teams').doc(teamId).collection(path);
  }

  /// Stream overview cards - returns empty list if no data exists.
  Stream<List<TeamOverviewCard>> overviewCards(String teamId) {
    return _subCollection(teamId, 'overview_cards').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <TeamOverviewCard>[];
      }
      return snapshot.docs.map(TeamOverviewCard.fromDoc).toList();
    });
  }

  /// Stream achievements for overview/performance sections - returns empty list if no data exists.
  Stream<List<TeamAchievement>> achievements(String teamId) {
    return _subCollection(teamId, 'achievements').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <TeamAchievement>[];
      }
      return snapshot.docs
          .map((doc) => TeamAchievement.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  /// Stream custom stats maintained by admin - returns empty list if no data exists.
  Stream<List<TeamCustomStat>> customStats(String teamId) {
    return _subCollection(teamId, 'custom_stats').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <TeamCustomStat>[];
      }
      return snapshot.docs.map(TeamCustomStat.fromDoc).toList();
    });
  }

  /// Stream upcoming matches for schedule - returns empty list if no data exists.
  Stream<List<TeamMatch>> scheduleMatches(String teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('matches')
        .orderBy('scheduledTime', descending: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <TeamMatch>[];
      }
      return snapshot.docs
          .map((doc) => TeamMatch.fromFireStore(doc, null))
          .toList();
    });
  }

  /// Stream historical venues with pagination support - returns empty list if no data exists.
  Stream<List<TeamHistoryEntry>> historyEntries(
    String teamId, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('teams')
        .doc(teamId)
        .collection('history')
        .orderBy('date', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <TeamHistoryEntry>[];
      }
      return snapshot.docs.map(TeamHistoryEntry.fromDoc).toList();
    });
  }

  /// Stream tournament participation cards - returns empty list if no data exists.
  Stream<List<TeamTournamentEntry>> tournamentEntries(String teamId) {
    return _subCollection(teamId, 'tournaments')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <TeamTournamentEntry>[];
      }
      return snapshot.docs.map(TeamTournamentEntry.fromDoc).toList();
    });
  }

  /// Stream compact player highlight stats - returns empty list if no data exists.
  Stream<List<PlayerHighlightStat>> playerHighlights(String teamId) {
    return _subCollection(teamId, 'player_highlights')
        .orderBy('playerName')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <PlayerHighlightStat>[];
      }
      return snapshot.docs.map(PlayerHighlightStat.fromDoc).toList();
    });
  }

  /// Stream high-level team performance summary - returns empty performance if no data exists.
  Stream<TeamPerformance> teamPerformance(String teamId) {
    return _subCollection(teamId, 'performance')
        .doc('aggregate')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return TeamPerformance(
          teamId: teamId,
          teamName: '',
          lastUpdated: DateTime.now(),
        );
      }
      final data = snapshot.data();
      if (data == null) {
        return TeamPerformance(
          teamId: teamId,
          teamName: '',
          lastUpdated: DateTime.now(),
        );
      }
      try {
        return TeamPerformance.fromMap({
          ...data,
          'teamId': teamId,
          'teamName': data['teamName'] ?? '',
        });
      } catch (error) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to parse team performance: $error');
        }
        return TeamPerformance(
          teamId: teamId,
          teamName: '',
          lastUpdated: DateTime.now(),
        );
      }
    });
  }

  /// Upsert a team achievement document.
  Future<void> saveAchievement(String teamId, TeamAchievement achievement) {
    final ref = _subCollection(teamId, 'achievements').doc(
        achievement.id.isEmpty
            ? _subCollection(teamId, 'achievements').doc().id
            : achievement.id);
    return ref.set(achievement.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAchievement(String teamId, String achievementId) {
    return _subCollection(teamId, 'achievements').doc(achievementId).delete();
  }

  Future<void> saveCustomStat(String teamId, TeamCustomStat stat) {
    final ref = _subCollection(teamId, 'custom_stats').doc(stat.id.isEmpty
        ? _subCollection(teamId, 'custom_stats').doc().id
        : stat.id);
    return ref.set(stat.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCustomStat(String teamId, String statId) {
    return _subCollection(teamId, 'custom_stats').doc(statId).delete();
  }

  Future<void> saveHistoryEntry(String teamId, TeamHistoryEntry entry) {
    final ref = _subCollection(teamId, 'history').doc(entry.id.isEmpty
        ? _subCollection(teamId, 'history').doc().id
        : entry.id);
    return ref.set(entry.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteHistoryEntry(String teamId, String entryId) {
    return _subCollection(teamId, 'history').doc(entryId).delete();
  }

  Future<void> saveTournamentEntry(
    String teamId,
    TeamTournamentEntry entry,
  ) {
    final ref = _subCollection(teamId, 'tournaments').doc(
      entry.id.isEmpty
          ? _subCollection(teamId, 'tournaments').doc().id
          : entry.id,
    );
    return ref.set(entry.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteTournamentEntry(String teamId, String entryId) {
    return _subCollection(teamId, 'tournaments').doc(entryId).delete();
  }

  Future<void> saveTeamMatch(String teamId, TeamMatch match) {
    final ref = _firestore
        .collection('teams')
        .doc(teamId)
        .collection('matches')
        .doc(match.id);
    return ref.set(match.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteMatch(String teamId, String matchId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('matches')
        .doc(matchId)
        .delete();
  }

  Future<void> saveTeamPerformance(
    String teamId,
    TeamPerformance performance,
  ) {
    return _subCollection(teamId, 'performance')
        .doc('aggregate')
        .set(performance.toMap(), SetOptions(merge: true));
  }
}

/// Dummy data helpers for previewing the team profile.
class DummyTeamData {
  static List<TeamOverviewCard> overviewCards(String teamId) {
    return const [
      TeamOverviewCard(
        id: 'wins',
        title: 'Season Wins',
        value: '12',
        trendLabel: '+2 this month',
        trendIsPositive: true,
        description: 'Wins recorded across all competitions',
        iconName: 'emoji_events',
      ),
      TeamOverviewCard(
        id: 'goals',
        title: 'Goals Scored',
        value: '38',
        trendLabel: '+6 recent matches',
        trendIsPositive: true,
        description: 'Total goals scored in the current season',
        iconName: 'sports_soccer',
      ),
      TeamOverviewCard(
        id: 'cleanSheets',
        title: 'Clean Sheets',
        value: '5',
        trendLabel: 'Last 10 games',
        trendIsPositive: true,
        description: 'Matches without conceding a goal',
        iconName: 'shield',
      ),
    ];
  }

  static List<TeamAchievement> achievements(String teamId) {
    final now = DateTime.now();
    return [
      TeamAchievement(
        id: 'championship_${teamId}_2024',
        teamId: teamId,
        title: 'City Championship Winners',
        description:
            'Lifted the city championship trophy with an undefeated run.',
        type: 'tournament_win',
        achievedAt: DateTime(now.year - 1, 11, 12),
      ),
      TeamAchievement(
        id: 'streak_${teamId}',
        teamId: teamId,
        title: '10 Match Winning Streak',
        description: 'Set a new club record with 10 consecutive wins.',
        type: 'record',
        achievedAt: DateTime(now.year, 3, 6),
      ),
    ];
  }

  static List<TeamCustomStat> customStats(String teamId) {
    return const [
      TeamCustomStat(
        id: 'avg_possession',
        label: 'Average Possession',
        value: '58',
        units: '%',
        description: 'Average ball possession over the last 10 games.',
      ),
      TeamCustomStat(
        id: 'training_hours',
        label: 'Training Hours',
        value: '24',
        units: 'hrs/week',
        description: 'Weekly team practice across all squads.',
      ),
    ];
  }

  static List<TeamMatch> scheduleMatches(String teamId) {
    final now = DateTime.now();
    return [
      TeamMatch(
        id: 'match_dummy_1',
        homeTeamId: teamId,
        awayTeamId: 'royal_tigers',
        homeTeam: TeamScore(teamId: teamId, teamName: 'Royal Tigers', score: 0),
        awayTeam:
            TeamScore(teamId: 'riverhawks', teamName: 'Riverhawks', score: 0),
        sportType: SportType.football,
        matchType: TeamMatchType.league,
        status: TeamMatchStatus.scheduled,
        scheduledTime: now.add(const Duration(days: 2)),
        venueName: 'Downtown Arena',
        venueLocation: 'City Center',
        createdAt: now,
      ),
      TeamMatch(
        id: 'match_dummy_2',
        homeTeamId: 'capital_lions',
        awayTeamId: teamId,
        homeTeam: TeamScore(
            teamId: 'capital_lions', teamName: 'Capital Lions', score: 0),
        awayTeam: TeamScore(teamId: teamId, teamName: 'Royal Tigers', score: 0),
        sportType: SportType.football,
        matchType: TeamMatchType.tournament,
        status: TeamMatchStatus.live,
        scheduledTime: now.subtract(const Duration(minutes: 20)),
        actualStartTime: now.subtract(const Duration(minutes: 20)),
        venueName: 'Legends Stadium',
        venueLocation: 'Coastal City',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TeamMatch(
        id: 'match_dummy_3',
        homeTeamId: 'northern_wolves',
        awayTeamId: teamId,
        homeTeam: TeamScore(
            teamId: 'northern_wolves', teamName: 'Northern Wolves', score: 2),
        awayTeam: TeamScore(teamId: teamId, teamName: 'Royal Tigers', score: 3),
        sportType: SportType.football,
        matchType: TeamMatchType.friendly,
        status: TeamMatchStatus.completed,
        scheduledTime: now.subtract(const Duration(days: 6)),
        actualStartTime: now.subtract(const Duration(days: 6, hours: 2)),
        actualEndTime: now.subtract(const Duration(days: 6, hours: 1)),
        result: 'Royal Tigers won 3-2',
        venueName: 'Maple Sports Complex',
        venueLocation: 'Mapleton',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  static List<TeamHistoryEntry> history(String teamId) {
    final now = DateTime.now();
    return [
      TeamHistoryEntry(
        id: 'history_1',
        venue: 'Legends Arena',
        venueId: 'legends_arena',
        opponent: 'Coastal Kings',
        date: DateTime(now.year, now.month - 1, 14),
        matchType: 'League',
        result: 'Won 2-1',
        summary: 'Comeback victory with late winning goal.',
        location: 'Bay City',
        matchId: 'match_dummy_4',
      ),
      TeamHistoryEntry(
        id: 'history_2',
        venue: 'Summit Dome',
        venueId: 'summit_dome',
        opponent: 'Mountain Bears',
        date: DateTime(now.year, now.month - 2, 3),
        matchType: 'Tournament',
        result: 'Lost 0-1',
        summary: 'Semi-final exit in penalty shootout.',
        location: 'Summit Valley',
        matchId: 'match_dummy_5',
      ),
    ];
  }

  static List<TeamTournamentEntry> tournaments(String teamId) {
    final now = DateTime.now();
    return [
      TeamTournamentEntry(
        id: 'tournament_1',
        tournamentName: 'National Cup',
        status: 'In Progress',
        stage: 'Quarter Finals',
        startDate: DateTime(now.year, now.month - 1, 20),
        tournamentId: 'national_cup_2024',
        logoUrl:
            'https://firebasestorage.googleapis.com/v0/b/playaround-app.appspot.com/o/tournaments%2Fnational_cup.png?alt=media',
      ),
      TeamTournamentEntry(
        id: 'tournament_2',
        tournamentName: 'City Premier League',
        status: 'Champions',
        stage: 'Completed',
        startDate: DateTime(now.year - 1, 9, 1),
        tournamentId: 'city_premier_league',
      ),
    ];
  }

  static List<PlayerHighlightStat> playerHighlights(String teamId) {
    return const [
      PlayerHighlightStat(
        playerId: 'player_1',
        playerName: 'Aiden Park',
        avatarUrl: '',
        metrics: {'Goals': 14, 'Assists': 9, 'Rating': 8.7},
      ),
      PlayerHighlightStat(
        playerId: 'player_2',
        playerName: 'Mateo Alvarez',
        metrics: {'Goals': 10, 'Assists': 12, 'Rating': 8.4},
      ),
      PlayerHighlightStat(
        playerId: 'player_3',
        playerName: 'Noah Idris',
        metrics: {'Saves': 52, 'Clean Sheets': 5, 'Rating': 7.9},
      ),
    ];
  }

  static TeamPerformance teamPerformance(String teamId) {
    final now = DateTime.now();
    return TeamPerformance(
      teamId: teamId,
      teamName: 'Royal Tigers',
      totalMatches: 24,
      wins: 16,
      losses: 5,
      draws: 3,
      winPercentage: 66.7,
      totalGoalsScored: 52,
      totalGoalsConceded: 28,
      cleanSheets: 6,
      averageGoalsPerMatch: 2.1,
      topScorers: const ['player_1', 'player_2'],
      topAssists: const ['player_2', 'player_4'],
      achievements: const {
        'recent': 'National Cup Quarter-finalists',
      },
      lastUpdated: now,
    );
  }
}

