import 'package:cloud_firestore/cloud_firestore.dart';

class VenueBooking {
  final String id;
  final String venueId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // in hours
  final double totalAmount;
  final String currency;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? paymentId;
  final String? specialRequests;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final double? refundAmount;

  VenueBooking({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.totalAmount,
    this.currency = 'USD',
    this.status = BookingStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentId,
    this.specialRequests,
    this.participants = const [],
    required this.createdAt,
    required this.updatedAt,
    this.cancellationReason,
    this.cancelledAt,
    this.refundAmount,
  });

  factory VenueBooking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VenueBooking(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      duration: data['duration'] ?? 1,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentId: data['paymentId'],
      specialRequests: data['specialRequests'],
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      refundAmount: data['refundAmount']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'venueId': venueId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'duration': duration,
      'totalAmount': totalAmount,
      'currency': currency,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'paymentId': paymentId,
      'specialRequests': specialRequests,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'refundAmount': refundAmount,
    };
  }

  VenueBooking copyWith({
    String? id,
    String? venueId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    double? totalAmount,
    String? currency,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentId,
    String? specialRequests,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancellationReason,
    DateTime? cancelledAt,
    double? refundAmount,
  }) {
    return VenueBooking(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      specialRequests: specialRequests ?? this.specialRequests,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      refundAmount: refundAmount ?? this.refundAmount,
    );
  }
}

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  refunded,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  partiallyRefunded,
}

class BookingSlot {
  final String id;
  final String venueId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final double price;
  final String currency;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingSlot({
    required this.id,
    required this.venueId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.price,
    this.currency = 'USD',
    this.bookingId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingSlot.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingSlot(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      bookingId: data['bookingId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'venueId': venueId,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
      'price': price,
      'currency': currency,
      'bookingId': bookingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
