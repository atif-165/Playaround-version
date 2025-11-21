import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../data/models/booking_model.dart' as data;
import '../../../data/models/listing_model.dart' as data;
import '../../../data/repositories/booking_repository.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../widgets/booking_status_chip.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.booking,
    this.repository,
  });

  final data.BookingModel booking;
  final BookingRepository? repository;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final BookingRepository _repository;

  bool _processing = false;
  String? _listingTitle;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BookingRepository();
    _repository.init();
    _loadListingTitle();
  }

  Future<void> _loadListingTitle() async {
    try {
      final listings = await _repository.loadListings();
      final match = listings.firstWhere(
          (listing) => listing.id == widget.booking.listingId,
          orElse: () => data.ListingModel(
                id: widget.booking.listingId,
                category: data.ListingCategory.venue,
                sport: widget.booking.sport,
                title: widget.booking.listingId,
                description: '',
                providerId: widget.booking.providerId,
                providerName: '',
                basePrice: widget.booking.total,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
      setState(() {
        _listingTitle = match.title;
      });
    } catch (_) {
      // ignore, fallback to listing id
    }
  }

  Future<void> _cancelBooking() async {
    setState(() => _processing = true);
    try {
      await _repository.cancelBooking(
        booking: widget.booking,
        reason: 'Cancelled via app',
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel booking: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMEEEEd();
    final timeFormat = DateFormat.jm();
    final booking = widget.booking;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking details'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _listingTitle ?? booking.listingId,
                    style: TextStyles.font18DarkBlueBold,
                  ),
                  Gap(6.h),
                  Text(
                    booking.sport,
                    style: TextStyles.font14Grey400Weight,
                  ),
                  Gap(12.h),
                  BookingStatusChip(status: booking.status),
                ],
              ),
            ),
          ),
          Gap(16.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    'Date',
                    dateFormat.format(booking.startTime),
                    Icons.calendar_today,
                  ),
                  Gap(12.h),
                  _infoRow(
                    'Time',
                    '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                    Icons.access_time,
                  ),
                  Gap(12.h),
                  _infoRow(
                    'Total',
                    '\$${booking.total.toStringAsFixed(2)}',
                    Icons.payments,
                  ),
                  if (booking.priceComponents.isNotEmpty) ...[
                    Gap(12.h),
                    Text('Price breakdown',
                        style: TextStyles.font14DarkBlueBold),
                    Gap(8.h),
                    ...booking.priceComponents.map(
                      (component) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(component.label,
                                style: TextStyles.font12Grey400Weight),
                            Text(
                              '\$${component.amount.toStringAsFixed(2)}',
                              style: TextStyles.font12DarkBlue600Weight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (booking.extras.isNotEmpty) ...[
            Gap(16.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add-ons', style: TextStyles.font16DarkBlueBold),
                    Gap(8.h),
                    ...booking.extras.entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key,
                                style: TextStyles.font12Grey400Weight),
                            Text(
                              '\$${entry.value.toStringAsFixed(2)}',
                              style: TextStyles.font12DarkBlue600Weight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            Gap(16.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes', style: TextStyles.font16DarkBlueBold),
                    Gap(8.h),
                    Text(
                      booking.notes!,
                      style: TextStyles.font14Grey400Weight,
                    ),
                  ],
                ),
              ),
            ),
          ],
          Gap(24.h),
          if (_canCancel(booking))
            ElevatedButton(
              onPressed: _processing ? null : _cancelBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: _processing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Cancel booking'),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: ColorsManager.mainBlue),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyles.font12Grey400Weight),
              Gap(4.h),
              Text(value, style: TextStyles.font14DarkBlueBold),
            ],
          ),
        ),
      ],
    );
  }

  bool _canCancel(data.BookingModel booking) {
    final now = DateTime.now();
    final twoHoursBefore = booking.startTime.subtract(const Duration(hours: 2));
    return booking.status == data.BookingStatusType.confirmed &&
        now.isBefore(twoHoursBefore) &&
        booking.userId == FirebaseAuth.instance.currentUser?.uid;
  }
}
