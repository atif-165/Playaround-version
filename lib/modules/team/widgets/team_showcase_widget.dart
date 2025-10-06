import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/team_service.dart';

/// Widget for displaying team showcase information
class TeamShowcaseWidget extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamShowcaseWidget({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamShowcaseWidget> createState() => _TeamShowcaseWidgetState();
}

class _TeamShowcaseWidgetState extends State<TeamShowcaseWidget> {
  final TeamService _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Showcase',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(16.h),
          _buildWinLossRecord(),
          Gap(20.h),
          _buildRecentAchievements(),
          Gap(20.h),
          _buildTeamStats(),
        ],
      ),
    );
  }

  Widget _buildWinLossRecord() {
    return StreamBuilder<TeamPerformance?>(
      stream: _teamService.getTeamPerformance(widget.teamId).asStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final performance = snapshot.data;
        if (performance == null) {
          return _buildEmptyState(
            icon: Icons.sports_soccer,
            title: 'No Match Data',
            subtitle: 'Win/loss record will appear here after matches',
          );
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorsManager.mainBlue.withValues(alpha: 0.1),
                ColorsManager.success.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Text(
                'Match Record',
                style: TextStyles.font16DarkBlue600Weight,
              ),
              Gap(16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRecordItem('Wins', '${performance.wins}', ColorsManager.success),
                  _buildRecordItem('Losses', '${performance.losses}', ColorsManager.error),
                  _buildRecordItem('Draws', '${performance.draws}', ColorsManager.warning),
                ],
              ),
              Gap(12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${performance.winPercentage.toStringAsFixed(1)}% Win Rate',
                  style: TextStyles.font14White600Weight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentAchievements() {
    return StreamBuilder<List<TeamAchievement>>(
      stream: _teamService.getTeamAchievements(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final achievements = snapshot.data ?? [];
        if (achievements.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No Achievements Yet',
            subtitle: 'Team achievements will appear here',
          );
        }

        // Show only recent achievements (last 3)
        final recentAchievements = achievements.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Achievements',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            Gap(12.h),
            ...recentAchievements.map((achievement) => _buildAchievementItem(achievement)),
          ],
        );
      },
    );
  }

  Widget _buildTeamStats() {
    return StreamBuilder<TeamPerformance?>(
      stream: _teamService.getTeamPerformance(widget.teamId).asStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final performance = snapshot.data;
        if (performance == null) {
          return _buildEmptyState(
            icon: Icons.analytics_outlined,
            title: 'No Statistics',
            subtitle: 'Team statistics will appear here',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Statistics',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            Gap(12.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Goals Scored',
                    '${performance.totalGoalsScored}',
                    Icons.sports_soccer,
                    ColorsManager.success,
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: _buildStatCard(
                    'Clean Sheets',
                    '${performance.cleanSheets}',
                    Icons.shield,
                    ColorsManager.mainBlue,
                  ),
                ),
              ],
            ),
            Gap(12.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Avg Goals/Match',
                    '${performance.averageGoalsPerMatch.toStringAsFixed(1)}',
                    Icons.trending_up,
                    ColorsManager.warning,
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: _buildStatCard(
                    'Form',
                    performance.form,
                    Icons.timeline,
                    ColorsManager.darkBlue,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyles.font18DarkBlue600Weight.copyWith(color: color),
            ),
          ),
        ),
        Gap(8.h),
        Text(
          label,
          style: TextStyles.font12Grey400Weight,
        ),
      ],
    );
  }

  Widget _buildAchievementItem(TeamAchievement achievement) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: ColorsManager.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: ColorsManager.warning,
            size: 20.sp,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyles.font14DarkBlue600Weight,
                ),
                Gap(2.h),
                Text(
                  achievement.description,
                  style: TextStyles.font12Grey400Weight,
                ),
                Gap(2.h),
                Text(
                  _formatDate(achievement.achievedAt),
                  style: TextStyles.font10Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          Gap(8.h),
          Text(
            value,
            style: TextStyles.font16DarkBlue600Weight.copyWith(color: color),
          ),
          Text(
            label,
            style: TextStyles.font10Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.gray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32.sp,
            color: ColorsManager.gray,
          ),
          Gap(8.h),
          Text(
            title,
            style: TextStyles.font14DarkBlue500Weight,
          ),
          Gap(4.h),
          Text(
            subtitle,
            style: TextStyles.font12Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
