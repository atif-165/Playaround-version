import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget for displaying earnings chart using fl_chart
class EarningsChartWidget extends StatelessWidget {
  final Map<String, double> earningsByMonth;
  final bool showGrid;
  final bool showTooltips;

  const EarningsChartWidget({
    super.key,
    required this.earningsByMonth,
    this.showGrid = true,
    this.showTooltips = true,
  });

  @override
  Widget build(BuildContext context) {
    if (earningsByMonth.isEmpty) {
      return _buildEmptyChart();
    }

    final sortedEntries = earningsByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    const maxY = 100.0;
    const minY = 0.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedEntries.length) {
                  final monthKey = sortedEntries[index].key;
                  final parts = monthKey.split('-');
                  if (parts.length == 2) {
                    final month = int.tryParse(parts[1]) ?? 1;
                    final monthNames = [
                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                    ];
                    return Text(
                      monthNames[month - 1],
                      style: TextStyles.font10Grey400Weight,
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: TextStyles.font10Grey400Weight,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minX: 0,
        maxX: (sortedEntries.length - 1).toDouble(),
        minY: minY,
        maxY: maxY * 1.1, // Add 10% padding at the top
        lineBarsData: [
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                ColorsManager.mainBlue.withValues(alpha: 0.8),
                ColorsManager.mainBlue,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: ColorsManager.mainBlue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  ColorsManager.mainBlue.withValues(alpha: 0.3),
                  ColorsManager.mainBlue.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: showTooltips
            ? LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final index = barSpot.x.toInt();
                      if (index >= 0 && index < sortedEntries.length) {
                        final monthKey = sortedEntries[index].key;
                        final value = barSpot.y;
                        return LineTooltipItem(
                          '$monthKey\n\$${value.toStringAsFixed(2)}',
                          TextStyles.font12WhiteMedium,
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              )
            : const LineTouchData(enabled: false),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No data available',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }
}

/// Simple bar chart for earnings comparison
class EarningsBarChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const EarningsBarChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxY = sortedEntries.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.font16DarkBlueBold,
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 200.h,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = sortedEntries[group.x.toInt()];
                    return BarTooltipItem(
                      '${entry.key}\n\$${entry.value.toStringAsFixed(2)}',
                      TextStyles.font12WhiteMedium,
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sortedEntries.length) {
                        return Text(
                          sortedEntries[index].key,
                          style: TextStyles.font10Grey400Weight,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: TextStyles.font10Grey400Weight,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: sortedEntries.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value,
                      color: ColorsManager.mainBlue,
                      width: 16.w,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No data available',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }
}
