import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/booking_model.dart' as data;
import '../../../models/booking_model.dart' as legacy;
import '../../../theming/styles.dart';

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  final Object status;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final descriptor = _describeStatus(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.w : 12.w,
        vertical: isCompact ? 4.h : 6.h,
      ),
      decoration: BoxDecoration(
        color: descriptor.background,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        descriptor.label.toUpperCase(),
        style: (isCompact
                ? TextStyles.font10DarkBlue600Weight
                : TextStyles.font12DarkBlue600Weight)
            .copyWith(color: descriptor.foreground),
      ),
    );
  }

  _StatusDescriptor _describeStatus(Object status) {
    if (status is data.BookingStatusType) {
      switch (status) {
        case data.BookingStatusType.draft:
          return _StatusDescriptor(
            label: 'Draft',
            background: Colors.grey[200]!,
            foreground: Colors.grey[700]!,
          );
        case data.BookingStatusType.pending:
          return _StatusDescriptor(
            label: 'Pending',
            background: Colors.orange[100]!,
            foreground: Colors.orange[700]!,
          );
        case data.BookingStatusType.confirmed:
          return _StatusDescriptor(
            label: 'Confirmed',
            background: Colors.green[100]!,
            foreground: Colors.green[700]!,
          );
        case data.BookingStatusType.cancelled:
          return _StatusDescriptor(
            label: 'Cancelled',
            background: Colors.red[100]!,
            foreground: Colors.red[700]!,
          );
        case data.BookingStatusType.completed:
          return _StatusDescriptor(
            label: 'Completed',
            background: Colors.blue[100]!,
            foreground: Colors.blue[700]!,
          );
      }
    }

    if (status is legacy.BookingStatus) {
      switch (status) {
        case legacy.BookingStatus.pending:
          return _StatusDescriptor(
            label: status.displayName,
            background: Colors.orange[100]!,
            foreground: Colors.orange[700]!,
          );
        case legacy.BookingStatus.confirmed:
          return _StatusDescriptor(
            label: status.displayName,
            background: Colors.green[100]!,
            foreground: Colors.green[700]!,
          );
        case legacy.BookingStatus.cancelled:
          return _StatusDescriptor(
            label: status.displayName,
            background: Colors.red[100]!,
            foreground: Colors.red[700]!,
          );
        case legacy.BookingStatus.completed:
          return _StatusDescriptor(
            label: status.displayName,
            background: Colors.blue[100]!,
            foreground: Colors.blue[700]!,
          );
      }
    }

    return const _StatusDescriptor(
      label: 'Unknown',
      background: Colors.grey,
      foreground: Colors.white,
    );
  }
}

class _StatusDescriptor {
  const _StatusDescriptor({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}
