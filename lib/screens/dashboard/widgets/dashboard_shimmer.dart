import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';

/// Shimmer loading widgets for dashboard components
class DashboardShimmer {
  static Widget header() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.primary,
            Color(0xFF1E6BFF),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.white.withValues(alpha: 0.3),
                  highlightColor: Colors.white.withValues(alpha: 0.5),
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Gap(16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.white.withValues(alpha: 0.3),
                        highlightColor: Colors.white.withValues(alpha: 0.5),
                        child: Container(
                          width: 120.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                      Gap(8.h),
                      Shimmer.fromColors(
                        baseColor: Colors.white.withValues(alpha: 0.3),
                        highlightColor: Colors.white.withValues(alpha: 0.5),
                        child: Container(
                          width: 180.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Gap(20.h),
            Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 16.w : 0),
                    child: Shimmer.fromColors(
                      baseColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor: Colors.white.withValues(alpha: 0.4),
                      child: Container(
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static Widget card({
    double? width,
    double? height,
  }) {
    return Shimmer.fromColors(
      baseColor: ColorsManager.shimmerBase,
      highlightColor: ColorsManager.shimmerHighlight,
      child: Container(
        width: width ?? 280.w,
        height: height ?? 200.h,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: ColorsManager.surfaceVariant,
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }

  static Widget eventCard() {
    return Container(
      width: 280.w,
      margin: EdgeInsets.only(right: 16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: ColorsManager.shimmerBase,
            highlightColor: ColorsManager.shimmerHighlight,
            child: Container(
              height: 140.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ColorsManager.shimmerBase,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                  highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                  child: Container(
                    width: 200.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                Gap(8.h),
                Shimmer.fromColors(
                  baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                  highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                  child: Container(
                    width: 150.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                Gap(8.h),
                Shimmer.fromColors(
                  baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                  highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                  child: Container(
                    width: 120.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget coachCard() {
    return Container(
      width: 260.w,
      margin: EdgeInsets.only(right: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Shimmer.fromColors(
                  baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                  highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                        highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                        child: Container(
                          width: 120.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                      Gap(6.h),
                      Shimmer.fromColors(
                        baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                        highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                        child: Container(
                          width: 80.w,
                          height: 14.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Gap(16.h),
            Row(
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.only(right: 6.w),
                  child: Shimmer.fromColors(
                    baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                    highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                    child: Container(
                      width: 60.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Gap(16.h),
            Row(
              children: [
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                    highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                    child: Container(
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                    highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                    child: Container(
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget actionGrid({int count = 4}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
          highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        );
      },
    );
  }

  static Widget carousel({
    required String title,
    required Widget Function() itemBuilder,
    int itemCount = 3,
    double height = 200,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                child: Container(
                  width: 150.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              const Spacer(),
              Shimmer.fromColors(
                baseColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                highlightColor: ColorsManager.surfaceVariant.withValues(alpha: 0.6),
                child: Container(
                  width: 60.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(16.h),
        SizedBox(
          height: height.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: itemCount,
            itemBuilder: (context, index) => itemBuilder(),
          ),
        ),
      ],
    );
  }
}
