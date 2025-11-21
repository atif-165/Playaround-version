import 'package:cloud_firestore/cloud_firestore.dart';

/// Shop location model for map markers
class ShopLocation {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String ownerId;
  final String ownerName;
  final String category;
  final List<String> images;
  final String address;
  final String phoneNumber;
  final String email;
  final String website;
  final Map<String, dynamic> businessHours;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final Map<String, dynamic> additionalInfo;

  ShopLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.ownerId,
    required this.ownerName,
    required this.category,
    required this.images,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.website,
    required this.businessHours,
    required this.rating,
    required this.reviewCount,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.additionalInfo,
  });

  factory ShopLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopLocation(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      category: data['category'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      businessHours: Map<String, dynamic>.from(data['businessHours'] ?? {}),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'category': category,
      'images': images,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'businessHours': businessHours,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'additionalInfo': additionalInfo,
    };
  }

  ShopLocation copyWith({
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? ownerId,
    String? ownerName,
    String? category,
    List<String>? images,
    String? address,
    String? phoneNumber,
    String? email,
    String? website,
    Map<String, dynamic>? businessHours,
    double? rating,
    int? reviewCount,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    Map<String, dynamic>? additionalInfo,
  }) {
    return ShopLocation(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      category: category ?? this.category,
      images: images ?? this.images,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      businessHours: businessHours ?? this.businessHours,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
