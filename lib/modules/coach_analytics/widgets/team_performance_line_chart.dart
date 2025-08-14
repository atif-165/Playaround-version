import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Line chart showing team performance over time
class TeamPerformanceLineChart extends StatefulWidget {
  final List<TeamPerformanceDataPoint> performanceHistory;
  final double height;
  final bool showAnimation;
  final bool showGrid;
  final VoidCallback? onTap;

  const TeamPerformanceLineChart({
    super.key,
    required this.performanceHistory,
    this.height = 250,
    this.showAnimation = true,
    this.showGrid = true,
    this.onTap,
  });

  @override
  State<TeamPerformanceLineChart> createState() => _TeamPerformanceLineChartState();
}

class _TeamPerformanceLineChartState extends State<TeamPerformanceLineChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    if (widget.performanceHistory.isEmpty) {
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
                  return LineChart(
                    _buildLineChartData(),
                    duration: const Duration(milliseconds: 250),
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
    final improvement = _calculateImprovement();
    final isImproving = improvement > 0;

    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: const Color(0xFF247CFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.trending_up,
            color: const Color(0xFF247CFF),
            size: 16.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Performance Trend',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (widget.performanceHistory.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      'Current: ${widget.performanceHistory.last.averageScore.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isImproving ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isImproving ? Icons.trending_up : Icons.trending_down,
                            size: 12.sp,
                            color: isImproving ? Colors.green[600] : Colors.red[600],
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${improvement.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: isImproving ? Colors.green[600] : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
              Icons.show_chart,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
            Text(
              'No performance data available',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Performance trends will appear as data is collected',
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

  LineChartData _buildLineChartData() {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < widget.performanceHistory.length; i++) {
      final point = widget.performanceHistory[i];
      final animatedScore = point.averageScore * _animation.value;
      spots.add(FlSpot(i.toDouble(), animatedScore));
    }

    // Calculate min and max values for better scaling
    final scores = widget.performanceHistory.map((p) => p.averageScore).toList();
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final padding = (maxScore - minScore) * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: widget.showGrid,
        drawVerticalLine: false,
        horizontalInterval: (maxScore - minScore) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30.h,
            interval: widget.performanceHistory.length > 8 ? 2 : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.performanceHistory.length) {
                final date = widget.performanceHistory[index].date;
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    DateFormat('MM/dd').format(date),
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
            interval: (maxScore - minScore) / 4,
            reservedSize: 40.w,
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
      minX: 0,
      maxX: (widget.performanceHistory.length - 1).toDouble(),
      minY: (minScore - padding).clamp(0, double.infinity),
      maxY: maxScore + padding,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF247CFF),
              const Color(0xFF247CFF).withValues(alpha: 0.7),
            ],
          ),
          barWidth: 4.w,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 5.r,
                color: Colors.white,
                strokeWidth: 3.w,
                strokeColor: const Color(0xFF247CFF),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF247CFF).withValues(alpha: 0.3),
                const Color(0xFF247CFF).withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.white,
          tooltipPadding: EdgeInsets.all(8.w),
          tooltipBorder: BorderSide(color: Colors.grey[300]!),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final index = barSpot.x.toInt();
              if (index >= 0 && index < widget.performanceHistory.length) {
                final point = widget.performanceHistory[index];
                return LineTooltipItem(
                  '${DateFormat('MMM dd').format(point.date)}\nScore: ${point.averageScore.toStringAsFixed(1)}\nActive: ${point.activePlayers}',
                  TextStyle(
                    color: const Color(0xFF247CFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
    );
  }

  double _calculateImprovement() {
    if (widget.performanceHistory.length < 2) return 0.0;
    
    final firstScore = widget.performanceHistory.first.averageScore;
    final lastScore = widget.performanceHistory.last.averageScore;
    
    if (firstScore == 0) return 0.0;
    
    return ((lastScore - firstScore) / firstScore) * 100;
  }
}
