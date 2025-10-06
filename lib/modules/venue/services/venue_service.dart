import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../models/venue_model.dart';
import '../../../models/venue_booking_model.dart';
import '../../../models/listing_model.dart';
import '../../../services/notification_service.dart';
import '../../skill_tracking/services/automated_skill_service.dart';

/// Service for managing venues and venue bookings
class VenueService {
  static final VenueService _instance = VenueService._internal();
  factory VenueService() => _instance;
  VenueService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final AutomatedSkillService _automatedSkillService = AutomatedSkillService();

  // Collection references
  CollectionReference get _venuesCollection => _firestore.collection('venues');
  CollectionReference get _venueBookingsCollection => _firestore.collection('venue_bookings');
  CollectionReference get _venueReviewsCollection => _firestore.collection('venue_reviews');

  /// Create a new venue
  Future<String> createVenue({
    required String title,
    required SportType sportType,
    required String description,
    required String location,
    String? gpsCoordinates,
    required double hourlyRate,
    List<String> images = const [],
    required List<TimeSlot> availableTimeSlots,
    required List<String> availableDays,
    List<String> amenities = const [],
    String? contactInfo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final venueId = _venuesCollection.doc().id;

      // Create venue data with server timestamps for Firestore rules compliance
      final venueData = {
        'id': venueId,
        'ownerId': user.uid,
        'ownerName': user.displayName ?? 'Unknown User',
        'ownerProfilePicture': user.photoURL,
        'title': title,
        'sportType': sportType.displayName,
        'description': description,
        'location': location,
        'gpsCoordinates': gpsCoordinates,
        'hourlyRate': hourlyRate,
        'images': images,
        'availableTimeSlots': availableTimeSlots.map((slot) => slot.toMap()).toList(),
        'availableDays': availableDays,
        'amenities': amenities,
        'contactInfo': contactInfo,
        'isActive': true,
        'averageRating': 0.0,
        'totalBookings': 0,
        'totalReviews': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': metadata,
      };

      await _venuesCollection.doc(venueId).set(venueData);
      return venueId;
    } catch (e) {
      throw Exception('Failed to create venue: $e');
    }
  }

