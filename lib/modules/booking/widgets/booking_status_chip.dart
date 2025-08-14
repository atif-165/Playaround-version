import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theming/styles.dart';
import '../../../models/booking_model.dart';

/// Chip widget for displaying booking status with appropriate colors
class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;
  final bool isCompact;

  const BookingStatusChip({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.w : 12.w,
        vertical: isCompact ? 4.h : 6.h,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        status.displayName,
        style: isCompact 
            ? TextStyles.font10DarkBlue600Weight.copyWith(
                color: _getTextColor(),
              )
            : TextStyles.font12DarkBlue600Weight.copyWith(
                color: _getTextColor(),
              ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange[100]!;
      case BookingStatus.confirmed:
        return Colors.green[100]!;
      case BookingStatus.cancelled:
        return Colors.red[100]!;
      case BookingStatus.completed:
        return Colors.blue[100]!;
    }
  }

  Color _getTextColor() {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange[800]!;
      case BookingStatus.confirmed:
        return Colors.green[800]!;
      case BookingStatus.cancelled:
        return Colors.red[800]!;
      case BookingStatus.completed:
        return Colors.blue[800]!;
    }
  }
}

/// Widget for displaying booking status with icon
class BookingStatusIndicator extends StatelessWidget {
  final BookingStatus status;
  final bool showLabel;

  const BookingStatusIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: _getStatusColor(),
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          SizedBox(width: 6.w),
          Text(
            status.displayName,
            style: TextStyles.font12DarkBlue600Weight.copyWith(
              color: _getStatusColor(),
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange[600]!;
      case BookingStatus.confirmed:
        return Colors.green[600]!;
      case BookingStatus.cancelled:
        return Colors.red[600]!;
      case BookingStatus.completed:
        return Colors.blue[600]!;
    }
  }
}

/// Widget for displaying booking status statistics
class BookingStatusStats extends StatelessWidget {
  final Map<BookingStatus, int> statusCounts;
  final int totalBookings;

  const BookingStatusStats({
    super.key,
    required this.statusCounts,
    required this.totalBookings,
  });

  @override
  Widget build(BuildContext context) {
    if (totalBookings == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Statistics',
            style: TextStyles.font14DarkBlueBold,
          ),
          SizedBox(height: 12.h),
          ...BookingStatus.values.map((status) {
            final count = statusCounts[status] ?? 0;
            final percentage = totalBookings > 0 ? (count / totalBookings * 100) : 0.0;
            
            if (count == 0) return const SizedBox.shrink();
            
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  BookingStatusIndicator(
                    status: status,
                    showLabel: false,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      status.displayName,
                      style: TextStyles.font12DarkBlue400Weight,
                    ),
                  ),
                  Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyles.font12DarkBlue600Weight,
                  ),
                ],
              ),
            );
          }).where((widget) => widget is! SizedBox),
        ],
      ),
    );
  }
}
