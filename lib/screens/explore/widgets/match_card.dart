import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import '../../../services/matchmaking_service.dart';
import '../../../theming/colors.dart';
import '../../../services/location_service.dart';

/// Card widget for displaying player match information
class MatchCard extends StatelessWidget {
  final PlayerMatch match;
  final VoidCallback onRequestMatch;

  const MatchCard({
    super.key,
    required this.match,
    required this.onRequestMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile and match score
            Row(
              children: [
                // Profile picture
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getMatchScoreColor(match.matchScore).withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: match.player.profilePictureUrl != null
                        ? CachedNetworkImage(
                            imageUrl: match.player.profilePictureUrl!,
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

                // Name and basic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.player.fullName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Gap(4.h),
                      Row(
                        children: [
                          Text(
                            '${match.player.age} years old',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (match.distance != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              LocationService().formatDistance(match.distance!),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: ColorsManager.mainBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Match score
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getMatchScoreColor(match.matchScore).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${match.matchScore.round()}%',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: _getMatchScoreColor(match.matchScore),
                        ),
                      ),
                      Text(
                        'Match',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: _getMatchScoreColor(match.matchScore),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Gap(16.h),

            // Common sports
            if (match.commonSports.isNotEmpty) ...[
              Text(
                'Common Sports',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Gap(8.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: match.commonSports.map((sport) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      sport,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: ColorsManager.mainBlue,
                      ),
                    ),
                  );
                }).toList(),
              ),
              Gap(16.h),
            ],

            // Match reasons
            if (match.matchReasons.isNotEmpty) ...[
              Text(
                'Why you match',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Gap(8.h),
              ...match.matchReasons.take(3).map((reason) =>
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14.sp,
                        color: Colors.green,
                      ),
                      Gap(8.w),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Gap(16.h),
            ],

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRequestMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.mainBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.handshake,
                      size: 18.sp,
                    ),
                    Gap(8.w),
                    Text(
                      'Request to Team Up',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.blue;
    return Colors.red;
  }
}
