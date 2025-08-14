import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Interactive star rating input widget
class StarRatingInput extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onRatingChanged;
  final bool allowHalfRating;
  final bool isReadOnly;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.starSize = 32.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    required this.onRatingChanged,
    this.allowHalfRating = false,
    this.isReadOnly = false,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput>
    with TickerProviderStateMixin {
  late int _currentRating;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int rating) {
    if (widget.isReadOnly) return;
    
    setState(() {
      _currentRating = rating;
    });
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    widget.onRatingChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starIndex = index + 1;
        final isActive = starIndex <= _currentRating;
        
        return GestureDetector(
          onTap: () => _handleTap(starIndex),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final scale = starIndex == _currentRating ? _scaleAnimation.value : 1.0;
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Icon(
                    isActive ? Icons.star : Icons.star_border,
                    size: widget.starSize.sp,
                    color: isActive ? widget.activeColor : widget.inactiveColor,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// Display-only star rating widget
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRatingText;
  final TextStyle? ratingTextStyle;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 16.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.showRatingText = false,
    this.ratingTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          final starIndex = index + 1;
          final isFullStar = starIndex <= rating.floor();
          final isHalfStar = starIndex == rating.ceil() && rating % 1 != 0;
          
          return Icon(
            isFullStar
                ? Icons.star
                : isHalfStar
                    ? Icons.star_half
                    : Icons.star_border,
            size: starSize.sp,
            color: (isFullStar || isHalfStar) ? activeColor : inactiveColor,
          );
        }),
        if (showRatingText) ...[
          SizedBox(width: 8.w),
          Text(
            rating.toStringAsFixed(1),
            style: ratingTextStyle ??
                TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
          ),
        ],
      ],
    );
  }
}

/// Compact rating summary widget
class RatingSummary extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final TextStyle? textStyle;

  const RatingSummary({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    this.starSize = 16.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRatingDisplay(
          rating: averageRating,
          starSize: starSize,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
        ),
        SizedBox(width: 8.w),
        Text(
          '${averageRating.toStringAsFixed(1)} ($totalRatings)',
          style: textStyle ??
              TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }
}

/// Rating progress bars showing distribution
class RatingDistribution extends StatelessWidget {
  final Map<int, int> starDistribution;
  final int totalRatings;
  final Color progressColor;
  final Color backgroundColor;

  const RatingDistribution({
    super.key,
    required this.starDistribution,
    required this.totalRatings,
    this.progressColor = Colors.amber,
    this.backgroundColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final count = starDistribution[stars] ?? 0;
        final percentage = totalRatings > 0 ? count / totalRatings : 0.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            children: [
              Text(
                '$stars',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.star,
                size: 12.sp,
                color: Colors.amber,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: backgroundColor.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 6.h,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Animated rating card with hover effects
class RatingCard extends StatefulWidget {
  final String raterName;
  final String? raterProfilePicture;
  final int stars;
  final String? feedback;
  final DateTime timestamp;
  final VoidCallback? onTap;

  const RatingCard({
    super.key,
    required this.raterName,
    this.raterProfilePicture,
    required this.stars,
    this.feedback,
    required this.timestamp,
    this.onTap,
  });

  @override
  State<RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<RatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 4.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: _isHovered ? 0.3 : 0.1),
                      spreadRadius: 1,
                      blurRadius: _isHovered ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundImage: widget.raterProfilePicture != null
                              ? NetworkImage(widget.raterProfilePicture!)
                              : null,
                          child: widget.raterProfilePicture == null
                              ? Icon(Icons.person, size: 20.sp)
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.raterName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              StarRatingDisplay(
                                rating: widget.stars.toDouble(),
                                starSize: 14,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTimestamp(widget.timestamp),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (widget.feedback != null && widget.feedback!.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Text(
                        widget.feedback!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
