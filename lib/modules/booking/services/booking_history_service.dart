import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/booking_model.dart';
import '../../../models/booking_analytics_model.dart';
import '../../../models/user_profile.dart';

/// Service for managing booking history and analytics
class BookingHistoryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _bookingsCollection = 'bookings';

  BookingHistoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Get booking history for current user with filtering
  Stream<List<BookingModel>> getUserBookingHistory({
    BookingStatus? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: user.uid);

      // Apply status filter
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      // Apply date range filter
      if (startDate != null) {
        query = query.where('selectedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('selectedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('selectedDate', descending: true).limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingHistoryService: Error getting user booking history: $e');
      }
      throw Exception('Failed to get booking history: $e');
    }
  }

  /// Get booking history for coach (bookings where user is the owner)
  Stream<List<BookingModel>> getCoachBookingHistory({
    BookingStatus? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore
          .collection(_bookingsCollection)
          .where('ownerId', isEqualTo: user.uid);

      // Apply status filter
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      // Apply date range filter
      if (startDate != null) {
        query = query.where('selectedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('selectedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('selectedDate', descending: true).limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingHistoryService: Error getting coach booking history: $e');
      }
      throw Exception('Failed to get coach booking history: $e');
    }
  }

  /// Get combined booking history (both as player and coach)
  Stream<List<BookingModel>> getCombinedBookingHistory({
    BookingStatus? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // We need to combine two queries, so we'll use a different approach
      return Stream.fromFuture(_getCombinedBookingsSnapshot(
        user.uid,
        statusFilter,
        startDate,
        endDate,
        limit,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingHistoryService: Error getting combined booking history: $e');
      }
      throw Exception('Failed to get combined booking history: $e');
    }
  }

  /// Get bookings snapshot for combined history
  Future<List<BookingModel>> _getCombinedBookingsSnapshot(
    String userId,
    BookingStatus? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit,
  ) async {
    try {
      // Get bookings as player
      Query playerQuery = _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId);

      // Get bookings as coach
      Query coachQuery = _firestore
          .collection(_bookingsCollection)
          .where('ownerId', isEqualTo: userId);

      // Apply filters to both queries
      if (statusFilter != null) {
        playerQuery = playerQuery.where('status', isEqualTo: statusFilter.value);
        coachQuery = coachQuery.where('status', isEqualTo: statusFilter.value);
      }

      if (startDate != null) {
        playerQuery = playerQuery.where('selectedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        coachQuery = coachQuery.where('selectedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        playerQuery = playerQuery.where('selectedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        coachQuery = coachQuery.where('selectedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Execute both queries
      final playerSnapshot = await playerQuery.get();
      final coachSnapshot = await coachQuery.get();

      // Combine results
      final allBookings = <BookingModel>[];
      
      for (final doc in playerSnapshot.docs) {
        allBookings.add(BookingModel.fromFirestore(doc));
      }
      
      for (final doc in coachSnapshot.docs) {
        final booking = BookingModel.fromFirestore(doc);
        // Avoid duplicates (shouldn't happen but just in case)
        if (!allBookings.any((b) => b.id == booking.id)) {
          allBookings.add(booking);
        }
      }

      // Sort by date descending
      allBookings.sort((a, b) => b.selectedDate.compareTo(a.selectedDate));

      // Apply limit
      return allBookings.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingHistoryService: Error in combined bookings snapshot: $e');
      }
      throw Exception('Failed to get combined bookings: $e');
    }
  }

  /// Get upcoming bookings
  Stream<List<BookingModel>> getUpcomingBookings({UserRole? userRole}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (userRole == UserRole.coach) {
      return getCoachBookingHistory(
        startDate: today,
      ).map((bookings) => bookings.where((b) => b.isUpcoming).toList());
    } else if (userRole == UserRole.player) {
      return getUserBookingHistory(
        startDate: today,
      ).map((bookings) => bookings.where((b) => b.isUpcoming).toList());
    } else {
      // Combined view
      return getCombinedBookingHistory(
        startDate: today,
      ).map((bookings) => bookings.where((b) => b.isUpcoming).toList());
    }
  }

  /// Get completed bookings
  Stream<List<BookingModel>> getCompletedBookings({UserRole? userRole}) {
    if (userRole == UserRole.coach) {
      return getCoachBookingHistory(
        statusFilter: BookingStatus.completed,
      );
    } else if (userRole == UserRole.player) {
      return getUserBookingHistory(
        statusFilter: BookingStatus.completed,
      );
    } else {
      // Combined view
      return getCombinedBookingHistory(
        statusFilter: BookingStatus.completed,
      );
    }
  }

  /// Get cancelled bookings
  Stream<List<BookingModel>> getCancelledBookings({UserRole? userRole}) {
    if (userRole == UserRole.coach) {
      return getCoachBookingHistory(
        statusFilter: BookingStatus.cancelled,
      );
    } else if (userRole == UserRole.player) {
      return getUserBookingHistory(
        statusFilter: BookingStatus.cancelled,
      );
    } else {
      // Combined view
      return getCombinedBookingHistory(
        statusFilter: BookingStatus.cancelled,
      );
    }
  }

  /// Calculate earnings summary for coach
  Future<EarningsSummary> getCoachEarningsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final defaultStartDate = startDate ?? DateTime(now.year, now.month, 1);
      final defaultEndDate = endDate ?? now;

      // Get all coach bookings in the period
      final bookings = await _getCombinedBookingsSnapshot(
        user.uid,
        null, // No status filter
        defaultStartDate,
        defaultEndDate,
        1000, // High limit for analytics
      );

      // Filter only bookings where user is the coach
      final coachBookings = bookings.where((b) => b.ownerId == user.uid).toList();

      return EarningsSummary.fromBookings(
        user.uid,
        coachBookings,
        defaultStartDate,
        defaultEndDate,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingHistoryService: Error calculating earnings summary: $e');
      }
      throw Exception('Failed to calculate earnings summary: $e');
    }
  }
}
