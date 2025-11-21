import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/venue_booking_model.dart';
import '../../../models/venue_model.dart';
import '../../../models/user_profile.dart';
import '../services/venue_service.dart';
import '../widgets/venue_booking_history_card.dart';
import 'venue_booking_detail_screen.dart';

/// Screen for venue owners to manage bookings for their venues
class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VenueService _venueService = VenueService();

  List<VenueModel> _ownedVenues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOwnedVenues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnedVenues() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _venueService.getMyVenues().listen((venues) {
          if (mounted) {
            setState(() {
              _ownedVenues = venues;
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Owner Bookings',
          style: TextStyles.font16White600Weight.copyWith(fontSize: 18.sp),
        ),
        backgroundColor: ColorsManager.neonBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: TextStyles.font14DarkBlueMedium,
          unselectedLabelStyle: TextStyles.font14Grey400Weight,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'All Bookings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ownedVenues.isEmpty
              ? _buildNoVenuesState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingBookingsTab(),
                    _buildAllBookingsTab(),
                  ],
                ),
    );
  }

  Widget _buildNoVenuesState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 64.sp,
              color: ColorsManager.gray,
            ),
            Gap(16.h),
            Text(
              'No Venues Found',
              style: TextStyles.font18DarkBlueBold,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'You need to create venues first to manage bookings.',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBookingsTab() {
    return StreamBuilder<List<VenueBookingModel>>(
      stream: _getPendingBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load pending bookings');
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmptyState(
            'No Pending Bookings',
            'You don\'t have any pending booking requests.',
            Icons.pending_actions,
          );
        }

        return _buildBookingsList(bookings, showOwnerActions: true);
      },
    );
  }

  Widget _buildAllBookingsTab() {
    return StreamBuilder<List<VenueBookingModel>>(
      stream: _getAllBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load bookings');
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmptyState(
            'No Bookings',
            'Your venues haven\'t received any bookings yet.',
            Icons.book_outlined,
          );
        }

        return _buildBookingsList(bookings);
      },
    );
  }

  Widget _buildBookingsList(List<VenueBookingModel> bookings,
      {bool showOwnerActions = false}) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Trigger rebuild to refresh streams
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: VenueBookingHistoryCard(
              booking: booking,
              userRole: UserRole.coach, // Owner context
              onTap: () => _navigateToBookingDetail(booking),
              onApprove: showOwnerActions &&
                      booking.status == VenueBookingStatus.pending
                  ? () => _approveBooking(booking)
                  : null,
              onReject: showOwnerActions &&
                      booking.status == VenueBookingStatus.pending
                  ? () => _rejectBooking(booking)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64.sp,
              color: ColorsManager.gray,
            ),
            Gap(16.h),
            Text(
              title,
              style: TextStyles.font18DarkBlueBold,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              message,
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red,
            ),
            Gap(16.h),
            Text(
              'Error',
              style: TextStyles.font18DarkBlueBold,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              message,
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<VenueBookingModel>> _getPendingBookingsStream() {
    if (_ownedVenues.isEmpty) {
      return Stream.value([]);
    }

    final venueIds = _ownedVenues.map((v) => v.id).toList();

    // This is a simplified approach - in production, you might want to use a compound query
    // For now, we'll get bookings for the first venue and filter by status
    return _venueService.getVenueBookings(venueIds.first).map((bookings) {
      return bookings
          .where((booking) => booking.status == VenueBookingStatus.pending)
          .toList();
    });
  }

  Stream<List<VenueBookingModel>> _getAllBookingsStream() {
    if (_ownedVenues.isEmpty) {
      return Stream.value([]);
    }

    final venueIds = _ownedVenues.map((v) => v.id).toList();

    // This is a simplified approach - in production, you might want to use a compound query
    return _venueService.getVenueBookings(venueIds.first);
  }

  void _navigateToBookingDetail(VenueBookingModel booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueBookingDetailScreen(booking: booking),
      ),
    );

    // If booking was updated, refresh the list
    if (result == true) {
      setState(() {}); // Trigger rebuild to refresh streams
    }
  }

  Future<void> _approveBooking(VenueBookingModel booking) async {
    try {
      await _venueService.updateBookingStatus(
        bookingId: booking.id,
        status: VenueBookingStatus.confirmed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(VenueBookingModel booking) async {
    try {
      await _venueService.updateBookingStatus(
        bookingId: booking.id,
        status: VenueBookingStatus.cancelled,
        cancellationReason: 'Rejected by venue owner',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
