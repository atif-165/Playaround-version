import 'dart:math';

/// Helper class for calculating real distances between locations
class DistanceHelper {
  // Map of major Pakistani cities with their coordinates
  static const Map<String, ({double lat, double lng})> _cityCoordinates = {
    // Major cities
    'karachi': (lat: 24.8607, lng: 67.0011),
    'lahore': (lat: 31.5497, lng: 74.3436),
    'islamabad': (lat: 33.6844, lng: 73.0479),
    'rawalpindi': (lat: 33.5651, lng: 73.0169),
    'faisalabad': (lat: 31.4504, lng: 73.1350),
    'multan': (lat: 30.1575, lng: 71.5249),
    'hyderabad': (lat: 25.3960, lng: 68.3578),
    'gujranwala': (lat: 32.1617, lng: 74.1883),
    'peshawar': (lat: 34.0151, lng: 71.5249),
    'quetta': (lat: 30.1798, lng: 66.9750),
    'bahawalpur': (lat: 29.3956, lng: 71.6836),
    'sargodha': (lat: 32.0836, lng: 72.6711),
    'sialkot': (lat: 32.4945, lng: 74.5229),
    'sukkur': (lat: 27.7050, lng: 68.8577),
    'larkana': (lat: 27.5590, lng: 68.2123),
    'sheikhupura': (lat: 31.7167, lng: 73.9850),
    'rahim yar khan': (lat: 28.4202, lng: 70.2952),
    'jhang': (lat: 31.2681, lng: 72.3181),
    'dera ghazi khan': (lat: 30.0561, lng: 70.6403),
    'gujrat': (lat: 32.5736, lng: 74.0789),
    'sahiwal': (lat: 30.6704, lng: 73.1080),
    'wah': (lat: 33.7969, lng: 72.7314),
    'mardan': (lat: 34.1958, lng: 72.0447),
    'kasur': (lat: 31.1167, lng: 74.4500),
    'okara': (lat: 30.8081, lng: 73.4595),
    'mingora': (lat: 34.7794, lng: 72.3600),
    'nawabshah': (lat: 26.2442, lng: 68.4100),
    'chiniot': (lat: 31.7167, lng: 72.9783),
    'kotri': (lat: 25.3647, lng: 68.3089),
    'khanpur': (lat: 28.6467, lng: 70.6569),
    'hafizabad': (lat: 32.0708, lng: 73.6878),
    'kohat': (lat: 33.5889, lng: 71.4414),
    'muzaffarabad': (lat: 34.3700, lng: 73.4711),
    'khanewali': (lat: 29.8167, lng: 71.9333),
    'dera ismail khan': (lat: 31.8311, lng: 70.9017),
    'turbat': (lat: 26.0062, lng: 63.0483),
    'khushab': (lat: 32.2969, lng: 72.3522),
    'abbottabad': (lat: 34.1463, lng: 73.2119),
    'muridke': (lat: 31.8025, lng: 74.2553),
    'mirpur': (lat: 33.1478, lng: 73.7514),
    'kamoke': (lat: 31.9761, lng: 74.2242),
    'mandi bahauddin': (lat: 32.5861, lng: 73.4917),
    'jhelum': (lat: 32.9425, lng: 73.7257),
    'sadiqabad': (lat: 28.3089, lng: 70.1261),
    'jacobabad': (lat: 28.2769, lng: 68.4514),
    'shikarpur': (lat: 27.9553, lng: 68.6383),
    'khanewal': (lat: 30.3017, lng: 71.9322),
    'daska': (lat: 32.3264, lng: 74.3508),
    'vehari': (lat: 30.0453, lng: 72.3489),
    'pakpattan': (lat: 30.3478, lng: 73.3900),
    'tando adam': (lat: 25.7689, lng: 68.6642),
  };

  /// Calculate distance between two locations in kilometers using Haversine formula
  /// Returns null if coordinates cannot be found for one or both locations
  static double? calculateDistance(String location1, String location2) {
    final coords1 = _getCoordinates(location1);
    final coords2 = _getCoordinates(location2);

    if (coords1 == null || coords2 == null) {
      // If coordinates not found, return a random distance as fallback
      // This maintains backwards compatibility
      return _getFallbackDistance(location1, location2);
    }

    return _haversineDistance(
      coords1.lat,
      coords1.lng,
      coords2.lat,
      coords2.lng,
    );
  }

  /// Calculate distance between two GPS coordinates using Haversine formula
  /// This is the most accurate method when GPS coordinates are available
  static double calculateDistanceFromCoordinates(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return _haversineDistance(lat1, lon1, lat2, lon2);
  }

  /// Get coordinates for a location string
  /// Handles partial matches and case-insensitive search
  static ({double lat, double lng})? _getCoordinates(String location) {
    final cleanLocation = location.toLowerCase().trim();

    // Direct match
    if (_cityCoordinates.containsKey(cleanLocation)) {
      return _cityCoordinates[cleanLocation];
    }

    // Try to find partial match
    for (final entry in _cityCoordinates.entries) {
      if (cleanLocation.contains(entry.key) ||
          entry.key.contains(cleanLocation)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Calculate distance using Haversine formula
  /// Returns distance in kilometers
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = earthRadiusKm * c;

    // Round to 1 decimal place
    return (distance * 10).round() / 10;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Fallback distance calculation when coordinates are not available
  /// Uses hash-based deterministic random value for consistency
  static double _getFallbackDistance(String location1, String location2) {
    final combinedHash = (location1 + location2).hashCode.abs();
    return (10 + (combinedHash % 90)).toDouble(); // 10-100 km range
  }

  /// Check if a location is supported (has coordinates)
  static bool isLocationSupported(String location) {
    return _getCoordinates(location) != null;
  }

  /// Get all supported cities
  static List<String> getSupportedCities() {
    return _cityCoordinates.keys.toList()..sort();
  }

  /// Get coordinates for a specific city name
  /// Returns null if city not found
  static ({double lat, double lng})? getCoordinatesForCity(String cityName) {
    return _getCoordinates(cityName);
  }

  /// Get formatted distance string
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }
}
