import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:playaround/data/datasources/firestore_booking_data_source.dart';
import 'package:playaround/data/datasources/firestore_matchmaking_data_source.dart';
import 'package:playaround/data/datasources/mock_data_source.dart';
import 'package:playaround/data/models/booking_model.dart' as data;
import 'package:playaround/data/models/listing_model.dart' as data;
import 'package:playaround/data/repositories/booking_repository.dart';

final FakeFirebaseFirestore _fakeFirestoreInstance = FakeFirebaseFirestore();

class TestBookingRepository extends BookingRepository {
  TestBookingRepository({required List<data.ListingModel> listings})
      : _listings = listings,
        bookings = [],
        super(
          mockDataSource: _FakeMockDataSource(listings: listings),
          bookingDataSource: _FakeFirestoreBookingDataSource(),
          listingDataSource: _FakeFirestoreMatchmakingDataSource(),
          firestore: _fakeFirestoreInstance,
        );

  final List<data.ListingModel> _listings;
  final List<data.BookingModel> bookings;

  @override
  Future<void> init() async {}

  @override
  Future<List<data.ListingModel>> loadListings(
          {bool prioritizeRemote = true}) async =>
      _listings;

  @override
  Future<data.BookingModel> createBooking({
    required String userId,
    required String providerId,
    required String listingId,
    required String sport,
    required DateTime startTime,
    required DateTime endTime,
    List<data.PriceComponent> priceComponents = const [],
    Map<String, dynamic> extras = const {},
    String? notes,
  }) async {
    final booking = data.BookingModel(
      id: 'booking_${bookings.length}',
      userId: userId,
      providerId: providerId,
      listingId: listingId,
      sport: sport,
      startTime: startTime,
      endTime: endTime,
      status: data.BookingStatusType.confirmed,
      priceComponents: priceComponents,
      extras: extras.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      subtotal: 0,
      total: priceComponents.fold<double>(
        0,
        (sum, component) => sum + component.amount,
      ),
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    bookings.add(booking);
    return booking;
  }

  @override
  Stream<List<data.BookingModel>> watchBookingsForUser(String userId) {
    return Stream.value(bookings.where((b) => b.userId == userId).toList());
  }

  @override
  Future<void> cancelBooking({
    required data.BookingModel booking,
    String reason = 'Cancelled',
  }) async {
    final index = bookings.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      bookings[index] = bookings[index].copyWith(
        status: data.BookingStatusType.cancelled,
      );
    }
  }
}

class _FakeMockDataSource extends MockDataSource {
  _FakeMockDataSource({required this.listings});

  final List<data.ListingModel> listings;

  @override
  Future<List<data.ListingModel>> loadListings() async => listings;
}

class _FakeFirestoreBookingDataSource extends FirestoreBookingDataSource {
  _FakeFirestoreBookingDataSource() : super(firestore: _fakeFirestoreInstance);

  @override
  Future<void> saveBooking(data.BookingModel booking) async {}

  @override
  Future<void> updateBookingStatus({
    required String bookingId,
    required data.BookingStatusType status,
    String? cancellationReason,
  }) async {}

  @override
  Future<data.BookingModel?> fetchBookingById(String bookingId) async => null;

  @override
  Stream<List<data.BookingModel>> watchBookingsForUser(String userId) =>
      const Stream.empty();

  @override
  Stream<List<data.BookingModel>> watchBookingsForProvider(String providerId) =>
      const Stream.empty();
}

class _FakeFirestoreMatchmakingDataSource
    extends FirestoreMatchmakingDataSource {
  _FakeFirestoreMatchmakingDataSource()
      : super(firestore: _fakeFirestoreInstance);

  @override
  Future<List<data.ListingModel>> fetchListings({int limit = 50}) async => [];
}

final data.ListingModel sampleListing = data.ListingModel(
  id: 'listing_1',
  category: data.ListingCategory.venue,
  sport: 'Tennis',
  title: 'Centre Court Session',
  description: 'Practice session with coach.',
  providerId: 'coach_1',
  providerName: 'Coach One',
  basePrice: 50,
  priceComponents: const [
    data.PriceComponent(label: 'Base rate', amount: 50),
    data.PriceComponent(label: 'Equipment', amount: 10),
  ],
  photos: const [],
  tags: const ['training'],
  extras: const {'Ball machine': 15.0},
  availability: const {
    '2025-11-08': [
      '2025-11-08T08:00:00.000Z-2025-11-08T09:30:00.000Z',
    ],
  },
  capacity: 1,
  rating: 4.5,
  reviewCount: 10,
  createdAt: DateTime(2025, 11, 1),
  updatedAt: DateTime(2025, 11, 1),
);
