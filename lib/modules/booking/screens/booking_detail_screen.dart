import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/booking_model.dart';

import '../services/booking_service.dart';
import '../widgets/booking_status_chip.dart';

/// Screen for displaying detailed booking information
class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = false;
      });
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
          'Booking Details',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBookingHeader(),
                  Gap(24.h),
                  _buildBookingDetails(),
                  Gap(24.h),
                  _buildParticipantInfo(),
                  Gap(24.h),
                  _buildPaymentInfo(),
                  if (widget.booking.notes != null) ...[
                    Gap(24.h),
                    _buildNotesSection(),
                  ],
                  if (widget.booking.cancellationReason != null) ...[
                    Gap(24.h),
                    _buildCancellationInfo(),
                  ],
                  Gap(32.h),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsManager.mainBlue.withValues(alpha: 0.1),
            ColorsManager.mainBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.booking.listingTitle,
                  style: TextStyles.font20DarkBlueBold,
                ),
              ),
              BookingStatusChip(status: widget.booking.status),
            ],
          ),
          Gap(8.h),
          Text(
            widget.booking.sportType.displayName,
            style: TextStyles.font14MainBlue500Weight,
          ),
          Gap(4.h),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16.w,
                color: ColorsManager.gray,
              ),
              Gap(4.w),
              Expanded(
                child: Text(
                  widget.booking.location,
                  style: TextStyles.font14Grey400Weight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return _buildSection(
      title: 'Booking Details',
      child: Column(
        children: [
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            widget.booking.formattedDate,
          ),
          _buildDetailRow(
            Icons.access_time,
            'Time',
            widget.booking.formattedTimeRange,
          ),
          _buildDetailRow(
            Icons.schedule,
            'Duration',
            '${widget.booking.durationInHours.toStringAsFixed(1)} hours',
          ),
          _buildDetailRow(
            Icons.sports,
            'Sport Type',
            widget.booking.sportType.displayName,
          ),
          _buildDetailRow(
            Icons.category,
            'Listing Type',
            widget.booking.listingType.displayName,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantInfo() {
    final isUserTheCoach = widget.booking.ownerId == FirebaseAuth.instance.currentUser?.uid;
    
    return _buildSection(
      title: 'Participants',
      child: Column(
        children: [
          _buildParticipantCard(
            title: 'Coach',
            name: widget.booking.ownerName,
            isCurrentUser: isUserTheCoach,
          ),
          Gap(12.h),
          _buildParticipantCard(
            title: 'Player',
            name: widget.booking.userName,
            isCurrentUser: !isUserTheCoach,
            profilePicture: widget.booking.userProfilePicture,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return _buildSection(
      title: 'Payment Information',
      child: Column(
        children: [
          _buildDetailRow(
            Icons.attach_money,
            'Hourly Rate',
            '\$${widget.booking.hourlyRate.toStringAsFixed(2)}/hour',
          ),
          _buildDetailRow(
            Icons.schedule,
            'Duration',
            '${widget.booking.durationInHours.toStringAsFixed(1)} hours',
          ),
          const Divider(),
          _buildDetailRow(
            Icons.payment,
            'Total Amount',
            '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'Notes',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorsManager.lightShadeOfGray,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          widget.booking.notes!,
          style: TextStyles.font14DarkBlue500Weight,
        ),
      ),
    );
  }

  Widget _buildCancellationInfo() {
    return _buildSection(
      title: 'Cancellation Information',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason:',
              style: TextStyles.font12DarkBlue600Weight,
            ),
            Gap(4.h),
            Text(
              widget.booking.cancellationReason!,
              style: TextStyles.font14DarkBlue500Weight,
            ),
            if (widget.booking.cancelledAt != null) ...[
              Gap(8.h),
              Text(
                'Cancelled on: ${_formatDateTime(widget.booking.cancelledAt!)}',
                style: TextStyles.font12Grey400Weight,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isUserTheCoach = widget.booking.ownerId == currentUserId;
    final isUserThePlayer = widget.booking.userId == currentUserId;

    if (!isUserTheCoach && !isUserThePlayer) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (widget.booking.canBeCancelled) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isProcessing ? null : _showCancelDialog,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ColorsManager.coralRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : Text(
                      'Cancel Booking',
                      style: TextStyles.font14DarkBlueMedium.copyWith(
                        color: ColorsManager.coralRed,
                      ),
                    ),
            ),
          ),
        ],
        if (isUserTheCoach && 
            widget.booking.status == BookingStatus.confirmed && 
            widget.booking.isPastBooking) ...[
          Gap(12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _completeBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Mark as Completed',
                      style: TextStyles.font14White500Weight,
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.w,
            color: ColorsManager.mainBlue,
          ),
          Gap(12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          Text(
            value,
            style: isHighlighted
                ? TextStyles.font16DarkBlueBold
                : TextStyles.font14DarkBlue500Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard({
    required String title,
    required String name,
    required bool isCurrentUser,
    String? profilePicture,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? ColorsManager.mainBlue.withValues(alpha: 0.1)
            : ColorsManager.lightShadeOfGray,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundImage: profilePicture != null 
                ? NetworkImage(profilePicture)
                : null,
            child: profilePicture == null
                ? Icon(
                    Icons.person,
                    size: 20.w,
                    color: Colors.white,
                  )
                : null,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.font12Grey400Weight,
                ),
                Text(
                  name,
                  style: TextStyles.font14DarkBlueBold,
                ),
              ],
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ColorsManager.mainBlue,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'You',
                style: TextStyles.font10DarkBlue600Weight.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: TextStyles.font18DarkBlueBold,
        ),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: TextStyles.font14Grey400Weight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Booking',
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking();
            },
            child: Text(
              'Cancel Booking',
              style: TextStyles.font14DarkBlueMedium.copyWith(
                color: ColorsManager.coralRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _bookingService.cancelBooking(
        widget.booking.id,
        'Cancelled by user',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate booking was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _completeBooking() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _bookingService.completeBooking(widget.booking.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate booking was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete booking: $e'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
