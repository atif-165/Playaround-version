import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

/// Geo data model for storing location with geohash
class GeoData {
  final String geohash;
  final GeoPoint geopoint;

  const GeoData({
    required this.geohash,
    required this.geopoint,
  });

  /// Create GeoData from GeoFirePoint
  factory GeoData.fromGeoFirePoint(GeoFirePoint geoFirePoint) {
    final data = geoFirePoint.data;
    return GeoData(
      geohash: data['geohash'] as String,
      geopoint: data['geopoint'] as GeoPoint,
    );
  }

  /// Create GeoData from Firestore map
  factory GeoData.fromMap(Map<String, dynamic> map) {
    return GeoData(
      geohash: map['geohash'] as String,
      geopoint: map['geopoint'] as GeoPoint,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'geohash': geohash,
      'geopoint': geopoint,
    };
  }

  /// Create GeoFirePoint from this GeoData
  GeoFirePoint toGeoFirePoint() {
    return GeoFirePoint(geopoint);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoData &&
        other.geohash == geohash &&
        other.geopoint == geopoint;
  }

  @override
  int get hashCode => geohash.hashCode ^ geopoint.hashCode;

  @override
  String toString() => 'GeoData(geohash: $geohash, geopoint: $geopoint)';
}

/// Extended venue model with geo location support
class GeoVenue {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerProfilePicture;
  final String title;
  final String sportType;
  final String description;
  final String location; // String location for display
  final GeoData? geoLocation; // Actual geo coordinates
  final double hourlyRate;
  final List<String> images;
  final List<String> availableDays;
  final List<String> amenities;
  final String? contactInfo;
  final bool isActive;
  final double averageRating;
  final int totalBookings;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeoVenue({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerProfilePicture,
    required this.title,
    required this.sportType,
    required this.description,
    required this.location,
    this.geoLocation,
    required this.hourlyRate,
    this.images = const [],
    required this.availableDays,
    this.amenities = const [],
    this.contactInfo,
    this.isActive = true,
    this.averageRating = 0.0,
    this.totalBookings = 0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory GeoVenue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    GeoData? geoLocation;
    if (data['geoLocation'] != null) {
      geoLocation =
          GeoData.fromMap(data['geoLocation'] as Map<String, dynamic>);
    }

    return GeoVenue(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerProfilePicture: data['ownerProfilePicture'],
      title: data['title'] ?? '',
      sportType: data['sportType'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      geoLocation: geoLocation,
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      images: List<String>.from(data['images'] ?? []),
      availableDays: List<String>.from(data['availableDays'] ?? []),
      amenities: List<String>.from(data['amenities'] ?? []),
      contactInfo: data['contactInfo'],
      isActive: data['isActive'] ?? true,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalBookings: data['totalBookings'] ?? 0,
      totalReviews: data['totalReviews'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerProfilePicture': ownerProfilePicture,
      'title': title,
      'sportType': sportType,
      'description': description,
      'location': location,
      'geoLocation': geoLocation?.toMap(),
      'hourlyRate': hourlyRate,
      'images': images,
      'availableDays': availableDays,
      'amenities': amenities,
      'contactInfo': contactInfo,
      'isActive': isActive,
      'averageRating': averageRating,
      'totalBookings': totalBookings,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get GeoPoint for distance calculations
  GeoPoint? get geoPoint => geoLocation?.geopoint;
}

/// Extended team model with geo location support
class GeoTeam {
  final String id;
  final String name;
  final String description;
  final String sportType;
  final String ownerId;
  final int maxMembers;
  final int currentMembersCount;
  final bool isPublic;
  final String? teamImageUrl;
  final String location; // String location for display
  final GeoData? geoLocation; // Actual geo coordinates
  final double? skillAverage; // Average skill level of team
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const GeoTeam({
    required this.id,
    required this.name,
    required this.description,
    required this.sportType,
    required this.ownerId,
    this.maxMembers = 11,
    this.currentMembersCount = 0,
    this.isPublic = true,
    this.teamImageUrl,
    required this.location,
    this.geoLocation,
    this.skillAverage,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Create from Firestore document
  factory GeoTeam.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    GeoData? geoLocation;
    if (data['geoLocation'] != null) {
      geoLocation =
          GeoData.fromMap(data['geoLocation'] as Map<String, dynamic>);
    }

    return GeoTeam(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sportType: data['sportType'] ?? '',
      ownerId: data['ownerId'] ?? '',
      maxMembers: data['maxMembers'] ?? 11,
      currentMembersCount: data['currentMembersCount'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      teamImageUrl: data['teamImageUrl'],
      location: data['location'] ?? '',
      geoLocation: geoLocation,
      skillAverage: (data['skillAverage'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'sportType': sportType,
      'ownerId': ownerId,
      'maxMembers': maxMembers,
      'currentMembersCount': currentMembersCount,
      'isPublic': isPublic,
      'teamImageUrl': teamImageUrl,
      'location': location,
      'geoLocation': geoLocation?.toMap(),
      'skillAverage': skillAverage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Get GeoPoint for distance calculations
  GeoPoint? get geoPoint => geoLocation?.geopoint;
}

/// Extended player model with geo location and skill scores
class GeoPlayer {
  final String uid;
  final String fullName;
  final String? profilePictureUrl;
  final List<String> sportsOfInterest;
  final String location; // String location for display
  final GeoData? geoLocation; // Actual geo coordinates
  final Map<String, int> skillScores; // Sport -> skill score mapping
  final List<String> availability; // Time slots when available
  final int age;
  final String gender;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const GeoPlayer({
    required this.uid,
    required this.fullName,
    this.profilePictureUrl,
    required this.sportsOfInterest,
    required this.location,
    this.geoLocation,
    this.skillScores = const {},
    this.availability = const [],
    required this.age,
    required this.gender,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Create from Firestore document
  factory GeoPlayer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    GeoData? geoLocation;
    if (data['geoLocation'] != null) {
      geoLocation =
          GeoData.fromMap(data['geoLocation'] as Map<String, dynamic>);
    }

    return GeoPlayer(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      sportsOfInterest: List<String>.from(data['sportsOfInterest'] ?? []),
      location: data['location'] ?? '',
      geoLocation: geoLocation,
      skillScores: Map<String, int>.from(data['skillScores'] ?? {}),
      availability: List<String>.from(data['availability'] ?? []),
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'profilePictureUrl': profilePictureUrl,
      'sportsOfInterest': sportsOfInterest,
      'location': location,
      'geoLocation': geoLocation?.toMap(),
      'skillScores': skillScores,
      'availability': availability,
      'age': age,
      'gender': gender,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Get GeoPoint for distance calculations
  GeoPoint? get geoPoint => geoLocation?.geopoint;

  /// Get average skill score across all sports
  double get averageSkillScore {
    if (skillScores.isEmpty) return 0.0;
    final total = skillScores.values.reduce((a, b) => a + b);
    return total / skillScores.length;
  }

  /// Get skill score for specific sport
  int getSkillScore(String sport) {
    return skillScores[sport] ?? 0;
  }
}

/// Extended tournament model with geo location
class GeoTournament {
  final String id;
  final String name;
  final String description;
  final String sportType;
  final String organizerId;
  final String organizerName;
  final DateTime registrationStartDate;
  final DateTime registrationEndDate;
  final DateTime startDate;
  final DateTime? endDate;
  final int maxTeams;
  final int currentTeamsCount;
  final String location; // String location for display
  final GeoData? geoLocation; // Actual geo coordinates
  final String? venueId;
  final String? venueName;
  final String? imageUrl;
  final List<String> rules;
  final bool isPublic;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeoTournament({
    required this.id,
    required this.name,
    required this.description,
    required this.sportType,
    required this.organizerId,
    required this.organizerName,
    required this.registrationStartDate,
    required this.registrationEndDate,
    required this.startDate,
    this.endDate,
    required this.maxTeams,
    this.currentTeamsCount = 0,
    required this.location,
    this.geoLocation,
    this.venueId,
    this.venueName,
    this.imageUrl,
    this.rules = const [],
    this.isPublic = true,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory GeoTournament.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    GeoData? geoLocation;
    if (data['geoLocation'] != null) {
      geoLocation =
          GeoData.fromMap(data['geoLocation'] as Map<String, dynamic>);
    }

    return GeoTournament(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sportType: data['sportType'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      registrationStartDate:
          (data['registrationStartDate'] as Timestamp).toDate(),
      registrationEndDate: (data['registrationEndDate'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      maxTeams: data['maxTeams'] ?? 0,
      currentTeamsCount: data['currentTeamsCount'] ?? 0,
      location: data['location'] ?? '',
      geoLocation: geoLocation,
      venueId: data['venueId'],
      venueName: data['venueName'],
      imageUrl: data['imageUrl'],
      rules: List<String>.from(data['rules'] ?? []),
      isPublic: data['isPublic'] ?? true,
      status: data['status'] ?? 'upcoming',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'sportType': sportType,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'registrationStartDate': Timestamp.fromDate(registrationStartDate),
      'registrationEndDate': Timestamp.fromDate(registrationEndDate),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'maxTeams': maxTeams,
      'currentTeamsCount': currentTeamsCount,
      'location': location,
      'geoLocation': geoLocation?.toMap(),
      'venueId': venueId,
      'venueName': venueName,
      'imageUrl': imageUrl,
      'rules': rules,
      'isPublic': isPublic,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get GeoPoint for distance calculations
  GeoPoint? get geoPoint => geoLocation?.geopoint;

  /// Check if registration is open
  bool get isRegistrationOpen {
    final now = DateTime.now();
    return now.isAfter(registrationStartDate) &&
        now.isBefore(registrationEndDate);
  }

  /// Check if tournament has started
  bool get hasStarted {
    return DateTime.now().isAfter(startDate);
  }
}
