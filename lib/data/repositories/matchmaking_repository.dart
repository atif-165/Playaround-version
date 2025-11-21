import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../datasources/firestore_matchmaking_data_source.dart';
import '../datasources/mock_data_source.dart';
import '../local/sync_manager.dart';
import '../models/listing_model.dart';
import '../models/match_decision_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/venue_model.dart';

class MatchmakingRepository {
  MatchmakingRepository({
    MockDataSource? mockDataSource,
    FirestoreMatchmakingDataSource? firestoreDataSource,
    SyncManager? syncManager,
    FirebaseFirestore? firestore,
  })  : _mockDataSource = mockDataSource ?? MockDataSource(),
        _firestoreDataSource =
            firestoreDataSource ?? FirestoreMatchmakingDataSource(),
        _syncManager = syncManager ?? SyncManager.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final MockDataSource _mockDataSource;
  final FirestoreMatchmakingDataSource _firestoreDataSource;
  final SyncManager _syncManager;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Future<void> init() async {
    await _syncManager.init();
  }

  Future<List<PlayerModel>> loadPlayers({bool prioritizeRemote = true}) async {
    if (prioritizeRemote) {
      try {
        final players = await _firestoreDataSource.fetchPlayers();
        if (players.isNotEmpty) {
          unawaited(_syncManager.cachePlayers(players));
          return players;
        }
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint(
              '🔀 MatchmakingRepository.loadPlayers remote failed: $error');
          debugPrint(stack.toString());
        }
      }
    }

    final cached = _syncManager.getCachedPlayers();
    if (cached.isNotEmpty) {
      return cached;
    }

    final mockPlayers = await _mockDataSource.loadPlayers();
    unawaited(_syncManager.cachePlayers(mockPlayers));
    return mockPlayers;
  }

  Future<List<TeamModel>> loadTeams({bool prioritizeRemote = true}) async {
    if (prioritizeRemote) {
      try {
        final teams = await _firestoreDataSource.fetchTeams();
        if (teams.isNotEmpty) {
          unawaited(_syncManager.cacheTeams(teams));
          return teams;
        }
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint(
              '🔀 MatchmakingRepository.loadTeams remote failed: $error');
          debugPrint(stack.toString());
        }
      }
    }

    final cached = _syncManager.getCachedTeams();
    if (cached.isNotEmpty) {
      return cached;
    }

    final mockTeams = await _mockDataSource.loadTeams();
    unawaited(_syncManager.cacheTeams(mockTeams));
    return mockTeams;
  }

  Future<List<VenueModel>> loadVenues({bool prioritizeRemote = true}) async {
    if (prioritizeRemote) {
      try {
        final venues = await _firestoreDataSource.fetchVenues();
        if (venues.isNotEmpty) {
          unawaited(_syncManager.cacheVenues(venues));
          return venues;
        }
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint(
              '🔀 MatchmakingRepository.loadVenues remote failed: $error');
          debugPrint(stack.toString());
        }
      }
    }

    final cached = _syncManager.getCachedVenues();
    if (cached.isNotEmpty) {
      return cached;
    }

    final mockVenues = await _mockDataSource.loadVenues();
    unawaited(_syncManager.cacheVenues(mockVenues));
    return mockVenues;
  }

  Future<List<ListingModel>> loadListings(
      {bool prioritizeRemote = true}) async {
    if (prioritizeRemote) {
      try {
        final listings = await _firestoreDataSource.fetchListings();
        if (listings.isNotEmpty) {
          unawaited(_syncManager.cacheListings(listings));
          return listings;
        }
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint(
              '🔀 MatchmakingRepository.loadListings remote failed: $error');
          debugPrint(stack.toString());
        }
      }
    }

    final cached = _syncManager.getCachedListings();
    if (cached.isNotEmpty) {
      return cached;
    }

    final mockListings = await _mockDataSource.loadListings();
    unawaited(_syncManager.cacheListings(mockListings));
    return mockListings;
  }

  Future<void> updateMatchDecision({
    required String swiperId,
    required String targetId,
    required MatchDecisionType decision,
  }) async {
    final model = MatchDecisionModel(
      id: _uuid.v4(),
      swiperId: swiperId,
      targetId: targetId,
      decision: decision,
      timestamp: DateTime.now(),
    );

    await _syncManager.enqueueMatchDecision(model);

    try {
      await _firestore.collection('swipes').doc(model.id).set(model.toJson());
      await _syncManager.markMatchDecisionSynced(model.id);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to sync swipe immediately: $error');
      }
    }
  }

  Future<void> syncMatchDecisions() async {
    await _syncManager.syncMatchDecisions((decision) async {
      await _firestore
          .collection('swipes')
          .doc(decision.id)
          .set(decision.toJson());
    });
  }
}
