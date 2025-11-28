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

  // Test function to directly fetch venues (for debugging)
  static Future<void> testFetchVenues() async {
    try {
      print('🧪 TEST: Fetching venues directly...');
      final snapshot = await _firestore.collection(_venuesCollection).get();
      print('🧪 TEST: Fetched ${snapshot.docs.length} documents');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('  📄 ${doc.id}: ${data['title'] ?? data['name'] ?? 'N/A'} - isActive: ${data['isActive']}');
      }
    } catch (e, stackTrace) {
      print('❌ TEST ERROR: $e');
      print('Stack: $stackTrace');
    }
  }

  // Venue CRUD Operations
  static Future<List<Venue>> getVenues({
    VenueFilter? filter,
    int? limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // First, verify we can access the collection at all
      print('🔍 VenueService.getVenues: Starting query on collection: $_venuesCollection');
      print('🔍 VenueService.getVenues: Firebase instance: ${_firestore.app.name}');
      
      // Try the absolute simplest query first - no filters, no orderBy, no limit
      print('🔍 VenueService.getVenues: Attempting simplest possible query first...');
      try {
        final simplestSnapshot = await _firestore.collection(_venuesCollection).get();
        print('✅ VenueService.getVenues: Simplest query returned ${simplestSnapshot.docs.length} documents');
        if (simplestSnapshot.docs.isNotEmpty) {
          // If simple query works, use it
          List<Venue> venues = [];
          int parseErrors = 0;
          
          for (var doc in simplestSnapshot.docs) {
            try {
              final venue = Venue.fromFirestore(doc);
              print('✅ Parsed venue: ${venue.name} (id: ${doc.id}, isActive: ${venue.isActive})');
              venues.add(venue);
            } catch (e, stackTrace) {
              parseErrors++;
              print('⚠️ Error parsing venue ${doc.id}: $e');
              print('⚠️ Stack trace: $stackTrace');
              // Print document data for debugging
              print('⚠️ Document data: ${doc.data()}');
            }
          }
          
          print('🔍 VenueService.getVenues: Successfully parsed ${venues.length} venues out of ${simplestSnapshot.docs.length} documents');
          
          if (parseErrors > 0) {
            print('⚠️ VenueService.getVenues: Failed to parse $parseErrors venues');
          }
          
          print('🔍 VenueService.getVenues: Before filtering: ${venues.length} venues');
          print('🔍 VenueService.getVenues: Filter: ${filter?.toMap()}');
          
          // Apply filters in memory if needed
          if (filter != null) {
            final beforeFilterCount = venues.length;
            
            // Apply location-based filtering if coordinates are provided
            if (filter.latitude != null &&
                filter.longitude != null &&
                filter.radius != null) {
              final beforeLocationFilter = venues.length;
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
              print('🔍 Location filter: ${beforeLocationFilter} -> ${venues.length} venues');
            }

            // Apply text search filter
            if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
              final beforeSearchFilter = venues.length;
              String searchQuery = filter.searchQuery!.toLowerCase();
              venues = venues.where((venue) {
                return venue.name.toLowerCase().contains(searchQuery) ||
                    venue.description.toLowerCase().contains(searchQuery) ||
                    venue.address.toLowerCase().contains(searchQuery) ||
                    venue.sports
                        .any((sport) => sport.toLowerCase().contains(searchQuery));
              }).toList();
              print('🔍 Search filter: ${beforeSearchFilter} -> ${venues.length} venues');
            }
            
            // Apply other filters
            if (filter.city != null) {
              final beforeCityFilter = venues.length;
              venues = venues.where((v) => v.city == filter.city).toList();
              print('🔍 City filter (${filter.city}): ${beforeCityFilter} -> ${venues.length} venues');
            }
            if (filter.state != null) {
              final beforeStateFilter = venues.length;
              venues = venues.where((v) => v.state == filter.state).toList();
              print('🔍 State filter (${filter.state}): ${beforeStateFilter} -> ${venues.length} venues');
            }
            if (filter.country != null) {
              final beforeCountryFilter = venues.length;
              venues = venues.where((v) => v.country == filter.country).toList();
              print('🔍 Country filter (${filter.country}): ${beforeCountryFilter} -> ${venues.length} venues');
            }
            if (filter.sports.isNotEmpty) {
              final beforeSportsFilter = venues.length;
              venues = venues.where((v) => 
                v.sports.any((s) => filter.sports.contains(s))
              ).toList();
              print('🔍 Sports filter (${filter.sports}): ${beforeSportsFilter} -> ${venues.length} venues');
            }
            if (filter.minPrice != null) {
              final beforePriceFilter = venues.length;
              venues = venues.where((v) => v.pricing.hourlyRate >= filter.minPrice!).toList();
              print('🔍 Min price filter (${filter.minPrice}): ${beforePriceFilter} -> ${venues.length} venues');
            }
            if (filter.maxPrice != null) {
              final beforePriceFilter = venues.length;
              venues = venues.where((v) => v.pricing.hourlyRate <= filter.maxPrice!).toList();
              print('🔍 Max price filter (${filter.maxPrice}): ${beforePriceFilter} -> ${venues.length} venues');
            }
            if (filter.minRating != null) {
              final beforeRatingFilter = venues.length;
              venues = venues.where((v) => v.rating >= filter.minRating!).toList();
              print('🔍 Min rating filter (${filter.minRating}): ${beforeRatingFilter} -> ${venues.length} venues');
            }
            if (filter.isVerified != null) {
              final beforeVerifiedFilter = venues.length;
              venues = venues.where((v) => v.isVerified == filter.isVerified).toList();
              print('🔍 Verified filter (${filter.isVerified}): ${beforeVerifiedFilter} -> ${venues.length} venues');
            }
            // Note: isActive filter is not part of VenueFilter - we always show active venues by default
            // The screen already filters for active venues after receiving results
            
            print('🔍 VenueService.getVenues: After filtering: ${beforeFilterCount} -> ${venues.length} venues');
          }
          
          // Sort in memory
          venues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('🔍 VenueService.getVenues: Returning ${venues.length} venues after filtering');
          return venues;
        }
      } catch (e) {
        print('❌ VenueService.getVenues: Simplest query failed: $e');
        // Continue with regular query
      }
      
      // Start with the simplest possible query - just get all documents
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
        // Note: isActive filter is not part of VenueFilter - we always show active venues by default
        // The screen already filters for active venues after receiving results
      }

      // For now, let's try fetching without orderBy and without limit to see if we get any documents
      // Firestore allows fetching up to a certain number without orderBy
      bool useOrderBy = false;
      if (filter?.sortBy != null) {
        useOrderBy = true;
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
      } else if (limit != null && limit! < 100) {
        // Only use orderBy for small limits (pagination)
        useOrderBy = true;
        query = query.orderBy('createdAt', descending: true);
      } else if (lastDocument != null) {
        // Use orderBy for pagination
        useOrderBy = true;
        query = query.orderBy('createdAt', descending: true);
      }
      // Skip orderBy when fetching all venues to avoid index requirements

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // Apply limit - but only if explicitly provided or for pagination
      // Don't apply default limit when fetching all venues to avoid restrictions
      if (limit != null) {
        query = query.limit(limit);
      } else if (lastDocument == null && !useOrderBy) {
        // When fetching all without orderBy, don't use limit
        // Firestore allows fetching documents without limit (up to a certain point)
        print('🔍 VenueService.getVenues: Fetching without limit to get all documents');
      } else {
        // Use a reasonable limit for other cases
        query = query.limit(1000);
      }

      print('🔍 VenueService.getVenues: Executing query (useOrderBy: $useOrderBy, limit: ${limit ?? "none"})');
      print('🔍 VenueService.getVenues: Collection name: $_venuesCollection');
      
      QuerySnapshot snapshot;
      try {
        snapshot = await query.get();
        print('✅ VenueService.getVenues: Query executed successfully');
      } catch (e, stackTrace) {
        print('❌ VenueService.getVenues: Query failed with error: $e');
        print('❌ Stack trace: $stackTrace');
        
        // Try the absolute simplest query possible
        print('🔍 VenueService.getVenues: Trying absolute simplest query...');
        try {
          final simplestQuery = _firestore.collection(_venuesCollection);
          snapshot = await simplestQuery.get();
          print('🔍 VenueService.getVenues: Simplest query returned ${snapshot.docs.length} documents');
        } catch (e2) {
          print('❌ VenueService.getVenues: Simplest query also failed: $e2');
          // Don't rethrow, return empty list instead
          return [];
        }
      }
      
      // Debug: Log raw document count
      print('🔍 VenueService.getVenues: Firestore returned ${snapshot.docs.length} documents');
      
      // If we got 0 documents, try fetching with a very simple query
      if (snapshot.docs.isEmpty) {
        print('⚠️ VenueService.getVenues: Got 0 documents, trying alternative approaches...');
        
        // Try 1: Get all documents without any limit
        try {
          print('🔍 Trying: collection($_venuesCollection).get()');
          final testQuery = _firestore.collection(_venuesCollection);
          final testSnapshot = await testQuery.get();
          print('🔍 Test query returned ${testSnapshot.docs.length} documents');
          if (testSnapshot.docs.isNotEmpty) {
            snapshot = testSnapshot;
            print('✅ Found ${snapshot.docs.length} documents with test query!');
          }
        } catch (e) {
          print('❌ Test query failed: $e');
        }
        
        // Try 2: Check if collection exists by trying to get a single doc
        try {
          print('🔍 Checking if collection exists by getting collection reference...');
          final collectionRef = _firestore.collection(_venuesCollection);
          final testSnapshot = await collectionRef.limit(1).get();
          print('🔍 Collection exists, limit(1) returned ${testSnapshot.docs.length} documents');
        } catch (e) {
          print('❌ Collection check failed: $e');
        }
      }
      
      List<Venue> venues = [];
      int parseErrors = 0;
      
      for (var doc in snapshot.docs) {
        try {
          final venue = Venue.fromFirestore(doc);
          venues.add(venue);
        } catch (e) {
          parseErrors++;
          print('⚠️ Error parsing venue ${doc.id}: $e');
        }
      }
      
      if (parseErrors > 0) {
        print('⚠️ VenueService.getVenues: Failed to parse $parseErrors venues');
      }
      
      // Sort in memory if we didn't use orderBy
      if (!useOrderBy) {
        venues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      // Debug: Log the number of venues fetched
      print('🔍 VenueService.getVenues: Successfully parsed ${venues.length} venues (useOrderBy: $useOrderBy)');

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

