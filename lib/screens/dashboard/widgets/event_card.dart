import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../models/dashboard_models.dart';

/// Event card widget for displaying event information
class EventCard extends StatelessWidget {
  final DashboardEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final bool showBookmark;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onBookmark,
    this.showBookmark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280.w,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventImage(),
            _buildEventInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
          child: SizedBox(
            height: 140.h,
            width: double.infinity,
            child: event.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: ColorsManager.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: ColorsManager.onSurfaceVariant,
                          size: 32.sp,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: ColorsManager.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: ColorsManager.onSurfaceVariant,
                          size: 32.sp,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: ColorsManager.surfaceVariant,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: ColorsManager.onSurfaceVariant,
                        size: 32.sp,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 12.h,
          left: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: _getEventTypeColor().withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              event.eventType.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (showBookmark)
          Positioned(
            top: 12.h,
            right: 12.w,
            child: GestureDetector(
              onTap: onBookmark,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  event.isBookmarked 
                      ? Icons.bookmark 
                      : Icons.bookmark_border,
                  color: event.isBookmarked 
                      ? ColorsManager.primary 
                      : ColorsManager.onSurfaceVariant,
                  size: 18.sp,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 12.h,
          right: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: event.isAvailable
                  ? ColorsManager.success.withValues(alpha: 0.9)
                  : ColorsManager.error.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              event.availabilityText,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Gap(8.h),
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: ColorsManager.onSurfaceVariant,
                size: 16.sp,
              ),
              Gap(4.w),
              Expanded(
                child: Text(
                  _formatDateTime(event.dateTime),
                  style: AppTypography.bodySmall.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Gap(4.h),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: ColorsManager.onSurfaceVariant,
                size: 16.sp,
              ),
              Gap(4.w),
              Expanded(
                child: Text(
                  event.location,
                  style: AppTypography.bodySmall.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4.w,
                  children: event.sportsInvolved.take(2).map((sport) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsManager.primaryContainer,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        sport,
                        style: AppTypography.labelSmall.copyWith(
                          color: ColorsManager.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (event.price != null)
                Text(
                  '\$${event.price!.toStringAsFixed(0)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: ColorsManager.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEventTypeColor() {
    switch (event.eventType.toLowerCase()) {
      case 'tournament':
        return ColorsManager.secondary;
      case 'training':
        return ColorsManager.primary;
      case 'match':
        return ColorsManager.tertiary;
      case 'workshop':
        return ColorsManager.success;
      default:
        return ColorsManager.primary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference == 1) {
      return 'Tomorrow ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference < 7) {
      return DateFormat('EEEE HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }
}

/// Compact event card for smaller spaces
class CompactEventCard extends StatelessWidget {
  final DashboardEvent event;
  final VoidCallback? onTap;

  const CompactEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: ColorsManager.outlineVariant,
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: SizedBox(
                width: 60.w,
                height: 60.w,
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: ColorsManager.surfaceVariant,
                    child: Icon(
                      Icons.image,
                      color: ColorsManager.onSurfaceVariant,
                      size: 24.sp,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: ColorsManager.surfaceVariant,
                    child: Icon(
                      Icons.broken_image,
                      color: ColorsManager.onSurfaceVariant,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTypography.titleSmall.copyWith(
                      color: ColorsManager.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(4.h),
                  Text(
                    _formatDateTime(event.dateTime),
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    event.location,
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (event.price != null)
              Text(
                '\$${event.price!.toStringAsFixed(0)}',
                style: AppTypography.titleSmall.copyWith(
                  color: ColorsManager.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference == 1) {
      return 'Tomorrow ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
