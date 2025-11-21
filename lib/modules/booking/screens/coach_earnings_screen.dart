import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/booking_analytics_model.dart';
import '../services/booking_history_service.dart';
import '../widgets/earnings_summary_card.dart';
import '../widgets/earnings_chart_widget.dart';

/// Screen for displaying coach earnings dashboard and analytics
class CoachEarningsScreen extends StatefulWidget {
  const CoachEarningsScreen({super.key});

  @override
  State<CoachEarningsScreen> createState() => _CoachEarningsScreenState();
}

class _CoachEarningsScreenState extends State<CoachEarningsScreen> {
  final BookingHistoryService _bookingHistoryService = BookingHistoryService();

  EarningsSummary? _earningsSummary;
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';

  final List<String> _periodOptions = [
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      switch (_selectedPeriod) {
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'Last 3 Months':
          startDate = DateTime(now.year, now.month - 3, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      final summary = await _bookingHistoryService.getCoachEarningsSummary(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _earningsSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load earnings data: $e'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Earnings Dashboard',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadEarningsData();
            },
            itemBuilder: (context) => _periodOptions.map((period) {
              return PopupMenuItem<String>(
                value: period,
                child: Text(period),
              );
            }).toList(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: TextStyles.font14MainBlue500Weight,
                  ),
                  Gap(4.w),
                  Icon(
                    Icons.arrow_drop_down,
                    color: ColorsManager.mainBlue,
                    size: 20.w,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _earningsSummary == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadEarningsData,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEarningsSummaryCards(),
                        Gap(24.h),
                        _buildEarningsChart(),
                        Gap(24.h),
                        _buildSportBreakdown(),
                        Gap(24.h),
                        _buildSessionStats(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEarningsSummaryCards() {
    final summary = _earningsSummary!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: EarningsSummaryCard(
                title: 'Total Earnings',
                value: '\$${summary.totalEarnings.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: EarningsSummaryCard(
                title: 'Pending Earnings',
                value: '\$${summary.pendingEarnings.toStringAsFixed(2)}',
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: EarningsSummaryCard(
                title: 'Completed Sessions',
                value: '${summary.completedSessions}',
                icon: Icons.check_circle,
                color: Colors.blue,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: EarningsSummaryCard(
                title: 'Avg per Session',
                value: '\$${summary.averageSessionEarnings.toStringAsFixed(0)}',
                icon: Icons.trending_up,
                color: ColorsManager.mainBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsChart() {
    if (_earningsSummary!.earningsByMonth.isEmpty) {
      return _buildEmptyChart();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Trend',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(16.h),
          SizedBox(
            height: 200.h,
            child: EarningsChartWidget(
              earningsByMonth: _earningsSummary!.earningsByMonth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportBreakdown() {
    final summary = _earningsSummary!;

    if (summary.earningsBySport.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings by Sport',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(16.h),
          ...summary.earningsBySport.entries.map((entry) {
            final percentage = summary.totalEarnings > 0
                ? (entry.value / summary.totalEarnings * 100)
                : 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: _getSportColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyles.font14DarkBlue500Weight,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: TextStyles.font14DarkBlueBold,
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyles.font12Grey400Weight,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessionStats() {
    final summary = _earningsSummary!;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Statistics',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(16.h),
          _buildStatRow('Total Sessions', '${summary.totalSessions}'),
          _buildStatRow('Completed Sessions', '${summary.completedSessions}'),
          _buildStatRow('Highest Session Earning',
              '\$${summary.highestSessionEarnings.toStringAsFixed(2)}'),
          _buildStatRow(
              'Most Profitable Sport',
              summary.mostProfitableSport.isNotEmpty
                  ? summary.mostProfitableSport
                  : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.font14Grey400Weight,
          ),
          Text(
            value,
            style: TextStyles.font14DarkBlueBold,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart,
            size: 48.w,
            color: ColorsManager.gray76,
          ),
          Gap(16.h),
          Text(
            'No earnings data available',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(8.h),
          Text(
            'Complete some sessions to see your earnings chart',
            style: TextStyles.font14Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.w,
              color: ColorsManager.coralRed,
            ),
            Gap(16.h),
            Text(
              'Failed to load earnings data',
              style: TextStyles.font18DarkBlueBold,
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            ElevatedButton(
              onPressed: _loadEarningsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
                style: TextStyles.font14White500Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSportColor(String sport) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[sport.hashCode % colors.length];
  }
}
