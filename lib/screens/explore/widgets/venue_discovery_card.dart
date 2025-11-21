import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../data/models/venue_model.dart';
import '../../../theming/colors.dart';

class VenueDiscoveryCard extends StatelessWidget {
  const VenueDiscoveryCard({
    super.key,
    required this.venue,
    this.distanceKm,
    required this.onTap,
  });

  final VenueModel venue;
  final double? distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
              child: SizedBox(
                height: 160.h,
                width: double.infinity,
                child: venue.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: venue.coverImageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: ColorsManager.lightShadeOfGray,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.location_city,
                          color: ColorsManager.gray,
                          size: 48,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                  Gap(6.h),
                  Text(
                    '${venue.address}, ${venue.city}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.star,
                            size: 16, color: Colors.amber),
                        label: Text(
                          venue.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[700],
                          ),
                        ),
                        backgroundColor: Colors.orange.withValues(alpha: 0.12),
                        side: BorderSide.none,
                      ),
                      Chip(
                        label: Text(
                          '${venue.reviewCount} reviews',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: ColorsManager.mainBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor:
                            ColorsManager.mainBlue.withValues(alpha: 0.08),
                        side: BorderSide.none,
                      ),
                      if (distanceKm != null)
                        Chip(
                          avatar: const Icon(Icons.map_outlined,
                              size: 16, color: Colors.green),
                          label: Text(
                            '${distanceKm!.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: Colors.green.withValues(alpha: 0.12),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  Gap(12.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: venue.sports.take(3).map((sport) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: ColorsManager.mainBlue.withValues(alpha: 0.08),
                        ),
                        child: Text(
                          sport,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: ColorsManager.mainBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
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
