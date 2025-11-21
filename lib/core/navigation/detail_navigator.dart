import 'package:flutter/material.dart';

import '../../modules/coach/screens/coach_detail_screen.dart';
import '../../modules/coach/services/coach_service.dart';
import '../../modules/matchmaking/models/matchmaking_model.dart';
import '../../modules/matchmaking/screens/match_profile_detail_screen.dart';
import '../../modules/team/models/team_model.dart';
import '../../modules/team/models/team_match_model.dart' as team_models;
import '../../modules/team/screens/team_profile_screen.dart';
import '../../modules/team/services/team_service.dart';
import '../../modules/tournament/models/tournament_match_model.dart';
import '../../modules/tournament/models/tournament_model.dart';
import '../../modules/tournament/screens/live_match_detail_screen.dart';
import '../../modules/tournament/screens/tournament_detail_screen.dart';
import '../../modules/tournament/services/tournament_match_service.dart';
import '../../modules/tournament/services/tournament_service.dart';
import '../../screens/venue/venue_profile_screen.dart';
import '../../routing/routes.dart';
import '../../models/coach_profile.dart';
import '../../models/player_profile.dart';
import '../../models/user_profile.dart';
import '../../models/venue.dart';
import '../../repositories/user_repository.dart';
import '../../services/venue_service.dart';

/// Centralised navigation helpers for opening detail screens safely.
class DetailNavigator {
  DetailNavigator._();

  static final TeamService _teamService = TeamService();
  static final CoachService _coachService = CoachService();
  static final TournamentService _tournamentService = TournamentService();
  static final TournamentMatchService _matchService = TournamentMatchService();
  static final UserRepository _userRepository = UserRepository();

