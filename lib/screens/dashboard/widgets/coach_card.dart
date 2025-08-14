import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../models/dashboard_models.dart';

/// Coach card widget for displaying featured coach information
class CoachCard extends StatelessWidget {
  final FeaturedCoach coach;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onBook;

  const CoachCard({
    super.key,
    required this.coach,
    this.onTap,
    this.onMessage,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260.w,
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
            _buildCoachHeader(),
            _buildCoachInfo(),
            _buildCoachActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorsManager.primary.withValues(alpha: 0.2),
                    width: 2.w,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: coach.profilePictureUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: ColorsManager.surfaceVariant,
                      child: Icon(
                        Icons.person,
                        color: ColorsManager.onSurfaceVariant,
                        size: 30.sp,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: ColorsManager.surfaceVariant,
                      child: Icon(
                        Icons.person,
                        color: ColorsManager.onSurfaceVariant,
                        size: 30.sp,
                      ),
                    ),
                  ),
                ),
              ),
              if (coach.isAvailable)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: ColorsManager.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.w,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.fullName,
                  style: AppTypography.titleMedium.copyWith(
                    color: ColorsManager.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(4.h),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16.sp,
                    ),
                    Gap(4.w),
                    Text(
                      coach.ratingText,
                      style: AppTypography.bodySmall.copyWith(
                        color: ColorsManager.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Gap(4.h),
                Text(
                  coach.experienceText,
                  style: AppTypography.bodySmall.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specializations',
            style: AppTypography.labelMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(6.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: coach.specializations.take(3).map((sport) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: ColorsManager.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
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
          Gap(12.h),
          if (coach.bio.isNotEmpty)
            Text(
              coach.bio,
              style: AppTypography.bodySmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          Gap(12.h),
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
                  coach.location,
                  style: AppTypography.bodySmall.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '\$${coach.hourlyRate.toStringAsFixed(0)}/hr',
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

  Widget _buildCoachActions() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMessage,
              icon: Icon(
                Icons.message,
                size: 16.sp,
              ),
              label: Text(
                'Message',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsManager.primary,
                side: BorderSide(
                  color: ColorsManager.primary,
                  width: 1.w,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
              ),
            ),
          ),
          Gap(8.w),
          Expanded(
            child: FilledButton.icon(
              onPressed: coach.isAvailable ? onBook : null,
              icon: Icon(
                Icons.calendar_today,
                size: 16.sp,
              ),
              label: Text(
                'Book',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: coach.isAvailable 
                    ? ColorsManager.primary 
                    : ColorsManager.surfaceVariant,
                foregroundColor: coach.isAvailable 
                    ? Colors.white 
                    : ColorsManager.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact coach card for smaller spaces
class CompactCoachCard extends StatelessWidget {
  final FeaturedCoach coach;
  final VoidCallback? onTap;

  const CompactCoachCard({
    super.key,
    required this.coach,
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
            Stack(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorsManager.primary.withValues(alpha: 0.2),
                      width: 1.w,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: coach.profilePictureUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ColorsManager.surfaceVariant,
                        child: Icon(
                          Icons.person,
                          color: ColorsManager.onSurfaceVariant,
                          size: 24.sp,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ColorsManager.surfaceVariant,
                        child: Icon(
                          Icons.person,
                          color: ColorsManager.onSurfaceVariant,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                if (coach.isAvailable)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: ColorsManager.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.w,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.fullName,
                    style: AppTypography.titleSmall.copyWith(
                      color: ColorsManager.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14.sp,
                      ),
                      Gap(4.w),
                      Text(
                        '${coach.rating}',
                        style: AppTypography.bodySmall.copyWith(
                          color: ColorsManager.onSurfaceVariant,
                        ),
                      ),
                      Gap(8.w),
                      Text(
                        coach.specializationsText,
                        style: AppTypography.bodySmall.copyWith(
                          color: ColorsManager.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '\$${coach.hourlyRate.toStringAsFixed(0)}',
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
}
