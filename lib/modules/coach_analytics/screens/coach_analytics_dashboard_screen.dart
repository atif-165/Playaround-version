import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/coach_analytics_service.dart';
import '../../team/models/models.dart';
import 'team_performance_screen.dart';
import 'player_comparison_screen.dart';

/// Main coach analytics dashboard screen showing all teams and quick stats
class CoachAnalyticsDashboardScreen extends StatefulWidget {
  const CoachAnalyticsDashboardScreen({super.key});

  @override
  State<CoachAnalyticsDashboardScreen> createState() => _CoachAnalyticsDashboardScreenState();
}

class _CoachAnalyticsDashboardScreenState extends State<CoachAnalyticsDashboardScreen> {
  final CoachAnalyticsService _analyticsService = CoachAnalyticsService();
  
  List<Team> _teams = [];
  Map<String, dynamic> _dashboardSummary = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load teams and dashboard summary in parallel
      final results = await Future.wait([
        _analyticsService.getCoachTeams(),
        _analyticsService.getCoachDashboardSummary(),
      ]);

      setState(() {
        _teams = results[0] as List<Team>;
        _dashboardSummary = results[1] as Map<String, dynamic>;
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
      title: Text(
        'Team Analytics',
        style: TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
      ),
      backgroundColor: ColorsManager.mainBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.compare_arrows),
          onPressed: _teams.length >= 2 ? _navigateToPlayerComparison : null,
          tooltip: 'Compare Players',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
          tooltip: 'Refresh',
        ),
      ],
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

    if (_teams.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: ColorsManager.mainBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStatsSection(),
            Gap(24.h),
            _buildTeamsSection(),
          ],
        ),
      ),
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
              'Failed to load analytics',
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
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
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
              Icons.groups_outlined,
              size: 64.sp,
              color: ColorsManager.gray,
            ),
            Gap(16.h),
            Text(
              'No Teams Found',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'You don\'t have any teams yet. Create or join a team to see analytics.',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Teams',
                _dashboardSummary['totalTeams']?.toString() ?? '0',
                Icons.groups,
                ColorsManager.mainBlue,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                'Total Players',
                _dashboardSummary['totalPlayers']?.toString() ?? '0',
                Icons.person,
                const Color(0xFF4ECDC4),
              ),
            ),
          ],
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg Team Score',
                (_dashboardSummary['averageTeamScore'] as double?)?.toStringAsFixed(1) ?? '0.0',
                Icons.trending_up,
                const Color(0xFF45B7D1),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                'Top Team',
                _dashboardSummary['topPerformingTeam']?.toString() ?? 'None',
                Icons.star,
                const Color(0xFFFFD700),
                isText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isText = false,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
            ],
          ),
          Gap(12.h),
          Text(
            title,
            style: TextStyles.font12DarkBlue400Weight,
          ),
          Gap(4.h),
          isText
              ? Text(
                  value,
                  style: TextStyles.font14DarkBlue600Weight,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  value,
                  style: TextStyles.font18DarkBlue600Weight,
                ),
        ],
      ),
    );
  }

  Widget _buildTeamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Teams',
              style: TextStyles.font18DarkBlue600Weight,
            ),
            if (_teams.length >= 2)
              TextButton.icon(
                onPressed: _navigateToPlayerComparison,
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Compare Players'),
                style: TextButton.styleFrom(
                  foregroundColor: ColorsManager.mainBlue,
                ),
              ),
          ],
        ),
        Gap(16.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _teams.length,
          separatorBuilder: (context, index) => Gap(12.h),
          itemBuilder: (context, index) {
            final team = _teams[index];
            return _buildTeamCard(team);
          },
        ),
      ],
    );
  }

  Widget _buildTeamCard(Team team) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTeamPerformance(team),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.groups,
                        color: ColorsManager.mainBlue,
                        size: 24.sp,
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: TextStyles.font16DarkBlue600Weight,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Gap(4.h),
                          Text(
                            '${team.sportType.displayName} • ${team.members.length} members',
                            style: TextStyles.font12DarkBlue400Weight,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: ColorsManager.gray,
                      size: 16.sp,
                    ),
                  ],
                ),
                Gap(12.h),
                Text(
                  team.description,
                  style: TextStyles.font14Grey400Weight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTeamPerformance(Team team) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeamPerformanceScreen(team: team),
      ),
    );
  }

  void _navigateToPlayerComparison() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerComparisonScreen(teams: _teams),
      ),
    );
  }
}
