import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';

/// Bar chart showing player performance comparison within a team
class PlayerBarChart extends StatefulWidget {
  final Map<String, PlayerPerformanceData> playerPerformances;
  final double height;
  final bool showAnimation;
  final VoidCallback? onTap;

  const PlayerBarChart({
    super.key,
    required this.playerPerformances,
    this.height = 250,
    this.showAnimation = true,
    this.onTap,
  });

  @override
  State<PlayerBarChart> createState() => _PlayerBarChartState();
}

class _PlayerBarChartState extends State<PlayerBarChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playerPerformances.isEmpty) {
      return _buildEmptyState();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16.h),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BarChart(
                    _buildBarChartData(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final topPlayer = widget.playerPerformances.values
        .reduce((a, b) => a.overallScore > b.overallScore ? a : b);

    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.bar_chart,
            color: const Color(0xFF4ECDC4),
            size: 16.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player Performance Comparison',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Top performer: ${topPlayer.playerName} (${topPlayer.overallScore.toStringAsFixed(1)})',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
            Text(
              'No player data available',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Player performance will appear here once data is available',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _buildBarChartData() {
    final players = widget.playerPerformances.values.toList()
      ..sort((a, b) => b.overallScore.compareTo(a.overallScore));

    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final animatedScore = player.overallScore * _animation.value;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: animatedScore,
              color: _getPlayerColor(i),
              width: 24.w,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4.r),
                topRight: Radius.circular(4.r),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey[200],
              ),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      minY: 0,
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40.h,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < players.length) {
                final player = players[index];
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Column(
                    children: [
                      Text(
                        _getShortName(player.playerName),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        player.overallScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: _getPlayerColor(index),
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
            reservedSize: 30.w,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10.sp,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Colors.white,
          tooltipPadding: EdgeInsets.all(8.w),
          tooltipBorder: BorderSide(color: Colors.grey[300]!),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final player = players[group.x.toInt()];
            return BarTooltipItem(
              '${player.playerName}\nScore: ${player.overallScore.toStringAsFixed(1)}\nSessions: ${player.totalSessions}',
              TextStyle(
                color: _getPlayerColor(group.x.toInt()),
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getPlayerColor(int index) {
    final colors = [
      const Color(0xFF247CFF), // Blue
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFF45B7D1), // Light Blue
      const Color(0xFF96CEB4), // Green
      const Color(0xFFFFD93D), // Yellow
      const Color(0xFFFF6B6B), // Red
      const Color(0xFFBA68C8), // Purple
      const Color(0xFFFF8A65), // Orange
    ];

    return colors[index % colors.length];
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length == 1) {
      return parts[0].length > 8 ? '${parts[0].substring(0, 8)}...' : parts[0];
    }

    // Return first name and first letter of last name
    final firstName =
        parts[0].length > 6 ? '${parts[0].substring(0, 6)}...' : parts[0];
    final lastInitial = parts.last.isNotEmpty ? parts.last[0] : '';

    return '$firstName $lastInitial.';
  }
}
