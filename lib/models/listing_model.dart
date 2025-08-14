import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for listing types
enum ListingType {
  coach('coach'),
  venue('venue');

  const ListingType(this.value);
  final String value;

  static ListingType fromString(String value) {
    return ListingType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ListingType.coach,
    );
  }

  String get displayName {
    switch (this) {
      case ListingType.coach:
        return 'Coach Session';
      case ListingType.venue:
        return 'Venue Booking';
    }
  }
}

/// Enum for sport types (shared across the app)
enum SportType {
  cricket('Cricket'),
  football('Football'),
  basketball('Basketball'),
  tennis('Tennis'),
  badminton('Badminton'),
  volleyball('Volleyball'),
  swimming('Swimming'),
  running('Running'),
  cycling('Cycling'),
  other('Other');

  const SportType(this.displayName);
  final String displayName;

  static SportType fromString(String value) {
    return SportType.values.firstWhere(
      (type) => type.displayName == value || type.name == value,
      orElse: () => SportType.other,
    );
  }
}

/// Time slot model for availability
class TimeSlot {
  final String start; // Format: "HH:mm"
  final String end;   // Format: "HH:mm"

  const TimeSlot({
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      start: map['start'] as String,
      end: map['end'] as String,
    );
  }

  /// Calculate duration in hours
  double get durationInHours {
    final startParts = start.split(':');
    final endParts = end.split(':');

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    return (endMinutes - startMinutes) / 60.0;
  }

  /// Check if this time slot overlaps with another
  bool overlaps(TimeSlot other) {
    final thisStartMinutes = _timeToMinutes(start);
    final thisEndMinutes = _timeToMinutes(end);
    final otherStartMinutes = _timeToMinutes(other.start);
    final otherEndMinutes = _timeToMinutes(other.end);

    return thisStartMinutes < otherEndMinutes && thisEndMinutes > otherStartMinutes;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => '$start - $end';
}

/// Model for coach and venue listings
class ListingModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerProfilePicture;
  final ListingType type;
  final String title;
  final SportType sportType;
  final String description;
  final double hourlyRate;
  final List<String> availableDays; // ['Monday', 'Tuesday', etc.]
  final List<TimeSlot> availableTimeSlots;
  final String location;
  final String? gpsCoordinates; // Optional GPS coordinates
  final List<String> photos; // URLs for venue photos
  final bool isActive;
  final double averageRating;
  final int totalBookings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const ListingModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerProfilePicture,
    required this.type,
    required this.title,
    required this.sportType,
    required this.description,
    required this.hourlyRate,
    required this.availableDays,
    required this.availableTimeSlots,
    required this.location,
    this.gpsCoordinates,
    this.photos = const [],
    this.isActive = true,
    this.averageRating = 0.0,
    this.totalBookings = 0,
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
      'type': type.value,
      'title': title,
      'sportType': sportType.displayName,
      'description': description,
      'hourlyRate': hourlyRate,
      'availableDays': availableDays,
      'availableTimeSlots': availableTimeSlots.map((slot) => slot.toMap()).toList(),
      'location': location,
      'gpsCoordinates': gpsCoordinates,
      'photos': photos,
      'isActive': isActive,
      'averageRating': averageRating,
      'totalBookings': totalBookings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel.fromMap(data);
  }

  /// Create from Map
  factory ListingModel.fromMap(Map<String, dynamic> map) {
    return ListingModel(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String,
      ownerProfilePicture: map['ownerProfilePicture'] as String?,
      type: ListingType.fromString(map['type'] as String),
      title: map['title'] as String,
      sportType: SportType.fromString(map['sportType'] as String),
      description: map['description'] as String,
      hourlyRate: (map['hourlyRate'] as num).toDouble(),
      availableDays: List<String>.from(map['availableDays'] as List),
      availableTimeSlots: (map['availableTimeSlots'] as List)
          .map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
          .toList(),
      location: map['location'] as String,
      gpsCoordinates: map['gpsCoordinates'] as String?,
      photos: List<String>.from(map['photos'] as List? ?? []),
      isActive: map['isActive'] as bool? ?? true,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalBookings: map['totalBookings'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with updated fields
  ListingModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerProfilePicture,
    ListingType? type,
    String? title,
    SportType? sportType,
    String? description,
    double? hourlyRate,
    List<String>? availableDays,
    List<TimeSlot>? availableTimeSlots,
    String? location,
    String? gpsCoordinates,
    List<String>? photos,
    bool? isActive,
    double? averageRating,
    int? totalBookings,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ListingModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerProfilePicture: ownerProfilePicture ?? this.ownerProfilePicture,
      type: type ?? this.type,
      title: title ?? this.title,
      sportType: sportType ?? this.sportType,
      description: description ?? this.description,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availableDays: availableDays ?? this.availableDays,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      location: location ?? this.location,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
      photos: photos ?? this.photos,
      isActive: isActive ?? this.isActive,
      averageRating: averageRating ?? this.averageRating,
      totalBookings: totalBookings ?? this.totalBookings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ListingModel(id: $id, title: $title, type: $type, sportType: $sportType)';
  }
}
