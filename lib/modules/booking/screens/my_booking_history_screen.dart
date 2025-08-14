import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';
import '../services/booking_history_service.dart';
import '../widgets/booking_history_card.dart';
import 'booking_detail_screen.dart';

/// Screen for displaying user's booking history with tabbed interface
class MyBookingHistoryScreen extends StatefulWidget {
  const MyBookingHistoryScreen({super.key});

  @override
  State<MyBookingHistoryScreen> createState() => _MyBookingHistoryScreenState();
}

class _MyBookingHistoryScreenState extends State<MyBookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingHistoryService _bookingHistoryService = BookingHistoryService();
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
          'My Bookings',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.mainBlue,
          unselectedLabelColor: ColorsManager.gray,
          indicatorColor: ColorsManager.mainBlue,
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
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingHistoryService.getUpcomingBookings(
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
            'You don\'t have any upcoming bookings.',
            Icons.calendar_today,
          );
        }

        return _buildBookingsList(bookings);
      },
    );
  }

  Widget _buildCompletedTab() {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingHistoryService.getCompletedBookings(
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
            'You haven\'t completed any bookings yet.',
            Icons.check_circle_outline,
          );
        }

        return _buildBookingsList(bookings);
      },
    );
  }

  Widget _buildCancelledTab() {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingHistoryService.getCancelledBookings(
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
            'You don\'t have any cancelled bookings.',
            Icons.cancel_outlined,
          );
        }

        return _buildBookingsList(bookings);
      },
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings) {
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
            child: BookingHistoryCard(
              booking: booking,
              userRole: _userProfile?.role ?? UserRole.player,
              onTap: () => _navigateToBookingDetail(booking),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64.w,
              color: ColorsManager.gray76,
            ),
            Gap(16.h),
            Text(
              title,
              style: TextStyles.font18DarkBlueBold,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              subtitle,
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
              size: 64.w,
              color: ColorsManager.coralRed,
            ),
            Gap(16.h),
            Text(
              'Oops!',
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
              onPressed: () {
                setState(() {}); // Trigger rebuild to retry
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
                style: TextStyles.font14White500Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBookingDetail(BookingModel booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(booking: booking),
      ),
    );

    // If booking was updated, refresh the list
    if (result == true) {
      setState(() {}); // Trigger rebuild to refresh streams
    }
  }
}
