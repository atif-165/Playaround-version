import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../data/models/booking_model.dart' as data;
import '../../../data/models/listing_model.dart' as data;
import '../../../data/repositories/booking_repository.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../widgets/booking_history_card.dart';
import 'booking_detail_screen.dart';

class MyBookingHistoryScreen extends StatefulWidget {
  const MyBookingHistoryScreen({super.key, this.repository});

  final BookingRepository? repository;

  @override
  State<MyBookingHistoryScreen> createState() => _MyBookingHistoryScreenState();
}

class _MyBookingHistoryScreenState extends State<MyBookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final BookingRepository _repository;

  late final TabController _tabController;

  Map<String, data.ListingModel> _listingLookup = {};
  List<data.BookingModel> _cachedBookings = [];
  Stream<List<data.BookingModel>>? _bookingStream;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BookingRepository();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _repository.init();
    final cached = await _repository.loadCachedBookingsForUser(user.uid);
    _bookingStream = _repository.watchBookingsForUser(user.uid);

    try {
      final listings = await _repository.loadListings();
      _listingLookup = {for (final listing in listings) listing.id: listing};
    } catch (_) {
      _listingLookup = {};
    }

    setState(() {
      _cachedBookings = cached;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view bookings.')),
      );
    }

    if (_bookingStream == null) {
      return const Scaffold(body: Center(child: CustomProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My bookings', style: TextStyles.font18DarkBlueBold),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ColorsManager.mainBlue,
          labelColor: ColorsManager.mainBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<data.BookingModel>>(
        stream: _bookingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError && _cachedBookings.isEmpty) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedBookings.isEmpty) {
            return const CustomProgressIndicator();
          }

          final streamBookings = snapshot.data ?? [];
          final useCached =
              (snapshot.connectionState == ConnectionState.waiting &&
                      _cachedBookings.isNotEmpty) ||
                  (snapshot.hasError && _cachedBookings.isNotEmpty);
          final bookings = useCached ? _cachedBookings : streamBookings;

          final upcoming = bookings.where(_isUpcoming).toList();
          final past = bookings.where(_isCompleted).toList();
          final cancelled = bookings.where(_isCancelled).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTab(upcoming, emptyLabel: 'No upcoming bookings'),
              _buildTab(past, emptyLabel: 'No completed bookings'),
              _buildTab(cancelled, emptyLabel: 'No cancelled bookings'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(List<data.BookingModel> bookings,
      {required String emptyLabel}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48.sp, color: Colors.grey[400]),
            Gap(12.h),
            Text(emptyLabel, style: TextStyles.font14Grey400Weight),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _init(),
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final listing = _listingLookup[booking.listingId];
          final subtitle = listing != null
              ? 'Provider: ${listing.providerName.isEmpty ? listing.providerId : listing.providerName}'
              : 'Listing: ${booking.listingId}';
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: BookingHistoryCard(
              booking: booking,
              subtitle: subtitle,
              onTap: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(booking: booking),
                  ),
                );
                if (updated == true) {
                  _init();
                }
              },
            ),
          );
        },
      ),
    );
  }

  bool _isUpcoming(data.BookingModel booking) {
    final now = DateTime.now();
    return booking.status == data.BookingStatusType.confirmed &&
        booking.startTime.isAfter(now);
  }

  bool _isCompleted(data.BookingModel booking) =>
      booking.status == data.BookingStatusType.completed;

  bool _isCancelled(data.BookingModel booking) =>
      booking.status == data.BookingStatusType.cancelled;
}
