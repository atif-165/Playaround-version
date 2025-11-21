import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import '../../../models/geo_models.dart';
import '../../../theming/colors.dart';
import '../../../services/location_service.dart';

/// Card widget for displaying player information
class PlayerCard extends StatelessWidget {
  final GeoPlayer player;
  final double? distance;
  final VoidCallback onTap;

  const PlayerCard({
    super.key,
    required this.player,
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
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Profile picture
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorsManager.mainBlue.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: player.profilePictureUrl != null
                      ? CachedNetworkImage(
                          imageUrl: player.profilePictureUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 30.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 30.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 30.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),

              Gap(16.w),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and age
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.fullName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${player.age}y',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    Gap(4.h),

                    // Location and distance
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14.sp,
                          color: Colors.grey[500],
                        ),
                        Gap(4.w),
                        Expanded(
                          child: Text(
                            player.location,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distance != null)
                          Text(
                            LocationService().formatDistance(distance!),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorsManager.mainBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),

                    Gap(8.h),

                    // Sports of interest
                    if (player.sportsOfInterest.isNotEmpty)
                      Wrap(
                        spacing: 4.w,
                        runSpacing: 4.h,
                        children: player.sportsOfInterest.take(3).map((sport) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  ColorsManager.mainBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              sport,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: ColorsManager.mainBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    Gap(8.h),

                    // Skill level and availability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Average skill score
                        if (player.skillScores.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getSkillColor(player.averageSkillScore)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 12.sp,
                                  color:
                                      _getSkillColor(player.averageSkillScore),
                                ),
                                Gap(4.w),
                                Text(
                                  '${player.averageSkillScore.round()}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _getSkillColor(
                                        player.averageSkillScore),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Availability indicator
                        if (player.availability.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'Available',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action button
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: ColorsManager.mainBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSkillColor(double skillScore) {
    if (skillScore >= 80) return Colors.green;
    if (skillScore >= 60) return Colors.orange;
    if (skillScore >= 40) return Colors.blue;
    return Colors.red;
  }
}
