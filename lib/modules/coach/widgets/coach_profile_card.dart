import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/coach_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Card widget for displaying coach profile information
class CoachProfileCard extends StatelessWidget {
  final CoachProfile coach;
  final VoidCallback onTap;
  final bool showFullBio;

  const CoachProfileCard({
    super.key,
    required this.coach,
    required this.onTap,
    this.showFullBio = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: Color(0xFF00FFFF), width: 1), // Neon blue border
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Gap(12.h),
              _buildBio(),
              Gap(12.h),
              _buildSpecializations(),
              Gap(12.h),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Square profile picture
        Container(
          width: 60.w,
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: const Color(0xFF00FFFF).withValues(alpha: 0.2), // Neon blue background
            border: Border.all(color: const Color(0xFF00FFFF), width: 1),
          ),
          child: coach.profilePictureUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: coach.profilePictureUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30.sp,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30.sp,
                ),
        ),
        Gap(12.w),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coach.fullName,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(3.h),
              _buildRatingRow(),
              Gap(3.h),
              _buildExperienceRow(),
            ],
          ),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_hasWinningTournaments()) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700), // Gold color for WIN tag
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 10.sp,
                        color: Colors.black,
                      ),
                      Gap(2.w),
                      Text(
                        'WIN',
                        style: TextStyle(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(4.h),
              ],
              _buildCoachBadge(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow() {
    // TODO: Implement actual rating system
    const rating = 4.5; // Placeholder rating
    const reviewCount = 23; // Placeholder review count

    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: 14.sp,
        ),
        Gap(3.w),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Gap(3.w),
        Expanded(
          child: Text(
            '($reviewCount reviews)',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceRow() {
    return Row(
      children: [
        Icon(
          Icons.work_outline,
          size: 12.sp,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        Gap(3.w),
        Expanded(
          child: Text(
            '${coach.experienceYears} years exp',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCoachBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: ColorsManager.primary, // Red
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports,
            color: Colors.white,
            size: 10.sp,
          ),
          Gap(2.w),
          Text(
            'COACH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    if (coach.bio == null || coach.bio!.isEmpty) {
      return Text(
        'No bio available',
        style: TextStyles.font12Grey400Weight.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Text(
      coach.bio!,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      maxLines: showFullBio ? null : 2,
      overflow: showFullBio ? null : TextOverflow.ellipsis,
    );
  }

  Widget _buildSpecializations() {
    if (coach.specializationSports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specializations:',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Gap(6.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: coach.specializationSports.take(3).map((sport) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFFF).withValues(alpha: 0.2), // Neon blue background
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFF00FFFF), // Neon blue border
                  width: 1,
                ),
              ),
              child: Text(
                sport,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate: \$${coach.hourlyRate.toStringAsFixed(0)}/hr',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Gap(2.h),
              Text(
                coach.location,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Gap(8.w),
        Flexible(
          flex: 2,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: ColorsManager.primary,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'View Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// Check if coach has winning tournaments
  bool _hasWinningTournaments() {
    // TODO: This should check if any of the coach's teams have won tournaments
    // For now, return false as placeholder
    return false;
  }
}