  static Future<bool> openTeam(
    BuildContext context, {
    TeamModel? team,
    String? teamId,
  }) async {
    final resolvedTeam = team;
    final resolvedId = team?.id ?? teamId;

    if (resolvedTeam != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TeamProfileScreen(team: resolvedTeam),
        ),
      );
      return true;
    }

    if (resolvedId == null || resolvedId.isEmpty) {
      _showSnack(context, 'Team details are not linked yet.');
      return false;
    }

    try {
      final fetched = await _teamService.getTeamById(resolvedId);
      if (fetched == null) {
        _showSnack(context, 'Team could not be found.');
        return false;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TeamProfileScreen(team: fetched),
        ),
      );
      return true;
    } catch (error) {
      _showSnack(context, 'Unable to open team right now.');
      return false;
    }
  }

  static Future<bool> openCoach(
    BuildContext context, {
    CoachProfile? coach,
    String? coachId,
  }) async {
    final resolvedCoach = coach;
    final resolvedId = coach?.uid ?? coachId;

    if (resolvedCoach != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoachDetailScreen(coach: resolvedCoach),
        ),
      );
      return true;
    }

    if (resolvedId == null || resolvedId.isEmpty) {
      _showSnack(context, 'Coach profile is not available.');
      return false;
    }

    try {
      final fetched = await _coachService.getCoach(resolvedId);
      if (fetched == null) {
        _showSnack(context, 'Coach profile was not found.');
        return false;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoachDetailScreen(coach: fetched),
        ),
      );
      return true;
    } catch (error) {
      _showSnack(context, 'Unable to open coach profile.');
      return false;
    }
  }

  static Future<bool> openPlayer(
    BuildContext context, {
    MatchProfile? profile,
    String? userId,
    String? userName,
  }) async {
      if (userId == null || userId.isEmpty) {
        _showSnack(context, 'Player profile is not linked yet.');
        return false;
      }

    try {
      await Navigator.of(context).pushNamed(
        Routes.communityUserProfile,
        arguments: userId,
      );
      return true;
    } catch (_) {
        _showSnack(context, 'Unable to open player profile.');
        return false;
      }
  }

  static Future<bool> openVenue(
    BuildContext context, {
    Venue? venue,
    String? venueId,
  }) async {
    final resolvedVenue = venue;
    final resolvedId = venue?.id ?? venueId;

    if (resolvedVenue != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenueProfileScreen(venue: resolvedVenue),
        ),
      );
      return true;
    }

    if (resolvedId == null || resolvedId.isEmpty) {
      _showSnack(context, 'Venue details are not available yet.');
      return false;
    }

    try {
      final fetched = await VenueService.getVenueById(resolvedId);
      if (fetched == null) {
        _showSnack(context, 'Venue could not be found.');
        return false;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenueProfileScreen(venue: fetched),
        ),
      );
      return true;
    } catch (error) {
      _showSnack(context, 'Unable to open venue right now.');
      return false;
    }
  }

  static Future<bool> openTournament(
    BuildContext context, {
    Tournament? tournament,
    String? tournamentId,
  }) async {
    final resolvedTournament = tournament;
    final resolvedId = tournament?.id ?? tournamentId;

    if (resolvedTournament != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentDetailScreen(tournament: resolvedTournament),
        ),
      );
      return true;
    }

    if (resolvedId == null || resolvedId.isEmpty) {
      _showSnack(context, 'Tournament details missing.');
      return false;
    }

    try {
      final fetched = await _tournamentService.getTournament(resolvedId);
      if (fetched == null) {
        _showSnack(context, 'Tournament could not be found.');
        return false;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentDetailScreen(tournament: fetched),
        ),
      );
      return true;
    } catch (error) {
      _showSnack(context, 'Unable to open tournament.');
      return false;
    }
  }

  static Future<bool> openMatch(
    BuildContext context, {
    TournamentMatch? match,
    team_models.TeamMatch? teamMatch,
    String? matchId,
  }) async {
    TournamentMatch? resolvedMatch;

    if (match != null) {
      resolvedMatch = match;
    } else if (teamMatch != null) {
      resolvedMatch = _convertTeamMatch(teamMatch);
    } else if (matchId != null && matchId.isNotEmpty) {
      try {
        resolvedMatch = await _matchService.getMatchById(matchId);
        if (resolvedMatch == null) {
          _showSnack(context, 'Match could not be found.');
          return false;
        }
      } catch (error) {
        _showSnack(context, 'Unable to open match right now.');
        return false;
      }
    } else {
      _showSnack(context, 'Match reference missing.');
      return false;
    }

    Tournament? tournament;
    final tournamentId = resolvedMatch.tournamentId;
    if (tournamentId != null && tournamentId.isNotEmpty) {
      try {
        tournament = await _tournamentService.getTournament(tournamentId);
      } catch (_) {
        // Ignore tournament fetch errors; screen works without it.
      }
    }

    final matchToOpen = resolvedMatch;
    if (matchToOpen == null) {
      _showSnack(context, 'Match details unavailable.');
      return false;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveMatchDetailScreen(
          match: matchToOpen,
          tournament: tournament,
        ),
      ),
    );
    return true;
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static TournamentMatch _convertTeamMatch(team_models.TeamMatch source) {
    final tournamentId = source.tournamentId ?? 'team-${source.id}';
    final tournamentName = source.tournamentName ?? 'Team Fixture';
    return TournamentMatch(
      id: 'team-${source.id}',
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      sportType: source.sportType,
      team1: _convertTeamScore(source.homeTeam),
      team2: _convertTeamScore(source.awayTeam),
      matchNumber: source.metadata?['matchNumber']?.toString() ??
          'Fixture ${source.matchType.displayName}',
      round: source.matchType.displayName,
      scheduledTime: source.scheduledTime,
      actualStartTime: source.actualStartTime,
      actualEndTime: source.actualEndTime,
      status: _mapTeamMatchStatus(source.status),
      commentary: const [],
      result: source.result,
      winnerTeamId: source.winnerTeamId,
      team1PlayerStats: const [],
      team2PlayerStats: const [],
      manOfTheMatch: null,
      team1CoachId: null,
      team1CoachName: null,
      team2CoachId: null,
      team2CoachName: null,
      venueId: source.venueId,
      venueName: source.venueName,
      venueLocation: source.venueLocation,
      backgroundImageUrl: null,
      createdAt: source.createdAt,
      updatedAt: source.actualEndTime ?? source.createdAt,
      createdBy: source.createdBy,
      metadata: source.metadata,
    );
  }

  static TeamMatchScore _convertTeamScore(team_models.TeamScore score) {
    return TeamMatchScore(
      teamId: score.teamId,
      teamName: score.teamName,
      teamLogoUrl: score.teamLogoUrl,
      score: score.score,
      sportSpecificData: score.sportSpecificData,
      playerIds: const [],
    );
  }

  static TournamentMatchStatus _mapTeamMatchStatus(
    team_models.TeamMatchStatus status,
  ) {
    switch (status) {
      case team_models.TeamMatchStatus.scheduled:
        return TournamentMatchStatus.scheduled;
      case team_models.TeamMatchStatus.live:
        return TournamentMatchStatus.live;
      case team_models.TeamMatchStatus.completed:
        return TournamentMatchStatus.completed;
      case team_models.TeamMatchStatus.cancelled:
        return TournamentMatchStatus.cancelled;
    }
  }
}

