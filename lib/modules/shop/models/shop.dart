import 'package:cloud_firestore/cloud_firestore.dart';

/// Partner shop/vendor model
class Shop {
  final String id;
  final String name;
  final String description;
  final String address;
  final String contactNumber;
  final String email;
  final String ownerId;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool isOnline;
  final bool isLocal;
  final String city;
  final String state;
  final String pincode;
  final List<String> categories;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic> businessHours;
  final String website;
  final List<String> socialMediaLinks;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.contactNumber,
    required this.email,
    required this.ownerId,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.isOnline,
    required this.isLocal,
    required this.city,
    required this.state,
    required this.pincode,
    required this.categories,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.businessHours,
    required this.website,
    required this.socialMediaLinks,
  });

  factory Shop.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Shop(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      contactNumber: (data['contactNumber'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      ownerId: (data['ownerId'] ?? '') as String,
      images: (data['images'] as List?)?.cast<String>() ?? const [],
      rating: (data['rating'] ?? 0.0) as double,
      reviewCount: (data['reviewCount'] ?? 0) as int,
      isOnline: (data['isOnline'] ?? false) as bool,
      isLocal: (data['isLocal'] ?? false) as bool,
      city: (data['city'] ?? '') as String,
      state: (data['state'] ?? '') as String,
      pincode: (data['pincode'] ?? '') as String,
      categories: (data['categories'] as List?)?.cast<String>() ?? const [],
      isVerified: (data['isVerified'] ?? false) as bool,
      isActive: (data['isActive'] ?? true) as bool,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      businessHours: Map<String, dynamic>.from(data['businessHours'] ?? {}),
      website: (data['website'] ?? '') as String,
      socialMediaLinks: (data['socialMediaLinks'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'address': address,
        'contactNumber': contactNumber,
        'email': email,
        'ownerId': ownerId,
        'images': images,
        'rating': rating,
        'reviewCount': reviewCount,
        'isOnline': isOnline,
        'isLocal': isLocal,
        'city': city,
        'state': state,
        'pincode': pincode,
        'categories': categories,
        'isVerified': isVerified,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'businessHours': businessHours,
        'website': website,
        'socialMediaLinks': socialMediaLinks,
      };

  Shop copyWith({
    String? name,
    String? description,
    String? address,
    String? contactNumber,
    String? email,
    List<String>? images,
    double? rating,
    int? reviewCount,
    bool? isOnline,
    bool? isLocal,
    String? city,
    String? state,
    String? pincode,
    List<String>? categories,
    bool? isVerified,
    bool? isActive,
    Map<String, dynamic>? businessHours,
    String? website,
    List<String>? socialMediaLinks,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      ownerId: ownerId,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOnline: isOnline ?? this.isOnline,
      isLocal: isLocal ?? this.isLocal,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      categories: categories ?? this.categories,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      businessHours: businessHours ?? this.businessHours,
      website: website ?? this.website,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
    );
  }
}
