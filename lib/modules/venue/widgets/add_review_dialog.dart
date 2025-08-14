import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/venue_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../services/venue_service.dart';

/// Dialog for adding a venue review
class AddReviewDialog extends StatefulWidget {
  final VenueModel venue;
  final VoidCallback onReviewAdded;

  const AddReviewDialog({
    super.key,
    required this.venue,
    required this.onReviewAdded,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final VenueService _venueService = VenueService();

  double _rating = 5.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {}); // Update character counter
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        constraints: BoxConstraints(
          maxWidth: 400.w,
          maxHeight: 600.h,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Gap(20.h),
              _buildVenueInfo(),
              Gap(20.h),
              _buildRatingSection(),
              Gap(20.h),
              _buildCommentSection(),
              Gap(24.h),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.rate_review,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
        Gap(8.w),
        Expanded(
          child: Text(
            'Add Review',
            style: TextStyles.font18DarkBlueBold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            size: 20.sp,
            color: Colors.grey[600],
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildVenueInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.location_on,
              color: ColorsManager.primary,
              size: 20.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.venue.title,
                  style: TextStyles.font14DarkBlue600Weight,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(2.h),
                Text(
                  widget.venue.location,
                  style: TextStyles.font12Grey400Weight,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating *',
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        Row(
          children: [
            Expanded(
              child: Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = (index + 1).toDouble();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(
                        index < _rating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        size: 32.sp,
                        color: Colors.amber,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Gap(12.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                '${_rating.toInt()}/5',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.primary,
                ),
              ),
            ),
          ],
        ),
        Gap(8.h),
        Text(
          _getRatingDescription(_rating),
          style: TextStyles.font12Grey400Weight,
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comment *',
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        AppTextField(
          controller: _commentController,
          hintText: 'Share your experience with this venue...',
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your review comment';
            }
            if (value.trim().length < 10) {
              return 'Comment must be at least 10 characters';
            }
            if (value.trim().length > 500) {
              return 'Comment must be less than 500 characters';
            }
            return null;
          },
        ),
        Gap(4.h),
        Text(
          '${_commentController.text.length}/500 characters',
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppOutlinedButton(
            text: 'Cancel',
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            size: ButtonSize.medium,
            variant: ButtonVariant.secondary,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: AppFilledButton(
            text: 'Submit Review',
            onPressed: _isLoading ? null : _submitReview,
            isLoading: _isLoading,
            size: ButtonSize.medium,
            variant: ButtonVariant.primary,
            icon: const Icon(Icons.send, size: 16),
          ),
        ),
      ],
    );
  }

  String _getRatingDescription(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor - Not recommended';
      case 2:
        return 'Fair - Below expectations';
      case 3:
        return 'Good - Meets expectations';
      case 4:
        return 'Very Good - Above expectations';
      case 5:
        return 'Excellent - Highly recommended';
      default:
        return 'Select a rating';
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _venueService.addVenueReview(
        venueId: widget.venue.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review submitted successfully!'),
            backgroundColor: ColorsManager.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: ${e.toString()}'),
            backgroundColor: ColorsManager.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
