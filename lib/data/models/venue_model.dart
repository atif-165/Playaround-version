import 'package:cloud_firestore/cloud_firestore.dart';

class VenueModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? coverImageUrl;
  final List<String> gallery;
  final List<String> sports;
  final Map<String, dynamic> amenities;
  final double rating;
  final int reviewCount;
  final List<String> availability; // e.g. ['mon:08:00-22:00']
  final DateTime createdAt;
  final DateTime updatedAt;

  const VenueModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.country,
    this.latitude,
    this.longitude,
    this.coverImageUrl,
    this.gallery = const [],
    this.sports = const [],
    this.amenities = const {},
    this.rating = 0,
    this.reviewCount = 0,
    this.availability = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      coverImageUrl: json['coverImageUrl'] as String?,
      gallery: List<String>.from(json['gallery'] ?? const []),
      sports: List<String>.from(json['sports'] ?? const []),
      amenities: Map<String, dynamic>.from(json['amenities'] ?? const {}),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      availability: List<String>.from(json['availability'] ?? const []),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VenueModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed venue',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? data['location'] as String? ?? '',
      country: data['country'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      coverImageUrl: data['coverImageUrl'] as String? ??
          (data['photos'] is List && (data['photos'] as List).isNotEmpty
              ? (data['photos'] as List).first as String
              : null),
      gallery: List<String>.from(data['photos'] ?? data['gallery'] ?? const []),
      sports: List<String>.from(data['sports'] ?? const []),
      amenities: Map<String, dynamic>.from(data['amenities'] ?? const {}),
      rating: (data['rating'] as num?)?.toDouble() ??
          (data['averageRating'] as num?)?.toDouble() ??
          0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ??
          (data['totalReviews'] as num?)?.toInt() ??
          0,
      availability: List<String>.from(data['availability'] ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'coverImageUrl': coverImageUrl,
      'gallery': gallery,
      'sports': sports,
      'amenities': amenities,
      'rating': rating,
      'reviewCount': reviewCount,
      'availability': availability,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  VenueModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    String? coverImageUrl,
    List<String>? gallery,
    List<String>? sports,
    Map<String, dynamic>? amenities,
    double? rating,
    int? reviewCount,
    List<String>? availability,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VenueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      gallery: gallery ?? this.gallery,
      sports: sports ?? this.sports,
      amenities: amenities ?? this.amenities,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      availability: availability ?? this.availability,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
