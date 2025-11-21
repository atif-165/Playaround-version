import 'package:flutter_test/flutter_test.dart';
import 'package:playaround/data/models/booking_model.dart' as data;

import 'helpers/test_booking_repository.dart';

void main() {
  test('cancelBooking updates booking status to cancelled', () async {
    final listing = sampleListing;
    final repository = TestBookingRepository(listings: [listing]);
    final booking = data.BookingModel(
      id: 'b1',
      userId: 'user_1',
      providerId: listing.providerId,
      listingId: listing.id,
      sport: listing.sport,
      startTime: DateTime.now().add(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
      status: data.BookingStatusType.confirmed,
      priceComponents: const [],
      extras: const {},
      subtotal: listing.basePrice,
      total: listing.basePrice,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    repository.bookings.add(booking);

    await repository.cancelBooking(booking: booking, reason: 'change');

    expect(repository.bookings.first.status, data.BookingStatusType.cancelled);
  });
}
