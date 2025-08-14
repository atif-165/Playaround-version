import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import 'app_cards.dart';
import 'app_buttons.dart';
import 'app_input_fields.dart';

/// Material 3 Feedback and Rating Components for PlayAround App
/// Comprehensive feedback system with ratings, reviews, and user input

/// Star rating widget
class StarRating extends StatefulWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalfRating;
  final bool readOnly;
  final Function(double)? onRatingChanged;

  const StarRating({
    super.key,
    this.rating = 0.0,
    this.maxRating = 5,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.allowHalfRating = true,
    this.readOnly = false,
    this.onRatingChanged,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        return GestureDetector(
          onTap: widget.readOnly ? null : () => _handleTap(index + 1.0),
          onPanUpdate: widget.readOnly ? null : (details) => _handlePan(details, index),
          child: Icon(
            _getStarIcon(index),
            size: widget.size,
            color: _getStarColor(index),
          ),
        );
      }),
    );
  }

  IconData _getStarIcon(int index) {
    final starValue = index + 1.0;
    if (_currentRating >= starValue) {
      return Icons.star;
    } else if (widget.allowHalfRating && _currentRating >= starValue - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(int index) {
    final starValue = index + 1.0;
    if (_currentRating >= starValue || 
        (widget.allowHalfRating && _currentRating >= starValue - 0.5)) {
      return widget.activeColor ?? ColorsManager.warning;
    } else {
      return widget.inactiveColor ?? ColorsManager.outline;
    }
  }

  void _handleTap(double rating) {
    setState(() {
      _currentRating = rating;
    });
    widget.onRatingChanged?.call(rating);
  }

  void _handlePan(DragUpdateDetails details, int index) {
    if (!widget.allowHalfRating) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final starWidth = widget.size;
    final starIndex = (localPosition.dx / starWidth).floor();
    final starPosition = (localPosition.dx % starWidth) / starWidth;
    
    double newRating;
    if (starPosition < 0.5) {
      newRating = starIndex + 0.5;
    } else {
      newRating = starIndex + 1.0;
    }
    
    newRating = newRating.clamp(0.0, widget.maxRating.toDouble());
    
    if (newRating != _currentRating) {
      setState(() {
        _currentRating = newRating;
      });
      widget.onRatingChanged?.call(newRating);
    }
  }
}

/// Rating display widget (read-only)
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final bool showValue;
  final String? label;
  final int? reviewCount;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16.0,
    this.showValue = true,
    this.label,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(
          rating: rating,
          maxRating: maxRating,
          size: size,
          readOnly: true,
        ),
        if (showValue) ...[
          Gap(8.w),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          Gap(4.w),
          Text(
            '($reviewCount)',
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
        if (label != null) ...[
          Gap(8.w),
          Text(
            label!,
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Feedback form widget
class FeedbackForm extends StatefulWidget {
  final String? title;
  final String? description;
  final bool includeRating;
  final bool includePhotos;
  final Function(FeedbackData)? onSubmit;
  final VoidCallback? onCancel;

  const FeedbackForm({
    super.key,
    this.title,
    this.description,
    this.includeRating = true,
    this.includePhotos = false,
    this.onSubmit,
    this.onCancel,
  });

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0.0;
  final List<String> _photoUrls = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: AppTypography.headlineSmall,
            ),
            Gap(8.h),
          ],
          if (widget.description != null) ...[
            Text(
              widget.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
            Gap(16.h),
          ],
          if (widget.includeRating) ...[
            Text(
              'Rating',
              style: AppTypography.titleMedium,
            ),
            Gap(8.h),
            StarRating(
              rating: _rating,
              size: 32.w,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            Gap(16.h),
          ],
          AppTextField(
            controller: _commentController,
            labelText: 'Comments',
            hintText: 'Share your experience...',
            maxLines: 4,
            validator: (value) {
              if (widget.includeRating && _rating == 0.0) {
                return 'Please provide a rating';
              }
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your comments';
              }
              return null;
            },
          ),
          if (widget.includePhotos) ...[
            Gap(16.h),
            _buildPhotoSection(),
          ],
          Gap(24.h),
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: AppOutlinedButton(
                    text: 'Cancel',
                    onPressed: widget.onCancel,
                  ),
                ),
                Gap(12.w),
              ],
              Expanded(
                child: AppFilledButton(
                  text: 'Submit Feedback',
                  onPressed: _submitFeedback,
                  isLoading: _isSubmitting,
                  icon: const Icon(Icons.send),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (Optional)',
          style: AppTypography.titleMedium,
        ),
        Gap(8.h),
        if (_photoUrls.isEmpty) ...[
          AppOutlinedButton(
            text: 'Add Photos',
            onPressed: _addPhotos,
            icon: const Icon(Icons.add_a_photo),
          ),
        ] else ...[
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              ..._photoUrls.map((url) => _buildPhotoThumbnail(url)),
              if (_photoUrls.length < 5)
                _buildAddPhotoButton(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoThumbnail(String url) {
    return Stack(
      children: [
        Container(
          width: 80.w,
          height: 80.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4.h,
          right: 4.w,
          child: GestureDetector(
            onTap: () => _removePhoto(url),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _addPhotos,
      child: Container(
        width: 80.w,
        height: 80.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: ColorsManager.outline,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.add_a_photo,
          color: ColorsManager.onSurfaceVariant,
          size: 24.w,
        ),
      ),
    );
  }

  void _addPhotos() {
    // TODO: Implement photo picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo picker functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removePhoto(String url) {
    setState(() {
      _photoUrls.remove(url);
    });
  }

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedbackData = FeedbackData(
        rating: widget.includeRating ? _rating : null,
        comment: _commentController.text.trim(),
        photoUrls: widget.includePhotos ? _photoUrls : null,
        timestamp: DateTime.now(),
      );

      await widget.onSubmit?.call(feedbackData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: ColorsManager.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: $e'),
            backgroundColor: ColorsManager.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

/// Feedback data model
class FeedbackData {
  final double? rating;
  final String comment;
  final List<String>? photoUrls;
  final DateTime timestamp;

  const FeedbackData({
    this.rating,
    required this.comment,
    this.photoUrls,
    required this.timestamp,
  });
}

/// Quick feedback buttons
class QuickFeedback extends StatelessWidget {
  final Function(String)? onFeedback;

  const QuickFeedback({
    super.key,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your experience?',
            style: AppTypography.titleMedium,
          ),
          Gap(12.h),
          Row(
            children: [
              _buildQuickFeedbackButton(
                context,
                '😊',
                'Great',
                ColorsManager.success,
              ),
              Gap(8.w),
              _buildQuickFeedbackButton(
                context,
                '😐',
                'Okay',
                ColorsManager.warning,
              ),
              Gap(8.w),
              _buildQuickFeedbackButton(
                context,
                '😞',
                'Poor',
                ColorsManager.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFeedbackButton(
    BuildContext context,
    String emoji,
    String label,
    Color color,
  ) {
    return Expanded(
      child: AppOutlinedButton(
        text: '$emoji $label',
        onPressed: () => onFeedback?.call(label),
        variant: ButtonVariant.primary,
      ),
    );
  }
}
