import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../models/dashboard_models.dart';
import '../../models/match_models.dart';
import '../../models/user_profile.dart';

/// Swipeable card widget for people search
class SwipeableCard extends StatefulWidget {
  final MatchmakingSuggestion suggestion;
  final Function(SwipeAction) onSwipe;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final bool isInteractive;

  const SwipeableCard({
    super.key,
    required this.suggestion,
    required this.onSwipe,
    required this.onLike,
    required this.onComment,
    this.isInteractive = true,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final offset = _isDragging 
            ? _dragOffset 
            : _slideAnimation.value * MediaQuery.of(context).size.width;
        
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: _isDragging 
                ? _dragOffset.dx * 0.001 
                : _rotationAnimation.value * (_slideAnimation.value.dx > 0 ? 1 : -1),
            child: Transform.scale(
              scale: _isDragging ? 1.0 : _scaleAnimation.value,
              child: widget.isInteractive 
                  ? GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: _buildCard(),
                    )
                  : _buildCard(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
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
        child: Column(
          children: [
            _buildImageSection(),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Expanded(
      flex: 3,
      child: Stack(
        children: [
          // Profile image
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: widget.suggestion.profilePictureUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.suggestion.profilePictureUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: ColorsManager.outline.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person,
                        size: 80.sp,
                        color: ColorsManager.outline,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: ColorsManager.outline.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person,
                        size: 80.sp,
                        color: ColorsManager.outline,
                      ),
                    ),
                  )
                : Container(
                    color: ColorsManager.outline.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      size: 80.sp,
                      color: ColorsManager.outline,
                    ),
                  ),
          ),

          // Compatibility score badge
          Positioned(
            top: 16.h,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _getCompatibilityColor(widget.suggestion.compatibilityScore),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '${widget.suggestion.compatibilityScore.round()}% Match',
                style: TextStyles.font12WhiteMedium,
              ),
            ),
          ),

          // Action indicators
          if (_isDragging) ...[
            if (_dragOffset.dx > 50)
              Positioned(
                left: 20.w,
                top: 20.h,
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
            if (_dragOffset.dx < -50)
              Positioned(
                right: 20.w,
                top: 20.h,
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and age
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.suggestion.fullName}, ${widget.suggestion.age}',
                    style: TextStyles.font18DarkBlue600Weight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildRoleBadge(),
              ],
            ),
            Gap(8.h),

            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16.sp,
                  color: ColorsManager.outline,
                ),
                Gap(4.w),
                Expanded(
                  child: Text(
                    widget.suggestion.location,
                    style: TextStyles.font14Grey400Weight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.suggestion.distance < 999)
                  Text(
                    '${widget.suggestion.distance.round()}km away',
                    style: TextStyles.font12Grey400Weight,
                  ),
              ],
            ),
            Gap(12.h),

            // Sports interests
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: widget.suggestion.sportsOfInterest.take(3).map((sport) {
                final isCommon = widget.suggestion.commonInterests.contains(sport);
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isCommon 
                        ? ColorsManager.primary.withValues(alpha: 0.2)
                        : ColorsManager.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: isCommon 
                        ? Border.all(color: ColorsManager.primary, width: 1.w)
                        : null,
                  ),
                  child: Text(
                    sport,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isCommon ? ColorsManager.primary : ColorsManager.outline,
                    ),
                  ),
                );
              }).toList(),
            ),
            Gap(12.h),

            // Bio
            if (widget.suggestion.bio.isNotEmpty)
              Expanded(
                child: Text(
                  widget.suggestion.bio,
                  style: TextStyles.font14Grey400Weight,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Action buttons
            if (widget.isInteractive) ...[
              Gap(16.h),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.favorite,
                      label: 'Like',
                      color: ColorsManager.primary,
                      onPressed: widget.onLike,
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.comment,
                      label: 'Comment',
                      color: ColorsManager.secondary,
                      onPressed: widget.onComment,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: widget.suggestion.role == UserRole.coach 
            ? ColorsManager.secondary.withValues(alpha: 0.2)
            : ColorsManager.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        widget.suggestion.role.displayName,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: widget.suggestion.role == UserRole.coach 
              ? ColorsManager.secondary
              : ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16.sp),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
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
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isInteractive) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isInteractive) return;
    
    setState(() {
      _isDragging = false;
    });

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
