import 'package:cloud_firestore/cloud_firestore.dart';
import 'listing_model.dart';

/// Enum for venue booking status
enum VenueBookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  cancelled('cancelled'),
  completed('completed');

  const VenueBookingStatus(this.value);
  final String value;

  static VenueBookingStatus fromString(String value) {
    return VenueBookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => VenueBookingStatus.pending,
    );
  }

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case VenueBookingStatus.pending:
        return 'Pending';
      case VenueBookingStatus.confirmed:
        return 'Confirmed';
      case VenueBookingStatus.cancelled:
        return 'Cancelled';
      case VenueBookingStatus.completed:
        return 'Completed';
    }
  }

  /// Get color for the status
  String get colorHex {
    switch (this) {
      case VenueBookingStatus.pending:
        return '#FFA500'; // Orange
      case VenueBookingStatus.confirmed:
        return '#4CAF50'; // Green
      case VenueBookingStatus.cancelled:
        return '#F44336'; // Red
      case VenueBookingStatus.completed:
        return '#2196F3'; // Blue
    }
  }
}

/// Model for venue booking transactions
class VenueBookingModel {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final String venueId;
  final String venueTitle;
  final String venueOwnerId;
  final String venueOwnerName;
  final SportType sportType;
  final DateTime selectedDate;
  final TimeSlot timeSlot;
  final VenueBookingStatus status;
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

  const VenueBookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.venueId,
    required this.venueTitle,
    required this.venueOwnerId,
    required this.venueOwnerName,
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
      'venueId': venueId,
      'venueTitle': venueTitle,
      'venueOwnerId': venueOwnerId,
      'venueOwnerName': venueOwnerName,
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
  factory VenueBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VenueBookingModel.fromMap(data);
  }

  /// Create from Map
  factory VenueBookingModel.fromMap(Map<String, dynamic> map) {
    return VenueBookingModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userProfilePicture: map['userProfilePicture'] as String?,
      venueId: map['venueId'] as String,
      venueTitle: map['venueTitle'] as String,
      venueOwnerId: map['venueOwnerId'] as String,
      venueOwnerName: map['venueOwnerName'] as String,
      sportType: SportType.fromString(map['sportType'] as String),
      selectedDate: (map['selectedDate'] as Timestamp).toDate(),
      timeSlot: TimeSlot.fromMap(map['timeSlot'] as Map<String, dynamic>),
      status: VenueBookingStatus.fromString(map['status'] as String),
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
  VenueBookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePicture,
    String? venueId,
    String? venueTitle,
    String? venueOwnerId,
    String? venueOwnerName,
    SportType? sportType,
    DateTime? selectedDate,
    TimeSlot? timeSlot,
    VenueBookingStatus? status,
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
    return VenueBookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      venueId: venueId ?? this.venueId,
      venueTitle: venueTitle ?? this.venueTitle,
      venueOwnerId: venueOwnerId ?? this.venueOwnerId,
      venueOwnerName: venueOwnerName ?? this.venueOwnerName,
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

  /// Check if booking is active (not cancelled or completed)
  bool get isActive => status == VenueBookingStatus.pending || status == VenueBookingStatus.confirmed;

  /// Check if booking can be cancelled
  bool get canBeCancelled => status == VenueBookingStatus.pending || status == VenueBookingStatus.confirmed;

  /// Get formatted date string
  String get formattedDate {
    return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
  }

  /// Get formatted time slot string
  String get formattedTimeSlot {
    return '${timeSlot.start} - ${timeSlot.end}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VenueBookingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VenueBookingModel(id: $id, venueTitle: $venueTitle, selectedDate: $selectedDate, status: $status)';
  }
}
