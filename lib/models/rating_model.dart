import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for different types of entities that can be rated
enum RatingType {
  coach('coach'),
  player('player'),
  venue('venue');

  const RatingType(this.value);
  final String value;

  static RatingType fromString(String value) {
    return RatingType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RatingType.coach,
    );
  }

  String get displayName {
    switch (this) {
      case RatingType.coach:
        return 'Coach';
      case RatingType.player:
        return 'Player';
      case RatingType.venue:
        return 'Venue';
    }
  }
}

/// Model for individual rating/review
class RatingModel {
  final String id;
  final String bookingId;
  final String ratedEntityId; // ID of coach, player, or venue being rated
  final RatingType ratingType;
  final String ratedBy; // User ID who gave the rating
  final String ratedByName; // Name of user who gave the rating
  final String? ratedByProfilePicture; // Profile picture of rater
  final int stars; // 1-5 star rating
  final String? feedback; // Optional text feedback
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Additional data

  const RatingModel({
    required this.id,
    required this.bookingId,
    required this.ratedEntityId,
    required this.ratingType,
    required this.ratedBy,
    required this.ratedByName,
    this.ratedByProfilePicture,
    required this.stars,
    this.feedback,
    required this.timestamp,
    this.metadata,
  });

  /// Create from Firestore document
  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RatingModel(
      id: doc.id,
      bookingId: data['bookingId'] as String,
      ratedEntityId: data['ratedEntityId'] as String,
      ratingType: RatingType.fromString(data['ratingType'] as String),
      ratedBy: data['ratedBy'] as String,
      ratedByName: data['ratedByName'] as String,
      ratedByProfilePicture: data['ratedByProfilePicture'] as String?,
      stars: data['stars'] as int,
      feedback: data['feedback'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'ratedEntityId': ratedEntityId,
      'ratingType': ratingType.value,
      'ratedBy': ratedBy,
      'ratedByName': ratedByName,
      'ratedByProfilePicture': ratedByProfilePicture,
      'stars': stars,
      'feedback': feedback,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  RatingModel copyWith({
    String? id,
    String? bookingId,
    String? ratedEntityId,
    RatingType? ratingType,
    String? ratedBy,
    String? ratedByName,
    String? ratedByProfilePicture,
    int? stars,
    String? feedback,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return RatingModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      ratedEntityId: ratedEntityId ?? this.ratedEntityId,
      ratingType: ratingType ?? this.ratingType,
      ratedBy: ratedBy ?? this.ratedBy,
      ratedByName: ratedByName ?? this.ratedByName,
      ratedByProfilePicture:
          ratedByProfilePicture ?? this.ratedByProfilePicture,
      stars: stars ?? this.stars,
      feedback: feedback ?? this.feedback,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RatingModel &&
        other.id == id &&
        other.bookingId == bookingId &&
        other.ratedEntityId == ratedEntityId &&
        other.ratingType == ratingType &&
        other.ratedBy == ratedBy &&
        other.stars == stars;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      bookingId,
      ratedEntityId,
      ratingType,
      ratedBy,
      stars,
    );
  }

  @override
  String toString() {
    return 'RatingModel(id: $id, ratedEntityId: $ratedEntityId, ratingType: $ratingType, stars: $stars)';
  }
}

/// Model for aggregated rating statistics
class RatingStats {
  final String entityId;
  final RatingType ratingType;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> starDistribution; // star -> count
  final DateTime lastUpdated;

  const RatingStats({
    required this.entityId,
    required this.ratingType,
    required this.averageRating,
    required this.totalRatings,
    required this.starDistribution,
    required this.lastUpdated,
  });

  /// Create from Firestore document
  factory RatingStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RatingStats(
      entityId: doc.id,
      ratingType: RatingType.fromString(data['ratingType'] as String),
      averageRating: (data['averageRating'] as num).toDouble(),
      totalRatings: data['totalRatings'] as int,
      starDistribution: Map<int, int>.from(data['starDistribution'] as Map),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ratingType': ratingType.value,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'starDistribution': starDistribution,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Create empty stats for new entity
  factory RatingStats.empty(String entityId, RatingType ratingType) {
    return RatingStats(
      entityId: entityId,
      ratingType: ratingType,
      averageRating: 0.0,
      totalRatings: 0,
      starDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      lastUpdated: DateTime.now(),
    );
  }

  /// Update stats with new rating
  RatingStats updateWithNewRating(int newStars) {
    final newTotal = totalRatings + 1;
    final newSum = (averageRating * totalRatings) + newStars;
    final newAverage = newSum / newTotal;

    final newDistribution = Map<int, int>.from(starDistribution);
    newDistribution[newStars] = (newDistribution[newStars] ?? 0) + 1;

    return RatingStats(
      entityId: entityId,
      ratingType: ratingType,
      averageRating: newAverage,
      totalRatings: newTotal,
      starDistribution: newDistribution,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get formatted average rating (e.g., "4.5")
  String get formattedAverage {
    if (totalRatings == 0) return '0.0';
    return averageRating.toStringAsFixed(1);
  }

  /// Get star percentage for a specific star rating
  double getStarPercentage(int stars) {
    if (totalRatings == 0) return 0.0;
    return (starDistribution[stars] ?? 0) / totalRatings * 100;
  }

  @override
  String toString() {
    return 'RatingStats(entityId: $entityId, average: $formattedAverage, total: $totalRatings)';
  }
}

/// Model for pending rating requests
class PendingRatingModel {
  final String id;
  final String bookingId;
  final String userId; // User who needs to give rating
  final String ratedEntityId; // Entity to be rated
  final RatingType ratingType;
  final String entityName; // Name of entity being rated
  final DateTime bookingDate;
  final DateTime createdAt;
  final bool isCompleted;

  const PendingRatingModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.ratedEntityId,
    required this.ratingType,
    required this.entityName,
    required this.bookingDate,
    required this.createdAt,
    required this.isCompleted,
  });

  /// Create from Firestore document
  factory PendingRatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PendingRatingModel(
      id: doc.id,
      bookingId: data['bookingId'] as String,
      userId: data['userId'] as String,
      ratedEntityId: data['ratedEntityId'] as String,
      ratingType: RatingType.fromString(data['ratingType'] as String),
      entityName: data['entityName'] as String,
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'ratedEntityId': ratedEntityId,
      'ratingType': ratingType.value,
      'entityName': entityName,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isCompleted': isCompleted,
    };
  }

  /// Mark as completed
  PendingRatingModel markCompleted() {
    return PendingRatingModel(
      id: id,
      bookingId: bookingId,
      userId: userId,
      ratedEntityId: ratedEntityId,
      ratingType: ratingType,
      entityName: entityName,
      bookingDate: bookingDate,
      createdAt: createdAt,
      isCompleted: true,
    );
  }

  @override
  String toString() {
    return 'PendingRatingModel(id: $id, entityName: $entityName, isCompleted: $isCompleted)';
  }
}
