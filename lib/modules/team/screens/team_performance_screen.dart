import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../models/models.dart';
import '../services/team_service.dart';

/// Screen for displaying team and player performance statistics
class TeamPerformanceScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamPerformanceScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamPerformanceScreen> createState() => _TeamPerformanceScreenState();
}

class _TeamPerformanceScreenState extends State<TeamPerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: PublicProfileTheme.backgroundGradient,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: PublicProfileTheme.glassPanelDecoration(
                borderRadius: 20.r,
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicator: BoxDecoration(
                  color: PublicProfileTheme.panelAccentColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                tabs: const [
                  Tab(text: 'Team Stats'),
                  Tab(text: 'Player Stats'),
                  Tab(text: 'Achievements'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTeamStatsTab(),
                _buildPlayerStatsTab(),
                _buildAchievementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatsTab() {
    return StreamBuilder<TeamPerformance>(
      stream: _teamService.watchTeamPerformance(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading team stats',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  snapshot.error.toString(),
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final teamPerformance = snapshot.data;
        if (teamPerformance == null) {
          return _buildNoStatsPlaceholder();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeamOverviewCard(teamPerformance),
              Gap(20.h),
              _buildMatchStatsCard(teamPerformance),
              Gap(20.h),
              _buildGoalStatsCard(teamPerformance),
              Gap(20.h),
              _buildFormCard(teamPerformance),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoStatsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64.sp,
            color: ColorsManager.gray,
          ),
          Gap(16.h),
          Text(
            'No performance data yet',
            style: TextStyles.font16DarkBlue500Weight,
          ),
          Gap(8.h),
          Text(
            'Team performance will appear here after matches.',
            style: TextStyles.font13Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsTab() {
    return StreamBuilder<List<PlayerHighlightStat>>(
      stream: _teamService.watchPlayerHighlights(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading player stats',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
              ],
            ),
          );
        }

        final playerHighlights =
            List<PlayerHighlightStat>.of(snapshot.data ?? const []);
        if (playerHighlights.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64.sp,
                  color: ColorsManager.gray,
                ),
                Gap(16.h),
                Text(
                  'No player stats yet',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  'Player performance will appear here after matches',
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        playerHighlights.sort(
          (a, b) =>
              (b.metrics['goals'] ?? 0).compareTo(a.metrics['goals'] ?? 0),
        );

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: playerHighlights.length,
          itemBuilder: (context, index) {
            final highlight = playerHighlights[index];
            return _buildPlayerHighlightCard(highlight);
          },
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return StreamBuilder<List<TeamAchievement>>(
      stream: _teamService.watchTeamAchievements(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading achievements',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
              ],
            ),
          );
        }

        final achievements = snapshot.data ?? [];
        if (achievements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64.sp,
                  color: ColorsManager.gray,
                ),
                Gap(16.h),
                Text(
                  'No achievements yet',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  'Team achievements will appear here',
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _buildAchievementCard(achievement);
          },
        );
      },
    );
  }

  Widget _buildTeamOverviewCard(TeamPerformance performance) {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Overview',
            style: TextStyles.font18DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Win Rate',
                  '${performance.winPercentage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  ColorsManager.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Matches',
                  '${performance.totalMatches}',
                  Icons.sports_soccer,
                  ColorsManager.primary,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Wins',
                  '${performance.wins}',
                  Icons.check_circle,
                  ColorsManager.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Losses',
                  '${performance.losses}',
                  Icons.cancel,
                  ColorsManager.error,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Draws',
                  '${performance.draws}',
                  Icons.remove,
                  ColorsManager.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStatsCard(TeamPerformance performance) {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Statistics',
            style: TextStyles.font18DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Goals Scored',
                  '${performance.totalGoalsScored}',
                  Icons.sports_soccer,
                  ColorsManager.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Goals Conceded',
                  '${performance.totalGoalsConceded}',
                  Icons.sports_soccer,
                  ColorsManager.error,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Clean Sheets',
                  '${performance.cleanSheets}',
                  Icons.shield,
                  ColorsManager.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Avg Goals/Match',
                  '${performance.averageGoalsPerMatch.toStringAsFixed(1)}',
                  Icons.analytics,
                  ColorsManager.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStatsCard(TeamPerformance performance) {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal Statistics',
            style: TextStyles.font18DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(16.h),
          if (performance.topScorers.isNotEmpty) ...[
            Text(
              'Top Scorers',
              style: TextStyles.font16DarkBlue500Weight
                  .copyWith(color: Colors.white),
            ),
            Gap(8.h),
            ...performance.topScorers.take(3).map((playerId) {
              return Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  '• Player $playerId',
                  style: TextStyles.font14Grey400Weight
                      .copyWith(color: Colors.white70),
                ),
              );
            }),
          ] else
            Text(
              'No top scorers data yet',
              style: TextStyles.font14Grey400Weight
                  .copyWith(color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard(TeamPerformance performance) {
    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Form',
            style: TextStyles.font18DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(16.h),
          Text(
            performance.form,
            style: TextStyles.font24DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(8.h),
          Text(
            'Last 5 matches',
            style:
                TextStyles.font14Grey400Weight.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHighlightCard(PlayerHighlightStat stat) {
    final metrics = stat.metrics;
    final sortedMetrics = metrics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _glassPanel(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: ColorsManager.primary.withOpacity(0.18),
                backgroundImage: stat.avatarUrl.isNotEmpty
                    ? NetworkImage(stat.avatarUrl)
                    : null,
                child: stat.avatarUrl.isEmpty
                    ? Text(
                        stat.playerName.isNotEmpty
                            ? stat.playerName[0].toUpperCase()
                            : 'P',
                        style: TextStyles.font16DarkBlue600Weight
                            .copyWith(color: Colors.white),
                      )
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.playerName,
                      style: TextStyles.font16DarkBlue600Weight
                          .copyWith(color: Colors.white),
                    ),
                    if (metrics.containsKey('matches'))
                      Text(
                        '${metrics['matches']} matches tracked',
                        style: TextStyles.font13Grey400Weight
                            .copyWith(color: Colors.white70),
                      ),
                  ],
                ),
              ),
              if (metrics.containsKey('rating'))
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${metrics['rating']?.toStringAsFixed(1) ?? metrics['rating']}★',
                    style: TextStyles.font12DarkBlue400Weight
                        .copyWith(color: ColorsManager.primary),
                  ),
                ),
            ],
          ),
          Gap(12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: sortedMetrics
                .where((entry) {
                  final key = entry.key.toLowerCase();
                  return key != 'rating' && key != 'matches';
                })
                .take(6)
                .map((entry) {
                  final metricValue = entry.value;
                  String value;
                  if (metricValue is num) {
                    value = metricValue % 1 == 0
                        ? metricValue.toStringAsFixed(0)
                        : metricValue.toStringAsFixed(1);
                  } else {
                    value = metricValue.toString();
                  }
                  final label = entry.key.replaceAll('_', ' ').toUpperCase();
                  return _buildPlayerMetricChip(label, value);
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerMetricChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyles.font14DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Text(
            label,
            style:
                TextStyles.font11Grey400Weight.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(TeamAchievement achievement) {
    return _glassPanel(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: ColorsManager.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Icon(
              Icons.emoji_events,
              color: ColorsManager.warning,
              size: 24.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyles.font16DarkBlue600Weight
                      .copyWith(color: Colors.white),
                ),
                Gap(4.h),
                if (achievement.description.isNotEmpty)
                  Text(
                    achievement.description,
                    style: TextStyles.font14Grey400Weight
                        .copyWith(color: Colors.white70),
                  ),
                Gap(4.h),
                Text(
                  _formatDate(achievement.achievedAt),
                  style: TextStyles.font12Grey400Weight
                      .copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassPanel({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double borderRadius = 22,
  }) {
    final radius = borderRadius.r;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: PublicProfileTheme.defaultBlurSigma,
            sigmaY: PublicProfileTheme.defaultBlurSigma,
          ),
          child: Container(
            padding: padding ?? EdgeInsets.all(20.w),
            decoration: PublicProfileTheme.glassPanelDecoration(
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        Gap(8.h),
        Text(
          value,
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style:
              TextStyles.font12Grey400Weight.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
