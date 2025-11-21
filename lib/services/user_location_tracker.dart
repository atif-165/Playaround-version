import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

/// Service for tracking and updating user's real-time GPS location
class UserLocationTracker {
  static final UserLocationTracker _instance = UserLocationTracker._internal();
  factory UserLocationTracker() => _instance;
  UserLocationTracker._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();

  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  GeoPoint? _lastKnownLocation;

  /// Start tracking user location with periodic updates
  /// Updates user's GPS coordinates in Firestore every [intervalMinutes] minutes
  Future<void> startLocationTracking({int intervalMinutes = 5}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          debugPrint('❌ UserLocationTracker: No authenticated user');
        }
        return;
      }

      // Get initial location
      await updateUserLocation();

      // Set up periodic updates
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = Timer.periodic(
        Duration(minutes: intervalMinutes),
        (_) => updateUserLocation(),
      );

      if (kDebugMode) {
        debugPrint(
            '✅ UserLocationTracker: Started tracking (updates every $intervalMinutes minutes)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ UserLocationTracker: Error starting location tracking - $e');
      }
    }
  }

  /// Start real-time location tracking (more frequent updates)
  /// Use this for active features like nearby users
  Future<void> startRealTimeTracking() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Cancel existing subscription
      await _positionStreamSubscription?.cancel();

      // Set up position stream
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update when user moves 100 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _updateLocationInFirestore(
            currentUser.uid,
            position.latitude,
            position.longitude,
          );
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint(
                '❌ UserLocationTracker: Error in position stream - $error');
          }
        },
      );

      if (kDebugMode) {
        debugPrint('✅ UserLocationTracker: Started real-time tracking');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ UserLocationTracker: Error starting real-time tracking - $e');
      }
    }
  }

  /// Stop all location tracking
  void stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    _positionStreamSubscription?.cancel();

    if (kDebugMode) {
      debugPrint('🛑 UserLocationTracker: Stopped tracking');
    }
  }

  /// Update user's location once
  Future<void> updateUserLocation() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        if (kDebugMode) {
          debugPrint('⚠️ UserLocationTracker: Could not get location');
        }
        return;
      }

      await _updateLocationInFirestore(
        currentUser.uid,
        location.latitude,
        location.longitude,
      );

      _lastKnownLocation = location;

      if (kDebugMode) {
        debugPrint(
            '📍 UserLocationTracker: Updated location - ${location.latitude}, ${location.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserLocationTracker: Error updating location - $e');
      }
    }
  }

  /// Update location in Firestore
  Future<void> _updateLocationInFirestore(
    String userId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint(
            '✅ Updated location for user $userId: ($latitude, $longitude)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating location in Firestore: $e');
      }
    }
  }

  /// Get last known location
  GeoPoint? get lastKnownLocation => _lastKnownLocation;

  /// Check if tracking is active
  bool get isTracking => _locationUpdateTimer?.isActive ?? false;

  /// Check if real-time tracking is active
  bool get isRealTimeTracking => _positionStreamSubscription != null;

  /// Get user's current location without updating Firestore
  Future<GeoPoint?> getCurrentLocationOnly() async {
    return await _locationService.getCurrentLocation();
  }

  /// Force update location immediately
  Future<void> forceUpdateLocation() async {
    await updateUserLocation();
  }
}
