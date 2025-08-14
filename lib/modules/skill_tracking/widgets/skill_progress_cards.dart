import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../models/models.dart';

/// Grid of skill progress cards with animations
class SkillProgressCards extends StatelessWidget {
  final Map<SkillType, int> skillScores;
  final Map<SkillType, SkillGoal?> skillGoals;
  final bool isLoading;
  final Function(SkillType)? onSkillTap;

  const SkillProgressCards({
    super.key,
    required this.skillScores,
    required this.skillGoals,
    this.isLoading = false,
    this.onSkillTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.2,
      ),
      itemCount: SkillType.allSkills.length,
      itemBuilder: (context, index) {
        final skillType = SkillType.allSkills[index];
        final currentScore = skillScores[skillType] ?? 0;
        final goal = skillGoals[skillType];

        return _SkillProgressCard(
          skillType: skillType,
          currentScore: currentScore,
          goal: goal,
          onTap: () => onSkillTap?.call(skillType),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.2,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        );
      },
    );
  }
}

class _SkillProgressCard extends StatefulWidget {
  final SkillType skillType;
  final int currentScore;
  final SkillGoal? goal;
  final VoidCallback? onTap;

  const _SkillProgressCard({
    required this.skillType,
    required this.currentScore,
    this.goal,
    this.onTap,
  });

  @override
  State<_SkillProgressCard> createState() => _SkillProgressCardState();
}

class _SkillProgressCardState extends State<_SkillProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    // Start progress animation
    _progressController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.goal != null 
        ? (widget.currentScore / widget.goal!.targetScore).clamp(0.0, 1.0)
        : (widget.currentScore / 100.0).clamp(0.0, 1.0);

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}'))
                      .withValues(alpha: 0.2),
                  width: 1.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}'))
                        .withValues(alpha: 0.1),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and score
                  Row(
                    children: [
                      Container(
                        width: 36.w,
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}'))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          _getSkillIcon(widget.skillType),
                          color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}')),
                          size: 18.sp,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}'))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${widget.currentScore}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}')),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Skill name
                  Text(
                    widget.skillType.displayName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  // Goal info or current status
                  if (widget.goal != null) ...[
                    Text(
                      'Goal: ${widget.goal!.targetScore}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${widget.goal!.remainingPoints} points to go',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'No active goal',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Progress bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (widget.goal != null && widget.goal!.isOverdue)
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12.sp,
                                  color: Colors.orange[600],
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: progress * _progressAnimation.value,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(int.parse('0xFF${widget.skillType.colorHex.substring(1)}')),
                              ),
                              minHeight: 6.h,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
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

/// Summary stats widget for overall performance
class SkillSummaryStats extends StatelessWidget {
  final Map<SkillType, int> skillScores;
  final int totalSessions;
  final double overallImprovement;
  final bool isLoading;

  const SkillSummaryStats({
    super.key,
    required this.skillScores,
    required this.totalSessions,
    required this.overallImprovement,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final averageScore = skillScores.values.isEmpty 
        ? 0.0 
        : skillScores.values.reduce((a, b) => a + b) / skillScores.values.length;

    return Container(
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
      child: Row(
        children: [
          _buildStatItem(
            'Average Score',
            averageScore.toStringAsFixed(1),
            Icons.trending_up,
            Colors.blue[600]!,
          ),
          _buildDivider(),
          _buildStatItem(
            'Total Sessions',
            totalSessions.toString(),
            Icons.fitness_center,
            Colors.green[600]!,
          ),
          _buildDivider(),
          _buildStatItem(
            'Improvement',
            '${overallImprovement.toStringAsFixed(1)}%',
            overallImprovement >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            overallImprovement >= 0 ? Colors.green[600]! : Colors.red[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.w,
      height: 40.h,
      color: Colors.grey[200],
      margin: EdgeInsets.symmetric(horizontal: 8.w),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}
