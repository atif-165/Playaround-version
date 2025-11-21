import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';

/// Widget for tournament review and rating system
class TournamentReviewSystem extends StatefulWidget {
  final Tournament tournament;
  final Function(TournamentReview)? onReviewSubmitted;

  const TournamentReviewSystem({
    super.key,
    required this.tournament,
    this.onReviewSubmitted,
  });

  @override
  State<TournamentReviewSystem> createState() => _TournamentReviewSystemState();
}

class _TournamentReviewSystemState extends State<TournamentReviewSystem> {
  final TextEditingController _reviewController = TextEditingController();

  List<TournamentReview> _reviews = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  UserProfile? _currentUserProfile;

  // Review form state
  int _overallRating = 0;
  int _organizationRating = 0;
  int _communicationRating = 0;
  int _fairnessRating = 0;
  int _valueRating = 0;
  String _reviewText = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load reviews from service
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _reviews = [
          // Mock reviews
          TournamentReview(
            id: '1',
            tournamentId: widget.tournament.id,
            userId: 'user1',
            userName: 'John Doe',
            userImageUrl: null,
            overallRating: 5,
            organizationRating: 5,
            communicationRating: 4,
            fairnessRating: 5,
            valueRating: 4,
            reviewText:
                'Excellent tournament! Well organized and fair play throughout.',
            isRecommended: true,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          TournamentReview(
            id: '2',
            tournamentId: widget.tournament.id,
            userId: 'user2',
            userName: 'Sarah Wilson',
            userImageUrl: null,
            overallRating: 4,
            organizationRating: 4,
            communicationRating: 5,
            fairnessRating: 4,
            valueRating: 3,
            reviewText:
                'Good tournament overall, but could improve on prize distribution.',
            isRecommended: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildReviewHeader(),
        Gap(16.h),
        _buildReviewForm(),
        Gap(24.h),
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildReviewHeader() {
    final averageRating = _calculateAverageRating();
    final totalReviews = _reviews.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tournament Reviews',
                style: TextStyles.font18DarkBlueBold,
              ),
              Gap(4.h),
              Row(
                children: [
                  _buildStarRating(averageRating, 20.sp),
                  Gap(8.w),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyles.font16DarkBlueBold.copyWith(
                      color: ColorsManager.primary,
                    ),
                  ),
                  Gap(4.w),
                  Text(
                    '($totalReviews reviews)',
                    style: TextStyles.font14Grey400Weight.copyWith(
                      color: ColorsManager.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _buildRatingBreakdown(),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildRatingBar(
            'Organization', _calculateCategoryAverage('organization')),
        _buildRatingBar(
            'Communication', _calculateCategoryAverage('communication')),
        _buildRatingBar('Fairness', _calculateCategoryAverage('fairness')),
        _buildRatingBar('Value', _calculateCategoryAverage('value')),
      ],
    );
  }

  Widget _buildRatingBar(String label, double rating) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60.w,
            child: Text(
              label,
              style: TextStyles.font12Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
          ),
          Gap(8.w),
          _buildStarRating(rating, 12.sp),
          Gap(4.w),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyles.font12Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write a Review',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(16.h),
          _buildRatingSection('Overall Experience', _overallRating, (rating) {
            setState(() {
              _overallRating = rating;
            });
          }),
          Gap(12.h),
          _buildRatingSection('Organization', _organizationRating, (rating) {
            setState(() {
              _organizationRating = rating;
            });
          }),
          Gap(12.h),
          _buildRatingSection('Communication', _communicationRating, (rating) {
            setState(() {
              _communicationRating = rating;
            });
          }),
          Gap(12.h),
          _buildRatingSection('Fairness', _fairnessRating, (rating) {
            setState(() {
              _fairnessRating = rating;
            });
          }),
          Gap(12.h),
          _buildRatingSection('Value for Money', _valueRating, (rating) {
            setState(() {
              _valueRating = rating;
            });
          }),
          Gap(16.h),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Your Review',
              hintText: 'Share your experience with this tournament...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _reviewText = value;
              });
            },
          ),
          Gap(16.h),
          Row(
            children: [
              Checkbox(
                value: _isRecommended(),
                onChanged: (value) {
                  setState(() {});
                },
                activeColor: ColorsManager.primary,
              ),
              Expanded(
                child: Text(
                  'I would recommend this tournament to others',
                  style: TextStyles.font14DarkBlueMedium,
                ),
              ),
            ],
          ),
          Gap(16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmitReview() ? _submitReview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
      String label, int rating, Function(int) onRatingChanged) {
    return Row(
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: TextStyles.font14DarkBlueMedium,
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber[600],
                  size: 20.sp,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return _buildEmptyReviews();
    }

    return Column(
      children: _reviews.map((review) => _buildReviewCard(review)).toList(),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48.sp,
            color: ColorsManager.textSecondary,
          ),
          Gap(16.h),
          Text(
            'No Reviews Yet',
            style: TextStyles.font16DarkBlueBold.copyWith(
              color: ColorsManager.textPrimary,
            ),
          ),
          Gap(8.h),
          Text(
            'Be the first to share your experience!',
            style: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(TournamentReview review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundImage: review.userImageUrl != null
                    ? NetworkImage(review.userImageUrl!)
                    : null,
                child: review.userImageUrl == null
                    ? Icon(
                        Icons.person,
                        size: 16.sp,
                        color: ColorsManager.primary,
                      )
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyles.font14DarkBlueMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        _buildStarRating(
                            review.overallRating.toDouble(), 14.sp),
                        Gap(8.w),
                        Text(
                          '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                          style: TextStyles.font12Grey400Weight.copyWith(
                            color: ColorsManager.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (review.isRecommended)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorsManager.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Recommended',
                    style: TextStyles.font10Grey400Weight.copyWith(
                      color: ColorsManager.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Gap(12.h),
          Text(
            review.reviewText,
            style: TextStyles.font14DarkBlueMedium,
          ),
          Gap(12.h),
          _buildReviewBreakdown(review),
        ],
      ),
    );
  }

  Widget _buildReviewBreakdown(TournamentReview review) {
    return Column(
      children: [
        _buildBreakdownRow('Organization', review.organizationRating),
        _buildBreakdownRow('Communication', review.communicationRating),
        _buildBreakdownRow('Fairness', review.fairnessRating),
        _buildBreakdownRow('Value', review.valueRating),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, int rating) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyles.font12Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
          ),
          _buildStarRating(rating.toDouble(), 12.sp),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          color: Colors.amber[600],
          size: size,
        );
      }),
    );
  }

  double _calculateAverageRating() {
    if (_reviews.isEmpty) return 0.0;
    final total =
        _reviews.fold(0.0, (sum, review) => sum + review.overallRating);
    return total / _reviews.length;
  }

  double _calculateCategoryAverage(String category) {
    if (_reviews.isEmpty) return 0.0;

    double total = 0.0;
    for (final review in _reviews) {
      switch (category) {
        case 'organization':
          total += review.organizationRating;
          break;
        case 'communication':
          total += review.communicationRating;
          break;
        case 'fairness':
          total += review.fairnessRating;
          break;
        case 'value':
          total += review.valueRating;
          break;
      }
    }
    return total / _reviews.length;
  }

  bool _isRecommended() {
    return _overallRating >= 4;
  }

  bool _canSubmitReview() {
    return _overallRating > 0 &&
        _organizationRating > 0 &&
        _communicationRating > 0 &&
        _fairnessRating > 0 &&
        _valueRating > 0 &&
        _reviewText.trim().isNotEmpty &&
        !_isSubmitting;
  }

  Future<void> _submitReview() async {
    if (!_canSubmitReview()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Submit review to service
      await Future.delayed(const Duration(seconds: 1));

      final newReview = TournamentReview(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tournamentId: widget.tournament.id,
        userId: _currentUserProfile?.uid ?? 'anonymous',
        userName: _currentUserProfile?.displayName ?? 'Anonymous',
        userImageUrl: _currentUserProfile?.photoURL,
        overallRating: _overallRating,
        organizationRating: _organizationRating,
        communicationRating: _communicationRating,
        fairnessRating: _fairnessRating,
        valueRating: _valueRating,
        reviewText: _reviewText.trim(),
        isRecommended: _isRecommended(),
        createdAt: DateTime.now(),
      );

      setState(() {
        _reviews.insert(0, newReview);
        _resetForm();
      });

      widget.onReviewSubmitted?.call(newReview);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: ColorsManager.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: ${e.toString()}'),
            backgroundColor: ColorsManager.error,
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

  void _resetForm() {
    _overallRating = 0;
    _organizationRating = 0;
    _communicationRating = 0;
    _fairnessRating = 0;
    _valueRating = 0;
    _reviewText = '';
    _reviewController.clear();
  }
}

/// Tournament review model
class TournamentReview {
  final String id;
  final String tournamentId;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final int overallRating;
  final int organizationRating;
  final int communicationRating;
  final int fairnessRating;
  final int valueRating;
  final String reviewText;
  final bool isRecommended;
  final DateTime createdAt;

  const TournamentReview({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.overallRating,
    required this.organizationRating,
    required this.communicationRating,
    required this.fairnessRating,
    required this.valueRating,
    required this.reviewText,
    required this.isRecommended,
    required this.createdAt,
  });
}
