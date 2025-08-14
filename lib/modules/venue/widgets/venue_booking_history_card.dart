import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../models/venue_booking_model.dart';
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Card widget for displaying venue booking history item
class VenueBookingHistoryCard extends StatelessWidget {
  final VenueBookingModel booking;
  final UserRole userRole;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onComplete;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const VenueBookingHistoryCard({
    super.key,
    required this.booking,
    required this.userRole,
    this.onTap,
    this.onCancel,
    this.onReschedule,
    this.onComplete,
    this.onApprove,
    this.onReject,
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
              if (_shouldShowActionButtons()) ...[
                Gap(12.h),
                _buildActionButtons(),
              ],
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
                booking.venueTitle,
                style: TextStyles.font16DarkBlueBold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(4.h),
              Text(
                booking.sportType.displayName,
                style: TextStyles.font12Grey400Weight,
              ),
            ],
          ),
        ),
        Gap(8.w),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (booking.status) {
      case VenueBookingStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        statusText = 'Pending';
        break;
      case VenueBookingStatus.confirmed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        statusText = 'Confirmed';
        break;
      case VenueBookingStatus.completed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        statusText = 'Completed';
        break;
      case VenueBookingStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        statusText,
        style: TextStyles.font14DarkBlueMedium.copyWith(
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildBookingInfo() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.calendar_today,
          label: 'Date',
          value: dateFormat.format(booking.selectedDate),
        ),
        Gap(8.h),
        _buildInfoRow(
          icon: Icons.access_time,
          label: 'Time',
          value: '${booking.timeSlot.start} - ${booking.timeSlot.end}',
        ),
        Gap(8.h),
        _buildInfoRow(
          icon: Icons.location_on,
          label: 'Location',
          value: booking.location,
        ),
        Gap(8.h),
        _buildInfoRow(
          icon: Icons.attach_money,
          label: 'Amount',
          value: '\$${booking.totalAmount.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: ColorsManager.gray,
        ),
        Gap(8.w),
        Text(
          '$label:',
          style: TextStyles.font12Grey400Weight,
        ),
        Gap(8.w),
        Expanded(
          child: Text(
            value,
            style: TextStyles.font14DarkBlueMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isUserBooking() ? 'Venue Owner' : 'Booked by',
                style: TextStyles.font10Grey400Weight,
              ),
              Gap(2.h),
              Text(
                _isUserBooking() ? booking.venueOwnerName : booking.userName,
                style: TextStyles.font14DarkBlueMedium,
              ),
            ],
          ),
        ),
        Gap(8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Booked on',
              style: TextStyles.font10Grey400Weight,
            ),
            Gap(2.h),
            Text(
              dateFormat.format(booking.createdAt),
              style: TextStyles.font14DarkBlueMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Owner actions (approve/reject) for pending bookings
        if (_canApprove() || _canReject()) ...[
          Row(
            children: [
              if (_canReject()) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: Icon(Icons.close, size: 16.sp),
                    label: Text('Reject', style: TextStyles.font14DarkBlueMedium),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
                Gap(8.w),
              ],
              if (_canApprove()) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: Icon(Icons.check, size: 16.sp),
                    label: Text('Approve', style: TextStyles.font12WhiteMedium),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_canCancel() || _canReschedule() || _canComplete()) Gap(8.h),
        ],
        // User actions (cancel/reschedule/complete)
        if (_canCancel() || _canReschedule() || _canComplete()) ...[
          Row(
            children: [
              if (_canCancel()) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: Icon(Icons.cancel_outlined, size: 16.sp),
                    label: Text('Cancel', style: TextStyles.font14DarkBlueMedium),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
                Gap(8.w),
              ],
              if (_canReschedule()) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReschedule,
                    icon: Icon(Icons.schedule, size: 16.sp),
                    label: Text('Reschedule', style: TextStyles.font14DarkBlueMedium),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorsManager.mainBlue,
                      side: const BorderSide(color: ColorsManager.mainBlue),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
                Gap(8.w),
              ],
              if (_canComplete()) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: Icon(Icons.check_circle, size: 16.sp),
                    label: Text('Complete', style: TextStyles.font12WhiteMedium),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  bool _shouldShowActionButtons() {
    return _canCancel() || _canReschedule() || _canComplete() || _canApprove() || _canReject();
  }

  bool _canApprove() {
    return onApprove != null &&
           booking.status == VenueBookingStatus.pending;
  }

  bool _canReject() {
    return onReject != null &&
           booking.status == VenueBookingStatus.pending;
  }

  bool _canCancel() {
    if (booking.status == VenueBookingStatus.completed || 
        booking.status == VenueBookingStatus.cancelled) {
      return false;
    }

    // Check if booking is in the future
    final now = DateTime.now();
    final bookingDateTime = DateTime(
      booking.selectedDate.year,
      booking.selectedDate.month,
      booking.selectedDate.day,
      int.parse(booking.timeSlot.start.split(':')[0]),
      int.parse(booking.timeSlot.start.split(':')[1]),
    );

    return bookingDateTime.isAfter(now) && onCancel != null;
  }

  bool _canReschedule() {
    if (booking.status == VenueBookingStatus.completed || 
        booking.status == VenueBookingStatus.cancelled) {
      return false;
    }

    // Only the user who made the booking can reschedule
    return _isUserBooking() && onReschedule != null;
  }

  bool _canComplete() {
    if (booking.status != VenueBookingStatus.confirmed) {
      return false;
    }

    // Only venue owner can mark as completed
    return !_isUserBooking() && onComplete != null;
  }

  bool _isUserBooking() {
    // Check if current user is the one who made the booking
    // This should be determined by comparing with current user ID
    // For now, we'll use a simple heuristic based on user role
    return userRole == UserRole.player;
  }
}
