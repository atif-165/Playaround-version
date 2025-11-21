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
  final String? phoneNumber;
  final String? googleMapsLink;
  final Map<String, dynamic>? metadata;

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
    this.phoneNumber,
    this.googleMapsLink,
    this.metadata,
  });

  factory Venue.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() ?? {}) as Map<String, dynamic>;

    final name = (data['name'] ??
            data['title'] ??
            data['venueName'] ??
            data['displayName'] ??
            '')
        .toString()
        .trim();
    final description =
        (data['description'] ?? data['details'] ?? data['summary'] ?? '')
            .toString();
    final address =
        (data['address'] ?? data['location'] ?? data['city'] ?? '').toString();

    final city =
        (data['city'] ?? _extractCityFromLocation(data['location']) ?? '')
            .toString();
    final state = (data['state'] ?? data['province'] ?? '').toString();
    final country = (data['country'] ?? data['countryName'] ?? '').toString();

    final coordinates = _parseCoordinates(data);

    final sports = _parseSports(data);
    final amenities = _parseAmenities(data);
    final pricing = _parsePricing(data);
    final hours = _parseHours(data);

    final rating =
        _toDouble(data['rating'] ?? data['averageRating'] ?? data['score']);
    final totalReviews =
        _toInt(data['totalReviews'] ?? data['reviewsCount']) ?? 0;
    final coachIds = _parseStringList(data['coachIds']);
    final isVerified =
        data['isVerified'] == true || (data['status'] == 'verified');

    final ownerId = (data['ownerId'] ?? data['createdBy']).toString();

    final createdAt =
        _parseTimestamp(data['createdAt']) ?? DateTime.now().toUtc();
    final updatedAt = _parseTimestamp(data['updatedAt']) ?? createdAt;

    final isActive = _parseIsActive(data);

    final images = _parseStringList(data['images']);

    final rawMetadata = data['metadata'];
    final metadata = rawMetadata is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawMetadata)
        : null;

    String? phoneNumber = data['phoneNumber']?.toString();
    if ((phoneNumber == null || phoneNumber.trim().isEmpty) &&
        data['contactInfo'] != null) {
      phoneNumber = data['contactInfo'].toString();
    }
    if ((phoneNumber == null || phoneNumber.trim().isEmpty) &&
        metadata != null) {
      final metaPhone = metadata['phoneNumber'] ?? metadata['contactInfo'];
      if (metaPhone != null) {
        phoneNumber = metaPhone.toString();
      }
    }

    String? googleMapsLink = data['googleMapsLink']?.toString();
    if ((googleMapsLink == null || googleMapsLink.trim().isEmpty) &&
        metadata != null &&
        metadata['googleMapsLink'] != null) {
      googleMapsLink = metadata['googleMapsLink'].toString();
    }

    return Venue(
      id: doc.id,
      name: name,
      description: description,
      address: address,
      city: city,
      state: state,
      country: country,
      latitude: coordinates.$1,
      longitude: coordinates.$2,
      sports: sports,
      images: images,
      amenities: amenities,
      pricing: pricing,
      hours: hours,
      rating: rating,
      totalReviews: totalReviews,
      coachIds: coachIds,
      isVerified: isVerified,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      phoneNumber: phoneNumber,
      googleMapsLink: googleMapsLink,
      metadata: metadata,
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
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (googleMapsLink != null) 'googleMapsLink': googleMapsLink,
      if (metadata != null) 'metadata': metadata,
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
    String? phoneNumber,
    String? googleMapsLink,
    Map<String, dynamic>? metadata,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      metadata: metadata ?? this.metadata,
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
      id: map['id']?.toString() ?? map['name']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      icon: map['icon']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isAvailable:
          map['isAvailable'] == null ? true : map['isAvailable'] == true,
    );
  }

  factory VenueAmenity.fromDynamic(dynamic value) {
    if (value is VenueAmenity) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      return VenueAmenity.fromMap(value);
    }
    final stringValue = value?.toString() ?? '';
    return VenueAmenity(
      id: stringValue.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      name: stringValue,
      icon: '',
      description: '',
      isAvailable: true,
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
    final rawTiers = map['tiers'];
    final tiers = <PricingTier>[];
    if (rawTiers is List) {
      for (final tier in rawTiers) {
        if (tier is Map) {
          tiers.add(
            PricingTier.fromMap(tier.cast<String, dynamic>()),
          );
        }
      }
    }

    final peakRates = <String, double>{};
    final rawPeakRates = map['peakRates'];
    if (rawPeakRates is Map) {
      rawPeakRates.forEach(
        (key, value) => peakRates[key.toString()] = _toDouble(value),
      );
    }

    return VenuePricing(
      hourlyRate: _toDouble(map['hourlyRate']),
      dailyRate: _toDouble(map['dailyRate']),
      weeklyRate: _toDouble(map['weeklyRate']),
      currency: (map['currency'] ?? 'USD').toString(),
      tiers: tiers,
      hasPeakPricing: map['hasPeakPricing'] == true,
      peakRates: peakRates,
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
      name: (map['name'] ?? '').toString(),
      price: _toDouble(map['price']),
      description: (map['description'] ?? '').toString(),
      minHours: _toInt(map['minHours']) ?? 1,
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
      'weeklyHours':
          weeklyHours.map((key, value) => MapEntry(key, value.toMap())),
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

List<String> _parseStringList(dynamic raw) {
  if (raw is List) {
    return raw
        .map((e) => e.toString())
        .where((element) => element.isNotEmpty)
        .toList();
  }
  if (raw is String && raw.isNotEmpty) {
    return [raw];
  }
  return [];
}

List<String> _parseSports(Map<String, dynamic> data) {
  final rawSports = data['sports'] ?? data['sportTypes'] ?? data['sportType'];
  final sports = _parseStringList(rawSports);
  if (sports.isNotEmpty) {
    return sports;
  }
  final amenities = data['amenities'];
  if (amenities is Map && amenities['sports'] is List) {
    return _parseStringList(amenities['sports']);
  }
  return [];
}

List<VenueAmenity> _parseAmenities(Map<String, dynamic> data) {
  final rawAmenities = data['amenities'];
  if (rawAmenities is List) {
    return rawAmenities.map(VenueAmenity.fromDynamic).toList();
  }
  if (rawAmenities is Map) {
    return rawAmenities.values.map(VenueAmenity.fromDynamic).toList();
  }
  return [];
}

VenuePricing _parsePricing(Map<String, dynamic> data) {
  final rawPricing = <String, dynamic>{};

  final pricingData = data['pricing'];
  if (pricingData is Map) {
    pricingData.forEach((key, value) {
      rawPricing[key.toString()] = value;
    });
  }

  if (rawPricing.isEmpty) {
    if (data.containsKey('hourlyRate') ||
        data.containsKey('dailyRate') ||
        data.containsKey('weeklyRate')) {
      rawPricing.addAll({
        'hourlyRate': data['hourlyRate'],
        'dailyRate': data['dailyRate'],
        'weeklyRate': data['weeklyRate'],
        'currency': data['currency'] ?? data['pricingCurrency'],
      });
    }
  }
  return VenuePricing.fromMap(rawPricing);
}

VenueHours _parseHours(Map<String, dynamic> data) {
  if (data['hours'] is Map<String, dynamic>) {
    return VenueHours.fromMap((data['hours'] as Map).cast<String, dynamic>());
  }

  final availableDays = _parseStringList(data['availableDays']);
  final timeSlots = data['availableTimeSlots'];

  if (availableDays.isNotEmpty && timeSlots is List && timeSlots.isNotEmpty) {
    final slot = timeSlots.first;
    final openTime = (slot is Map && slot['start'] != null)
        ? slot['start'].toString()
        : null;
    final closeTime =
        (slot is Map && slot['end'] != null) ? slot['end'].toString() : null;

    final weekly = {
      for (final day in availableDays)
        day: DayHours(
          isOpen: true,
          openTime: openTime,
          closeTime: closeTime,
        ),
    };
    return VenueHours(weeklyHours: weekly, holidays: const []);
  }

  return VenueHours(weeklyHours: const {}, holidays: const []);
}

(double, double) _parseCoordinates(Map<String, dynamic> data) {
  final lat = _toDouble(data['latitude'] ?? data['lat']);
  final lng = _toDouble(data['longitude'] ?? data['lng'] ?? data['long']);

  if (lat != 0 || lng != 0) {
    return (lat, lng);
  }

  final coordinates = data['coordinates'];
  if (coordinates is Map<String, dynamic>) {
    final mapLat = _toDouble(coordinates['latitude'] ?? coordinates['lat']);
    final mapLng = _toDouble(
        coordinates['longitude'] ?? coordinates['lng'] ?? coordinates['long']);
    if (mapLat != 0 || mapLng != 0) {
      return (mapLat, mapLng);
    }
  }

  final gpsString = data['gpsCoordinates']?.toString();
  if (gpsString != null && gpsString.contains(',')) {
    final parts = gpsString.split(',');
    if (parts.length >= 2) {
      final parsedLat = _toDouble(parts[0]);
      final parsedLng = _toDouble(parts[1]);
      return (parsedLat, parsedLng);
    }
  }

  return (0.0, 0.0);
}

bool _parseIsActive(Map<String, dynamic> data) {
  if (data['isActive'] != null) {
    return data['isActive'] == true;
  }
  final status = data['status']?.toString().toLowerCase();
  if (status != null) {
    return status == 'active' || status == 'published';
  }
  return true;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

DateTime? _parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? _extractCityFromLocation(dynamic location) {
  if (location is String && location.contains(',')) {
    final parts = location.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
  }
  return null;
}
