import 'package:cloud_firestore/cloud_firestore.dart';

class VenueReview {
  final String id;
  final String venueId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String title;
  final String comment;
  final List<String> images;
  final List<ReviewCategory> categories;
  final bool isVerified;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int helpfulCount;
  final List<String> helpfulUsers;
  final bool isReported;
  final String? reportReason;

  VenueReview({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.title,
    required this.comment,
    this.images = const [],
    this.categories = const [],
    this.isVerified = false,
    this.bookingId,
    required this.createdAt,
    required this.updatedAt,
    this.helpfulCount = 0,
    this.helpfulUsers = const [],
    this.isReported = false,
    this.reportReason,
  });

  factory VenueReview.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VenueReview(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      title: data['title'] ?? '',
      comment: data['comment'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      categories: (data['categories'] as List<dynamic>?)
          ?.map((e) => ReviewCategory.fromMap(e))
          .toList() ?? [],
      isVerified: data['isVerified'] ?? false,
      bookingId: data['bookingId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      helpfulCount: data['helpfulCount'] ?? 0,
      helpfulUsers: List<String>.from(data['helpfulUsers'] ?? []),
      isReported: data['isReported'] ?? false,
      reportReason: data['reportReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'venueId': venueId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'categories': categories.map((e) => e.toMap()).toList(),
      'isVerified': isVerified,
      'bookingId': bookingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'helpfulCount': helpfulCount,
      'helpfulUsers': helpfulUsers,
      'isReported': isReported,
      'reportReason': reportReason,
    };
  }

  VenueReview copyWith({
    String? id,
    String? venueId,
    String? userId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? title,
    String? comment,
    List<String>? images,
    List<ReviewCategory>? categories,
    bool? isVerified,
    String? bookingId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? helpfulCount,
    List<String>? helpfulUsers,
    bool? isReported,
    String? reportReason,
  }) {
    return VenueReview(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      categories: categories ?? this.categories,
      isVerified: isVerified ?? this.isVerified,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulUsers: helpfulUsers ?? this.helpfulUsers,
      isReported: isReported ?? this.isReported,
      reportReason: reportReason ?? this.reportReason,
    );
  }
}

class ReviewCategory {
  final String name;
  final double rating;
  final String description;

  ReviewCategory({
    required this.name,
    required this.rating,
    required this.description,
  });

  factory ReviewCategory.fromMap(Map<String, dynamic> map) {
    return ReviewCategory(
      name: map['name'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rating': rating,
      'description': description,
    };
  }
}

class VenueFilter {
  final String? searchQuery;
  final String? city;
  final String? state;
  final String? country;
  final List<String> sports;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final List<String> amenities;
  final double? latitude;
  final double? longitude;
  final double? radius; // in kilometers
  final bool? isVerified;
  final bool? hasAvailability;
  final DateTime? availableDate;
  final String? sortBy; // 'rating', 'price', 'distance', 'newest'
  final bool? sortAscending;

  VenueFilter({
    this.searchQuery,
    this.city,
    this.state,
    this.country,
    this.sports = const [],
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.amenities = const [],
    this.latitude,
    this.longitude,
    this.radius,
    this.isVerified,
    this.hasAvailability,
    this.availableDate,
    this.sortBy,
    this.sortAscending,
  });

  VenueFilter copyWith({
    String? searchQuery,
    String? city,
    String? state,
    String? country,
    List<String>? sports,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? amenities,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isVerified,
    bool? hasAvailability,
    DateTime? availableDate,
    String? sortBy,
    bool? sortAscending,
  }) {
    return VenueFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      sports: sports ?? this.sports,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      amenities: amenities ?? this.amenities,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isVerified: isVerified ?? this.isVerified,
      hasAvailability: hasAvailability ?? this.hasAvailability,
      availableDate: availableDate ?? this.availableDate,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'searchQuery': searchQuery,
      'city': city,
      'state': state,
      'country': country,
      'sports': sports,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minRating': minRating,
      'amenities': amenities,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isVerified': isVerified,
      'hasAvailability': hasAvailability,
      'availableDate': availableDate?.millisecondsSinceEpoch,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
    };
  }

  factory VenueFilter.fromMap(Map<String, dynamic> map) {
    return VenueFilter(
      searchQuery: map['searchQuery'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
      sports: List<String>.from(map['sports'] ?? []),
      minPrice: map['minPrice']?.toDouble(),
      maxPrice: map['maxPrice']?.toDouble(),
      minRating: map['minRating']?.toDouble(),
      amenities: List<String>.from(map['amenities'] ?? []),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      radius: map['radius']?.toDouble(),
      isVerified: map['isVerified'],
      hasAvailability: map['hasAvailability'],
      availableDate: map['availableDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['availableDate'])
          : null,
      sortBy: map['sortBy'],
      sortAscending: map['sortAscending'],
    );
  }

  /// Check if any filters are active
  bool get isActive {
    return searchQuery != null ||
        city != null ||
        state != null ||
        country != null ||
        sports.isNotEmpty ||
        minPrice != null ||
        maxPrice != null ||
        minRating != null ||
        amenities.isNotEmpty ||
        isVerified != null ||
        hasAvailability != null ||
        availableDate != null ||
        sortBy != null;
  }
}
