import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../models/dashboard_models.dart';
import '../../../models/user_profile.dart';

/// Matchmaking card widget for swipeable user suggestions
class MatchmakingCard extends StatelessWidget {
  final MatchmakingSuggestion suggestion;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final VoidCallback? onTap;

  const MatchmakingCard({
    super.key,
    required this.suggestion,
    this.onLike,
    this.onPass,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280.w,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserImage(),
            _buildUserInfo(),
            _buildMatchingInfo(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
          child: SizedBox(
            height: 180.h,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: suggestion.profilePictureUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: ColorsManager.surfaceVariant,
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: ColorsManager.onSurfaceVariant,
                    size: 48.sp,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: ColorsManager.surfaceVariant,
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: ColorsManager.onSurfaceVariant,
                    size: 48.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12.h,
          right: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: _getRoleColor().withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              suggestion.role.name.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12.h,
          left: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              suggestion.compatibilityText,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  suggestion.fullName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: ColorsManager.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${suggestion.age}',
                style: AppTypography.titleMedium.copyWith(
                  color: ColorsManager.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Gap(8.h),
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
                  suggestion.distanceText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                  ),
                ),
              ),
              if (suggestion.skillLevel != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getSkillLevelColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    suggestion.skillLevel!.name.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: _getSkillLevelColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (suggestion.bio.isNotEmpty) ...[
            Gap(8.h),
            Text(
              suggestion.bio,
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchingInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common Interests',
            style: AppTypography.labelMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(6.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: suggestion.commonInterests.take(4).map((interest) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: ColorsManager.secondaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  interest,
                  style: AppTypography.labelSmall.copyWith(
                    color: ColorsManager.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          if (suggestion.sportsOfInterest.length > suggestion.commonInterests.length) ...[
            Gap(8.h),
            Text(
              'Other Sports',
              style: AppTypography.labelMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Gap(4.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: suggestion.sportsOfInterest
                  .where((sport) => !suggestion.commonInterests.contains(sport))
                  .take(3)
                  .map((sport) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: ColorsManager.surfaceVariant,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    sport,
                    style: AppTypography.labelSmall.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPass,
              icon: Icon(
                Icons.close,
                size: 18.sp,
                color: ColorsManager.error,
              ),
              label: Text(
                'Pass',
                style: AppTypography.labelLarge.copyWith(
                  color: ColorsManager.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: ColorsManager.error,
                  width: 1.w,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: FilledButton.icon(
              onPressed: onLike,
              icon: Icon(
                Icons.favorite,
                size: 18.sp,
                color: Colors.white,
              ),
              label: Text(
                'Connect',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor() {
    switch (suggestion.role) {
      case UserRole.player:
        return ColorsManager.playerAccent;
      case UserRole.coach:
        return ColorsManager.coachAccent;
      case UserRole.admin:
        return ColorsManager.adminAccent;
    }
  }

  Color _getSkillLevelColor() {
    if (suggestion.skillLevel == null) return ColorsManager.primary;
    
    switch (suggestion.skillLevel!) {
      case SkillLevel.beginner:
        return ColorsManager.beginnerColor;
      case SkillLevel.intermediate:
        return ColorsManager.intermediateColor;
      case SkillLevel.pro:
        return ColorsManager.proColor;
    }
  }
}

/// Compact matchmaking card for smaller spaces
class CompactMatchmakingCard extends StatelessWidget {
  final MatchmakingSuggestion suggestion;
  final VoidCallback? onTap;

  const CompactMatchmakingCard({
    super.key,
    required this.suggestion,
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
            ClipOval(
              child: SizedBox(
                width: 50.w,
                height: 50.w,
                child: CachedNetworkImage(
                  imageUrl: suggestion.profilePictureUrl,
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
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestion.fullName,
                          style: AppTypography.titleSmall.copyWith(
                            color: ColorsManager.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          suggestion.compatibilityText,
                          style: AppTypography.labelSmall.copyWith(
                            color: ColorsManager.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(4.h),
                  Text(
                    '${suggestion.commonInterests.join(', ')} • ${suggestion.distanceText}',
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
