import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/skill_tracking_service.dart';
import '../widgets/widgets.dart';

/// Comprehensive analytics dashboard for skill tracking
class AnalyticsDashboardScreen extends StatefulWidget {
  final String playerId;

  const AnalyticsDashboardScreen({
    super.key,
    required this.playerId,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  final SkillTrackingService _skillService = SkillTrackingService();
  late TabController _tabController;
  
  SkillAnalytics? _analytics;
  bool _isLoading = true;
  String _selectedPeriod = '3M'; // 1M, 3M, 6M, 1Y

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case '1M':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '3M':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case '6M':
          startDate = now.subtract(const Duration(days: 180));
          break;
        case '1Y':
          startDate = now.subtract(const Duration(days: 365));
          break;
        default:
          startDate = now.subtract(const Duration(days: 90));
      }

      final analytics = await _skillService.getPlayerSkillAnalytics(
        widget.playerId,
        startDate: startDate,
        endDate: now,
      );

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Performance Analytics',
        style: TextStyles.font18DarkBlue600Weight.copyWith(fontSize: 20.sp),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios,
          color: ColorsManager.mainBlue,
          size: 20.sp,
        ),
      ),
      actions: [
        _buildPeriodSelector(),
        Gap(8.w),
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
          Tab(text: 'Trends'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      initialValue: _selectedPeriod,
      onSelected: (period) {
        setState(() => _selectedPeriod = period);
        _loadAnalytics();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: '1M', child: Text('Last Month')),
        const PopupMenuItem(value: '3M', child: Text('Last 3 Months')),
        const PopupMenuItem(value: '6M', child: Text('Last 6 Months')),
        const PopupMenuItem(value: '1Y', child: Text('Last Year')),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: ColorsManager.mainBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedPeriod,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: ColorsManager.mainBlue,
              ),
            ),
            Gap(4.w),
            Icon(
              Icons.arrow_drop_down,
              color: ColorsManager.mainBlue,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_analytics == null) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildTrendsTab(),
        _buildInsightsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          _buildKeyMetricsSection(),
          Gap(24.h),
          
          // Current skill levels radar chart
          Text(
            'Current Skill Levels',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(12.h),
          Center(
            child: SkillRadarChart(
              skillScores: _analytics!.currentSkillScores,
              size: 280,
              showAnimation: true,
            ),
          ),
          Gap(24.h),
          
          // Recent performance trend
          Text(
            'Overall Performance Trend',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(12.h),
          _buildOverallTrendChart(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Individual Skill Trends',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(16.h),
          
          // Individual skill trend charts
          for (final skillType in SkillType.allSkills) ...[
            Builder(
              builder: (context) {
                final trendData = _analytics!.getSkillTrend(skillType);
                return Column(
                  children: [
                    SkillLineChart(
                      dataPoints: trendData,
                      skillType: skillType,
                      height: 200,
                      showAnimation: true,
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

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance insights
          _buildPerformanceInsights(),
          Gap(24.h),
          
          // Goal progress
          _buildGoalProgressSection(),
          Gap(24.h),
          
          // Improvement recommendations
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Sessions',
            _analytics!.totalSessions.toString(),
            Icons.fitness_center,
            Colors.blue[600]!,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildMetricCard(
            'Average Score',
            _analytics!.overallAverageScore.toStringAsFixed(1),
            Icons.trending_up,
            Colors.green[600]!,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildMetricCard(
            'Improvement',
            '${_analytics!.isImproving ? '+' : ''}${_getOverallImprovement().toStringAsFixed(1)}%',
            _analytics!.isImproving ? Icons.arrow_upward : Icons.arrow_downward,
            _analytics!.isImproving ? Colors.green[600]! : Colors.red[600]!,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 24.sp),
          Gap(8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Gap(4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallTrendChart() {
    final trendData = _analytics!.overallTrend;
    
    if (trendData.isEmpty) {
      return _buildEmptyChartState('No trend data available');
    }

    return Container(
      height: 200.h,
      padding: EdgeInsets.all(16.w),
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30.h,
                interval: trendData.length > 6 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < trendData.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        '${trendData[index].date.month}/${trendData[index].date.day}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10.sp,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 40.w,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trendData.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: trendData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.score.toDouble());
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [ColorsManager.mainBlue, ColorsManager.mainBlue.withValues(alpha: 0.7)],
              ),
              barWidth: 3.w,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4.r,
                  color: Colors.white,
                  strokeWidth: 2.w,
                  strokeColor: ColorsManager.mainBlue,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.mainBlue.withValues(alpha: 0.2),
                    ColorsManager.mainBlue.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsights() {
    final strongestSkill = _analytics!.strongestSkill;
    final weakestSkill = _analytics!.weakestSkill;
    final mostImproved = _analytics!.mostImprovedSkill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Insights',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        
        if (strongestSkill != null)
          _buildInsightCard(
            'Strongest Skill',
            strongestSkill.displayName,
            'Score: ${_analytics!.currentSkillScores[strongestSkill]}',
            Icons.star,
            Colors.amber[600]!,
          ),
        
        Gap(12.h),
        
        if (weakestSkill != null)
          _buildInsightCard(
            'Area for Improvement',
            weakestSkill.displayName,
            'Score: ${_analytics!.currentSkillScores[weakestSkill]}',
            Icons.trending_down,
            Colors.orange[600]!,
          ),
        
        Gap(12.h),
        
        if (mostImproved != null)
          _buildInsightCard(
            'Most Improved',
            mostImproved.displayName,
            'Improvement: +${_analytics!.skillImprovements[mostImproved]?.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.green[600]!,
          ),
      ],
    );
  }

  Widget _buildGoalProgressSection() {
    final activeGoals = _analytics!.activeGoalsBySkill;
    final hasActiveGoals = activeGoals.values.any((goal) => goal != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Progress',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        
        if (!hasActiveGoals) ...[
          _buildEmptyGoalsInsight(),
        ] else ...[
          Text(
            'Goals Completion Rate: ${_analytics!.goalsCompletionRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(12.h),
          for (final entry in activeGoals.entries)
            if (entry.value != null) _buildGoalProgressCard(entry.value!),
        ],
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        
        // Generate recommendations based on analytics
        for (final rec in _generateRecommendations()) _buildRecommendationCard(rec),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
            child: Icon(icon, color: color, size: 20.sp),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Gap(2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Gap(2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(SkillGoal goal) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.skillType.displayName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Gap(4.h),
                LinearProgressIndicator(
                  value: goal.progressPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(int.parse('0xFF${goal.skillType.colorHex.substring(1)}')),
                  ),
                ),
              ],
            ),
          ),
          Gap(12.w),
          Text(
            '${goal.progressPercentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Color(int.parse('0xFF${goal.skillType.colorHex.substring(1)}')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ColorsManager.mainBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: ColorsManager.mainBlue,
            size: 16.sp,
          ),
          Gap(8.w),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsInsight() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        'No active goals set. Consider setting goals to track progress more effectively.',
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildEmptyChartState(String message) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          Gap(16.h),
          Text(
            'No Analytics Data',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Gap(8.h),
          Text(
            'Start logging performance to see analytics',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  double _getOverallImprovement() {
    if (_analytics == null) return 0.0;
    final improvements = _analytics!.skillImprovements.values;
    if (improvements.isEmpty) return 0.0;
    return improvements.reduce((a, b) => a + b) / improvements.length;
  }

  List<String> _generateRecommendations() {
    if (_analytics == null) return [];
    
    final recommendations = <String>[];
    
    // Recommendation based on weakest skill
    final weakestSkill = _analytics!.weakestSkill;
    if (weakestSkill != null) {
      recommendations.add('Focus on improving ${weakestSkill.displayName} - it\'s currently your lowest scoring skill.');
    }
    
    // Recommendation based on improvement trends
    if (!_analytics!.isImproving) {
      recommendations.add('Consider increasing training frequency or intensity to see better improvement trends.');
    }
    
    // Recommendation based on goals
    if (_analytics!.goalsCompletionRate < 50) {
      recommendations.add('Review your goals - they might be too ambitious. Consider setting smaller, achievable milestones.');
    }
    
    // Recommendation based on consistency
    if (_analytics!.totalSessions < 10) {
      recommendations.add('Consistency is key! Try to maintain regular training sessions for better progress tracking.');
    }
    
    return recommendations;
  }
}
