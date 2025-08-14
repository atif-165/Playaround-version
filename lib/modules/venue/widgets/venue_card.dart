import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/venue_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Card widget for displaying venue information
class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback? onTap;

  const VenueCard({
    super.key,
    required this.venue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 180.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
        color: Colors.grey[200],
      ),
      child: venue.images.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              child: Image.network(
                venue.images.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderImage();
                },
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.mainBlue.withValues(alpha: 0.1),
            ColorsManager.mainBlue.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city,
              size: 48.sp,
              color: ColorsManager.mainBlue.withValues(alpha: 0.5),
            ),
            Gap(8.h),
            Text(
              'No Image',
              style: TextStyles.font12Grey400Weight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  venue.title,
                  style: TextStyles.font16DarkBlueBold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Gap(8.w),
              _buildRatingSection(),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                size: 16.sp,
                color: ColorsManager.mainBlue,
              ),
              Gap(4.w),
              Text(
                venue.sportType.displayName,
                style: TextStyles.font12MainBlue500Weight,
              ),
            ],
          ),
          Gap(6.h),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16.sp,
                color: Colors.grey[600],
              ),
              Gap(4.w),
              Expanded(
                child: Text(
                  venue.location,
                  style: TextStyles.font12Grey400Weight,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceSection(),
              _buildBookingsCount(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    if (venue.totalReviews == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          'New',
          style: TextStyles.font10Grey400Weight,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 12.sp,
            color: Colors.amber,
          ),
          Gap(2.w),
          Text(
            venue.averageRating.toStringAsFixed(1),
            style: TextStyles.font10DarkBlue600Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₹${venue.hourlyRate.toStringAsFixed(0)}/hour',
          style: TextStyles.font14DarkBlueBold,
        ),
        Text(
          'Starting price',
          style: TextStyles.font10Grey400Weight,
        ),
      ],
    );
  }

  Widget _buildBookingsCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            size: 12.sp,
            color: Colors.green[700],
          ),
          Gap(4.w),
          Text(
            '${venue.totalBookings} bookings',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}
