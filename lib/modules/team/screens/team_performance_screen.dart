import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.teamName} Performance',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.darkBlue),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.mainBlue,
          unselectedLabelColor: ColorsManager.gray,
          indicatorColor: ColorsManager.mainBlue,
          tabs: const [
            Tab(text: 'Team Stats'),
            Tab(text: 'Player Stats'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamStatsTab(),
          _buildPlayerStatsTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildTeamStatsTab() {
    return StreamBuilder<TeamPerformance?>(
      stream: _teamService.getTeamPerformance(widget.teamId).asStream(),
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
                  'Team performance will appear here after matches',
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
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

  Widget _buildPlayerStatsTab() {
    return StreamBuilder<List<PlayerPerformance>>(
      stream: _teamService.getTeamPlayerPerformances(widget.teamId),
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

        final playerPerformances = snapshot.data ?? [];
        if (playerPerformances.isEmpty) {
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

        // Sort players by goals scored (descending)
        playerPerformances.sort((a, b) => b.goalsScored.compareTo(a.goalsScored));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: playerPerformances.length,
          itemBuilder: (context, index) {
            final performance = playerPerformances[index];
            return _buildPlayerStatsCard(performance);
          },
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return StreamBuilder<List<TeamAchievement>>(
      stream: _teamService.getTeamAchievements(widget.teamId),
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
            'Team Overview',
            style: TextStyles.font18DarkBlue600Weight,
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
                  ColorsManager.mainBlue,
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
            'Match Statistics',
            style: TextStyles.font18DarkBlue600Weight,
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
                  ColorsManager.mainBlue,
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
            'Goal Statistics',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(16.h),
          if (performance.topScorers.isNotEmpty) ...[
            Text(
              'Top Scorers',
              style: TextStyles.font16DarkBlue500Weight,
            ),
            Gap(8.h),
            ...performance.topScorers.take(3).map((playerId) {
              return Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  '• Player $playerId',
                  style: TextStyles.font14Grey400Weight,
                ),
              );
            }),
          ] else
            Text(
              'No top scorers data yet',
              style: TextStyles.font14Grey400Weight,
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard(TeamPerformance performance) {
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
            'Recent Form',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(16.h),
          Text(
            performance.form,
            style: TextStyles.font24DarkBlue600Weight,
          ),
          Gap(8.h),
          Text(
            'Last 5 matches',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsCard(PlayerPerformance performance) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: ColorsManager.mainBlue,
                child: Text(
                  performance.playerName.isNotEmpty 
                      ? performance.playerName[0].toUpperCase()
                      : 'P',
                  style: TextStyles.font16White600Weight,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      performance.playerName,
                      style: TextStyles.font16DarkBlue600Weight,
                    ),
                    Text(
                      '${performance.matchesPlayed} matches played',
                      style: TextStyles.font13Grey400Weight,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorsManager.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${performance.averageRating.toStringAsFixed(1)}★',
                  style: TextStyles.font12DarkBlue400Weight.copyWith(
                    color: ColorsManager.success,
                  ),
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _buildPlayerStatItem('Goals', '${performance.goalsScored}'),
              ),
              Expanded(
                child: _buildPlayerStatItem('Assists', '${performance.assists}'),
              ),
              Expanded(
                child: _buildPlayerStatItem('Saves', '${performance.saves}'),
              ),
              Expanded(
                child: _buildPlayerStatItem('Win Rate', '${(performance.winRatio * 100).toStringAsFixed(0)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Text(
          label,
          style: TextStyles.font12Grey400Weight,
        ),
      ],
    );
  }

  Widget _buildAchievementCard(TeamAchievement achievement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  style: TextStyles.font16DarkBlue600Weight,
                ),
                Gap(4.h),
                Text(
                  achievement.description,
                  style: TextStyles.font14Grey400Weight,
                ),
                Gap(4.h),
                Text(
                  _formatDate(achievement.achievedAt),
                  style: TextStyles.font12Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        Gap(8.h),
        Text(
          value,
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Text(
          label,
          style: TextStyles.font12Grey400Weight,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
