import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Premium animated line chart for displaying skill progress over time
class SkillLineChart extends StatefulWidget {
  final List<SkillDataPoint> dataPoints;
  final SkillType skillType;
  final double height;
  final bool showAnimation;
  final bool showGrid;
  final VoidCallback? onTap;

  const SkillLineChart({
    super.key,
    required this.dataPoints,
    required this.skillType,
    this.height = 200,
    this.showAnimation = true,
    this.showGrid = true,
    this.onTap,
  });

  @override
  State<SkillLineChart> createState() => _SkillLineChartState();
}

class _SkillLineChartState extends State<SkillLineChart>
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
    if (widget.dataPoints.isEmpty) {
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
            color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}'))
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            _getSkillIcon(widget.skillType),
            color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}')),
            size: 16.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.skillType.displayName} Progress',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (widget.dataPoints.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      'Current: ${widget.dataPoints.last.score}',
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
              'No data available',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Start logging performance to see progress',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < widget.dataPoints.length; i++) {
      final point = widget.dataPoints[i];
      final animatedScore = point.score * _animation.value;
      spots.add(FlSpot(i.toDouble(), animatedScore));
    }

    return LineChartData(
      gridData: FlGridData(
        show: widget.showGrid,
        drawVerticalLine: false,
        horizontalInterval: 20,
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
            interval: widget.dataPoints.length > 6 ? 2 : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.dataPoints.length) {
                final date = widget.dataPoints[index].date;
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
            interval: 25,
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
      maxX: (widget.dataPoints.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}')),
              Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}'))
                  .withValues(alpha: 0.7),
            ],
          ),
          barWidth: 3.w,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4.r,
                color: Colors.white,
                strokeWidth: 2.w,
                strokeColor: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}')),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}'))
                    .withValues(alpha: 0.2),
                Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}'))
                    .withValues(alpha: 0.05),
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
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final index = barSpot.x.toInt();
              if (index >= 0 && index < widget.dataPoints.length) {
                final point = widget.dataPoints[index];
                return LineTooltipItem(
                  '${DateFormat('MMM dd').format(point.date)}\n${point.score}',
                  TextStyle(
                    color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}')),
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
    if (widget.dataPoints.length < 2) return 0.0;
    
    final firstScore = widget.dataPoints.first.score;
    final lastScore = widget.dataPoints.last.score;
    
    if (firstScore == 0) return 0.0;
    
    return ((lastScore - firstScore) / firstScore) * 100;
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
