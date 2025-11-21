import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/coach_analytics_service.dart';
import '../widgets/team_radar_chart.dart';
import '../widgets/team_performance_line_chart.dart';
import '../widgets/player_bar_chart.dart';
import '../../team/models/models.dart';

/// Detailed team performance screen with comprehensive analytics
class TeamPerformanceScreen extends StatefulWidget {
  final Team team;

  const TeamPerformanceScreen({
    super.key,
    required this.team,
  });

  @override
  State<TeamPerformanceScreen> createState() => _TeamPerformanceScreenState();
}

class _TeamPerformanceScreenState extends State<TeamPerformanceScreen>
    with SingleTickerProviderStateMixin {
  final CoachAnalyticsService _analyticsService = CoachAnalyticsService();

  late TabController _tabController;
  TeamAnalytics? _teamAnalytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTeamAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final analytics =
          await _analyticsService.getTeamAnalytics(widget.team.id);

      setState(() {
        _teamAnalytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.team.name,
            style: TextStyles.font16White600Weight,
          ),
          Text(
            'Team Performance',
            style: TextStyles.font12DarkBlue400Weight.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      backgroundColor: ColorsManager.mainBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadTeamAnalytics,
          tooltip: 'Refresh',
        ),
      ],
      bottom: _isLoading || _error != null || _teamAnalytics == null
          ? null
          : TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              labelStyle: TextStyles.font14White500Weight,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Progress'),
                Tab(text: 'Players'),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorsManager.mainBlue,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_teamAnalytics == null) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildProgressTab(),
        _buildPlayersTab(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: ColorsManager.gray,
            ),
            Gap(16.h),
            Text(
              'Failed to load team analytics',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            ElevatedButton(
              onPressed: _loadTeamAnalytics,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
                style: TextStyles.font16White600Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
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
              'No Analytics Available',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'Team analytics will appear here once players start logging activities.',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadTeamAnalytics,
      color: ColorsManager.mainBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeamStatsCards(),
            Gap(24.h),
            _buildTeamRadarChart(),
            Gap(24.h),
            _buildInsightsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    return RefreshIndicator(
      onRefresh: _loadTeamAnalytics,
      color: ColorsManager.mainBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Progress Over Time',
              style: TextStyles.font18DarkBlue600Weight,
            ),
            Gap(16.h),
            TeamPerformanceLineChart(
              performanceHistory: _teamAnalytics!.performanceHistory,
              height: 300,
            ),
            Gap(24.h),
            _buildProgressInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersTab() {
    return RefreshIndicator(
      onRefresh: _loadTeamAnalytics,
      color: ColorsManager.mainBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player Performance Comparison',
              style: TextStyles.font18DarkBlue600Weight,
            ),
            Gap(16.h),
            PlayerBarChart(
              playerPerformances: _teamAnalytics!.playerPerformances,
              height: 300,
            ),
            Gap(24.h),
            _buildPlayersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Overall Score',
            _teamAnalytics!.overallTeamScore.toStringAsFixed(1),
            Icons.trending_up,
            ColorsManager.mainBlue,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildStatCard(
            'Improvement',
            '${_teamAnalytics!.isImproving ? '+' : ''}${_teamAnalytics!.improvementPercentage.toStringAsFixed(1)}%',
            _teamAnalytics!.isImproving
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            _teamAnalytics!.isImproving ? Colors.green : Colors.red,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildStatCard(
            'Active Players',
            _teamAnalytics!.playerPerformances.values
                .where((p) => p.isActive)
                .length
                .toString(),
            Icons.person,
            const Color(0xFF4ECDC4),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16.sp,
            ),
          ),
          Gap(8.h),
          Text(
            value,
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(4.h),
          Text(
            title,
            style: TextStyles.font12DarkBlue400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRadarChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Skill Levels',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        Center(
          child: TeamRadarChart(
            skillScores: _teamAnalytics!.averageSkillScores,
            size: 280,
            showAnimation: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    final strongestSkill = _teamAnalytics!.strongestSkill;
    final weakestSkill = _teamAnalytics!.weakestSkill;
    final mostImprovedPlayer = _teamAnalytics!.mostImprovedPlayerId != null
        ? _teamAnalytics!
            .playerPerformances[_teamAnalytics!.mostImprovedPlayerId!]
            ?.playerName
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Insights',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        if (strongestSkill != null)
          _buildInsightCard(
            'Strongest Skill',
            strongestSkill.displayName,
            'Score: ${_teamAnalytics!.averageSkillScores[strongestSkill]!.toStringAsFixed(1)}',
            Icons.star,
            Colors.amber,
          ),
        if (weakestSkill != null) ...[
          Gap(12.h),
          _buildInsightCard(
            'Area for Improvement',
            weakestSkill.displayName,
            'Score: ${_teamAnalytics!.averageSkillScores[weakestSkill]!.toStringAsFixed(1)}',
            Icons.trending_down,
            Colors.orange,
          ),
        ],
        if (mostImprovedPlayer != null) ...[
          Gap(12.h),
          _buildInsightCard(
            'Most Improved Player',
            mostImprovedPlayer,
            'Keep up the great work!',
            Icons.emoji_events,
            Colors.green,
          ),
        ],
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String subtitle,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.font12DarkBlue400Weight,
                ),
                Gap(2.h),
                Text(
                  subtitle,
                  style: TextStyles.font16DarkBlue600Weight,
                ),
                Gap(2.h),
                Text(
                  description,
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInsights() {
    final isImproving = _teamAnalytics!.isImproving;
    final improvementRate = _teamAnalytics!.improvementPercentage;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isImproving ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isImproving ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isImproving ? Icons.trending_up : Icons.trending_flat,
            color: isImproving ? Colors.green[600] : Colors.orange[600],
            size: 24.sp,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isImproving ? 'Team is Improving!' : 'Steady Performance',
                  style: TextStyles.font16DarkBlue600Weight.copyWith(
                    color: isImproving ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                Gap(4.h),
                Text(
                  isImproving
                      ? 'Your team has improved by ${improvementRate.toStringAsFixed(1)}% over time.'
                      : 'Team performance is stable. Consider new training methods.',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    final players = _teamAnalytics!.playerPerformances.values.toList()
      ..sort((a, b) => b.overallScore.compareTo(a.overallScore));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Player Rankings',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players.length,
          separatorBuilder: (context, index) => Gap(8.h),
          itemBuilder: (context, index) {
            final player = players[index];
            return _buildPlayerListItem(player, index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildPlayerListItem(PlayerPerformanceData player, int rank) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyles.font12DarkBlue400Weight.copyWith(
                  color: _getRankColor(rank),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName,
                  style: TextStyles.font14DarkBlue600Weight,
                ),
                Text(
                  'Score: ${player.overallScore.toStringAsFixed(1)} • ${player.totalSessions} sessions',
                  style: TextStyles.font12DarkBlue400Weight,
                ),
              ],
            ),
          ),
          if (player.isImproving)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'Improving',
                style: TextStyles.font12DarkBlue400Weight.copyWith(
                  color: Colors.green[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return ColorsManager.gray;
    }
  }
}
