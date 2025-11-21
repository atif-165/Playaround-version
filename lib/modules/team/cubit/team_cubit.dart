import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import '../models/team_model.dart';
import '../services/team_service.dart';

part 'team_cubit.freezed.dart';

@freezed
class TeamState with _$TeamState {
  const factory TeamState.initial() = _Initial;
  const factory TeamState.loading() = _Loading;
  const factory TeamState.loaded(List<TeamModel> teams) = _Loaded;
  const factory TeamState.userTeamsLoaded(List<TeamModel> teams) =
      _UserTeamsLoaded;
  const factory TeamState.searchResults(List<TeamModel> teams) = _SearchResults;
  const factory TeamState.teamDetails(TeamModel team) = _TeamDetails;
  const factory TeamState.teamCreated(String teamId) = _TeamCreated;
  const factory TeamState.teamUpdated() = _TeamUpdated;
  const factory TeamState.teamDeleted() = _TeamDeleted;
  const factory TeamState.playerAdded() = _PlayerAdded;
  const factory TeamState.playerRemoved() = _PlayerRemoved;
  const factory TeamState.error(String message) = _Error;
}

class TeamCubit extends Cubit<TeamState> {
  final TeamService _teamService;
  StreamSubscription? _teamsSubscription;
  StreamSubscription? _userTeamsSubscription;

  TeamCubit(this._teamService) : super(const TeamState.initial());

  /// Load teams with optional filters
  void loadTeams({
    SportType? sportType,
    String? city,
    bool? isPublic,
    int limit = 20,
  }) {
    emit(const TeamState.loading());

    _teamsSubscription?.cancel();
    _teamsSubscription = _teamService
        .getTeamsStream(
          sportType: sportType,
          city: city,
          isPublic: isPublic,
          limit: limit,
        )
        .listen(
          (teams) => emit(TeamState.loaded(teams)),
          onError: (error) => emit(TeamState.error(error.toString())),
        );
  }

  /// Load user teams
  void loadUserTeams(String userId) {
    emit(const TeamState.loading());

    _userTeamsSubscription?.cancel();
    _userTeamsSubscription = _teamService.getUserTeamsStream(userId).listen(
          (teams) => emit(TeamState.userTeamsLoaded(teams)),
          onError: (error) => emit(TeamState.error(error.toString())),
        );
  }

  /// Create a new team
  Future<void> createTeam({
    required String name,
    required SportType sportType,
    String? city,
    String? description,
    String? profileImageUrl,
    String? bannerImageUrl,
    bool isPublic = true,
    int? maxPlayers,
  }) async {
    try {
      emit(const TeamState.loading());

      final teamId = await _teamService.createTeam(
        name: name,
        sportType: sportType,
        location: city,
        description: description ?? '',
        teamImageUrl: profileImageUrl,
        backgroundImageUrl: bannerImageUrl,
        isPublic: isPublic,
        maxMembers: maxPlayers ?? 11,
      );

      emit(TeamState.teamCreated(teamId));
    } catch (e) {
      emit(TeamState.error(e.toString()));
    }
  }

  /// Update team details
  Future<void> updateTeam({
    required String teamId,
    String? name,
    String? city,
    String? description,
    String? profileImageUrl,
    String? bannerImageUrl,
    bool? isPublic,
    int? maxPlayers,
  }) async {
    try {
      emit(const TeamState.loading());

      await _teamService.updateTeam(
        teamId: teamId,
        name: name,
        description: description,
        teamImageUrl: profileImageUrl,
        isPublic: isPublic,
        maxMembers: maxPlayers,
      );

      emit(const TeamState.teamUpdated());
    } catch (e) {
      emit(TeamState.error(e.toString()));
    }
  }

  /// Add player to team
  Future<void> addPlayerToTeam({
    required String teamId,
    required String playerId,
    required String playerName,
    String? profileImageUrl,
    TeamRole role = TeamRole.member,
  }) async {
    try {
      emit(const TeamState.loading());

      await _teamService.addPlayerToTeam(
        teamId: teamId,
        playerId: playerId,
        playerName: playerName,
        profileImageUrl: profileImageUrl,
        role: role,
      );

      emit(const TeamState.playerAdded());
    } catch (e) {
      emit(TeamState.error(e.toString()));
    }
  }

  /// Remove player from team
  Future<void> removePlayerFromTeam({
    required String teamId,
    required String playerId,
  }) async {
    try {
      emit(const TeamState.loading());

      await _teamService.removePlayerFromTeam(
        teamId: teamId,
        playerId: playerId,
      );

      emit(const TeamState.playerRemoved());
    } catch (e) {
      emit(TeamState.error(e.toString()));
    }
  }

  /// Search teams
  Future<void> searchTeams(String searchQuery) async {
    try {
      emit(const TeamState.loading());

      final teams = await _teamService.searchTeams(searchQuery);
      emit(TeamState.searchResults(teams));
    } catch (e) {
      emit(TeamState.error(e.toString()));
    }
  }

  /// Get team by ID
  Future<void> getTeamById(String teamId) async {
    try {
      emit(const TeamState.loading());

      final team = await _teamService.getTeamById(teamId);
      if (team != null) {
        emit(TeamState.teamDetails(team));
      } else {
        emit(const TeamState.error('Team not found'));
      }
    } catch (e) {
      emit(TeamState.error(e.toString()));
    }
  }

  /// Delete team
  Future<void> deleteTeam(String teamId) async {
    try {
      emit(const TeamState.loading());

      await _teamService.deleteTeam(teamId);
      emit(const TeamState.teamDeleted());
    } catch (e) {
      emit(TeamState.error(e.toString()));
    }
  }

  /// Clear state
  void clearState() {
    emit(const TeamState.initial());
  }

  @override
  Future<void> close() {
    _teamsSubscription?.cancel();
    _userTeamsSubscription?.cancel();
    return super.close();
  }
}
