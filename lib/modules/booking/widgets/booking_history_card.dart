import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_profile.dart';
import 'booking_status_chip.dart';

/// Card widget for displaying booking history item
class BookingHistoryCard extends StatelessWidget {
  final BookingModel booking;
  final UserRole userRole;
  final VoidCallback? onTap;

  const BookingHistoryCard({
    super.key,
    required this.booking,
    required this.userRole,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Gap(12.h),
              _buildBookingInfo(),
              Gap(12.h),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.listingTitle,
                style: TextStyles.font16DarkBlueBold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(4.h),
              Text(
                _getRoleBasedSubtitle(),
                style: TextStyles.font12Grey400Weight,
              ),
            ],
          ),
        ),
        Gap(8.w),
        BookingStatusChip(status: booking.status),
      ],
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.lightShadeOfGray,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            booking.formattedDate,
          ),
          Gap(8.h),
          _buildInfoRow(
            Icons.access_time,
            'Time',
            booking.formattedTimeRange,
          ),
          Gap(8.h),
          _buildInfoRow(
            Icons.location_on,
            'Location',
            booking.location,
          ),
          Gap(8.h),
          _buildInfoRow(
            Icons.sports,
            'Sport',
            booking.sportType.displayName,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount',
              style: TextStyles.font12Grey400Weight,
            ),
            Text(
              '\$${booking.totalAmount.toStringAsFixed(2)}',
              style: TextStyles.font16DarkBlueBold,
            ),
          ],
        ),
        if (_shouldShowEarningsInfo())
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Your Earnings',
                style: TextStyles.font12Grey400Weight,
              ),
              Text(
                '\$${booking.coachEarnings.toStringAsFixed(2)}',
                style: TextStyles.font16DarkBlueBold.copyWith(
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.w,
          color: ColorsManager.mainBlue,
        ),
        Gap(8.w),
        Text(
          '$label:',
          style: TextStyles.font12DarkBlue400Weight,
        ),
        Gap(4.w),
        Expanded(
          child: Text(
            value,
            style: TextStyles.font12DarkBlue600Weight,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _getRoleBasedSubtitle() {
    if (userRole == UserRole.coach && booking.ownerId == _getCurrentUserId()) {
      return 'Session with ${booking.userName}';
    } else if (userRole == UserRole.player && booking.userId == _getCurrentUserId()) {
      return 'Session with ${booking.ownerName}';
    } else {
      // Combined view - show role context
      if (booking.ownerId == _getCurrentUserId()) {
        return 'As Coach • Session with ${booking.userName}';
      } else {
        return 'As Player • Session with ${booking.ownerName}';
      }
    }
  }

  bool _shouldShowEarningsInfo() {
    // Show earnings if user is the coach and booking is completed
    return booking.ownerId == _getCurrentUserId() && 
           booking.status == BookingStatus.completed;
  }

  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }
}
