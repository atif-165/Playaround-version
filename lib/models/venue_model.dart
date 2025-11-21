import 'package:cloud_firestore/cloud_firestore.dart';
import 'listing_model.dart';

/// Model for venue-specific data
class VenueModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerProfilePicture;
  final String title;
  final SportType sportType;
  final String description;
  final String location;
  final String? gpsCoordinates;
  final double hourlyRate;
  final List<String> images; // Multiple venue images
  final List<TimeSlot> availableTimeSlots;
  final List<String> availableDays; // ['Monday', 'Tuesday', etc.]
  final List<String> amenities; // ['Parking', 'Changing Rooms', etc.]
  final String? contactInfo; // Optional contact information
  final bool isActive;
  final double averageRating;
  final int totalBookings;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const VenueModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerProfilePicture,
    required this.title,
    required this.sportType,
    required this.description,
    required this.location,
    this.gpsCoordinates,
    required this.hourlyRate,
    this.images = const [],
    required this.availableTimeSlots,
    required this.availableDays,
    this.amenities = const [],
    this.contactInfo,
    this.isActive = true,
    this.averageRating = 0.0,
    this.totalBookings = 0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerProfilePicture': ownerProfilePicture,
      'title': title,
      'sportType': sportType.displayName,
      'description': description,
      'location': location,
      'gpsCoordinates': gpsCoordinates,
      'hourlyRate': hourlyRate,
      'images': images,
      'availableTimeSlots':
          availableTimeSlots.map((slot) => slot.toMap()).toList(),
      'availableDays': availableDays,
      'amenities': amenities,
      'contactInfo': contactInfo,
      'isActive': isActive,
      'averageRating': averageRating,
      'totalBookings': totalBookings,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VenueModel.fromMap(data);
  }

  /// Create from Map
  factory VenueModel.fromMap(Map<String, dynamic> map) {
    return VenueModel(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String,
      ownerProfilePicture: map['ownerProfilePicture'] as String?,
      title: map['title'] as String,
      sportType: SportType.fromString(map['sportType'] as String),
      description: map['description'] as String,
      location: map['location'] as String,
      gpsCoordinates: map['gpsCoordinates'] as String?,
      hourlyRate: (map['hourlyRate'] as num).toDouble(),
      images: List<String>.from(map['images'] as List? ?? []),
      availableTimeSlots: (map['availableTimeSlots'] as List)
          .map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
          .toList(),
      availableDays: List<String>.from(map['availableDays'] as List),
      amenities: List<String>.from(map['amenities'] as List? ?? []),
      contactInfo: map['contactInfo'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalBookings: map['totalBookings'] as int? ?? 0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with updated fields
  VenueModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerProfilePicture,
    String? title,
    SportType? sportType,
    String? description,
    String? location,
    String? gpsCoordinates,
    double? hourlyRate,
    List<String>? images,
    List<TimeSlot>? availableTimeSlots,
    List<String>? availableDays,
    List<String>? amenities,
    String? contactInfo,
    bool? isActive,
    double? averageRating,
    int? totalBookings,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return VenueModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerProfilePicture: ownerProfilePicture ?? this.ownerProfilePicture,
      title: title ?? this.title,
      sportType: sportType ?? this.sportType,
      description: description ?? this.description,
      location: location ?? this.location,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      images: images ?? this.images,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      availableDays: availableDays ?? this.availableDays,
      amenities: amenities ?? this.amenities,
      contactInfo: contactInfo ?? this.contactInfo,
      isActive: isActive ?? this.isActive,
      averageRating: averageRating ?? this.averageRating,
      totalBookings: totalBookings ?? this.totalBookings,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VenueModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VenueModel(id: $id, title: $title, sportType: $sportType, location: $location)';
  }
}

/// Model for venue reviews
class VenueReview {
  final String id;
  final String venueId;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final double rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;

  const VenueReview({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'venueId': venueId,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory VenueReview.fromMap(Map<String, dynamic> map) {
    return VenueReview(
      id: map['id'] as String,
      venueId: map['venueId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userProfilePicture: map['userProfilePicture'] as String?,
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
