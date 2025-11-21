import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../models/models.dart';
import '../services/skill_tracking_service.dart';
import '../widgets/widgets.dart';
import 'add_goal_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'coach_logging_screen.dart';

/// Premium Skill Dashboard Screen for players
class SkillDashboardScreen extends StatefulWidget {
  final String playerId;

  const SkillDashboardScreen({
    super.key,
    required this.playerId,
  });

  @override
  State<SkillDashboardScreen> createState() => _SkillDashboardScreenState();
}

class _SkillDashboardScreenState extends State<SkillDashboardScreen>
    with TickerProviderStateMixin {
  final SkillTrackingService _skillService = SkillTrackingService();
  late TabController _tabController;

  // Data streams
  late Stream<List<SessionLog>> _skillLogsStream;
  late Stream<List<SkillGoal>> _skillGoalsStream;

  // Current data
  List<SessionLog> _skillLogs = [];
  List<SkillGoal> _skillGoals = [];
  SkillRecord? _analytics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeStreams() {
    _skillLogsStream = _skillService.getPlayerSkillLogsStream(widget.playerId);
    _skillGoalsStream =
        _skillService.getPlayerSkillGoalsStream(widget.playerId);
  }

  void _updateAnalytics() {
    if (_skillLogs.isNotEmpty || _skillGoals.isNotEmpty) {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 90));

      _analytics = SkillRecord(
        playerId: widget.playerId,
        skillLogs: _skillLogs,
        skillGoals: _skillGoals,
        periodStart: startDate,
        periodEnd: now,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: StreamBuilder<List<SessionLog>>(
        stream: _skillLogsStream,
        builder: (context, logsSnapshot) {
          return StreamBuilder<List<SkillGoal>>(
            stream: _skillGoalsStream,
            builder: (context, goalsSnapshot) {
              if (logsSnapshot.connectionState == ConnectionState.waiting ||
                  goalsSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (logsSnapshot.hasError || goalsSnapshot.hasError) {
                return _buildErrorState(logsSnapshot.error?.toString() ??
                    goalsSnapshot.error?.toString() ??
                    'Unknown error');
              }

              // Update data when streams provide new data
              _skillLogs = logsSnapshot.data ?? [];
              _skillGoals = goalsSnapshot.data ?? [];
              _updateAnalytics();

              return _buildContent();
            },
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Dashboard',
            style: TextStyles.font18DarkBlue600Weight.copyWith(fontSize: 20.sp),
          ),
          Text(
            'Track your performance & goals',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showAnalyticsBottomSheet(),
          icon: Icon(
            Icons.analytics_outlined,
            color: ColorsManager.mainBlue,
            size: 24.sp,
          ),
        ),
        IconButton(
          onPressed: () => _refreshData(),
          icon: Icon(
            Icons.refresh,
            color: ColorsManager.mainBlue,
            size: 24.sp,
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: ColorsManager.mainBlue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: ColorsManager.mainBlue,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Progress'),
          Tab(text: 'Goals'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildProgressTab(),
        _buildGoalsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final currentScores = _analytics?.currentSkillScores ?? {};
    final activeGoals = _analytics?.activeGoalsBySkill ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          if (_analytics != null) ...[
            SkillSummaryStats(
              skillScores: currentScores,
              totalSessions: _analytics!.totalSessions,
              overallImprovement: _analytics!.skillImprovements.values.isEmpty
                  ? 0.0
                  : _analytics!.skillImprovements.values
                          .reduce((a, b) => a + b) /
                      _analytics!.skillImprovements.values.length,
              isLoading: false,
            ),
            Gap(20.h),
          ],

          // Radar chart
          Text(
            'Current Skill Levels',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(12.h),
          Center(
            child: SkillRadarChart(
              skillScores: currentScores,
              size: 280,
              showAnimation: true,
              onTap: () => _showSkillDetailsBottomSheet(),
            ),
          ),
          Gap(24.h),

          // Skill progress cards
          Text(
            'Skill Progress',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(12.h),
          SkillProgressCards(
            skillScores: currentScores,
            skillGoals: activeGoals,
            isLoading: false,
            onSkillTap: (skillType) => _showSkillDetailScreen(skillType),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Trends',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(16.h),

          // Line charts for each skill
          for (final skillType in SkillType.allSkills) ...[
            Builder(
              builder: (context) {
                final trendData = _analytics?.getSkillTrend(skillType) ?? [];
                return Column(
                  children: [
                    SkillLineChart(
                      dataPoints: trendData,
                      skillType: skillType,
                      height: 200,
                      showAnimation: true,
                      onTap: () => _showSkillDetailScreen(skillType),
                    ),
                    Gap(16.h),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    final activeGoals =
        _skillGoals.where((goal) => goal.status == GoalStatus.active).toList();
    final completedGoals = _skillGoals
        .where((goal) => goal.status == GoalStatus.achieved)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active goals section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Goals',
                style: TextStyles.font18DarkBlue600Weight,
              ),
              AppTextButton(
                buttonText: 'Add Goal',
                textStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                onPressed: () => _showAddGoalBottomSheet(),
                buttonWidth: 80.w,
                buttonHeight: 32.h,
              ),
            ],
          ),
          Gap(12.h),

          if (activeGoals.isEmpty) ...[
            _buildEmptyGoalsState(),
          ] else ...[
            for (final goal in activeGoals) _buildGoalCard(goal),
          ],

          Gap(24.h),

          // Completed goals section
          if (completedGoals.isNotEmpty) ...[
            Text(
              'Completed Goals',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            Gap(12.h),
            for (final goal in completedGoals.take(3)) _buildGoalCard(goal),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalCard(SkillGoal goal) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: goal.status == GoalStatus.achieved
              ? Colors.green[200]!
              : Color(int.parse('0xFF${goal.skillType.colorHex.substring(1)}'))
                  .withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.r,
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
                _getSkillIcon(goal.skillType),
                color: Color(
                    int.parse('0xFF${goal.skillType.colorHex.substring(1)}')),
                size: 20.sp,
              ),
              Gap(8.w),
              Expanded(
                child: Text(
                  '${goal.skillType.displayName} Goal',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (goal.status == GoalStatus.achieved)
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 20.sp,
                ),
            ],
          ),
          Gap(8.h),
          Text(
            'Target: ${goal.targetScore} by ${goal.formattedTargetDate}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          Gap(8.h),
          LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(int.parse('0xFF${goal.skillType.colorHex.substring(1)}')),
            ),
          ),
          Gap(4.h),
          Text(
            '${goal.progressPercentage.toStringAsFixed(1)}% complete',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          Gap(12.h),
          Text(
            'No Active Goals',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Gap(4.h),
          Text(
            'Set goals to track your progress',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
          Gap(16.h),
          AppTextButton(
            buttonText: 'Set Your First Goal',
            textStyle: TextStyles.font16White600Weight,
            onPressed: () => _showAddGoalBottomSheet(),
            buttonWidth: 160.w,
            buttonHeight: 36.h,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      heroTag: "skill_dashboard_fab",
      onPressed: () => _showQuickLogBottomSheet(),
      backgroundColor: ColorsManager.mainBlue,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Quick Log',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red[400],
            ),
            Gap(16.h),
            Text(
              'Error Loading Data',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              error,
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _initializeStreams();
                });
              },
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

  // Helper methods for navigation and actions
  void _showSkillDetailScreen(SkillType skillType) {
    // TODO: Navigate to detailed skill screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${skillType.displayName} details coming soon!')),
    );
  }

  void _showSkillDetailsBottomSheet() {
    // TODO: Show detailed skill breakdown
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Skill details coming soon!')),
    );
  }

  void _showAnalyticsBottomSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalyticsDashboardScreen(playerId: widget.playerId),
      ),
    );
  }

  void _showAddGoalBottomSheet() {
    final currentScores = _analytics?.currentSkillScores ??
        {
          for (final skill in SkillType.allSkills) skill: 0,
        };

    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) => AddGoalScreen(
          playerId: widget.playerId,
          currentSkillScores: currentScores,
        ),
      ),
    )
        .then((created) {
      if (created == true) {
        _refreshData();
      }
    });
  }

  void _showQuickLogBottomSheet() {
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) => CoachLoggingScreen(
          coachId: widget.playerId,
          playerId: widget.playerId,
          playerName: 'Your Performance',
        ),
      ),
    )
        .then((logged) {
      if (logged == true) {
        _refreshData();
      }
    });
  }

  void _refreshData() {
    _initializeStreams();
  }

  IconData _getSkillIcon(SkillType skillType) {
    switch (skillType) {
      case SkillType.speed:
        return Icons.speed;
      case SkillType.strength:
        return Icons.fitness_center;
      case SkillType.endurance:
        return Icons.directions_run;
      case SkillType.accuracy:
        return Icons.gps_fixed;
      case SkillType.teamwork:
        return Icons.group;
    }
  }
}
