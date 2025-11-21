import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/booking_model.dart' as data;
import '../models/listing_model.dart';
import '../models/match_decision_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/venue_model.dart';
import 'hive_boxes.dart';

class SyncManager {
  SyncManager._();

  static final SyncManager instance = SyncManager._();

  bool _initialized = false;
  Box<dynamic>? _matchDecisionBox;
  Box<dynamic>? _bookingBox;
  Box<dynamic>? _profileBox;

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    if (!Hive.isBoxOpen(HiveBoxes.matchmakingDecisions)) {
      _matchDecisionBox =
          await Hive.openBox<dynamic>(HiveBoxes.matchmakingDecisions);
    } else {
      _matchDecisionBox = Hive.box<dynamic>(HiveBoxes.matchmakingDecisions);
    }

    if (!Hive.isBoxOpen(HiveBoxes.bookings)) {
      _bookingBox = await Hive.openBox<dynamic>(HiveBoxes.bookings);
    } else {
      _bookingBox = Hive.box<dynamic>(HiveBoxes.bookings);
    }

    if (!Hive.isBoxOpen(HiveBoxes.matchmakingProfiles)) {
      _profileBox = await Hive.openBox<dynamic>(HiveBoxes.matchmakingProfiles);
    } else {
      _profileBox = Hive.box<dynamic>(HiveBoxes.matchmakingProfiles);
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    await _matchDecisionBox?.close();
    await _bookingBox?.close();
    await _profileBox?.close();
  }

  Future<void> enqueueMatchDecision(MatchDecisionModel decision) async {
    await _matchDecisionBox?.put(decision.id, decision.toJson());
  }

  List<MatchDecisionModel> getPendingMatchDecisions() {
    final box = _matchDecisionBox;
    if (box == null) return [];
    return box.keys
        .map((key) => box.get(key))
        .whereType<Map>()
        .map((dynamic json) => MatchDecisionModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .where((decision) => !decision.synced)
        .toList();
  }

  Future<void> markMatchDecisionSynced(String decisionId) async {
    final box = _matchDecisionBox;
    if (box == null) return;
    final stored = box.get(decisionId);
    if (stored is Map) {
      final model = MatchDecisionModel.fromJson(
        Map<String, dynamic>.from(stored),
      ).markSynced();
      await box.put(decisionId, model.toJson());
    }
  }

  Future<void> enqueueBooking(data.BookingModel booking) async {
    await _bookingBox?.put(booking.id, booking.toJson());
  }

  List<data.BookingModel> getPendingBookings() {
    final box = _bookingBox;
    if (box == null) return [];
    return box.keys
        .map((key) => box.get(key))
        .whereType<Map>()
        .map((dynamic json) => data.BookingModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .where((booking) =>
            booking.status == data.BookingStatusType.pending ||
            booking.status == data.BookingStatusType.confirmed)
        .toList();
  }

  Future<void> markBookingSynced(
      String bookingId, data.BookingModel booking) async {
    final box = _bookingBox;
    if (box == null) return;
    await box.put(bookingId, booking.toJson());
  }

  Future<void> cacheBookings(List<data.BookingModel> bookings) async {
    final box = _bookingBox;
    if (box == null) return;
    for (final booking in bookings) {
      await box.put(booking.id, booking.toJson());
    }
  }

  List<data.BookingModel> getCachedBookings() {
    final box = _bookingBox;
    if (box == null) return [];
    return box.values
        .whereType<Map>()
        .map((dynamic json) => data.BookingModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  List<data.BookingModel> getCachedBookingsForUser(String userId) {
    return getCachedBookings()
        .where((booking) => booking.userId == userId)
        .toList();
  }

  List<data.BookingModel> getCachedBookingsForProvider(String providerId) {
    return getCachedBookings()
        .where((booking) => booking.providerId == providerId)
        .toList();
  }

  data.BookingModel? getCachedBooking(String bookingId) {
    final box = _bookingBox;
    if (box == null) return null;
    final raw = box.get(bookingId);
    if (raw is Map) {
      return data.BookingModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Future<void> cachePlayers(List<PlayerModel> players) async {
    await _profileBox?.put(
      'players',
      players.map((player) => player.toJson()).toList(),
    );
  }

  List<PlayerModel> getCachedPlayers() {
    final raw = _profileBox?.get('players');
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((dynamic json) => PlayerModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    }
    return [];
  }

  Future<void> cacheTeams(List<TeamModel> teams) async {
    await _profileBox?.put(
      'teams',
      teams.map((team) => team.toJson()).toList(),
    );
  }

  List<TeamModel> getCachedTeams() {
    final raw = _profileBox?.get('teams');
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((dynamic json) => TeamModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    }
    return [];
  }

  Future<void> cacheVenues(List<VenueModel> venues) async {
    await _profileBox?.put(
      'venues',
      venues.map((venue) => venue.toJson()).toList(),
    );
  }

  List<VenueModel> getCachedVenues() {
    final raw = _profileBox?.get('venues');
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((dynamic json) => VenueModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    }
    return [];
  }

  Future<void> cacheListings(List<ListingModel> listings) async {
    await _profileBox?.put(
      'listings',
      listings.map((listing) => listing.toJson()).toList(),
    );
  }

  List<ListingModel> getCachedListings() {
    final raw = _profileBox?.get('listings');
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((dynamic json) => ListingModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    }
    return [];
  }

  Future<void> syncMatchDecisions(
    Future<void> Function(MatchDecisionModel) uploader,
  ) async {
    final pending = getPendingMatchDecisions();
    for (final decision in pending) {
      await uploader(decision);
      await markMatchDecisionSynced(decision.id);
    }
  }

  Future<void> syncBookings(
    Future<void> Function(data.BookingModel) uploader,
  ) async {
    final pending = getPendingBookings();
    for (final booking in pending) {
      await uploader(booking);
      await markBookingSynced(booking.id, booking);
    }
  }
}
