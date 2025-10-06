import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/coach_profile.dart';
import '../../../models/match_models.dart';
import '../../../services/coach_matching_service.dart';

/// Swipeable card widget for coach matchmaking
class CoachSwipeableCard extends StatefulWidget {
  final CoachMatch coachMatch;
  final Function(SwipeAction) onSwipe;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final bool isInteractive;

  const CoachSwipeableCard({
    super.key,
    required this.coachMatch,
    required this.onSwipe,
    required this.onLike,
    required this.onComment,
    this.isInteractive = true,
  });

  @override
  State<CoachSwipeableCard> createState() => _CoachSwipeableCardState();
}

class _CoachSwipeableCardState extends State<CoachSwipeableCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _dragAnimationController;
  late Animation<double> _rotationAnimation;
  
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _dragAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dragAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coach = widget.coachMatch.coach;
    
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _dragAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: _rotationAnimation.value * (_dragOffset.dx / 100),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20.r,
                      offset: Offset(0, 10.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Stack(
                    children: [
                      // Background image
                      _buildBackgroundImage(coach),
                      
                      // Gradient overlay
                      _buildGradientOverlay(),
                      
                      // Content
                      _buildContent(coach),
                      
                      // Action overlays
                      _buildActionOverlays(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundImage(CoachProfile coach) {
    return Positioned.fill(
      child: coach.profilePictureUrl != null && coach.profilePictureUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: coach.profilePictureUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: ColorsManager.outline.withValues(alpha: 0.1),
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorsManager.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: ColorsManager.outline.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  size: 80.sp,
                  color: ColorsManager.outline,
                ),
              ),
            )
          : Container(
              color: ColorsManager.outline.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 80.sp,
                color: ColorsManager.outline,
              ),
            ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CoachProfile coach) {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with name and compatibility
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coach.fullName,
                        style: TextStyles.font24WhiteBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(4.h),
                      Text(
                        '${coach.experienceYears} years experience',
                        style: TextStyles.font16White600Weight,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _getCompatibilityColor(widget.coachMatch.matchScore),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${widget.coachMatch.matchScore.toInt()}%',
                    style: TextStyles.font14White600Weight,
                  ),
                ),
              ],
            ),
            
            Spacer(),
            
            // Specializations
            if (coach.specializationSports.isNotEmpty) ...[
              Text(
                'Specializes in:',
                style: TextStyles.font14White600Weight,
              ),
              Gap(8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: coach.specializationSports.take(3).map((sport) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      sport,
                      style: TextStyles.font12White600Weight,
                    ),
                  );
                }).toList(),
              ),
              Gap(16.h),
            ],
            
            // Bio
            if (coach.bio != null && coach.bio!.isNotEmpty) ...[
              Text(
                coach.bio!,
                style: TextStyles.font14White600Weight,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(16.h),
            ],
            
            // Bottom info
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 16.sp,
                ),
                Gap(4.w),
                Expanded(
                  child: Text(
                    coach.location,
                    style: TextStyles.font14White600Weight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.coachMatch.distance != null) ...[
                  Gap(8.w),
                  Text(
                    '${widget.coachMatch.distance!.toStringAsFixed(1)} km',
                    style: TextStyles.font14White600Weight,
                  ),
                ],
              ],
            ),
            
            Gap(8.h),
            
            // Rate and availability
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 16.sp,
                ),
                Gap(4.w),
                Text(
                  '\$${coach.hourlyRate.toStringAsFixed(0)}/hour',
                  style: TextStyles.font14White600Weight,
                ),
                Gap(16.w),
                Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 16.sp,
                ),
                Gap(4.w),
                Text(
                  coach.availableTimeSlots.isNotEmpty ? 'Available' : 'Not available',
                  style: TextStyles.font14White600Weight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOverlays() {
    return Positioned.fill(
      child: Row(
        children: [
          // Left overlay (Pass)
          if (_dragOffset.dx < -50)
            Container(
              width: 100.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.red.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  'PASS',
                  style: TextStyles.font24WhiteBold,
                ),
              ),
            ),
          
          Spacer(),
          
          // Right overlay (Like)
          if (_dragOffset.dx > 50)
            Container(
              width: 100.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.green.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  'LIKE',
                  style: TextStyles.font24WhiteBold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isInteractive) return;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isInteractive) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isInteractive) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx.abs() > threshold) {
      // Trigger swipe action
      final action = _dragOffset.dx > 0 ? SwipeAction.like : SwipeAction.pass;
      
      // Animate card off screen
      _animationController.forward().then((_) {
        widget.onSwipe(action);
        _resetCard();
      });
    } else {
      // Snap back to center
      _resetCard();
    }
  }

  void _resetCard() {
    setState(() {
      _dragOffset = Offset.zero;
    });
    _animationController.reset();
  }
}
