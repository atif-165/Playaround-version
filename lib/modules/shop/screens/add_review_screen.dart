import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../models/location_review.dart';
import '../services/location_review_service.dart';

class AddReviewScreen extends StatefulWidget {
  final String locationId;
  final String locationName;

  const AddReviewScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewService = LocationReviewService();

  final _commentController = TextEditingController();
  double _rating = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final review = LocationReview(
        id: '', // Will be set by Firestore
        locationId: widget.locationId,
        userId: _reviewService.currentUserId,
        userName: 'Current User', // TODO: Get from user service
        userProfileImage: '', // TODO: Get from user service
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        images: [],
        isVerified: false,
      );

      await _reviewService.addReview(review);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review added successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      appBar: AppBar(
        backgroundColor: ColorsManager.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Add Review',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(2.w, 30.h, 1.w, 5.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationInfo(),
              Gap(32.h),
              _buildRatingSection(),
              Gap(24.h),
              _buildCommentSection(),
              Gap(32.h),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviewing',
            style: AppTypography.labelMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          Gap(8.h),
          Text(
            widget.locationName,
            style: AppTypography.headlineSmall.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating *',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(16.h),
          Row(
            children: [
              ...List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = (index + 1).toDouble();
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: ColorsManager.warning,
                      size: 24.w,
                    ),
                  ),
                );
              }),
              Gap(8.w),
              Expanded(
                child: Text(
                  _rating > 0 ? _rating.toStringAsFixed(1) : 'Select rating',
                  style: AppTypography.bodyMedium.copyWith(
                    color: ColorsManager.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Review',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(16.h),
          AppTextField(
            controller: _commentController,
            labelText: 'Write your review',
            hintText: 'Share your experience with this location...',
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please write a review';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AppFilledButton(
        text: _isLoading ? 'Adding Review...' : 'Submit Review',
        onPressed: _isLoading ? null : _submitReview,
        icon: _isLoading ? null : const Icon(Icons.send),
      ),
    );
  }
}
