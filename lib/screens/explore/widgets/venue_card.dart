import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:gap/gap.dart';

import '../../../core/utils/image_utils.dart';
import '../../../models/geo_models.dart';
import '../../../theming/colors.dart';
import '../../../services/location_service.dart';

/// Card widget for displaying venue information
class VenueCard extends StatelessWidget {
  final GeoVenue venue;
  final double? distance;
  final VoidCallback onTap;

  const VenueCard({
    super.key,
    required this.venue,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Image section
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              child: SizedBox(
                height: 160.h,
                width: double.infinity,
                child: ImageUtils.buildSafeCachedImage(
                  imageUrl: venue.images.isNotEmpty ? venue.images.first : '',
                  width: double.infinity,
                  height: 160.h,
                  fit: BoxFit.cover,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12.r)),
                  fallbackIcon: Icons.location_city,
                  fallbackIconColor: Colors.grey[400],
                  fallbackIconSize: 40.sp,
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ),

            // Content section
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          venue.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Gap(8.w),
                      if (venue.averageRating > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                ColorsManager.mainBlue.withValues(alpha: 0.1),
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
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: ColorsManager.mainBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  Gap(8.h),

                  // Sport type and location
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          venue.sportType,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Gap(8.w),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14.sp,
                              color: Colors.grey[500],
                            ),
                            Gap(4.w),
                            Expanded(
                              child: Text(
                                venue.location,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Gap(8.h),

                  // Distance and price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (distance != null)
                        Text(
                          LocationService().formatDistance(distance!),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: ColorsManager.mainBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        '₹${venue.hourlyRate.toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  Gap(8.h),

                  // Amenities (if any)
                  if (venue.amenities.isNotEmpty)
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.h,
                      children: venue.amenities.take(3).map((amenity) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            amenity,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.green[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // Availability indicator
                  if (venue.isActive)
                    Container(
                      margin: EdgeInsets.only(top: 8.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Available Today',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
