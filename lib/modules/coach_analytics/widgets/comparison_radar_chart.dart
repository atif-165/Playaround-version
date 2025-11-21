import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../skill_tracking/models/models.dart';

/// Radar chart for comparing two players side by side
class ComparisonRadarChart extends StatefulWidget {
  final Map<SkillType, int> player1Data;
  final Map<SkillType, int> player2Data;
  final String player1Name;
  final String player2Name;
  final double size;
  final bool showAnimation;
  final VoidCallback? onTap;

  const ComparisonRadarChart({
    super.key,
    required this.player1Data,
    required this.player2Data,
    required this.player1Name,
    required this.player2Name,
    this.size = 300,
    this.showAnimation = true,
    this.onTap,
  });

  @override
  State<ComparisonRadarChart> createState() => _ComparisonRadarChartState();
}

class _ComparisonRadarChartState extends State<ComparisonRadarChart>
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size.w,
        height: (widget.size + 60).h, // Extra space for legend
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return RadarChart(
                    RadarChartData(
                      radarTouchData: RadarTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, response) {
                          // Handle touch events if needed
                        },
                      ),
                      dataSets: _buildComparisonDataSets(),
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData:
                          const BorderSide(color: Colors.transparent),
                      titlePositionPercentageOffset: 0.15,
                      titleTextStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      getTitle: (index, angle) {
                        final skillType = SkillType.allSkills[index];
                        final player1Score = widget.player1Data[skillType] ?? 0;
                        final player2Score = widget.player2Data[skillType] ?? 0;
                        return RadarChartTitle(
                          text:
                              '${skillType.displayName}\n$player1Score | $player2Score',
                          angle: angle,
                        );
                      },
                      tickCount: 5,
                      ticksTextStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 9.sp,
                      ),
                      tickBorderData: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      gridBorderData: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<RadarDataSet> _buildComparisonDataSets() {
    final dataSets = <RadarDataSet>[];

    // Player 1 dataset
    final player1Entries = <RadarEntry>[];
    for (int i = 0; i < SkillType.allSkills.length; i++) {
      final skillType = SkillType.allSkills[i];
      final score = (widget.player1Data[skillType] ?? 0).toDouble();
      final animatedScore = score * _animation.value;
      player1Entries.add(RadarEntry(value: animatedScore));
    }

    dataSets.add(RadarDataSet(
      fillColor: const Color(0xFF247CFF).withValues(alpha: 0.2),
      borderColor: const Color(0xFF247CFF),
      entryRadius: 4.r,
      dataEntries: player1Entries,
      borderWidth: 3.w,
    ));

    // Player 2 dataset
    final player2Entries = <RadarEntry>[];
    for (int i = 0; i < SkillType.allSkills.length; i++) {
      final skillType = SkillType.allSkills[i];
      final score = (widget.player2Data[skillType] ?? 0).toDouble();
      final animatedScore = score * _animation.value;
      player2Entries.add(RadarEntry(value: animatedScore));
    }

    dataSets.add(RadarDataSet(
      fillColor: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
      borderColor: const Color(0xFF4ECDC4),
      entryRadius: 4.r,
      dataEntries: player2Entries,
      borderWidth: 3.w,
    ));

    return dataSets;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          _getShortName(widget.player1Name),
          const Color(0xFF247CFF),
        ),
        SizedBox(width: 24.w),
        _buildLegendItem(
          _getShortName(widget.player2Name),
          const Color(0xFF4ECDC4),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length == 1) {
      return parts[0].length > 10
          ? '${parts[0].substring(0, 10)}...'
          : parts[0];
    }

    // Return first name and first letter of last name
    final firstName =
        parts[0].length > 8 ? '${parts[0].substring(0, 8)}...' : parts[0];
    final lastInitial = parts.last.isNotEmpty ? parts.last[0] : '';

    return '$firstName $lastInitial.';
  }
}

/// Side-by-side radar charts for detailed comparison
class SideBySideRadarComparison extends StatefulWidget {
  final Map<SkillType, int> player1Data;
  final Map<SkillType, int> player2Data;
  final String player1Name;
  final String player2Name;
  final double size;
  final bool showAnimation;

  const SideBySideRadarComparison({
    super.key,
    required this.player1Data,
    required this.player2Data,
    required this.player1Name,
    required this.player2Name,
    this.size = 200,
    this.showAnimation = true,
  });

  @override
  State<SideBySideRadarComparison> createState() =>
      _SideBySideRadarComparisonState();
}

class _SideBySideRadarComparisonState extends State<SideBySideRadarComparison>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
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
    return Row(
      children: [
        Expanded(
          child: _buildPlayerRadar(
            widget.player1Data,
            widget.player1Name,
            const Color(0xFF247CFF),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildPlayerRadar(
            widget.player2Data,
            widget.player2Name,
            const Color(0xFF4ECDC4),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRadar(
    Map<SkillType, int> playerData,
    String playerName,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
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
      child: Column(
        children: [
          Text(
            _getShortName(playerName),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: widget.size.w,
            height: widget.size.h,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return RadarChart(
                  RadarChartData(
                    radarTouchData: RadarTouchData(enabled: false),
                    dataSets: [_buildSinglePlayerDataSet(playerData, color)],
                    radarBackgroundColor: Colors.transparent,
                    borderData: FlBorderData(show: false),
                    radarBorderData:
                        const BorderSide(color: Colors.transparent),
                    titlePositionPercentageOffset: 0.2,
                    titleTextStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    getTitle: (index, angle) {
                      final skillType = SkillType.allSkills[index];
                      final score = playerData[skillType] ?? 0;
                      return RadarChartTitle(
                        text: '${skillType.displayName}\n$score',
                        angle: angle,
                      );
                    },
                    tickCount: 4,
                    ticksTextStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 8.sp,
                    ),
                    tickBorderData: BorderSide(
                      color: Colors.grey[300]!,
                      width: 0.5,
                    ),
                    gridBorderData: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  RadarDataSet _buildSinglePlayerDataSet(
    Map<SkillType, int> playerData,
    Color color,
  ) {
    final entries = <RadarEntry>[];

    for (int i = 0; i < SkillType.allSkills.length; i++) {
      final skillType = SkillType.allSkills[i];
      final score = (playerData[skillType] ?? 0).toDouble();
      final animatedScore = score * _animation.value;
      entries.add(RadarEntry(value: animatedScore));
    }

    return RadarDataSet(
      fillColor: color.withValues(alpha: 0.2),
      borderColor: color,
      entryRadius: 3.r,
      dataEntries: entries,
      borderWidth: 2.w,
    );
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length == 1) {
      return parts[0].length > 12
          ? '${parts[0].substring(0, 12)}...'
          : parts[0];
    }

    return parts[0]; // Just return first name for side-by-side view
  }
}
