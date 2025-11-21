import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';

/// Loading shimmer widget for community posts
class CommunityLoadingShimmer extends StatelessWidget {
  const CommunityLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: _buildShimmerCard(),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: ColorsManager.surfaceVariant,
      highlightColor: ColorsManager.surface,
      child: Container(
        decoration: BoxDecoration(
          color: ColorsManager.surfaceVariant,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (author info)
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: const BoxDecoration(
                      color: ColorsManager.surface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Gap(12.w),
                  // Name and timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120.w,
                          height: 14.h,
                          decoration: BoxDecoration(
                            color: ColorsManager.surface,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        Gap(6.h),
                        Container(
                          width: 80.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: ColorsManager.surface,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Gap(16.h),

              // Content lines
              Container(
                width: double.infinity,
                height: 14.h,
                decoration: BoxDecoration(
                  color: ColorsManager.surface,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Gap(8.h),
              Container(
                width: double.infinity,
                height: 14.h,
                decoration: BoxDecoration(
                  color: ColorsManager.surface,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Gap(8.h),
              Container(
                width: 200.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: ColorsManager.surface,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Gap(16.h),

              // Image placeholder
              Container(
                width: double.infinity,
                height: 200.h,
                decoration: BoxDecoration(
                  color: ColorsManager.surface,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              Gap(16.h),

              // Action buttons (like, comment, share)
              Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: ColorsManager.surface,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  Gap(12.w),
                  Container(
                    width: 60.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: ColorsManager.surface,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  Gap(12.w),
                  Container(
                    width: 60.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: ColorsManager.surface,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple shimmer for single item loading
class CommunityItemShimmer extends StatelessWidget {
  const CommunityItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ColorsManager.surfaceVariant,
      highlightColor: ColorsManager.surface,
      child: Container(
        width: double.infinity,
        height: 100.h,
        decoration: BoxDecoration(
          color: ColorsManager.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}
