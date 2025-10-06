import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/dashboard_models.dart';

class UpcomingEventsWidget extends StatelessWidget {
  final List<UpcomingEvent> events;

  const UpcomingEventsWidget({
    Key? key,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Events',
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            if (events.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/schedule'),
                child: Text(
                  'View All',
                  style: TextStyles.font14Blue400Weight.copyWith(
                    color: ColorsManager.primary,
                  ),
                ),
              ),
          ],
        ),
        Gap(16.h),
        
        if (events.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: events.take(3).map((event) => _buildEventCard(event)).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.outline),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            color: ColorsManager.textSecondary,
            size: 48.sp,
          ),
          Gap(12.h),
          Text(
            'No Upcoming Events',
            style: TextStyles.font16DarkBlue500Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
          Gap(8.h),
          Text(
            'Book a facility or join a tournament to get started!',
            style: TextStyles.font14Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(UpcomingEvent event) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withOpacity(0.1),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Event Type Icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _getEventTypeColor(event.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _getEventTypeIcon(event.type),
              color: _getEventTypeColor(event.type),
              size: 24.sp,
            ),
          ),
          Gap(16.w),
          
          // Event Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyles.font16DarkBlueBold.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
                Gap(4.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: ColorsManager.textSecondary,
                      size: 14.sp,
                    ),
                    Gap(4.w),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(event.dateTime),
                      style: TextStyles.font12Grey400Weight,
                    ),
                  ],
                ),
                Gap(4.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: ColorsManager.textSecondary,
                      size: 14.sp,
                    ),
                    Gap(4.w),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyles.font12Grey400Weight,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Time Until Event
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorsManager.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _getTimeUntilEvent(event.dateTime),
                  style: TextStyles.font10Grey400Weight.copyWith(
                    color: ColorsManager.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Gap(8.h),
              Icon(
                Icons.arrow_forward_ios,
                color: ColorsManager.textSecondary,
                size: 16.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getEventTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'match':
        return Icons.sports_basketball;
      case 'training':
        return Icons.fitness_center;
      case 'practice':
        return Icons.sports;
      case 'tournament':
        return Icons.emoji_events;
      default:
        return Icons.event;
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'match':
        return ColorsManager.primary;
      case 'training':
        return ColorsManager.success;
      case 'practice':
        return ColorsManager.secondary;
      case 'tournament':
        return ColorsManager.warning;
      default:
        return ColorsManager.textSecondary;
    }
  }

  String _getTimeUntilEvent(DateTime eventTime) {
    final now = DateTime.now();
    final difference = eventTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}