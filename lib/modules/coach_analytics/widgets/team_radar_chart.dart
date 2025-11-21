import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../skill_tracking/models/models.dart';

/// Radar chart specifically designed for team average skill scores
class TeamRadarChart extends StatefulWidget {
  final Map<SkillType, double> skillScores;
  final double size;
  final bool showAnimation;
  final VoidCallback? onTap;

  const TeamRadarChart({
    super.key,
    required this.skillScores,
    this.size = 300,
    this.showAnimation = true,
    this.onTap,
  });

  @override
  State<TeamRadarChart> createState() => _TeamRadarChartState();
}

class _TeamRadarChartState extends State<TeamRadarChart>
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size.w,
        height: widget.size.h,
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
                dataSets: _buildDataSets(),
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                getTitle: (index, angle) {
                  final skillType = SkillType.allSkills[index];
                  return RadarChartTitle(
                    text: skillType.displayName,
                    angle: angle,
                  );
                },
                tickCount: 5,
                ticksTextStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10.sp,
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
    );
  }

  List<RadarDataSet> _buildDataSets() {
    final dataEntries = <RadarEntry>[];

    for (int i = 0; i < SkillType.allSkills.length; i++) {
      final skillType = SkillType.allSkills[i];
      final score = widget.skillScores[skillType] ?? 0.0;
      final animatedScore = score * _animation.value;

      dataEntries.add(RadarEntry(value: animatedScore));
    }

    return [
      RadarDataSet(
        fillColor: const Color(0xFF247CFF)
            .withValues(alpha: 0.2), // Main blue with transparency
        borderColor: const Color(0xFF247CFF),
        entryRadius: 4.r,
        dataEntries: dataEntries,
        borderWidth: 3.w,
      ),
    ];
  }
}

/// Enhanced radar chart showing team performance with additional visual elements
class EnhancedTeamRadarChart extends StatefulWidget {
  final Map<SkillType, double> skillScores;
  final Map<SkillType, double>? targetScores;
  final double size;
  final bool showAnimation;
  final bool showTargets;
  final String? title;
  final VoidCallback? onTap;

  const EnhancedTeamRadarChart({
    super.key,
    required this.skillScores,
    this.targetScores,
    this.size = 300,
    this.showAnimation = true,
    this.showTargets = false,
    this.title,
    this.onTap,
  });

  @override
  State<EnhancedTeamRadarChart> createState() => _EnhancedTeamRadarChartState();
}

class _EnhancedTeamRadarChartState extends State<EnhancedTeamRadarChart>
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
        height: (widget.size + (widget.title != null ? 40 : 0)).h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16.h),
            ],
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return RadarChart(
                    RadarChartData(
                      radarTouchData: RadarTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, response) {
                          // Handle touch events
                        },
                      ),
                      dataSets: _buildEnhancedDataSets(),
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
                        final currentScore =
                            widget.skillScores[skillType] ?? 0.0;
                        return RadarChartTitle(
                          text:
                              '${skillType.displayName}\n${currentScore.toStringAsFixed(1)}',
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
            if (widget.showTargets && widget.targetScores != null) ...[
              SizedBox(height: 12.h),
              _buildLegend(),
            ],
          ],
        ),
      ),
    );
  }

  List<RadarDataSet> _buildEnhancedDataSets() {
    final dataSets = <RadarDataSet>[];

    // Current scores dataset
    final currentEntries = <RadarEntry>[];
    for (int i = 0; i < SkillType.allSkills.length; i++) {
      final skillType = SkillType.allSkills[i];
      final score = widget.skillScores[skillType] ?? 0.0;
      final animatedScore = score * _animation.value;
      currentEntries.add(RadarEntry(value: animatedScore));
    }

    dataSets.add(RadarDataSet(
      fillColor: const Color(0xFF247CFF).withValues(alpha: 0.25),
      borderColor: const Color(0xFF247CFF),
      entryRadius: 5.r,
      dataEntries: currentEntries,
      borderWidth: 3.w,
    ));

    // Target scores dataset (if enabled)
    if (widget.showTargets && widget.targetScores != null) {
      final targetEntries = <RadarEntry>[];
      for (int i = 0; i < SkillType.allSkills.length; i++) {
        final skillType = SkillType.allSkills[i];
        final targetScore = widget.targetScores![skillType] ?? 0.0;
        final animatedScore = targetScore * _animation.value;
        targetEntries.add(RadarEntry(value: animatedScore));
      }

      dataSets.add(RadarDataSet(
        fillColor: Colors.transparent,
        borderColor: const Color(0xFFFF6B6B),
        entryRadius: 3.r,
        dataEntries: targetEntries,
        borderWidth: 2.w,
      ));
    }

    return dataSets;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Current', const Color(0xFF247CFF)),
        SizedBox(width: 16.w),
        _buildLegendItem('Target', const Color(0xFFFF6B6B)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
