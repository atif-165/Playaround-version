import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../models/booking_model.dart';
import '../../../models/listing_model.dart';
import '../../../models/notification_model.dart';
import '../../../services/rating_service.dart';
import '../../../services/notification_service.dart';
import '../../skill_tracking/services/automated_skill_service.dart';

/// Service class for managing bookings in Firestore
class BookingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AutomatedSkillService _automatedSkillService;
  final RatingService _ratingService;
  final NotificationService _notificationService;

  static const String _bookingsCollection = 'bookings';

  BookingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AutomatedSkillService? automatedSkillService,
    RatingService? ratingService,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _automatedSkillService =
            automatedSkillService ?? AutomatedSkillService(),
        _ratingService = ratingService ?? RatingService(),
        _notificationService = notificationService ??
            NotificationService(firestore: firestore, auth: auth);

  /// Create a new booking
  Future<String> createBooking({
    required String listingId,
    required DateTime selectedDate,
    required TimeSlot timeSlot,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get listing details
      final listingDoc =
          await _firestore.collection('listings').doc(listingId).get();

      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }

      final listing = ListingModel.fromFirestore(listingDoc);

      // Check if the time slot is available
      final isAvailable = await _checkTimeSlotAvailability(
        listingId,
        selectedDate,
        timeSlot,
      );

      if (!isAvailable) {
        throw Exception('Time slot is not available');
      }

      // Calculate total amount based on duration
      final duration = _calculateDuration(timeSlot);
      final totalAmount = listing.hourlyRate * duration;

      final now = DateTime.now();
      final bookingId = _firestore.collection(_bookingsCollection).doc().id;

      final booking = BookingModel(
        id: bookingId,
        userId: user.uid,
        userName: user.displayName ?? 'Unknown User',
        userProfilePicture: user.photoURL,
        listingId: listingId,
        listingTitle: listing.title,
        listingType: listing.type,
        ownerId: listing.ownerId,
        ownerName: listing.ownerName,
        sportType: listing.sportType,
        selectedDate: selectedDate,
        timeSlot: timeSlot,
        status: BookingStatus.confirmed, // Auto-confirm for now
        totalAmount: totalAmount,
        hourlyRate: listing.hourlyRate,
        location: listing.location,
        notes: notes,
        confirmedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_bookingsCollection)
          .doc(bookingId)
          .set(booking.toFirestore());

      if (kDebugMode) {
        debugPrint('✅ BookingService: Created booking with ID: $bookingId');
      }

      return bookingId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingService: Error creating booking: $e');
      }
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get booking by ID
  Future<BookingModel?> getBooking(String bookingId) async {
    try {
      final doc =
          await _firestore.collection(_bookingsCollection).doc(bookingId).get();

      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingService: Error getting booking: $e');
      }
      throw Exception('Failed to get booking: $e');
    }
  }

  /// Get bookings by user
  Stream<List<BookingModel>> getBookingsByUser(String userId) {
    try {
      return _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('selectedDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingService: Error getting bookings by user: $e');
      }
      throw Exception('Failed to get bookings by user: $e');
    }
  }

  /// Get bookings for listing owner
  Stream<List<BookingModel>> getBookingsForOwner(String ownerId) {
    try {
      return _firestore
          .collection(_bookingsCollection)
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('selectedDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingService: Error getting bookings for owner: $e');
      }
      throw Exception('Failed to get bookings for owner: $e');
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(
      String bookingId, String cancellationReason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final booking = await getBooking(bookingId);
      if (booking == null) throw Exception('Booking not found');

      // Check if user can cancel this booking
      if (booking.userId != user.uid && booking.ownerId != user.uid) {
        throw Exception('Only booking owner or listing owner can cancel');
      }

      if (!booking.canBeCancelled) {
        throw Exception('Booking cannot be cancelled at this time');
      }

      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': BookingStatus.cancelled.value,
        'cancellationReason': cancellationReason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        debugPrint('✅ BookingService: Cancelled booking: $bookingId');
      }

      await _notifyBookingUpdate(
        booking: booking,
        status: BookingStatus.cancelled,
        triggeredByUserId: user.uid,
        extraMessage: cancellationReason,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingService: Error cancelling booking: $e');
      }
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Complete booking
  Future<void> completeBooking(String bookingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final booking = await getBooking(bookingId);
      if (booking == null) throw Exception('Booking not found');

      // Only listing owner can mark as completed
      if (booking.ownerId != user.uid) {
        throw Exception('Only listing owner can mark booking as completed');
      }

      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': BookingStatus.completed.value,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Trigger automated skill updates for the booking user
      try {
        final sessionDuration = _calculateSessionDuration(booking.timeSlot);
        await _automatedSkillService.onBookingCompleted(
          bookingId: bookingId,
          userId: booking.userId,
          sportType: booking.sportType,
          sessionDurationHours: sessionDuration,
          sessionTitle: booking.listingTitle,
          additionalMetadata: {
            'listingType': booking.listingType.value,
            'ownerId': booking.ownerId,
            'ownerName': booking.ownerName,
            'location': booking.location,
          },
        );
      } catch (skillUpdateError) {
        // Log skill update error but don't fail the booking completion
        if (kDebugMode) {
          debugPrint(
              '⚠️ BookingService: Skill update failed: $skillUpdateError');
        }
      }

      // Create pending rating requests
      try {
        await _ratingService.createPendingRatings(booking);
        if (kDebugMode) {
          debugPrint(
              '✅ BookingService: Created pending ratings for booking: $bookingId');
        }
      } catch (ratingError) {
        // Log rating creation error but don't fail the booking completion
        if (kDebugMode) {
          debugPrint('⚠️ BookingService: Rating creation failed: $ratingError');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ BookingService: Completed booking: $bookingId');
      }

      await _notifyBookingUpdate(
        booking: booking,
        status: BookingStatus.completed,
        triggeredByUserId: user.uid,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingService: Error completing booking: $e');
      }
      throw Exception('Failed to complete booking: $e');
    }
  }

  /// Calculate session duration in hours from time slot
  double _calculateSessionDuration(TimeSlot timeSlot) {
    try {
      final startParts = timeSlot.start.split(':');
      final endParts = timeSlot.end.split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      return (endMinutes - startMinutes) / 60.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating session duration: $e');
      }
      return 1.0; // Default to 1 hour if calculation fails
    }
  }

  /// Check if a time slot is available for booking
  Future<bool> _checkTimeSlotAvailability(
    String listingId,
    DateTime selectedDate,
    TimeSlot timeSlot,
  ) async {
    try {
      // Check for existing bookings on the same date and overlapping time
      final existingBookings = await _firestore
          .collection(_bookingsCollection)
          .where('listingId', isEqualTo: listingId)
          .where('selectedDate', isEqualTo: Timestamp.fromDate(selectedDate))
          .where('status', whereIn: [
        BookingStatus.confirmed.value,
        BookingStatus.pending.value,
      ]).get();

      for (final doc in existingBookings.docs) {
        final booking = BookingModel.fromFirestore(doc);
        if (_timeSlotsOverlap(timeSlot, booking.timeSlot)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingService: Error checking availability: $e');
      }
      return false;
    }
  }

  /// Check if two time slots overlap
  bool _timeSlotsOverlap(TimeSlot slot1, TimeSlot slot2) {
    final start1 = _timeToMinutes(slot1.start);
    final end1 = _timeToMinutes(slot1.end);
    final start2 = _timeToMinutes(slot2.start);
    final end2 = _timeToMinutes(slot2.end);

    return start1 < end2 && start2 < end1;
  }

  /// Convert time string to minutes
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Calculate duration in hours
  double _calculateDuration(TimeSlot timeSlot) {
    final startMinutes = _timeToMinutes(timeSlot.start);
    final endMinutes = _timeToMinutes(timeSlot.end);
    return (endMinutes - startMinutes) / 60.0;
  }

  /// Get available time slots for a listing on a specific date
  Future<List<TimeSlot>> getAvailableTimeSlots(
    String listingId,
    DateTime selectedDate,
  ) async {
    try {
      // Get listing details
      final listingDoc =
          await _firestore.collection('listings').doc(listingId).get();

      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }

      final listing = ListingModel.fromFirestore(listingDoc);

      // Get existing bookings for the date
      final existingBookings = await _firestore
          .collection(_bookingsCollection)
          .where('listingId', isEqualTo: listingId)
          .where('selectedDate', isEqualTo: Timestamp.fromDate(selectedDate))
          .where('status', whereIn: [
        BookingStatus.confirmed.value,
        BookingStatus.pending.value,
      ]).get();

      final bookedSlots = existingBookings.docs
          .map((doc) => BookingModel.fromFirestore(doc).timeSlot)
          .toList();

      // Filter out booked slots
      final availableSlots = listing.availableTimeSlots.where((slot) {
        return !bookedSlots
            .any((bookedSlot) => _timeSlotsOverlap(slot, bookedSlot));
      }).toList();

      return availableSlots;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingService: Error getting available slots: $e');
      }
      throw Exception('Failed to get available time slots: $e');
    }
  }

  Future<void> _notifyBookingUpdate({
    required BookingModel booking,
    required BookingStatus status,
    required String triggeredByUserId,
    String? extraMessage,
  }) async {
    try {
      final eventDateTime =
          _combineDateAndTime(booking.selectedDate, booking.timeSlot.start);
      final formatter = DateFormat('EEE, MMM d • h:mm a');
      final title = 'Booking ${status.displayName}';
      final statusMessage = status == BookingStatus.cancelled
          ? 'Booking for ${booking.listingTitle} was cancelled'
          : 'Booking for ${booking.listingTitle} is ${status.displayName.toLowerCase()}';

      final message = [
        statusMessage,
        formatter.format(eventDateTime),
        if (extraMessage != null && extraMessage.isNotEmpty) extraMessage,
      ].join(' • ');

      final targets = <String>{booking.userId, booking.ownerId}
        ..remove(triggeredByUserId);

      for (final userId in targets) {
        await _notificationService.createNotification(
          userId: userId,
          type: NotificationType.bookingUpdate,
          title: title,
          message: message,
          data: {
            'bookingId': booking.id,
            'listingId': booking.listingId,
            'listingTitle': booking.listingTitle,
            'status': status.value,
            'startTime': eventDateTime.toIso8601String(),
            'location': booking.location,
            'triggeredBy': triggeredByUserId,
            if (extraMessage != null) 'notes': extraMessage,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ BookingService: Failed to send booking notification - $e');
      }
    }
  }

  DateTime _combineDateAndTime(DateTime date, String startTime) {
    final parts = startTime.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