  /// Get venue by ID
  Future<VenueModel?> getVenue(String venueId) async {
    try {
      final doc = await _venuesCollection.doc(venueId).get();
      if (doc.exists) {
        return VenueModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get venue: $e');
    }
  }

  /// Get all venues with optional filters
  Stream<List<VenueModel>> getVenues({
    SportType? sportType,
    String? location,
    String? searchQuery,
    int? limit,
  }) {
    try {
      Query query = _venuesCollection.where('isActive', isEqualTo: true);

      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType.displayName);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isGreaterThanOrEqualTo: location)
                    .where('location', isLessThanOrEqualTo: '$location\uf8ff');
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        try {
          var venues = snapshot.docs
              .map((doc) => VenueModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          // Apply search filter if provided
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final searchLower = searchQuery.toLowerCase();
            venues = venues.where((venue) =>
                venue.title.toLowerCase().contains(searchLower) ||
                venue.description.toLowerCase().contains(searchLower) ||
                venue.location.toLowerCase().contains(searchLower)
            ).toList();
          }

          return venues;
        } catch (e) {
          // Log the error and return empty list to prevent stream from breaking
          debugPrint('Error processing venues data: $e');
          return <VenueModel>[];
        }
      }).asBroadcastStream();
    } catch (e) {
      throw Exception('Failed to get venues: $e');
    }
  }

  /// Get venues owned by current user
  Stream<List<VenueModel>> getMyVenues() {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _venuesCollection
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => VenueModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList())
          .asBroadcastStream();
    } catch (e) {
      throw Exception('Failed to get my venues: $e');
    }
  }

  /// Update venue
  Future<void> updateVenue({
    required String venueId,
    String? title,
    SportType? sportType,
    String? description,
    String? location,
    String? gpsCoordinates,
    double? hourlyRate,
    List<String>? images,
    List<TimeSlot>? availableTimeSlots,
    List<String>? availableDays,
    List<String>? amenities,
    String? contactInfo,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) async {
    try {


      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final venue = await getVenue(venueId);
      if (venue == null) {
        throw Exception('Venue not found');
      }

      // Check if user owns the venue
      if (venue.ownerId != user.uid) {
        throw Exception('Only venue owner can update venue');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (sportType != null) updateData['sportType'] = sportType.displayName;
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (gpsCoordinates != null) updateData['gpsCoordinates'] = gpsCoordinates;
      if (hourlyRate != null) updateData['hourlyRate'] = hourlyRate;
      if (images != null) updateData['images'] = images;
      if (availableTimeSlots != null) {
        updateData['availableTimeSlots'] = availableTimeSlots.map((slot) => slot.toMap()).toList();
      }
      if (availableDays != null) updateData['availableDays'] = availableDays;
      if (amenities != null) updateData['amenities'] = amenities;
      if (contactInfo != null) updateData['contactInfo'] = contactInfo;
      if (isActive != null) updateData['isActive'] = isActive;
      if (metadata != null) updateData['metadata'] = metadata;



      await _venuesCollection.doc(venueId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update venue: $e');
    }
  }

  /// Delete venue
  Future<void> deleteVenue(String venueId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final venue = await getVenue(venueId);
      if (venue == null) throw Exception('Venue not found');

      // Check if user owns the venue
      if (venue.ownerId != user.uid) {
        throw Exception('Only venue owner can delete venue');
      }

      // Check for active bookings
      final activeBookings = await _venueBookingsCollection
          .where('venueId', isEqualTo: venueId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      if (activeBookings.docs.isNotEmpty) {
        throw Exception('Cannot delete venue with active bookings');
      }

      await _venuesCollection.doc(venueId).delete();
    } catch (e) {
      throw Exception('Failed to delete venue: $e');
    }
  }

  /// Check if time slot is available for booking
  Future<bool> isTimeSlotAvailable({
    required String venueId,
    required DateTime date,
    required TimeSlot timeSlot,
  }) async {
    try {
      final bookings = await _venueBookingsCollection
          .where('venueId', isEqualTo: venueId)
          .where('selectedDate', isEqualTo: Timestamp.fromDate(date))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      for (final doc in bookings.docs) {
        final booking = VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>);
        if (booking.timeSlot.overlaps(timeSlot)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to check time slot availability: $e');
    }
  }

  /// Book a venue
  Future<String> bookVenue({
    required String venueId,
    required DateTime selectedDate,
    required TimeSlot timeSlot,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final venue = await getVenue(venueId);
      if (venue == null) throw Exception('Venue not found');

      // Check if venue is active
      if (!venue.isActive) throw Exception('Venue is not available for booking');

      // Validate booking date and time
      await _validateBookingDateTime(selectedDate, timeSlot);

      // Validate time slot format
      if (!isValidTimeSlot(timeSlot)) {
        throw Exception('Invalid time slot format or duration');
      }

      // Check business hours
      if (!isWithinBusinessHours(timeSlot)) {
        throw Exception('Booking must be within business hours (6 AM - 11 PM)');
      }

      // Check if user can book this venue (not their own venue)
      if (venue.ownerId == user.uid) {
        throw Exception('You cannot book your own venue');
      }

      // Check for double booking
      final hasConflict = await hasConflictingBooking(
        userId: user.uid,
        date: selectedDate,
        timeSlot: timeSlot,
      );

      if (hasConflict) {
        throw Exception('You already have a booking at this time');
      }

      // Check if time slot is available
      final isAvailable = await isTimeSlotAvailable(
        venueId: venueId,
        date: selectedDate,
        timeSlot: timeSlot,
      );

      if (!isAvailable) {
        throw Exception('Time slot is not available');
      }

      // Check venue availability for the selected day
      final dayOfWeek = _getDayOfWeek(selectedDate.weekday);
      if (!venue.availableDays.contains(dayOfWeek)) {
        throw Exception('Venue is not available on ${dayOfWeek}s');
      }

      final bookingId = _venueBookingsCollection.doc().id;

      // Create booking data with server timestamps for Firestore rules compliance
      final bookingData = {
        'id': bookingId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Unknown User',
        'userProfilePicture': user.photoURL,
        'venueId': venueId,
        'venueTitle': venue.title,
        'venueOwnerId': venue.ownerId,
        'venueOwnerName': venue.ownerName,
        'sportType': venue.sportType.displayName,
        'selectedDate': Timestamp.fromDate(selectedDate),
        'timeSlot': timeSlot.toMap(),
        'status': VenueBookingStatus.pending.value,
        'totalAmount': venue.hourlyRate * timeSlot.durationInHours,
        'hourlyRate': venue.hourlyRate,
        'location': venue.location,
        'notes': notes,
        'cancellationReason': null,
        'confirmedAt': null,
        'cancelledAt': null,
        'completedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': metadata,
      };

      await _venueBookingsCollection.doc(bookingId).set(bookingData);

      // Send notification to venue owner
      try {
        await _notificationService.createVenueBookingNotification(
          venueOwnerId: venue.ownerId,
          venueTitle: venue.title,
          bookerName: user.displayName ?? 'Unknown User',
          bookingId: bookingId,
        );
      } catch (e) {
        // Log notification error but don't fail the booking
      }

      return bookingId;
    } catch (e) {
      throw Exception('Failed to book venue: $e');
    }
  }

  /// Get venue bookings for a user
  Stream<List<VenueBookingModel>> getUserBookings() {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _venueBookingsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  /// Get venue bookings for venue owner
  Stream<List<VenueBookingModel>> getVenueBookings(String venueId) {
    try {
      return _venueBookingsCollection
          .where('venueId', isEqualTo: venueId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to get venue bookings: $e');
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus({
    required String bookingId,
    required VenueBookingStatus status,
    String? cancellationReason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _venueBookingsCollection.doc(bookingId).get();
      if (!doc.exists) throw Exception('Booking not found');

      // final booking = VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>);

      final updateData = <String, dynamic>{
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add timestamp based on status
      switch (status) {
        case VenueBookingStatus.confirmed:
          updateData['confirmedAt'] = FieldValue.serverTimestamp();
          break;
        case VenueBookingStatus.cancelled:
          updateData['cancelledAt'] = FieldValue.serverTimestamp();
          if (cancellationReason != null) {
            updateData['cancellationReason'] = cancellationReason;
          }
          break;
        case VenueBookingStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _venueBookingsCollection.doc(bookingId).update(updateData);

      // Trigger automated skill updates if booking is completed
      if (status == VenueBookingStatus.completed) {
        try {
          final booking = VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>);
          final sessionDuration = _calculateSessionDuration(booking.timeSlot);

          await _automatedSkillService.onVenueBookingCompleted(
            bookingId: bookingId,
            userId: booking.userId,
            sportType: booking.sportType,
            sessionDurationHours: sessionDuration,
            venueTitle: booking.venueTitle,
            additionalMetadata: {
              'venueId': booking.venueId,
              'venueOwnerId': booking.venueOwnerId,
              'venueOwnerName': booking.venueOwnerName,
              'location': booking.location,
            },
          );
        } catch (skillUpdateError) {
          // Log skill update error but don't fail the booking status update
          if (kDebugMode) {
            debugPrint('⚠️ VenueService: Skill update failed: $skillUpdateError');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Calculate session duration in hours from time slot
  double _calculateSessionDuration(TimeSlot timeSlot) {
    try {
      final startParts = timeSlot.start.split(':');
      final endParts = timeSlot.end.split(':');

      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      return (endMinutes - startMinutes) / 60.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating session duration: $e');
      }
      return 1.0; // Default to 1 hour if calculation fails
    }
  }

  /// Add review for venue
  Future<String> addVenueReview({
    required String venueId,
    required double rating,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user has completed booking for this venue
      final completedBookings = await _venueBookingsCollection
          .where('venueId', isEqualTo: venueId)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: VenueBookingStatus.completed.value)
          .get();

      if (completedBookings.docs.isEmpty) {
        throw Exception('You can only review venues you have booked');
      }

      // Check if user already reviewed this venue
      final existingReview = await _venueReviewsCollection
          .where('venueId', isEqualTo: venueId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingReview.docs.isNotEmpty) {
        throw Exception('You have already reviewed this venue');
      }

      final reviewId = _venueReviewsCollection.doc().id;

      // Create review data with server timestamp for Firestore rules compliance
      final reviewData = {
        'id': reviewId,
        'venueId': venueId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Unknown User',
        'userProfilePicture': user.photoURL,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add review and update venue rating in a batch
      final batch = _firestore.batch();

      batch.set(_venueReviewsCollection.doc(reviewId), reviewData);

      // Update venue rating
      final venue = await getVenue(venueId);
      if (venue != null) {
        final newTotalReviews = venue.totalReviews + 1;
        final newAverageRating = ((venue.averageRating * venue.totalReviews) + rating) / newTotalReviews;

        batch.update(_venuesCollection.doc(venueId), {
          'averageRating': newAverageRating,
          'totalReviews': newTotalReviews,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return reviewId;
    } catch (e) {
      throw Exception('Failed to add venue review: $e');
    }
  }

  /// Get venue reviews
  Stream<List<VenueReview>> getVenueReviews(String venueId) {
    try {
      return _venueReviewsCollection
          .where('venueId', isEqualTo: venueId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => VenueReview.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to get venue reviews: $e');
    }
  }

  /// Get available time slots for a specific date
  Future<List<TimeSlot>> getAvailableTimeSlots({
    required String venueId,
    required DateTime date,
  }) async {
    try {
      final venue = await getVenue(venueId);
      if (venue == null) throw Exception('Venue not found');

      // Get day of week
      final dayOfWeek = _getDayOfWeek(date.weekday);

      // Check if venue is available on this day
      if (!venue.availableDays.contains(dayOfWeek)) {
        return [];
      }

      // Get booked time slots for this date
      final bookings = await _venueBookingsCollection
          .where('venueId', isEqualTo: venueId)
          .where('selectedDate', isEqualTo: Timestamp.fromDate(date))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final bookedTimeSlots = bookings.docs
          .map((doc) => VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>))
          .map((booking) => booking.timeSlot)
          .toList();

      // Filter out booked time slots
      final availableTimeSlots = venue.availableTimeSlots.where((timeSlot) {
        return !bookedTimeSlots.any((bookedSlot) => bookedSlot.overlaps(timeSlot));
      }).toList();

      return availableTimeSlots;
    } catch (e) {
      throw Exception('Failed to get available time slots: $e');
    }
  }

  /// Cancel venue booking
  Future<void> cancelVenueBooking({
    required String bookingId,
    String? cancellationReason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get booking details
      final bookingDoc = await _venueBookingsCollection.doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');

      final booking = VenueBookingModel.fromMap(bookingDoc.data() as Map<String, dynamic>);

      // Check if user can cancel this booking
      if (booking.userId != user.uid && booking.venueOwnerId != user.uid) {
        throw Exception('You can only cancel your own bookings or bookings for your venues');
      }

      // Check if booking can be cancelled (not already completed or cancelled)
      if (booking.status == VenueBookingStatus.completed) {
        throw Exception('Cannot cancel completed booking');
      }

      if (booking.status == VenueBookingStatus.cancelled) {
        throw Exception('Booking is already cancelled');
      }

      // Check if booking is in the past
      final now = DateTime.now();
      final bookingDateTime = DateTime(
        booking.selectedDate.year,
        booking.selectedDate.month,
        booking.selectedDate.day,
        int.parse(booking.timeSlot.start.split(':')[0]),
        int.parse(booking.timeSlot.start.split(':')[1]),
      );

      if (bookingDateTime.isBefore(now)) {
        throw Exception('Cannot cancel past bookings');
      }

      // Update booking status
      await updateBookingStatus(
        bookingId: bookingId,
        status: VenueBookingStatus.cancelled,
        cancellationReason: cancellationReason,
      );

      // Send notification to the other party
      try {
        final isUserCancelling = booking.userId == user.uid;
        final notificationUserId = isUserCancelling ? booking.venueOwnerId : booking.userId;
        final notificationTitle = isUserCancelling
            ? 'Booking Cancelled'
            : 'Venue Booking Cancelled';
        final notificationMessage = isUserCancelling
            ? '${booking.userName} cancelled their booking for ${booking.venueTitle}'
            : 'Your booking for ${booking.venueTitle} has been cancelled by the venue owner';

        await _notificationService.createGeneralNotification(
          userId: notificationUserId,
          title: notificationTitle,
          message: notificationMessage,
          data: {
            'bookingId': bookingId,
            'venueId': booking.venueId,
            'type': 'venue_booking_cancelled',
          },
        );
      } catch (e) {
        // Log notification error but don't fail the cancellation
        if (kDebugMode) {
          debugPrint('⚠️ VenueService: Failed to send cancellation notification: $e');
        }
      }


    } catch (e) {
      throw Exception('Failed to cancel venue booking: $e');
    }
  }

  /// Reschedule venue booking
  Future<void> rescheduleVenueBooking({
    required String bookingId,
    required DateTime newDate,
    required TimeSlot newTimeSlot,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get booking details
      final bookingDoc = await _venueBookingsCollection.doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');

      final booking = VenueBookingModel.fromMap(bookingDoc.data() as Map<String, dynamic>);

      // Check if user can reschedule this booking
      if (booking.userId != user.uid) {
        throw Exception('You can only reschedule your own bookings');
      }

      // Check if booking can be rescheduled
      if (booking.status == VenueBookingStatus.completed) {
        throw Exception('Cannot reschedule completed booking');
      }

      if (booking.status == VenueBookingStatus.cancelled) {
        throw Exception('Cannot reschedule cancelled booking');
      }

      // Check if new date is not in the past
      final now = DateTime.now();
      final newBookingDateTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        int.parse(newTimeSlot.start.split(':')[0]),
        int.parse(newTimeSlot.start.split(':')[1]),
      );

      if (newBookingDateTime.isBefore(now)) {
        throw Exception('Cannot reschedule to a past date/time');
      }

      // Check if new time slot is available
      final isAvailable = await isTimeSlotAvailable(
        venueId: booking.venueId,
        date: newDate,
        timeSlot: newTimeSlot,
      );

      if (!isAvailable) {
        throw Exception('New time slot is not available');
      }

      // Update booking with new date and time
      final updateData = <String, dynamic>{
        'selectedDate': Timestamp.fromDate(newDate),
        'timeSlot': newTimeSlot.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null && notes.trim().isNotEmpty) {
        updateData['notes'] = notes.trim();
      }

      await _venueBookingsCollection.doc(bookingId).update(updateData);

      // Send notification to venue owner
      try {
        await _notificationService.createGeneralNotification(
          userId: booking.venueOwnerId,
          title: 'Booking Rescheduled',
          message: '${booking.userName} rescheduled their booking for ${booking.venueTitle}',
          data: {
            'bookingId': bookingId,
            'venueId': booking.venueId,
            'type': 'venue_booking_rescheduled',
            'newDate': newDate.toIso8601String(),
            'newTimeSlot': newTimeSlot.toMap(),
          },
        );
      } catch (e) {
        // Log notification error but don't fail the reschedule
        if (kDebugMode) {
          debugPrint('⚠️ VenueService: Failed to send reschedule notification: $e');
        }
      }


    } catch (e) {
      throw Exception('Failed to reschedule venue booking: $e');
    }
  }

  /// Get single venue booking by ID
  Future<VenueBookingModel?> getVenueBooking(String bookingId) async {
    try {
      final doc = await _venueBookingsCollection.doc(bookingId).get();
      if (!doc.exists) return null;

      return VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get venue booking: $e');
    }
  }

  /// Check if user has double booking at the same time
  Future<bool> hasConflictingBooking({
    required String userId,
    required DateTime date,
    required TimeSlot timeSlot,
    String? excludeBookingId,
  }) async {
    try {
      final query = _venueBookingsCollection
          .where('userId', isEqualTo: userId)
          .where('selectedDate', isEqualTo: Timestamp.fromDate(date))
          .where('status', whereIn: ['pending', 'confirmed']);

      final bookings = await query.get();

      for (final doc in bookings.docs) {
        final booking = VenueBookingModel.fromMap(doc.data() as Map<String, dynamic>);

        // Skip the booking being rescheduled
        if (excludeBookingId != null && booking.id == excludeBookingId) {
          continue;
        }

        // Check if time slots overlap
        if (booking.timeSlot.overlaps(timeSlot)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check conflicting bookings: $e');
    }
  }

  /// Validate booking date and time
  Future<void> _validateBookingDateTime(DateTime selectedDate, TimeSlot timeSlot) async {
    final now = DateTime.now();

    // Check if booking date is in the past
    final bookingDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final today = DateTime(now.year, now.month, now.day);

    if (bookingDate.isBefore(today)) {
      throw Exception('Cannot book venues for past dates');
    }

    // Check if booking time is too close to current time (minimum 1 hour advance booking)
    final bookingDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(timeSlot.start.split(':')[0]),
      int.parse(timeSlot.start.split(':')[1]),
    );

    final minimumAdvanceTime = now.add(const Duration(hours: 1));
    if (bookingDateTime.isBefore(minimumAdvanceTime)) {
      throw Exception('Bookings must be made at least 1 hour in advance');
    }

    // Check if booking is too far in the future (maximum 90 days)
    final maxFutureDate = now.add(const Duration(days: 90));
    if (bookingDateTime.isAfter(maxFutureDate)) {
      throw Exception('Bookings can only be made up to 90 days in advance');
    }
  }

  /// Validate time slot format and duration
  bool isValidTimeSlot(TimeSlot timeSlot) {
    try {
      final startParts = timeSlot.start.split(':');
      final endParts = timeSlot.end.split(':');

      if (startParts.length != 2 || endParts.length != 2) return false;

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      // Validate hour and minute ranges
      if (startHour < 0 || startHour > 23 || endHour < 0 || endHour > 23) return false;
      if (startMinute < 0 || startMinute > 59 || endMinute < 0 || endMinute > 59) return false;

      // Check if end time is after start time
      final startTotalMinutes = startHour * 60 + startMinute;
      final endTotalMinutes = endHour * 60 + endMinute;

      if (endTotalMinutes <= startTotalMinutes) return false;

      // Check minimum duration (30 minutes)
      final durationMinutes = endTotalMinutes - startTotalMinutes;
      if (durationMinutes < 30) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if booking is within business hours
  bool isWithinBusinessHours(TimeSlot timeSlot) {
    try {
      final startParts = timeSlot.start.split(':');
      final endParts = timeSlot.end.split(':');

      final startHour = int.parse(startParts[0]);
      final endHour = int.parse(endParts[0]);

      // Typical business hours: 6 AM to 11 PM
      return startHour >= 6 && endHour <= 23;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to get day of week string
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }
}
