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
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header with team image and basic info
            Container(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Enhanced team image
                  Container(
                    width: 64.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: LinearGradient(
                        colors: [
                          ColorsManager.mainBlue.withValues(alpha: 0.1),
                          ColorsManager.mainBlue.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: ColorsManager.mainBlue.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: ImageUtils.buildSafeCachedImage(
                        imageUrl: team.teamImageUrl,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(14.r),
                        fallbackIcon: Icons.groups,
                        fallbackIconColor: ColorsManager.mainBlue,
                        fallbackIconSize: 32.sp,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),

                  Gap(16.w),

                  // Team info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Team name
                        Text(
                          team.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        Gap(4.h),
                        
                        // Sport type with icon
                        Row(
                          children: [
                            Icon(
                              _getSportIcon(team.sportType),
                              size: 16.sp,
                              color: ColorsManager.mainBlue,
                            ),
                            Gap(6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                team.sportType,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: ColorsManager.mainBlue,
                                ),
                              ),
                            ),
                          ],
                        ),

                        Gap(8.h),

                        // Location with distance
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14.sp,
                              color: Colors.grey[500],
                            ),
                            Gap(4.w),
                            Expanded(
                              child: Text(
                                team.location,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (distance != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  LocationService().formatDistance(distance!),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Stats section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  // Members count
                  _buildStatChip(
                    icon: Icons.people_rounded,
                    label: '${team.currentMembersCount}/${team.maxMembers}',
                    color: ColorsManager.mainBlue,
                  ),

                  Gap(12.w),

                  // Skill average (if available)
                  if (team.skillAverage != null)
                    _buildStatChip(
                      icon: Icons.trending_up_rounded,
                      label: '${team.skillAverage!.round()}',
                      color: _getSkillColor(team.skillAverage!),
                    ),

                  const Spacer(),

                  // Status indicator
                  if (team.currentMembersCount < team.maxMembers)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.green[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                          Gap(6.w),
                          Text(
                            'Recruiting',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Full',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    
                  Gap(12.w),
                  
                  // Action button
                  Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: ColorsManager.mainBlue,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.sp,
                      color: Colors.white,
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
  
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: color,
          ),
          Gap(4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'cricket': return Icons.sports_cricket;
      case 'football': return Icons.sports_soccer;
      case 'basketball': return Icons.sports_basketball;
      case 'volleyball': return Icons.sports_volleyball;
      case 'tennis': return Icons.sports_tennis;
      case 'badminton': return Icons.sports_tennis;
      default: return Icons.sports;
    }
  }

  Color _getSkillColor(double skillScore) {
    if (skillScore >= 80) return Colors.green;
    if (skillScore >= 60) return Colors.orange;
    if (skillScore >= 40) return Colors.blue;
    return Colors.red;
  }
}
