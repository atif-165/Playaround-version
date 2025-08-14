import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

/// Service for handling location-based operations
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final loc.Location _location = loc.Location();
  GeoPoint? _currentLocation;

  /// Get current user location with permission handling
  Future<GeoPoint?> getCurrentLocation() async {
    try {
      // Check and request location permissions
      final permissionStatus = await Permission.location.request();
      if (permissionStatus != PermissionStatus.granted) {
        if (kDebugMode) {
          debugPrint('🚫 LocationService: Location permission denied');
        }
        return null;
      }

      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          if (kDebugMode) {
            debugPrint('🚫 LocationService: Location service disabled');
          }
          return null;
        }
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _currentLocation = GeoPoint(position.latitude, position.longitude);
      
      if (kDebugMode) {
        debugPrint('📍 LocationService: Current location - ${position.latitude}, ${position.longitude}');
      }

      return _currentLocation;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ LocationService: Error getting location - $e');
      }
      return null;
    }
  }

  /// Calculate distance between two GeoPoints in kilometers
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert to kilometers
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km away';
    } else {
      return '${distanceKm.round()}km away';
    }
  }

  /// Create GeoFirePoint from GeoPoint
  GeoFirePoint createGeoFirePoint(GeoPoint geoPoint) {
    return GeoFirePoint(geoPoint);
  }

  /// Get cached current location (may be null if not fetched yet)
  GeoPoint? get cachedCurrentLocation => _currentLocation;

  /// Check if location is within radius
  bool isWithinRadius(GeoPoint center, GeoPoint target, double radiusKm) {
    final distance = calculateDistance(center, target);
    return distance <= radiusKm;
  }

  /// Sort list of items by distance from current location
  List<T> sortByDistance<T>(
    List<T> items,
    GeoPoint fromLocation,
    GeoPoint Function(T item) getLocationFromItem,
  ) {
    final itemsWithDistance = items.map((item) {
      final itemLocation = getLocationFromItem(item);
      final distance = calculateDistance(fromLocation, itemLocation);
      return MapEntry(item, distance);
    }).toList();

    // Sort by distance
    itemsWithDistance.sort((a, b) => a.value.compareTo(b.value));

    return itemsWithDistance.map((entry) => entry.key).toList();
  }

  /// Get approximate location from string (for existing data migration)
  /// This is a simple implementation - in production you'd use a geocoding service
  GeoPoint? getApproximateLocationFromString(String locationString) {
    // Simple mapping for common locations - extend as needed
    final locationMap = {
      'mumbai': const GeoPoint(19.0760, 72.8777),
      'delhi': const GeoPoint(28.7041, 77.1025),
      'bangalore': const GeoPoint(12.9716, 77.5946),
      'chennai': const GeoPoint(13.0827, 80.2707),
      'hyderabad': const GeoPoint(17.3850, 78.4867),
      'pune': const GeoPoint(18.5204, 73.8567),
      'kolkata': const GeoPoint(22.5726, 88.3639),
      'ahmedabad': const GeoPoint(23.0225, 72.5714),
    };

    final key = locationString.toLowerCase().trim();
    return locationMap[key];
  }
}
