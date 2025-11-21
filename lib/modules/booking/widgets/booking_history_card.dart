import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

import '../../../data/models/booking_model.dart' as data;
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import 'booking_status_chip.dart';

class BookingHistoryCard extends StatelessWidget {
  const BookingHistoryCard({
    super.key,
    required this.booking,
    this.subtitle,
    this.onTap,
  });

  final data.BookingModel booking;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.Hm();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.sport,
                          style: TextStyles.font16DarkBlueBold,
                        ),
                        if (subtitle != null) ...[
                          Gap(4.h),
                          Text(
                            subtitle!,
                            style: TextStyles.font12Grey400Weight,
                          ),
                        ],
                      ],
                    ),
                  ),
                  BookingStatusChip(status: booking.status),
                ],
              ),
              Gap(12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ColorsManager.lightShadeOfGray,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.calendar_today,
                      'Date',
                      dateFormat.format(booking.startTime),
                    ),
                    Gap(8.h),
                    _infoRow(
                      Icons.access_time,
                      'Time',
                      '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                    ),
                    if (booking.priceComponents.isNotEmpty) ...[
                      Gap(8.h),
                      _infoRow(
                        Icons.payments,
                        'Charges',
                        booking.priceComponents
                            .map((component) =>
                                '${component.label}: \$${component.amount.toStringAsFixed(2)}')
                            .join('\n'),
                      ),
                    ],
                  ],
                ),
              ),
              Gap(12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total paid', style: TextStyles.font12Grey400Weight),
                      Text(
                        '\$${booking.total.toStringAsFixed(2)}',
                        style: TextStyles.font16DarkBlueBold,
                      ),
                    ],
                  ),
                  if (booking.extras.isNotEmpty)
                    Text(
                      '${booking.extras.length} add-ons',
                      style: TextStyles.font12Grey400Weight,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.w, color: ColorsManager.mainBlue),
        Gap(8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyles.font12DarkBlue400Weight),
              Gap(2.h),
              Text(
                value,
                style: TextStyles.font12DarkBlue600Weight,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
