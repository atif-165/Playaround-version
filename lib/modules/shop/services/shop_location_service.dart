import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_location.dart';

class ShopLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'shop_locations';

  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Get all shop locations
  Future<List<ShopLocation>> getAllLocations() async {
    try {
      print('Fetching locations from Firestore collection: $_collection');
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${snapshot.docs.length} documents in Firestore');
      final locations =
          snapshot.docs.map((doc) => ShopLocation.fromFirestore(doc)).toList();
      print('Converted to ${locations.length} ShopLocation objects');

      return locations;
    } catch (e) {
      print('Error fetching locations: $e');
      throw Exception('Failed to fetch locations: $e');
    }
  }

  /// Get locations by category
  Future<List<ShopLocation>> getLocationsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ShopLocation.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch locations by category: $e');
    }
  }

  /// Search locations by title or description
  Future<List<ShopLocation>> searchLocations(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final locations =
          snapshot.docs.map((doc) => ShopLocation.fromFirestore(doc)).toList();

      return locations.where((location) {
        final searchQuery = query.toLowerCase();
        return location.title.toLowerCase().contains(searchQuery) ||
            location.description.toLowerCase().contains(searchQuery) ||
            location.address.toLowerCase().contains(searchQuery) ||
            location.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search locations: $e');
    }
  }

  /// Get locations within a radius
  Future<List<ShopLocation>> getLocationsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // Simple implementation - in production, use GeoFlutterFire for better performance
      final allLocations = await getAllLocations();

      return allLocations.where((location) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          location.latitude,
          location.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby locations: $e');
    }
  }

  /// Add a new location
  Future<String> addLocation(ShopLocation location) async {
    try {
      print('Adding location to Firestore: ${location.title}');
      print('Location data: ${location.toMap()}');
      final docRef =
          await _firestore.collection(_collection).add(location.toMap());
      print('Location added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding location: $e');
      throw Exception('Failed to add location: $e');
    }
  }

  /// Update a location
  Future<void> updateLocation(String locationId, ShopLocation location) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(locationId)
          .update(location.toMap());
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  /// Delete a location (soft delete)
  Future<void> deleteLocation(String locationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(locationId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete location: $e');
    }
  }

  /// Get locations owned by current user
  Future<List<ShopLocation>> getMyLocations() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ShopLocation.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch my locations: $e');
    }
  }

  /// Check if user owns a location
  bool isLocationOwner(ShopLocation location) {
    return location.ownerId == currentUserId;
  }

  /// Get location by ID
  Future<ShopLocation?> getLocationById(String locationId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(locationId).get();
      if (doc.exists) {
        return ShopLocation.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch location: $e');
    }
  }

  /// Get stream of locations for real-time updates
  Stream<List<ShopLocation>> getLocationsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopLocation.fromFirestore(doc))
            .toList());
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
