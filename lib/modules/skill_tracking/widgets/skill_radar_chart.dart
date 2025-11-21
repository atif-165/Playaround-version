import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';

/// Premium animated radar chart for displaying skill scores
class SkillRadarChart extends StatefulWidget {
  final Map<SkillType, int> skillScores;
  final double size;
  final bool showAnimation;
  final VoidCallback? onTap;

  const SkillRadarChart({
    super.key,
    required this.skillScores,
    this.size = 300,
    this.showAnimation = true,
    this.onTap,
  });

  @override
  State<SkillRadarChart> createState() => _SkillRadarChartState();
}

class _SkillRadarChartState extends State<SkillRadarChart>
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
                ),
                dataSets: _buildDataSets(),
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                  color: Colors.grey[600],
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
                  color: Colors.grey[400],
                  fontSize: 10.sp,
                ),
                tickBorderData: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
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
    );
  }

  List<RadarDataSet> _buildDataSets() {
    final dataEntries = <RadarEntry>[];

    for (int i = 0; i < SkillType.allSkills.length; i++) {
      final skillType = SkillType.allSkills[i];
      final score = widget.skillScores[skillType] ?? 0;
      final animatedScore = score * _animation.value;

      dataEntries.add(RadarEntry(value: animatedScore));
    }

    return [
      RadarDataSet(
        fillColor: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
        borderColor: const Color(0xFF4ECDC4),
        entryRadius: 4.r,
        dataEntries: dataEntries,
        borderWidth: 2.w,
      ),
    ];
  }
}

/// Skill score card widget for displaying individual skill metrics
class SkillScoreCard extends StatelessWidget {
  final SkillType skillType;
  final int currentScore;
  final int? targetScore;
  final bool showProgress;
  final VoidCallback? onTap;

  const SkillScoreCard({
    super.key,
    required this.skillType,
    required this.currentScore,
    this.targetScore,
    this.showProgress = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetScore != null && targetScore! > 0
        ? (currentScore / targetScore!).clamp(0.0, 1.0)
        : (currentScore / 100.0).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')),
            width: 2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skill icon and name
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Color(
                            int.parse('0xFF${skillType.colorHex.substring(1)}'))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    _getSkillIcon(skillType),
                    color: Color(
                        int.parse('0xFF${skillType.colorHex.substring(1)}')),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skillType.displayName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (targetScore != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          '$currentScore / $targetScore',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Score display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Color(
                            int.parse('0xFF${skillType.colorHex.substring(1)}'))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '$currentScore',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(
                          int.parse('0xFF${skillType.colorHex.substring(1)}')),
                    ),
                  ),
                ),
              ],
            ),

            if (showProgress) ...[
              SizedBox(height: 12.h),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(int.parse('0xFF${skillType.colorHex.substring(1)}')),
                  ),
                  minHeight: 6.h,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
