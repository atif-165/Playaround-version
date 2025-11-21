import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../models/team_performance.dart';
import '../models/team_profile_models.dart';
import '../services/team_service.dart';

class TeamStatisticsScreen extends StatelessWidget {
  TeamStatisticsScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  final String teamId;
  final String teamName;
  final TeamService _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '$teamName Statistics',
          style: TextStyles.font16White600Weight,
        ),
      ),
      body: StreamBuilder<TeamPerformance>(
        stream: _teamService.watchTeamPerformance(teamId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ColorsManager.mainBlue),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(
                'Unable to load team statistics right now.');
          }

          final performance = snapshot.data;
          if (performance == null) {
            return _buildEmptyState();
          }

          return StreamBuilder<List<TeamCustomStat>>(
            stream: _teamService.watchTeamCustomStats(teamId),
            builder: (context, customSnapshot) {
              final customStats = customSnapshot.data ?? const [];
              return _buildContent(performance, customStats);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    TeamPerformance performance,
    List<TeamCustomStat> customStats,
  ) {
    final points = performance.wins * 3 + performance.draws;
    final goalDifference =
        performance.totalGoalsScored - performance.totalGoalsConceded;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Season Overview'),
          Gap(12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _buildStatTile(
                label: 'Matches Played',
                value: performance.totalMatches.toString(),
                color: ColorsManager.mainBlue,
                icon: Icons.sports_soccer,
              ),
              _buildStatTile(
                label: 'Wins',
                value: performance.wins.toString(),
                color: ColorsManager.success,
                icon: Icons.emoji_events,
              ),
              _buildStatTile(
                label: 'Losses',
                value: performance.losses.toString(),
                color: ColorsManager.error,
                icon: Icons.cancel,
              ),
              _buildStatTile(
                label: 'Draws',
                value: performance.draws.toString(),
                color: ColorsManager.warning,
                icon: Icons.remove,
              ),
            ],
          ),
          Gap(24.h),
          _buildSectionTitle('Performance Metrics'),
          Gap(12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _buildStatTile(
                label: 'Total Points',
                value: points.toString(),
                color: ColorsManager.primary,
                icon: Icons.leaderboard,
              ),
              _buildStatTile(
                label: 'Win Percentage',
                value: '${performance.winPercentage.toStringAsFixed(1)}%',
                color: ColorsManager.success,
                icon: Icons.trending_up,
              ),
              _buildStatTile(
                label: 'Goal Difference',
                value: goalDifference >= 0
                    ? '+$goalDifference'
                    : goalDifference.toString(),
                color: goalDifference >= 0
                    ? ColorsManager.success
                    : ColorsManager.error,
                icon: Icons.score,
              ),
              _buildStatTile(
                label: 'Clean Sheets',
                value: performance.cleanSheets.toString(),
                color: ColorsManager.mainBlue,
                icon: Icons.shield,
              ),
            ],
          ),
          Gap(24.h),
          _buildSectionTitle('Scoring Insights'),
          Gap(12.h),
          _buildInsightCard(
            icon: Icons.sports,
            title: 'Goals Scored',
            value: performance.totalGoalsScored.toString(),
            subtitle:
                'Average ${performance.averageGoalsPerMatch.toStringAsFixed(2)} per match',
            accent: ColorsManager.success,
          ),
          Gap(12.h),
          _buildInsightCard(
            icon: Icons.flag,
            title: 'Goals Conceded',
            value: performance.totalGoalsConceded.toString(),
            subtitle: 'Goalkeepers kept ${performance.cleanSheets} clean sheets',
            accent: ColorsManager.warning,
          ),
          Gap(24.h),
          _buildSectionTitle('Custom Team Stats'),
          Gap(12.h),
          if (customStats.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                'No custom team stats yet. Team admins can add manual metrics from the admin panel.',
                style: TextStyles.font13White500Weight
                    .copyWith(color: Colors.white70),
              ),
            )
          else
            Column(
              children: customStats.map((stat) {
                final value = stat.units != null && stat.units!.isNotEmpty
                    ? '${stat.value} ${stat.units}'
                    : stat.value;
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.label,
                        style: TextStyles.font14White600Weight,
                      ),
                      Gap(6.h),
                      Text(
                        value,
                        style: TextStyles.font16White600Weight
                            .copyWith(color: ColorsManager.panelAccentColor),
                      ),
                      if (stat.description != null &&
                          stat.description!.trim().isNotEmpty) ...[
                        Gap(6.h),
                        Text(
                          stat.description!,
                          style: TextStyles.font12White500Weight
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyles.font16White600Weight,
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: (ScreenUtil().screenWidth - 64.w) / 2,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22.sp),
          Gap(12.h),
          Text(
            value,
            style: TextStyles.font18White600Weight.copyWith(color: color),
          ),
          Gap(4.h),
          Text(
            label,
            style:
                TextStyles.font12White500Weight.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: accent, size: 22.sp),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyles.font14White600Weight),
                Gap(4.h),
                Text(
                  value,
                  style: TextStyles.font18White600Weight.copyWith(color: accent),
                ),
                Gap(4.h),
                Text(
                  subtitle,
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined,
                size: 48, color: Colors.white38),
            Gap(16.h),
            Text(
              'No team statistics yet',
              style: TextStyles.font16White600Weight,
            ),
            Gap(8.h),
            Text(
              'Statistics will update automatically after your team records matches.',
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.redAccent),
            Gap(12.h),
            Text(
              'Something went wrong',
              style: TextStyles.font14White600Weight,
            ),
            Gap(6.h),
            Text(
              message,
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

