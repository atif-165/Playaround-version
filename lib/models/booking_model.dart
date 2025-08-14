import 'package:cloud_firestore/cloud_firestore.dart';
import 'listing_model.dart';

/// Enum for booking status
enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  cancelled('cancelled'),
  completed('completed');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.pending,
    );
  }

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  /// Get color for status display
  String get colorHex {
    switch (this) {
      case BookingStatus.pending:
        return '#FFA500'; // Orange
      case BookingStatus.confirmed:
        return '#4CAF50'; // Green
      case BookingStatus.cancelled:
        return '#F44336'; // Red
      case BookingStatus.completed:
        return '#2196F3'; // Blue
    }
  }
}

/// Model for booking transactions
class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final String listingId;
  final String listingTitle;
  final ListingType listingType;
  final String ownerId;
  final String ownerName;
  final SportType sportType;
  final DateTime selectedDate;
  final TimeSlot timeSlot;
  final BookingStatus status;
  final double totalAmount;
  final double hourlyRate;
  final String location;
  final String? notes; // Optional notes from user
  final String? cancellationReason; // Reason for cancellation
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.listingId,
    required this.listingTitle,
    required this.listingType,
    required this.ownerId,
    required this.ownerName,
    required this.sportType,
    required this.selectedDate,
    required this.timeSlot,
    required this.status,
    required this.totalAmount,
    required this.hourlyRate,
    required this.location,
    this.notes,
    this.cancellationReason,
    this.confirmedAt,
    this.cancelledAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingType': listingType.value,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'sportType': sportType.displayName,
      'selectedDate': Timestamp.fromDate(selectedDate),
      'timeSlot': timeSlot.toMap(),
      'status': status.value,
      'totalAmount': totalAmount,
      'hourlyRate': hourlyRate,
      'location': location,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel.fromMap(data);
  }

  /// Create from Map
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userProfilePicture: map['userProfilePicture'] as String?,
      listingId: map['listingId'] as String,
      listingTitle: map['listingTitle'] as String,
      listingType: ListingType.fromString(map['listingType'] as String),
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String,
      sportType: SportType.fromString(map['sportType'] as String),
      selectedDate: (map['selectedDate'] as Timestamp).toDate(),
      timeSlot: TimeSlot.fromMap(map['timeSlot'] as Map<String, dynamic>),
      status: BookingStatus.fromString(map['status'] as String),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      hourlyRate: (map['hourlyRate'] as num).toDouble(),
      location: map['location'] as String,
      notes: map['notes'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
      confirmedAt: map['confirmedAt'] != null 
          ? (map['confirmedAt'] as Timestamp).toDate() 
          : null,
      cancelledAt: map['cancelledAt'] != null 
          ? (map['cancelledAt'] as Timestamp).toDate() 
          : null,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with updated fields
  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePicture,
    String? listingId,
    String? listingTitle,
    ListingType? listingType,
    String? ownerId,
    String? ownerName,
    SportType? sportType,
    DateTime? selectedDate,
    TimeSlot? timeSlot,
    BookingStatus? status,
    double? totalAmount,
    double? hourlyRate,
    String? location,
    String? notes,
    String? cancellationReason,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingType: listingType ?? this.listingType,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      sportType: sportType ?? this.sportType,
      selectedDate: selectedDate ?? this.selectedDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if booking is in the past
  bool get isPastBooking {
    final bookingDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(timeSlot.end.split(':')[0]),
      int.parse(timeSlot.end.split(':')[1]),
    );
    return bookingDateTime.isBefore(DateTime.now());
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    if (status == BookingStatus.cancelled || status == BookingStatus.completed) {
      return false;
    }
    
    // Allow cancellation up to 2 hours before the booking
    final bookingDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(timeSlot.start.split(':')[0]),
      int.parse(timeSlot.start.split(':')[1]),
    );
    
    final twoHoursBefore = bookingDateTime.subtract(const Duration(hours: 2));
    return DateTime.now().isBefore(twoHoursBefore);
  }

  /// Get duration in hours
  double get durationInHours {
    final startParts = timeSlot.start.split(':');
    final endParts = timeSlot.end.split(':');
    
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    return (endMinutes - startMinutes) / 60.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Check if booking is upcoming (future and confirmed/pending)
  bool get isUpcoming {
    if (status == BookingStatus.cancelled || status == BookingStatus.completed) {
      return false;
    }
    return !isPastBooking;
  }

  /// Check if booking is completed
  bool get isCompleted {
    return status == BookingStatus.completed;
  }

  /// Check if booking is cancelled
  bool get isCancelled {
    return status == BookingStatus.cancelled;
  }

  /// Get formatted date string
  String get formattedDate {
    return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
  }

  /// Get formatted time range
  String get formattedTimeRange {
    return '${timeSlot.start} - ${timeSlot.end}';
  }

  /// Get earnings for coach (only if user is the owner)
  double get coachEarnings {
    if (status == BookingStatus.completed) {
      return totalAmount;
    }
    return 0.0;
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, listingTitle: $listingTitle, status: $status, selectedDate: $selectedDate)';
  }
}
