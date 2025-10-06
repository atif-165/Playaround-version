import 'package:cloud_firestore/cloud_firestore.dart';

class Venue {
  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String country;
  final double latitude;
  final double longitude;
  final List<String> sports;
  final List<String> images;
  final List<VenueAmenity> amenities;
  final VenuePricing pricing;
  final VenueHours hours;
  final double rating;
  final int totalReviews;
  final List<String> coachIds;
  final bool isVerified;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Venue({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.sports,
    required this.images,
    required this.amenities,
    required this.pricing,
    required this.hours,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.coachIds = const [],
    this.isVerified = false,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Venue.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Venue(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      country: data['country'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      sports: List<String>.from(data['sports'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      amenities: (data['amenities'] as List<dynamic>?)
          ?.map((e) => VenueAmenity.fromMap(e))
          .toList() ?? [],
      pricing: VenuePricing.fromMap(data['pricing'] ?? {}),
      hours: VenueHours.fromMap(data['hours'] ?? {}),
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      coachIds: List<String>.from(data['coachIds'] ?? []),
      isVerified: data['isVerified'] ?? false,
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'sports': sports,
      'images': images,
      'amenities': amenities.map((e) => e.toMap()).toList(),
      'pricing': pricing.toMap(),
      'hours': hours.toMap(),
      'rating': rating,
      'totalReviews': totalReviews,
      'coachIds': coachIds,
      'isVerified': isVerified,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  Venue copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    List<String>? sports,
    List<String>? images,
    List<VenueAmenity>? amenities,
    VenuePricing? pricing,
    VenueHours? hours,
    double? rating,
    int? totalReviews,
    List<String>? coachIds,
    bool? isVerified,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sports: sports ?? this.sports,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      pricing: pricing ?? this.pricing,
      hours: hours ?? this.hours,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      coachIds: coachIds ?? this.coachIds,
      isVerified: isVerified ?? this.isVerified,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class VenueAmenity {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool isAvailable;

  VenueAmenity({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.isAvailable = true,
  });

  factory VenueAmenity.fromMap(Map<String, dynamic> map) {
    return VenueAmenity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      description: map['description'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'isAvailable': isAvailable,
    };
  }
}

class VenuePricing {
  final double hourlyRate;
  final double dailyRate;
  final double weeklyRate;
  final String currency;
  final List<PricingTier> tiers;
  final bool hasPeakPricing;
  final Map<String, double> peakRates;

  VenuePricing({
    required this.hourlyRate,
    required this.dailyRate,
    required this.weeklyRate,
    this.currency = 'USD',
    this.tiers = const [],
    this.hasPeakPricing = false,
    this.peakRates = const {},
  });

  factory VenuePricing.fromMap(Map<String, dynamic> map) {
    return VenuePricing(
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      dailyRate: (map['dailyRate'] ?? 0.0).toDouble(),
      weeklyRate: (map['weeklyRate'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      tiers: (map['tiers'] as List<dynamic>?)
          ?.map((e) => PricingTier.fromMap(e))
          .toList() ?? [],
      hasPeakPricing: map['hasPeakPricing'] ?? false,
      peakRates: Map<String, double>.from(map['peakRates'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'weeklyRate': weeklyRate,
      'currency': currency,
      'tiers': tiers.map((e) => e.toMap()).toList(),
      'hasPeakPricing': hasPeakPricing,
      'peakRates': peakRates,
    };
  }
}

class PricingTier {
  final String name;
  final double price;
  final String description;
  final int minHours;

  PricingTier({
    required this.name,
    required this.price,
    required this.description,
    this.minHours = 1,
  });

  factory PricingTier.fromMap(Map<String, dynamic> map) {
    return PricingTier(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      minHours: map['minHours'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'minHours': minHours,
    };
  }
}

class VenueHours {
  final Map<String, DayHours> weeklyHours;
  final List<String> holidays;

  VenueHours({
    required this.weeklyHours,
    this.holidays = const [],
  });

  factory VenueHours.fromMap(Map<String, dynamic> map) {
    Map<String, DayHours> hours = {};
    if (map['weeklyHours'] != null) {
      (map['weeklyHours'] as Map<String, dynamic>).forEach((key, value) {
        hours[key] = DayHours.fromMap(value);
      });
    }
    return VenueHours(
      weeklyHours: hours,
      holidays: List<String>.from(map['holidays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeklyHours': weeklyHours.map((key, value) => MapEntry(key, value.toMap())),
      'holidays': holidays,
    };
  }
}

class DayHours {
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? breakStartTime;
  final String? breakEndTime;

  DayHours({
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.breakStartTime,
    this.breakEndTime,
  });

  factory DayHours.fromMap(Map<String, dynamic> map) {
    return DayHours(
      isOpen: map['isOpen'] ?? false,
      openTime: map['openTime'],
      closeTime: map['closeTime'],
      breakStartTime: map['breakStartTime'],
      breakEndTime: map['breakEndTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
      'breakStartTime': breakStartTime,
      'breakEndTime': breakEndTime,
    };
  }
}
