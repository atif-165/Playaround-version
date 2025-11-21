import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/rating_model.dart';
import '../../../services/rating_service.dart';
import 'star_rating_input.dart';

/// Modal rating prompt that appears after booking completion
class RatingPromptModal extends StatefulWidget {
  final PendingRatingModel pendingRating;
  final VoidCallback onCompleted;
  final VoidCallback? onSkipped;

  const RatingPromptModal({
    super.key,
    required this.pendingRating,
    required this.onCompleted,
    this.onSkipped,
  });

  @override
  State<RatingPromptModal> createState() => _RatingPromptModalState();
}

class _RatingPromptModalState extends State<RatingPromptModal>
    with TickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  final RatingService _ratingService = RatingService();

  int _selectedStars = 0;
  bool _isSubmitting = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      _showErrorDialog('Please select a star rating');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _ratingService.createRating(
        bookingId: widget.pendingRating.bookingId,
        ratedEntityId: widget.pendingRating.ratedEntityId,
        ratingType: widget.pendingRating.ratingType,
        stars: _selectedStars,
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
      );

      // Show success animation
      await _showSuccessAnimation();

      widget.onCompleted();
    } catch (e) {
      _showErrorDialog('Failed to submit rating: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showSuccessAnimation() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SuccessAnimationDialog(),
    );
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          _getIconForRatingType(
                              widget.pendingRating.ratingType),
                          color: ColorsManager.mainBlue,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rate ${widget.pendingRating.ratingType.displayName}',
                              style: TextStyles.font18DarkBlue600Weight,
                            ),
                            Text(
                              widget.pendingRating.entityName,
                              style: TextStyles.font14Grey400Weight,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Star Rating
                  Text(
                    'How was your experience?',
                    style: TextStyles.font16DarkBlue500Weight,
                  ),

                  SizedBox(height: 16.h),

                  StarRatingInput(
                    initialRating: _selectedStars,
                    starSize: 40,
                    activeColor: Colors.amber,
                    inactiveColor: Colors.grey[300]!,
                    onRatingChanged: (rating) {
                      setState(() {
                        _selectedStars = rating;
                      });
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Feedback Text Field
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Share your feedback (optional)',
                      hintStyle: TextStyles.font14Grey400Weight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide:
                            const BorderSide(color: ColorsManager.mainBlue),
                      ),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Action Buttons
                  Row(
                    children: [
                      if (widget.onSkipped != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : widget.onSkipped,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyles.font14Grey400Weight,
                            ),
                          ),
                        ),
                      if (widget.onSkipped != null) SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManager.mainBlue,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Submit Rating',
                                  style: TextStyles.font14White600Weight,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForRatingType(RatingType type) {
    switch (type) {
      case RatingType.coach:
        return Icons.sports_tennis;
      case RatingType.player:
        return Icons.person;
      case RatingType.venue:
        return Icons.location_city;
    }
  }
}

/// Success animation dialog
class _SuccessAnimationDialog extends StatefulWidget {
  const _SuccessAnimationDialog();

  @override
  State<_SuccessAnimationDialog> createState() =>
      _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));

    _controller.forward();

    // Auto close after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.1,
                child: Container(
                  padding: EdgeInsets.all(32.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 48.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Thank you!',
                        style: TextStyles.font18DarkBlue600Weight,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Your rating has been submitted',
                        style: TextStyles.font14Grey400Weight,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Full-screen rating prompt for mandatory ratings
class FullScreenRatingPrompt extends StatelessWidget {
  final List<PendingRatingModel> pendingRatings;
  final Function(PendingRatingModel) onRatingCompleted;
  final VoidCallback onAllCompleted;

  const FullScreenRatingPrompt({
    super.key,
    required this.pendingRatings,
    required this.onRatingCompleted,
    required this.onAllCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.mainBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 48.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Rate Your Experience',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Help others by sharing your feedback',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Rating Cards
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.all(24.w),
                  itemCount: pendingRatings.length,
                  itemBuilder: (context, index) {
                    final pendingRating = pendingRatings[index];

                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      child: RatingPromptModal(
                        pendingRating: pendingRating,
                        onCompleted: () => onRatingCompleted(pendingRating),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
