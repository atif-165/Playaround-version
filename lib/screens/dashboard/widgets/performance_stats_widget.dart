import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/dashboard_models.dart';

class PerformanceStatsWidget extends StatelessWidget {
  final PerformanceStats? stats;
  final UserRole userRole;

  const PerformanceStatsWidget({
    Key? key,
    required this.stats,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getStatsTitle(),
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/analytics'),
              child: Text(
                'View Details',
                style: TextStyles.font14Blue400Weight.copyWith(
                  color: ColorsManager.primary,
                ),
              ),
            ),
          ],
        ),
        Gap(16.h),
        
        // Win Rate & Top Performer
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Win Rate',
                '${stats!.winRate.toStringAsFixed(1)}%',
                Icons.emoji_events,
                ColorsManager.success,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                _getTopPerformerLabel(),
                stats!.topPerformer,
                Icons.star,
                ColorsManager.primary,
              ),
            ),
          ],
        ),
        Gap(16.h),
        
        // Skill Progress Chart
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorsManager.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorsManager.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skill Progress',
                style: TextStyles.font16DarkBlueBold.copyWith(
                  color: ColorsManager.textPrimary,
                ),
              ),
              Gap(16.h),
              ...stats!.skillProgress.map((skill) => _buildSkillProgressBar(skill)),
            ],
          ),
        ),
        Gap(16.h),
        
        // Analytics Overview
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorsManager.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorsManager.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Analytics',
                style: TextStyles.font16DarkBlueBold.copyWith(
                  color: ColorsManager.textPrimary,
                ),
              ),
              Gap(16.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 2.5,
                ),
                itemCount: stats!.analytics.length,
                itemBuilder: (context, index) {
                  final entry = stats!.analytics.entries.elementAt(index);
                  return _buildAnalyticsItem(entry.key, entry.value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatsTitle() {
    switch (userRole) {
      case UserRole.player:
        return 'My Performance';
      case UserRole.coach:
        return 'Student Progress';
      case UserRole.team:
        return 'Team Performance';
      case UserRole.admin:
        return 'System Analytics';
    }
  }

  String _getTopPerformerLabel() {
    switch (userRole) {
      case UserRole.player:
        return 'Personal Best';
      case UserRole.coach:
        return 'Top Student';
      case UserRole.team:
        return 'MVP Player';
      case UserRole.admin:
        return 'Top Performer';
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
              Gap(8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.font12Grey400Weight,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Text(
            value,
            style: TextStyles.font20DarkBlueBold.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillProgressBar(SkillProgress skill) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill.skillName,
                style: TextStyles.font14DarkBlue500Weight.copyWith(
                  color: ColorsManager.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${skill.currentLevel.toInt()}%',
                    style: TextStyles.font14DarkBlueBold.copyWith(
                      color: skill.color,
                    ),
                  ),
                  if (skill.improvement > 0) ...[
                    Gap(4.w),
                    Icon(
                      Icons.trending_up,
                      color: ColorsManager.success,
                      size: 16.sp,
                    ),
                    Text(
                      '+${skill.improvement.toInt()}',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: ColorsManager.success,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Gap(8.h),
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: ColorsManager.surfaceVariant,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: skill.currentLevel / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: skill.color,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, double value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyles.font12Grey400Weight,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap(4.h),
          Text(
            value.toInt().toString(),
            style: TextStyles.font16DarkBlueBold.copyWith(
              color: ColorsManager.primary,
            ),
          ),
        ],
      ),
    );
  }
}