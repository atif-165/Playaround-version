import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_model.dart' as data;

class FirestoreBookingDataSource {
  FirestoreBookingDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('bookings');

  Future<void> saveBooking(data.BookingModel booking) async {
    await _collection.doc(booking.id).set(booking.toJson());
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required data.BookingStatusType status,
    String? cancellationReason,
  }) async {
    await _collection.doc(bookingId).update({
      'status': status.name,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (status == data.BookingStatusType.cancelled)
        'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<data.BookingModel?> fetchBookingById(String bookingId) async {
    final doc = await _collection.doc(bookingId).get();
    if (!doc.exists) return null;
    return data.BookingModel.fromFirestore(doc);
  }

  Stream<List<data.BookingModel>> watchBookingsForUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(data.BookingModel.fromFirestore).toList());
  }

  Stream<List<data.BookingModel>> watchBookingsForProvider(String providerId) {
    return _collection
        .where('providerId', isEqualTo: providerId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(data.BookingModel.fromFirestore).toList());
  }
}
