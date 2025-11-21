import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../models/venue_booking_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/venue_service.dart';
import 'venue_reschedule_screen.dart';

/// Screen displaying detailed venue booking information
class VenueBookingDetailScreen extends StatefulWidget {
  final VenueBookingModel booking;

  const VenueBookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<VenueBookingDetailScreen> createState() =>
      _VenueBookingDetailScreenState();
}

class _VenueBookingDetailScreenState extends State<VenueBookingDetailScreen> {
  final VenueService _venueService = VenueService();
  late VenueBookingModel _currentBooking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Booking Details',
          style: TextStyles.font16White600Weight.copyWith(fontSize: 18.sp),
        ),
        backgroundColor: ColorsManager.neonBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  Gap(16.h),
                  _buildVenueInfo(),
                  Gap(16.h),
                  _buildBookingDetails(),
                  Gap(16.h),
                  _buildParticipantInfo(),
                  if (_currentBooking.notes != null) ...[
                    Gap(16.h),
                    _buildNotesSection(),
                  ],
                  if (_currentBooking.cancellationReason != null) ...[
                    Gap(16.h),
                    _buildCancellationReason(),
                  ],
                  Gap(24.h),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData statusIcon;

    switch (_currentBooking.status) {
      case VenueBookingStatus.pending:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        statusText = 'Pending Confirmation';
        statusIcon = Icons.schedule;
        break;
      case VenueBookingStatus.confirmed:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        statusText = 'Confirmed';
        statusIcon = Icons.check_circle;
        break;
      case VenueBookingStatus.completed:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        statusText = 'Completed';
        statusIcon = Icons.done_all;
        break;
      case VenueBookingStatus.cancelled:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: textColor, size: 24.sp),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style:
                      TextStyles.font16DarkBlueBold.copyWith(color: textColor),
                ),
                Gap(4.h),
                Text(
                  'Booking ID: ${_currentBooking.id.substring(0, 8)}...',
                  style: TextStyles.font12Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Venue Information',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(12.h),
            _buildInfoRow(
              icon: Icons.sports_soccer,
              label: 'Venue',
              value: _currentBooking.venueTitle,
            ),
            Gap(8.h),
            _buildInfoRow(
              icon: Icons.category,
              label: 'Sport',
              value: _currentBooking.sportType.displayName,
            ),
            Gap(8.h),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: _currentBooking.location,
            ),
            Gap(8.h),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Owner',
              value: _currentBooking.venueOwnerName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(12.h),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: dateFormat.format(_currentBooking.selectedDate),
            ),
            Gap(8.h),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Time',
              value:
                  '${_currentBooking.timeSlot.start} - ${_currentBooking.timeSlot.end}',
            ),
            Gap(8.h),
            _buildInfoRow(
              icon: Icons.schedule,
              label: 'Duration',
              value:
                  '${_currentBooking.timeSlot.durationInHours.toStringAsFixed(1)} hours',
            ),
            Gap(8.h),
            _buildInfoRow(
              icon: Icons.attach_money,
              label: 'Hourly Rate',
              value: '\$${_currentBooking.hourlyRate.toStringAsFixed(2)}',
            ),
            Gap(8.h),
            _buildInfoRow(
              icon: Icons.payment,
              label: 'Total Amount',
              value: '\$${_currentBooking.totalAmount.toStringAsFixed(2)}',
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participant Information',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(12.h),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Booked by',
              value: _currentBooking.userName,
            ),
            Gap(8.h),
            _buildInfoRow(
              icon: Icons.schedule,
              label: 'Booked on',
              value: dateFormat.format(_currentBooking.createdAt),
            ),
            if (_currentBooking.confirmedAt != null) ...[
              Gap(8.h),
              _buildInfoRow(
                icon: Icons.check_circle,
                label: 'Confirmed on',
                value: dateFormat.format(_currentBooking.confirmedAt!),
              ),
            ],
            if (_currentBooking.completedAt != null) ...[
              Gap(8.h),
              _buildInfoRow(
                icon: Icons.done_all,
                label: 'Completed on',
                value: dateFormat.format(_currentBooking.completedAt!),
              ),
            ],
            if (_currentBooking.cancelledAt != null) ...[
              Gap(8.h),
              _buildInfoRow(
                icon: Icons.cancel,
                label: 'Cancelled on',
                value: dateFormat.format(_currentBooking.cancelledAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: ColorsManager.mainBlue, size: 20.sp),
                Gap(8.w),
                Text(
                  'Notes',
                  style: TextStyles.font16DarkBlueBold,
                ),
              ],
            ),
            Gap(12.h),
            Text(
              _currentBooking.notes!,
              style: TextStyles.font14DarkBlueMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationReason() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red, size: 20.sp),
                Gap(8.w),
                Text(
                  'Cancellation Reason',
                  style:
                      TextStyles.font16DarkBlueBold.copyWith(color: Colors.red),
                ),
              ],
            ),
            Gap(12.h),
            Text(
              _currentBooking.cancellationReason!,
              style: TextStyles.font14DarkBlueMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: isHighlighted ? ColorsManager.mainBlue : ColorsManager.gray,
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
            style: isHighlighted
                ? TextStyles.font14DarkBlueBold
                : TextStyles.font14DarkBlueMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final isUserBooking = _currentBooking.userId == user.uid;
    final isVenueOwner = _currentBooking.venueOwnerId == user.uid;

    if (_currentBooking.status == VenueBookingStatus.completed ||
        _currentBooking.status == VenueBookingStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (isUserBooking) ...[
          // User can cancel or reschedule their own booking
          Row(
            children: [
              Expanded(
                child: AppTextButton(
                  buttonText: 'Cancel Booking',
                  textStyle: TextStyles.font16WhiteSemiBold,
                  backgroundColor: Colors.red,
                  onPressed: _showCancelDialog,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: AppTextButton(
                  buttonText: 'Reschedule',
                  textStyle: TextStyles.font16WhiteSemiBold,
                  backgroundColor: ColorsManager.mainBlue,
                  onPressed: _navigateToReschedule,
                ),
              ),
            ],
          ),
        ],
        if (isVenueOwner &&
            _currentBooking.status == VenueBookingStatus.confirmed) ...[
          // Venue owner can mark as completed
          AppTextButton(
            buttonText: 'Mark as Completed',
            textStyle: TextStyles.font16WhiteSemiBold,
            backgroundColor: Colors.green,
            onPressed: _showCompleteDialog,
          ),
        ],
      ],
    );
  }

  void _showCancelDialog() {
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
              'Are you sure you want to cancel this booking?',
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
            onPressed: () => _cancelBooking(reasonController.text.trim()),
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

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Complete Booking',
          style: TextStyles.font18DarkBlueBold,
        ),
        content: Text(
          'Mark this booking as completed?',
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
            onPressed: _completeBooking,
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

  void _navigateToReschedule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueRescheduleScreen(booking: _currentBooking),
      ),
    );

    if (result == true) {
      // Refresh booking data
      _refreshBookingData();
    }
  }

  Future<void> _cancelBooking(String reason) async {
    Navigator.pop(context); // Close dialog

    setState(() {
      _isLoading = true;
    });

    try {
      await _venueService.cancelVenueBooking(
        bookingId: _currentBooking.id,
        cancellationReason: reason.isNotEmpty ? reason : null,
      );

      // Refresh booking data
      await _refreshBookingData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return to previous screen
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeBooking() async {
    Navigator.pop(context); // Close dialog

    setState(() {
      _isLoading = true;
    });

    try {
      await _venueService.updateBookingStatus(
        bookingId: _currentBooking.id,
        status: VenueBookingStatus.completed,
      );

      // Refresh booking data
      await _refreshBookingData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBookingData() async {
    try {
      final updatedBooking =
          await _venueService.getVenueBooking(_currentBooking.id);
      if (updatedBooking != null) {
        setState(() {
          _currentBooking = updatedBooking;
        });
      }
    } catch (e) {
      // Handle error silently or show a message
    }
  }
}
