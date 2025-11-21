import 'package:cloud_firestore/cloud_firestore.dart';

import 'listing_model.dart';

enum BookingStatusType {
  draft,
  pending,
  confirmed,
  cancelled,
  completed;

  static BookingStatusType fromString(String value) {
    return BookingStatusType.values.firstWhere(
      (element) => element.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BookingStatusType.pending,
    );
  }
}

class BookingModel {
  final String id;
  final String userId;
  final String providerId;
  final String listingId;
  final String sport;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatusType status;
  final List<PriceComponent> priceComponents;
  final Map<String, dynamic> extras;
  final double subtotal;
  final double total;
  final String? notes;
  final String? cancellationReason;
  final String? paymentReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.listingId,
    required this.sport,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.priceComponents = const [],
    this.extras = const {},
    this.subtotal = 0,
    this.total = 0,
    this.notes = '',
    this.cancellationReason,
    this.paymentReference,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return BookingModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      providerId: json['providerId'] as String? ?? '',
      listingId: json['listingId'] as String? ?? '',
      sport: json['sport'] as String? ?? 'General',
      startTime: _parseDate(json['startTime']),
      endTime: _parseDate(json['endTime']),
      status:
          BookingStatusType.fromString(json['status'] as String? ?? 'pending'),
      priceComponents: (json['priceComponents'] as List<dynamic>? ?? const [])
          .map((e) => PriceComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      extras: Map<String, dynamic>.from(json['extras'] ?? const {}),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      paymentReference: json['paymentReference'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookingModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      providerId:
          data['providerId'] as String? ?? data['ownerId'] as String? ?? '',
      listingId: data['listingId'] as String? ?? '',
      sport:
          data['sport'] as String? ?? data['sportType'] as String? ?? 'General',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ??
          (data['selectedDate'] != null && data['timeSlot'] != null
              ? DateTime.tryParse(
                      '${(data['selectedDate'] as Timestamp).toDate().toIso8601String().split('T').first} ${((data['timeSlot'] as Map<String, dynamic>)['start'] as String? ?? '00:00')}:00') ??
                  DateTime.now()
              : DateTime.now()),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ??
          (data['selectedDate'] != null && data['timeSlot'] != null
              ? DateTime.tryParse(
                      '${(data['selectedDate'] as Timestamp).toDate().toIso8601String().split('T').first} ${((data['timeSlot'] as Map<String, dynamic>)['end'] as String? ?? '00:00')}:00') ??
                  DateTime.now()
              : DateTime.now()),
      status: BookingStatusType.fromString(
        data['status'] as String? ?? 'pending',
      ),
      priceComponents: (data['priceComponents'] as List<dynamic>? ?? const [])
          .map((e) => PriceComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      extras: Map<String, dynamic>.from(data['extras'] ?? const {}),
      subtotal: (data['subtotal'] as num?)?.toDouble() ??
          (data['totalAmount'] as num?)?.toDouble() ??
          0,
      total: (data['total'] as num?)?.toDouble() ??
          (data['totalAmount'] as num?)?.toDouble() ??
          0,
      notes: data['notes'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
      paymentReference: data['paymentReference'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'providerId': providerId,
      'listingId': listingId,
      'sport': sport,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.name,
      'priceComponents': priceComponents.map((e) => e.toJson()).toList(),
      'extras': extras,
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'paymentReference': paymentReference,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? providerId,
    String? listingId,
    String? sport,
    DateTime? startTime,
    DateTime? endTime,
    BookingStatusType? status,
    List<PriceComponent>? priceComponents,
    Map<String, dynamic>? extras,
    double? subtotal,
    double? total,
    String? notes,
    String? cancellationReason,
    String? paymentReference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      providerId: providerId ?? this.providerId,
      listingId: listingId ?? this.listingId,
      sport: sport ?? this.sport,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      priceComponents: priceComponents ?? this.priceComponents,
      extras: extras ?? this.extras,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isUpcoming => startTime.isAfter(DateTime.now());

  bool get isCancellable =>
      status == BookingStatusType.confirmed ||
      status == BookingStatusType.pending;
}
