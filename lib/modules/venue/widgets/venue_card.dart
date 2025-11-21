import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/venue_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Card widget for displaying venue information
class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback? onTap;
  final double? distance;

  const VenueCard({
    super.key,
    required this.venue,
    this.onTap,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.surfaceVariant,
            ColorsManager.background,
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Gap(16.h),
                _buildDescription(),
                Gap(16.h),
                _buildAmenities(),
                Gap(16.h),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Venue image
        Container(
          width: 70.w,
          height: 70.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: ColorsManager.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: ColorsManager.primary.withValues(alpha: 0.3),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                color: ColorsManager.background,
              ),
              child: venue.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: CachedNetworkImage(
                        imageUrl: venue.images.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: ColorsManager.primary,
                            strokeWidth: 2.w,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.location_city,
                          color: ColorsManager.primary,
                          size: 32.sp,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.location_city,
                      color: ColorsManager.primary,
                      size: 32.sp,
                    ),
            ),
          ),
        ),
        Gap(16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      venue.title,
                      style: TextStyles.font18DarkBlueBold.copyWith(
                        color: ColorsManager.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildVenueBadge(),
                ],
              ),
              Gap(6.h),
              _buildRatingBadge(),
              Gap(6.h),
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: ColorsManager.primary.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports,
                          size: 14.sp,
                          color: ColorsManager.primary,
                        ),
                        Gap(4.w),
                        Text(
                          venue.sportType.displayName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorsManager.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap(8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorsManager.playerAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color:
                            ColorsManager.playerAccent.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 14.sp,
                          color: ColorsManager.playerAccent,
                        ),
                        Gap(2.w),
                        Text(
                          '₹${venue.hourlyRate.toStringAsFixed(0)}/hr',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorsManager.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.outline,
          width: 1.w,
        ),
      ),
      child: Text(
        venue.description,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: ColorsManager.onBackground,
          height: 1.4,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAmenities() {
    if (venue.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: ColorsManager.primary,
              size: 16.sp,
            ),
            Gap(6.w),
            Text(
              'Amenities',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: ColorsManager.onBackground,
              ),
            ),
          ],
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: venue.amenities.take(4).map((amenity) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.primary.withValues(alpha: 0.1),
                    ColorsManager.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: ColorsManager.primary.withValues(alpha: 0.3),
                  width: 1.w,
                ),
              ),
              child: Text(
                amenity,
                style: TextStyle(
                  color: ColorsManager.onBackground,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
        if (venue.amenities.length > 4)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              '+${venue.amenities.length - 4} more',
              style: TextStyle(
                color: ColorsManager.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: ColorsManager.textSecondary,
                size: 16.sp,
              ),
              Gap(4.w),
              Expanded(
                child: Text(
                  venue.location,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: ColorsManager.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Gap(8.w),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              gradient: ColorsManager.primaryGradient,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: ColorsManager.primary.withValues(alpha: 0.4),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: onTap,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View',
                        style: TextStyle(
                          color: ColorsManager.onPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Gap(4.w),
                      Icon(
                        Icons.arrow_forward,
                        color: ColorsManager.onPrimary,
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: ColorsManager.primaryGradient,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.3),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: ColorsManager.onPrimary,
            size: 12.sp,
          ),
          Gap(4.w),
          Text(
            'VENUE',
            style: TextStyle(
              color: ColorsManager.onPrimary,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge() {
    if (venue.totalReviews == 0) {
      return Text(
        'No reviews yet',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: ColorsManager.textSecondary,
        ),
      );
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.3),
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 14.sp,
              ),
              Gap(4.w),
              Text(
                venue.averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.onBackground,
                ),
              ),
            ],
          ),
        ),
        Gap(8.w),
        Text(
          '(${venue.totalReviews} review${venue.totalReviews == 1 ? '' : 's'})',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: ColorsManager.textSecondary,
          ),
        ),
      ],
    );
  }
}
