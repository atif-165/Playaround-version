import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import '../models/tournament_model.dart';
import '../../team/models/team_model.dart';
import '../services/tournament_service.dart';

part 'tournament_cubit.freezed.dart';

@freezed
class TournamentState with _$TournamentState {
  const factory TournamentState.initial() = _Initial;
  const factory TournamentState.loading() = _Loading;
  const factory TournamentState.loaded(List<TournamentModel> tournaments) =
      _Loaded;
  const factory TournamentState.userTournamentsLoaded(
      List<TournamentModel> tournaments) = _UserTournamentsLoaded;
  const factory TournamentState.searchResults(
      List<TournamentModel> tournaments) = _SearchResults;
  const factory TournamentState.tournamentDetails(TournamentModel tournament) =
      _TournamentDetails;
  const factory TournamentState.tournamentCreated(String tournamentId) =
      _TournamentCreated;
  const factory TournamentState.tournamentUpdated() = _TournamentUpdated;
  const factory TournamentState.tournamentDeleted() = _TournamentDeleted;
  const factory TournamentState.teamAdded() = _TeamAdded;
  const factory TournamentState.teamRemoved() = _TeamRemoved;
  const factory TournamentState.statusUpdated() = _StatusUpdated;
  const factory TournamentState.error(String message) = _Error;
}

class TournamentCubit extends Cubit<TournamentState> {
  final TournamentService _tournamentService;
  StreamSubscription? _tournamentsSubscription;
  StreamSubscription? _userTournamentsSubscription;

  TournamentCubit(this._tournamentService)
      : super(const TournamentState.initial());

  /// Load tournaments with optional filters
  void loadTournaments({
    SportType? sportType,
    TournamentType? type,
    TournamentStatus? status,
    String? location,
    bool? isPublic,
    int limit = 20,
  }) {
    emit(const TournamentState.loading());

    _tournamentsSubscription?.cancel();
    _tournamentsSubscription = _tournamentService
        .getTournamentsStream(
          sportType: sportType,
          type: type,
          status: status,
          location: location,
          isPublic: isPublic,
          limit: limit,
        )
        .listen(
          (tournaments) => emit(TournamentState.loaded(tournaments)),
          onError: (error) => emit(TournamentState.error(error.toString())),
        );
  }

  /// Load user tournaments
  void loadUserTournaments(String userId) {
    emit(const TournamentState.loading());

    _userTournamentsSubscription?.cancel();
    _userTournamentsSubscription =
        _tournamentService.getUserTournamentsStream().listen(
              (tournaments) =>
                  emit(TournamentState.userTournamentsLoaded(tournaments)),
              onError: (error) => emit(TournamentState.error(error.toString())),
            );
  }

  /// Create a new tournament
  Future<void> createTournament({
    required String name,
    required TournamentFormat format,
    required SportType sportType,
    required DateTime registrationStartDate,
    required DateTime registrationEndDate,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? imageUrl,
    bool isPublic = true,
    int maxTeams = 8,
    int? minTeams,
    String? location,
    String? venueId,
    String? venueName,
    List<String> rules = const [],
    Map<String, dynamic>? prizes,
    double? entryFee,
    double? winningPrize,
    List<String> qualifyingQuestions = const [],
  }) async {
    try {
      emit(const TournamentState.loading());

      final tournamentId = await _tournamentService.createTournament(
        name: name,
        format: format,
        sportType: sportType,
        registrationStartDate: registrationStartDate,
        registrationEndDate: registrationEndDate,
        startDate: startDate,
        endDate: endDate,
        description: description ?? '',
        imageUrl: imageUrl,
        isPublic: isPublic,
        maxTeams: maxTeams,
        minTeams: minTeams ?? 2,
        location: location,
        venueId: venueId,
        venueName: venueName,
        rules: rules,
        prizes: prizes,
        entryFee: entryFee,
        winningPrize: winningPrize,
        qualifyingQuestions: qualifyingQuestions,
      );

      emit(TournamentState.tournamentCreated(tournamentId));
    } catch (e) {
      emit(TournamentState.error(e.toString()));
    }
  }

