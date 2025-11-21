import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/venue_booking_model.dart';
import '../../../models/user_profile.dart';

/// Service for managing venue booking history and filtering
class VenueBookingHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _venueBookingsCollection = 'venue_bookings';

  /// Get upcoming venue bookings for current user
  Stream<List<VenueBookingModel>> getUpcomingVenueBookings({
    UserRole? userRole,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      Query query = _firestore.collection(_venueBookingsCollection);

      // Filter based on user role
      if (userRole == UserRole.coach || userRole == UserRole.admin) {
        // For coaches/admins, show bookings for their venues AND their own bookings
        query = query.where(Filter.or(
          Filter.and(
            Filter('venueOwnerId', isEqualTo: user.uid),
            Filter('status', whereIn: ['pending', 'confirmed']),
          ),
          Filter.and(
            Filter('userId', isEqualTo: user.uid),
            Filter('status', whereIn: ['pending', 'confirmed']),
          ),
        ));
      } else {
        // For players, show only their own bookings
        query = query
            .where('userId', isEqualTo: user.uid)
            .where('status', whereIn: ['pending', 'confirmed']);
      }

      return query
          .orderBy('selectedDate')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final bookings = snapshot.docs
            .map((doc) =>
                VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
            .where((booking) {
          // Filter out past bookings
          final bookingDate = DateTime(
            booking.selectedDate.year,
            booking.selectedDate.month,
            booking.selectedDate.day,
          );
          return bookingDate.isAfter(today) ||
              bookingDate.isAtSameMomentAs(today);
        }).toList();

        return bookings;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting upcoming venue bookings: $e');
      }
      throw Exception('Failed to get upcoming venue bookings: $e');
    }
  }

  /// Get completed venue bookings for current user
  Stream<List<VenueBookingModel>> getCompletedVenueBookings({
    UserRole? userRole,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore.collection(_venueBookingsCollection);

      // Filter based on user role
      if (userRole == UserRole.coach || userRole == UserRole.admin) {
        // For coaches/admins, show bookings for their venues AND their own bookings
        query = query.where(Filter.or(
          Filter.and(
            Filter('venueOwnerId', isEqualTo: user.uid),
            Filter('status', isEqualTo: 'completed'),
          ),
          Filter.and(
            Filter('userId', isEqualTo: user.uid),
            Filter('status', isEqualTo: 'completed'),
          ),
        ));
      } else {
        // For players, show only their own bookings
        query = query
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed');
      }

      return query.orderBy('completedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting completed venue bookings: $e');
      }
      throw Exception('Failed to get completed venue bookings: $e');
    }
  }

  /// Get cancelled venue bookings for current user
  Stream<List<VenueBookingModel>> getCancelledVenueBookings({
    UserRole? userRole,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore.collection(_venueBookingsCollection);

      // Filter based on user role
      if (userRole == UserRole.coach || userRole == UserRole.admin) {
        // For coaches/admins, show bookings for their venues AND their own bookings
        query = query.where(Filter.or(
          Filter.and(
            Filter('venueOwnerId', isEqualTo: user.uid),
            Filter('status', isEqualTo: 'cancelled'),
          ),
          Filter.and(
            Filter('userId', isEqualTo: user.uid),
            Filter('status', isEqualTo: 'cancelled'),
          ),
        ));
      } else {
        // For players, show only their own bookings
        query = query
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'cancelled');
      }

      return query.orderBy('cancelledAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting cancelled venue bookings: $e');
      }
      throw Exception('Failed to get cancelled venue bookings: $e');
    }
  }

  /// Get all venue bookings for current user (for general overview)
  Stream<List<VenueBookingModel>> getAllVenueBookings({
    UserRole? userRole,
    int? limit,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore.collection(_venueBookingsCollection);

      // Filter based on user role
      if (userRole == UserRole.coach || userRole == UserRole.admin) {
        // For coaches/admins, show bookings for their venues AND their own bookings
        query = query.where(Filter.or(
          Filter('venueOwnerId', isEqualTo: user.uid),
          Filter('userId', isEqualTo: user.uid),
        ));
      } else {
        // For players, show only their own bookings
        query = query.where('userId', isEqualTo: user.uid);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) =>
              VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all venue bookings: $e');
      }
      throw Exception('Failed to get all venue bookings: $e');
    }
  }

  /// Get venue bookings by status
  Stream<List<VenueBookingModel>> getVenueBookingsByStatus({
    required VenueBookingStatus status,
    UserRole? userRole,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore.collection(_venueBookingsCollection);

      // Filter based on user role
      if (userRole == UserRole.coach || userRole == UserRole.admin) {
        // For coaches/admins, show bookings for their venues AND their own bookings
        query = query.where(Filter.or(
          Filter.and(
            Filter('venueOwnerId', isEqualTo: user.uid),
            Filter('status', isEqualTo: status.value),
          ),
          Filter.and(
            Filter('userId', isEqualTo: user.uid),
            Filter('status', isEqualTo: status.value),
          ),
        ));
      } else {
        // For players, show only their own bookings
        query = query
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: status.value);
      }

      return query.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting venue bookings by status: $e');
      }
      throw Exception('Failed to get venue bookings by status: $e');
    }
  }

  /// Get booking statistics for current user
  Future<Map<String, int>> getBookingStatistics({UserRole? userRole}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore.collection(_venueBookingsCollection);

      // Filter based on user role
      if (userRole == UserRole.coach || userRole == UserRole.admin) {
        query = query.where(Filter.or(
          Filter('venueOwnerId', isEqualTo: user.uid),
          Filter('userId', isEqualTo: user.uid),
        ));
      } else {
        query = query.where('userId', isEqualTo: user.uid);
      }

      final snapshot = await query.get();
      final bookings = snapshot.docs
          .map((doc) =>
              VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final stats = <String, int>{
        'total': bookings.length,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final booking in bookings) {
        switch (booking.status) {
          case VenueBookingStatus.pending:
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case VenueBookingStatus.confirmed:
            stats['confirmed'] = (stats['confirmed'] ?? 0) + 1;
            break;
          case VenueBookingStatus.completed:
            stats['completed'] = (stats['completed'] ?? 0) + 1;
            break;
          case VenueBookingStatus.cancelled:
            stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting booking statistics: $e');
      }
      throw Exception('Failed to get booking statistics: $e');
    }
  }
}
