import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/venue_booking_model.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';
import '../services/venue_booking_history_service.dart';
import '../services/venue_service.dart';
import '../widgets/venue_booking_history_card.dart';
import 'venue_booking_detail_screen.dart';
import 'venue_reschedule_screen.dart';

/// Screen for displaying user's venue booking history with tabbed interface
class MyVenueBookingsScreen extends StatefulWidget {
  const MyVenueBookingsScreen({super.key});

  @override
  State<MyVenueBookingsScreen> createState() => _MyVenueBookingsScreenState();
}

class _MyVenueBookingsScreenState extends State<MyVenueBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VenueBookingHistoryService _bookingHistoryService = VenueBookingHistoryService();
  final VenueService _venueService = VenueService();
  final UserRepository _userRepository = UserRepository();
  
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _userRepository.getUserProfile(user.uid);
        setState(() {
          _userProfile = profile;
          _isLoading = false;
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
          'My Venue Bookings',
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
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildCompletedTab(),
                _buildCancelledTab(),
              ],
            ),
    );
  }

  Widget _buildUpcomingTab() {
    return StreamBuilder<List<VenueBookingModel>>(
      stream: _bookingHistoryService.getUpcomingVenueBookings(
        userRole: _userProfile?.role,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load upcoming bookings');
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmptyState(
            'No Upcoming Bookings',
            'You don\'t have any upcoming venue bookings.',
            Icons.calendar_today,
          );
        }

        return _buildBookingsList(bookings, showActions: true);
      },
    );
  }

  Widget _buildCompletedTab() {
    return StreamBuilder<List<VenueBookingModel>>(
      stream: _bookingHistoryService.getCompletedVenueBookings(
        userRole: _userProfile?.role,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load completed bookings');
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmptyState(
            'No Completed Bookings',
            'You haven\'t completed any venue bookings yet.',
            Icons.check_circle_outline,
          );
        }

        return _buildBookingsList(bookings);
      },
    );
  }

  Widget _buildCancelledTab() {
    return StreamBuilder<List<VenueBookingModel>>(
      stream: _bookingHistoryService.getCancelledVenueBookings(
        userRole: _userProfile?.role,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load cancelled bookings');
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmptyState(
            'No Cancelled Bookings',
            'You don\'t have any cancelled venue bookings.',
            Icons.cancel_outlined,
          );
        }

        return _buildBookingsList(bookings);
      },
    );
  }

  Widget _buildBookingsList(List<VenueBookingModel> bookings, {bool showActions = false}) {
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
              userRole: _userProfile?.role ?? UserRole.player,
              onTap: () => _navigateToBookingDetail(booking),
              onCancel: showActions ? () => _showCancelDialog(booking) : null,
              onReschedule: showActions ? () => _navigateToReschedule(booking) : null,
              onComplete: showActions ? () => _showCompleteDialog(booking) : null,
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

  void _navigateToReschedule(VenueBookingModel booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueRescheduleScreen(booking: booking),
      ),
    );

    // If booking was rescheduled, refresh the list
    if (result == true) {
      setState(() {}); // Trigger rebuild to refresh streams
    }
  }

  void _showCancelDialog(VenueBookingModel booking) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: TextStyles.font18DarkBlueBold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this booking for ${booking.venueTitle}?',
              style: TextStyles.font14DarkBlueMedium,
            ),
            Gap(16.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Booking',
              style: TextStyles.font14DarkBlueMedium,
            ),
          ),
          ElevatedButton(
            onPressed: () => _cancelBooking(booking, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Cancel Booking',
              style: TextStyles.font14White500Weight,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(VenueBookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Complete Booking',
          style: TextStyles.font18DarkBlueBold,
        ),
        content: Text(
          'Mark this booking for ${booking.venueTitle} as completed?',
          style: TextStyles.font14DarkBlueMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyles.font14DarkBlueMedium,
            ),
          ),
          ElevatedButton(
            onPressed: () => _completeBooking(booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Complete',
              style: TextStyles.font14White500Weight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(VenueBookingModel booking, String reason) async {
    Navigator.pop(context); // Close dialog

    try {
      await _venueService.cancelVenueBooking(
        bookingId: booking.id,
        cancellationReason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeBooking(VenueBookingModel booking) async {
    Navigator.pop(context); // Close dialog

    try {
      await _venueService.updateBookingStatus(
        bookingId: booking.id,
        status: VenueBookingStatus.completed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
