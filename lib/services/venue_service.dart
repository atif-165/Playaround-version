import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/venue.dart';
import '../models/venue_booking.dart';
import '../models/venue_review.dart';

class VenueService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _venuesCollection = 'venues';
  static const String _bookingsCollection = 'venue_bookings';
  static const String _reviewsCollection = 'venue_reviews';
  static const String _slotsCollection = 'booking_slots';

  // Venue CRUD Operations
  static Future<List<Venue>> getVenues({
    VenueFilter? filter,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection(_venuesCollection);

      // Apply filters
      if (filter != null) {
        if (filter.city != null) {
          query = query.where('city', isEqualTo: filter.city);
        }
        if (filter.state != null) {
          query = query.where('state', isEqualTo: filter.state);
        }
        if (filter.country != null) {
          query = query.where('country', isEqualTo: filter.country);
        }
        if (filter.sports.isNotEmpty) {
          query = query.where('sports', arrayContainsAny: filter.sports);
        }
        if (filter.minPrice != null) {
          query = query.where('pricing.hourlyRate',
              isGreaterThanOrEqualTo: filter.minPrice);
        }
        if (filter.maxPrice != null) {
          query = query.where('pricing.hourlyRate',
              isLessThanOrEqualTo: filter.maxPrice);
        }
        if (filter.minRating != null) {
          query =
              query.where('rating', isGreaterThanOrEqualTo: filter.minRating);
        }
        if (filter.isVerified != null) {
          query = query.where('isVerified', isEqualTo: filter.isVerified);
        }
        if (filter.isActive != null) {
          query = query.where('isActive', isEqualTo: filter.isActive);
        }
      }

      // Apply sorting
      if (filter?.sortBy != null) {
        switch (filter!.sortBy) {
          case 'rating':
            query = query.orderBy('rating',
                descending: !(filter.sortAscending ?? false));
            break;
          case 'price':
            query = query.orderBy('pricing.hourlyRate',
                descending: filter.sortAscending ?? false);
            break;
          case 'newest':
            query = query.orderBy('createdAt',
                descending: !(filter.sortAscending ?? false));
            break;
        }
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      query = query.limit(limit);

      QuerySnapshot snapshot = await query.get();
      List<Venue> venues =
          snapshot.docs.map((doc) => Venue.fromFirestore(doc)).toList();

      // Apply location-based filtering if coordinates are provided
      if (filter?.latitude != null &&
          filter?.longitude != null &&
          filter?.radius != null) {
        venues = venues.where((venue) {
          double distance = Geolocator.distanceBetween(
                filter!.latitude!,
                filter.longitude!,
                venue.latitude,
                venue.longitude,
              ) /
              1000; // Convert to kilometers
          return distance <= filter.radius!;
        }).toList();
      }

      // Apply text search filter
      if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
        String searchQuery = filter.searchQuery!.toLowerCase();
        venues = venues.where((venue) {
          return venue.name.toLowerCase().contains(searchQuery) ||
              venue.description.toLowerCase().contains(searchQuery) ||
              venue.address.toLowerCase().contains(searchQuery) ||
              venue.sports
                  .any((sport) => sport.toLowerCase().contains(searchQuery));
        }).toList();
      }

      return venues;
    } catch (e) {
      throw Exception('Failed to fetch venues: $e');
    }
  }

  static Future<Venue?> getVenueById(String venueId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_venuesCollection).doc(venueId).get();

      if (doc.exists) {
        return Venue.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch venue: $e');
    }
  }

  static Future<String> createVenue(Venue venue) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_venuesCollection)
          .add(venue.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create venue: $e');
    }
  }

  static Future<void> updateVenue(String venueId, Venue venue) async {
    try {
      await _firestore
          .collection(_venuesCollection)
          .doc(venueId)
          .update(venue.toFirestore());
    } catch (e) {
      throw Exception('Failed to update venue: $e');
    }
  }

  static Future<void> deleteVenue(String venueId) async {
    try {
      await _firestore
          .collection(_venuesCollection)
          .doc(venueId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete venue: $e');
    }
  }

  // Booking Operations
  static Future<String> createBooking(VenueBooking booking) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_bookingsCollection)
          .add(booking.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  static Future<List<VenueBooking>> getUserBookings(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VenueBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  static Future<List<VenueBooking>> getVenueBookings(String venueId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_bookingsCollection)
          .where('venueId', isEqualTo: venueId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VenueBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch venue bookings: $e');
    }
  }

  static Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  static Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Review Operations
  static Future<String> createReview(VenueReview review) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toFirestore());

      // Update venue rating
      await _updateVenueRating(review.venueId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  static Future<List<VenueReview>> getVenueReviews(String venueId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('venueId', isEqualTo: venueId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VenueReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch venue reviews: $e');
    }
  }

  static Future<void> _updateVenueRating(String venueId) async {
    try {
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('venueId', isEqualTo: venueId)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          VenueReview review = VenueReview.fromFirestore(doc);
          totalRating += review.rating;
        }
        double averageRating = totalRating / reviewsSnapshot.docs.length;

        await _firestore.collection(_venuesCollection).doc(venueId).update({
          'rating': averageRating,
          'totalReviews': reviewsSnapshot.docs.length,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update venue rating: $e');
    }
  }

  // Booking Slots Operations
  static Future<List<BookingSlot>> getAvailableSlots(
    String venueId,
    DateTime date,
  ) async {
    try {
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(_slotsCollection)
          .where('venueId', isEqualTo: venueId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('isAvailable', isEqualTo: true)
          .orderBy('date')
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => BookingSlot.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch available slots: $e');
    }
  }

  static Future<void> createBookingSlots(
    String venueId,
    List<BookingSlot> slots,
  ) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (BookingSlot slot in slots) {
        DocumentReference docRef =
            _firestore.collection(_slotsCollection).doc();
        batch.set(docRef, slot.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create booking slots: $e');
    }
  }

  static Future<void> updateSlotAvailability(
    String slotId,
    bool isAvailable,
    String? bookingId,
  ) async {
    try {
      await _firestore.collection(_slotsCollection).doc(slotId).update({
        'isAvailable': isAvailable,
        'bookingId': bookingId,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update slot availability: $e');
    }
  }

  // Search and Filter Operations
  static Future<List<Venue>> searchVenues(String query) async {
    try {
      // This is a basic implementation. For production, consider using
      // Algolia or Elasticsearch for better search capabilities
      QuerySnapshot snapshot = await _firestore
          .collection(_venuesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      List<Venue> allVenues =
          snapshot.docs.map((doc) => Venue.fromFirestore(doc)).toList();

      String searchQuery = query.toLowerCase();
      return allVenues.where((venue) {
        return venue.name.toLowerCase().contains(searchQuery) ||
            venue.description.toLowerCase().contains(searchQuery) ||
            venue.address.toLowerCase().contains(searchQuery) ||
            venue.city.toLowerCase().contains(searchQuery) ||
            venue.sports
                .any((sport) => sport.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search venues: $e');
    }
  }

  // Analytics and Statistics
  static Future<Map<String, dynamic>> getVenueAnalytics(String venueId) async {
    try {
      // Get booking statistics
      QuerySnapshot bookingsSnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('venueId', isEqualTo: venueId)
          .get();

      int totalBookings = bookingsSnapshot.docs.length;
      int completedBookings = bookingsSnapshot.docs
          .where((doc) =>
              (doc.data() as Map<String, dynamic>)['status'] == 'completed')
          .length;

      // Get revenue statistics
      double totalRevenue = 0;
      for (var doc in bookingsSnapshot.docs) {
        VenueBooking booking = VenueBooking.fromFirestore(doc);
        if (booking.status == BookingStatus.completed) {
          totalRevenue += booking.totalAmount;
        }
      }

      // Get review statistics
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('venueId', isEqualTo: venueId)
          .get();

      int totalReviews = reviewsSnapshot.docs.length;
      double averageRating = 0;
      if (totalReviews > 0) {
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          VenueReview review = VenueReview.fromFirestore(doc);
          totalRating += review.rating;
        }
        averageRating = totalRating / totalReviews;
      }

      return {
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'totalRevenue': totalRevenue,
        'totalReviews': totalReviews,
        'averageRating': averageRating,
      };
    } catch (e) {
      throw Exception('Failed to fetch venue analytics: $e');
    }
  }
}
