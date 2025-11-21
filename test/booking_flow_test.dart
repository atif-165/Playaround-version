import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playaround/data/models/booking_model.dart' as data;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:playaround/modules/booking/screens/booking_flow_screen.dart';
import 'helpers/test_booking_repository.dart';

void main() {
  group('BookingFlowScreen', () {
    late TestBookingRepository repository;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      repository = TestBookingRepository(listings: [sampleListing]);
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'test_user'),
      );
    });

    testWidgets('completes booking wizard', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) => MaterialApp(home: child),
          child: BookingFlowScreen(
            listing: sampleListing,
            repository: repository,
            firebaseAuth: mockAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final dateKey =
          ValueKey('date_${DateTime.parse('2025-11-08').toIso8601String()}');
      final dateChip = find.byKey(dateKey);
      expect(dateChip, findsOneWidget);
      await tester.tap(dateChip);
      await tester.pumpAndSettle();

      final slotKey = ValueKey(
        'slot_${DateTime.parse('2025-11-08T08:00:00.000Z').toIso8601String()}_'
        '${DateTime.parse('2025-11-08T09:30:00.000Z').toIso8601String()}',
      );
      final timeChip = find.byKey(slotKey);
      expect(timeChip, findsOneWidget);
      await tester.tap(timeChip);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final extraSwitch = find.byType(SwitchListTile);
      expect(extraSwitch, findsWidgets);
      await tester.tap(extraSwitch.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester
          .ensureVisible(find.byKey(const Key('confirm_and_pay_button')));
      await tester.tap(find.byKey(const Key('confirm_and_pay_button')));
      await tester.pumpAndSettle();

      expect(find.text('Booking confirmed'), findsOneWidget);
      expect(repository.bookings.length, 1);
      final booking = repository.bookings.first;
      expect(booking.status, equals(data.BookingStatusType.confirmed));
      expect(booking.extras.length, greaterThan(0));
    });
  });
}