  /// Update tournament details
  Future<void> updateTournament({
    required String tournamentId,
    String? name,
    String? description,
    SportType? sportType,
    TournamentFormat? format,
    TournamentStatus? status,
    DateTime? registrationStartDate,
    DateTime? registrationEndDate,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    bool? isPublic,
    int? maxTeams,
    int? minTeams,
    String? location,
    List<String>? rules,
    Map<String, dynamic>? prizes,
  }) async {
    try {
      emit(const TournamentState.loading());

      await _tournamentService.updateTournament(
        tournamentId: tournamentId,
        name: name,
        description: description,
        sportType: sportType,
        format: format,
        status: status,
        registrationStartDate: registrationStartDate,
        registrationEndDate: registrationEndDate,
        startDate: startDate,
        endDate: endDate,
        imageUrl: imageUrl,
        isPublic: isPublic,
        maxTeams: maxTeams,
        minTeams: minTeams,
        location: location,
        rules: rules,
        prizes: prizes,
      );

      emit(const TournamentState.tournamentUpdated());
    } catch (e) {
      emit(TournamentState.error(e.toString()));
    }
  }

  /// Add team to tournament
  Future<void> addTeamToTournament({
    required String tournamentId,
    required String teamId,
  }) async {
    try {
      emit(const TournamentState.loading());

      await _tournamentService.addTeamToTournament(
        tournamentId: tournamentId,
        teamId: teamId,
      );

      emit(const TournamentState.teamAdded());
    } catch (e) {
      emit(TournamentState.error(e.toString()));
    }
  }

  /// Remove team from tournament
  Future<void> removeTeamFromTournament({
    required String tournamentId,
    required String teamId,
  }) async {
    try {
      emit(const TournamentState.loading());

      await _tournamentService.removeTeamFromTournament(
        tournamentId: tournamentId,
        teamId: teamId,
      );

      emit(const TournamentState.teamRemoved());
    } catch (e) {
      emit(TournamentState.error(e.toString()));
    }
  }

  /// Search tournaments
  Future<void> searchTournaments(String searchQuery) async {
    try {
      emit(const TournamentState.loading());

      final tournaments =
          await _tournamentService.searchTournaments(searchQuery);
      emit(TournamentState.searchResults(tournaments));
    } catch (e) {
      emit(TournamentState.error(e.toString()));
    }
  }

  /// Get tournament by ID
  Future<void> getTournamentById(String tournamentId) async {
    try {
      emit(const TournamentState.loading());

      final tournament =
          await _tournamentService.getTournamentById(tournamentId);
      if (tournament != null) {
        emit(TournamentState.tournamentDetails(tournament));
      } else {
        emit(const TournamentState.error('Tournament not found'));
      }
    } catch (e) {
      emit(TournamentState.error(e.toString()));
    }
  }

  /// Update tournament status
  Future<void> updateTournamentStatus({
    required String tournamentId,
    required TournamentStatus status,
  }) async {
    try {
      emit(const TournamentState.loading());

      await _tournamentService.updateTournamentStatus(
        tournamentId,
        status,
      );

      emit(const TournamentState.statusUpdated());
    } catch (e) {
      emit(TournamentState.error(e.toString()));
    }
  }

  /// Delete tournament
  Future<void> deleteTournament(String tournamentId) async {
    try {
      emit(const TournamentState.loading());

      await _tournamentService.deleteTournament(tournamentId);
      emit(const TournamentState.tournamentDeleted());
    } catch (e) {
      emit(TournamentState.error(e.toString()));
    }
  }

  /// Clear state
  void clearState() {
    emit(const TournamentState.initial());
  }

  @override
  Future<void> close() {
    _tournamentsSubscription?.cancel();
    _userTournamentsSubscription?.cancel();
    return super.close();
  }
}
