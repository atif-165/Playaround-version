import 'package:cloud_firestore/cloud_firestore.dart';

import 'venue_model.dart';

enum ListingCategory {
  player,
  team,
  tournament,
  venue;

  static ListingCategory fromString(String value) {
    return ListingCategory.values.firstWhere(
      (element) => element.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ListingCategory.venue,
    );
  }
}

class PriceComponent {
  final String label;
  final double amount;
  final bool taxable;

  const PriceComponent({
    required this.label,
    required this.amount,
    this.taxable = false,
  });

  factory PriceComponent.fromJson(Map<String, dynamic> json) {
    return PriceComponent(
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      taxable: json['taxable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'taxable': taxable,
      };
}

class ListingModel {
  final String id;
  final ListingCategory category;
  final String sport;
  final String title;
  final String description;
  final String providerId;
  final String providerName;
  final String? providerAvatarUrl;
  final String? venueId;
  final VenueModel? venue;
  final double basePrice;
  final List<PriceComponent> priceComponents;
  final List<String> photos;
  final List<String> tags;
  final Map<String, dynamic> extras; // e.g. equipment rentals
  final Map<String, dynamic> availability; // keyed by date => [slot ids]
  final int capacity;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ListingModel({
    required this.id,
    required this.category,
    required this.sport,
    required this.title,
    required this.description,
    required this.providerId,
    required this.providerName,
    this.providerAvatarUrl,
    this.venueId,
    this.venue,
    required this.basePrice,
    this.priceComponents = const [],
    this.photos = const [],
    this.tags = const [],
    this.extras = const {},
    this.availability = const {},
    this.capacity = 1,
    this.rating = 0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String,
      category:
          ListingCategory.fromString(json['category'] as String? ?? 'venue'),
      sport: json['sport'] as String? ?? 'General',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      providerId: json['providerId'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      providerAvatarUrl: json['providerAvatarUrl'] as String?,
      venueId: json['venueId'] as String?,
      venue: json['venue'] != null
          ? VenueModel.fromJson(json['venue'] as Map<String, dynamic>)
          : null,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      priceComponents: (json['priceComponents'] as List<dynamic>? ?? const [])
          .map((e) => PriceComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: List<String>.from(json['photos'] ?? const []),
      tags: List<String>.from(json['tags'] ?? const []),
      extras: Map<String, dynamic>.from(json['extras'] ?? const {}),
      availability: Map<String, dynamic>.from(json['availability'] ?? const {}),
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ListingModel(
      id: doc.id,
      category: ListingCategory.fromString(
        data['category'] as String? ??
            data['listingType'] as String? ??
            'venue',
      ),
      sport:
          data['sport'] as String? ?? data['sportType'] as String? ?? 'General',
      title: data['title'] as String? ?? data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      providerId:
          data['providerId'] as String? ?? data['ownerId'] as String? ?? '',
      providerName:
          data['providerName'] as String? ?? data['ownerName'] as String? ?? '',
      providerAvatarUrl: data['providerAvatarUrl'] as String? ??
          data['ownerProfilePicture'] as String?,
      venueId: data['venueId'] as String?,
      venue: null,
      basePrice: (data['basePrice'] as num?)?.toDouble() ??
          (data['hourlyRate'] as num?)?.toDouble() ??
          0,
      priceComponents: (data['priceComponents'] as List<dynamic>? ?? const [])
          .map((e) => PriceComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: List<String>.from(data['photos'] ?? const []),
      tags: List<String>.from(data['tags'] ?? const []),
      extras: Map<String, dynamic>.from(data['extras'] ?? const {}),
      availability: Map<String, dynamic>.from(data['availability'] ?? const {}),
      capacity: (data['capacity'] as num?)?.toInt() ?? 1,
      rating: (data['rating'] as num?)?.toDouble() ??
          (data['averageRating'] as num?)?.toDouble() ??
          0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ??
          (data['totalBookings'] as num?)?.toInt() ??
          0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'sport': sport,
      'title': title,
      'description': description,
      'providerId': providerId,
      'providerName': providerName,
      'providerAvatarUrl': providerAvatarUrl,
      'venueId': venueId,
      'venue': venue?.toJson(),
      'basePrice': basePrice,
      'priceComponents': priceComponents.map((e) => e.toJson()).toList(),
      'photos': photos,
      'tags': tags,
      'extras': extras,
      'availability': availability,
      'capacity': capacity,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ListingModel copyWith({
    String? id,
    ListingCategory? category,
    String? sport,
    String? title,
    String? description,
    String? providerId,
    String? providerName,
    String? providerAvatarUrl,
    String? venueId,
    VenueModel? venue,
    double? basePrice,
    List<PriceComponent>? priceComponents,
    List<String>? photos,
    List<String>? tags,
    Map<String, dynamic>? extras,
    Map<String, dynamic>? availability,
    int? capacity,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ListingModel(
      id: id ?? this.id,
      category: category ?? this.category,
      sport: sport ?? this.sport,
      title: title ?? this.title,
      description: description ?? this.description,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerAvatarUrl: providerAvatarUrl ?? this.providerAvatarUrl,
      venueId: venueId ?? this.venueId,
      venue: venue ?? this.venue,
      basePrice: basePrice ?? this.basePrice,
      priceComponents: priceComponents ?? this.priceComponents,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
      extras: extras ?? this.extras,
      availability: availability ?? this.availability,
      capacity: capacity ?? this.capacity,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
