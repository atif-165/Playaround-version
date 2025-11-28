import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/venue_model.dart';

class FirestoreMatchmakingDataSource {
  FirestoreMatchmakingDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<PlayerModel>> fetchPlayers({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'player')
        .limit(limit)
        .get();
    return snapshot.docs.map(PlayerModel.fromFirestore).toList();
  }

  Future<List<TeamModel>> fetchTeams({int limit = 50}) async {
    final snapshot = await _firestore.collection('teams').limit(limit).get();
    return snapshot.docs.map(TeamModel.fromFirestore).toList();
  }

  Future<List<VenueModel>> fetchVenues({int? limit}) async {
    Query query = _firestore.collection('venues');
    if (limit != null) {
      query = query.limit(limit);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(VenueModel.fromFirestore).toList();
  }

  Future<List<ListingModel>> fetchListings({int limit = 50}) async {
    final snapshot = await _firestore.collection('listings').limit(limit).get();
    return snapshot.docs.map(ListingModel.fromFirestore).toList();
  }
}
