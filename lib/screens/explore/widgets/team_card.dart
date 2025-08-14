import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:gap/gap.dart';

import '../../../core/utils/image_utils.dart';
import '../../../models/geo_models.dart';
import '../../../theming/colors.dart';
import '../../../services/location_service.dart';

/// Card widget for displaying team information
class TeamCard extends StatelessWidget {
  final GeoTeam team;
  final double? distance;
  final VoidCallback onTap;

  const TeamCard({
    super.key,
    required this.team,
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
              // Team image/icon
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: ColorsManager.mainBlue.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: ImageUtils.buildSafeCachedImage(
                    imageUrl: team.teamImageUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(10.r),
                    fallbackIcon: Icons.groups,
                    fallbackIconColor: ColorsManager.mainBlue,
                    fallbackIconSize: 30.sp,
                    backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.1),
                  ),
                ),
              ),

              Gap(16.w),

              // Team info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team name and sport
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                            team.sportType,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
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
                            team.location,
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

                    // Team stats row
                    Row(
                      children: [
                        // Members count
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                size: 12.sp,
                                color: ColorsManager.mainBlue,
                              ),
                              Gap(4.w),
                              Text(
                                '${team.currentMembersCount}/${team.maxMembers}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: ColorsManager.mainBlue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Gap(8.w),

                        // Skill average (if available)
                        if (team.skillAverage != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getSkillColor(team.skillAverage!)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 12.sp,
                                  color: _getSkillColor(team.skillAverage!),
                                ),
                                Gap(4.w),
                                Text(
                                  '${team.skillAverage!.round()}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _getSkillColor(team.skillAverage!),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const Spacer(),

                        // Looking for members indicator
                        if (team.currentMembersCount < team.maxMembers)
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
                              'Recruiting',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                      ],
                    ),

                    Gap(8.h),

                    // Description (if available)
                    if (team.description.isNotEmpty)
                      Text(
                        team.description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
