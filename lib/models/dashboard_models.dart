import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart';

/// Dashboard statistics model for displaying user progress and activity
class DashboardStats {
  final int sessionsThisMonth;
  final int hoursTrained;
  final int skillPoints;
  final int matchesPlayed;
  final int teamsJoined;
  final int tournamentsParticipated;
  final double averageRating;
  final int totalBookings;

  const DashboardStats({
    required this.sessionsThisMonth,
    required this.hoursTrained,
    required this.skillPoints,
    required this.matchesPlayed,
    required this.teamsJoined,
    required this.tournamentsParticipated,
    required this.averageRating,
    required this.totalBookings,
  });

  factory DashboardStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return DashboardStats(
      sessionsThisMonth: data?['sessionsThisMonth'] ?? 0,
      hoursTrained: data?['hoursTrained'] ?? 0,
      skillPoints: data?['skillPoints'] ?? 0,
      matchesPlayed: data?['matchesPlayed'] ?? 0,
      teamsJoined: data?['teamsJoined'] ?? 0,
      tournamentsParticipated: data?['tournamentsParticipated'] ?? 0,
      averageRating: (data?['averageRating'] ?? 0.0).toDouble(),
      totalBookings: data?['totalBookings'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionsThisMonth': sessionsThisMonth,
      'hoursTrained': hoursTrained,
      'skillPoints': skillPoints,
      'matchesPlayed': matchesPlayed,
      'teamsJoined': teamsJoined,
      'tournamentsParticipated': tournamentsParticipated,
      'averageRating': averageRating,
      'totalBookings': totalBookings,
    };
  }

  /// Create empty stats for new users
  factory DashboardStats.empty() {
    return const DashboardStats(
      sessionsThisMonth: 0,
      hoursTrained: 0,
      skillPoints: 0,
      matchesPlayed: 0,
      teamsJoined: 0,
      tournamentsParticipated: 0,
      averageRating: 0.0,
      totalBookings: 0,
    );
  }
}

/// Event discovery model for dashboard event cards
class DashboardEvent {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime dateTime;
  final String location;
  final String eventType; // tournament, training, match, etc.
  final double? price;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> sportsInvolved;
  final String organizerId;
  final String organizerName;
  final bool isBookmarked;

  const DashboardEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.dateTime,
    required this.location,
    required this.eventType,
    this.price,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.sportsInvolved,
    required this.organizerId,
    required this.organizerName,
    this.isBookmarked = false,
  });

  factory DashboardEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // Handle null document data
    if (data == null) {
      throw Exception('Document data is null for event ${doc.id}');
    }

    // Handle dateTime field safely
    DateTime eventDateTime;
    try {
      final dateTimeData = data['dateTime'];
      if (dateTimeData is Timestamp) {
        eventDateTime = dateTimeData.toDate();
      } else if (dateTimeData is String) {
        eventDateTime = DateTime.parse(dateTimeData);
      } else {
        // Fallback to current time if dateTime is null or invalid
        eventDateTime = DateTime.now();
      }
    } catch (e) {
      // Fallback to current time if parsing fails
      eventDateTime = DateTime.now();
    }

    return DashboardEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      dateTime: eventDateTime,
      location: data['location'] ?? '',
      eventType: data['eventType'] ?? '',
      price: data['price']?.toDouble(),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      sportsInvolved: List<String>.from(data['sportsInvolved'] ?? []),
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      isBookmarked: data['isBookmarked'] ?? false,
    );
  }

  bool get isAvailable => currentParticipants < maxParticipants;
  bool get isFull => currentParticipants >= maxParticipants;
  String get availabilityText => '$currentParticipants/$maxParticipants spots';
}

/// Featured coach model for dashboard coach carousel
class FeaturedCoach {
  final String id;
  final String fullName;
  final String profilePictureUrl;
  final List<String> specializations;
  final double rating;
  final int reviewCount;
  final double hourlyRate;
  final String bio;
  final String location;
  final int experienceYears;
  final bool isAvailable;
  final List<String> certifications;

  const FeaturedCoach({
    required this.id,
    required this.fullName,
    required this.profilePictureUrl,
    required this.specializations,
    required this.rating,
    required this.reviewCount,
    required this.hourlyRate,
    required this.bio,
    required this.location,
    required this.experienceYears,
    required this.isAvailable,
    required this.certifications,
  });

  factory FeaturedCoach.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeaturedCoach(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      specializations: List<String>.from(data['specializationSports'] ?? []),
      rating: (data['averageRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
      bio: data['bio'] ?? '',
      location: data['location'] ?? '',
      experienceYears: data['experienceYears'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      certifications: List<String>.from(data['certifications'] ?? []),
    );
  }

  String get specializationsText => specializations.join(', ');
  String get experienceText => '$experienceYears years experience';
  String get ratingText => '$rating ($reviewCount reviews)';
}

/// Matchmaking suggestion model for swipeable cards
class MatchmakingSuggestion {
  final String id;
  final String fullName;
  final String profilePictureUrl;
  final UserRole role;
  final List<String> sportsOfInterest;
  final String location;
  final int age;
  final SkillLevel? skillLevel;
  final String bio;
  final double compatibilityScore;
  final List<String> commonInterests;
  final double distance; // in kilometers

  const MatchmakingSuggestion({
    required this.id,
    required this.fullName,
    required this.profilePictureUrl,
    required this.role,
    required this.sportsOfInterest,
    required this.location,
    required this.age,
    this.skillLevel,
    required this.bio,
    required this.compatibilityScore,
    required this.commonInterests,
    required this.distance,
  });

  factory MatchmakingSuggestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchmakingSuggestion(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == data['role'],
        orElse: () => UserRole.player,
      ),
      sportsOfInterest: List<String>.from(data['sportsOfInterest'] ?? []),
      location: data['location'] ?? '',
      age: data['age'] ?? 0,
      skillLevel: data['skillLevel'] != null
          ? SkillLevel.values.firstWhere(
              (level) => level.toString().split('.').last == data['skillLevel'],
              orElse: () => SkillLevel.beginner,
            )
          : null,
      bio: data['bio'] ?? '',
      compatibilityScore: (data['compatibilityScore'] ?? 0.0).toDouble(),
      commonInterests: List<String>.from(data['commonInterests'] ?? []),
      distance: (data['distance'] ?? 0.0).toDouble(),
    );
  }

  String get sportsText => sportsOfInterest.join(', ');
  String get distanceText => '${distance.toStringAsFixed(1)} km away';
  String get compatibilityText => '${(compatibilityScore * 100).toInt()}% match';
}

/// Shop product model for dashboard shop integration
class ShopProduct {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String category;
  final List<String> tags;
  final double rating;
  final int reviewCount;
  final bool isOnSale;
  final bool isRecommended;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.tags,
    required this.rating,
    required this.reviewCount,
    this.isOnSale = false,
    this.isRecommended = false,
  });

  factory ShopProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopProduct(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      originalPrice: data['originalPrice']?.toDouble(),
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isOnSale: data['isOnSale'] ?? false,
      isRecommended: data['isRecommended'] ?? false,
    );
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  double get discountPercentage => hasDiscount 
      ? ((originalPrice! - price) / originalPrice! * 100) 
      : 0.0;
  String get priceText => '\$${price.toStringAsFixed(2)}';
  String get originalPriceText => originalPrice != null 
      ? '\$${originalPrice!.toStringAsFixed(2)}' 
      : '';
}
