import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/booking_model.dart' as booking;
import '../models/listing_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/venue_model.dart';

class MockDataSource {
  MockDataSource(
      {this.matchmakingPath = 'mocks/matchmaking.json',
      this.listingsPath = 'mocks/listings.json'});

  final String matchmakingPath;
  final String listingsPath;

  Future<Map<String, dynamic>> _loadJson(String path) async {
    final raw = await rootBundle.loadString(path);
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<List<PlayerModel>> loadPlayers() async {
    final data = await _loadJson(matchmakingPath);
    final players = data['players'] as List<dynamic>? ?? const [];
    return players
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeamModel>> loadTeams() async {
    final data = await _loadJson(matchmakingPath);
    final teams = data['teams'] as List<dynamic>? ?? const [];
    return teams
        .map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VenueModel>> loadVenues() async {
    final data = await _loadJson(matchmakingPath);
    final venues = data['venues'] as List<dynamic>? ?? const [];
    return venues
        .map((e) => VenueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ListingModel>> loadListings() async {
    final data = await _loadJson(listingsPath);
    final listings = data['listings'] as List<dynamic>? ?? const [];
    return listings
        .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<booking.BookingModel>> loadBookings() async {
    final data = await _loadJson(listingsPath);
    final bookings = data['bookings'] as List<dynamic>? ?? const [];
    return bookings
        .map((e) => booking.BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
