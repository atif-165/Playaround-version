import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/venue_review.dart';
import '../../../routing/routes.dart';
import '../../../services/venue_service.dart';
import '../../../theming/colors.dart';

const _reviewsSectionGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF1B1938),
    Color(0xFF070614),
  ],
);

class VenueReviewsSection extends StatefulWidget {
  final List<VenueReview> reviews;
  final String venueId;
  final VoidCallback? onReviewAdded;
  final Gradient? backgroundGradient;

  const VenueReviewsSection({
    Key? key,
    required this.reviews,
    required this.venueId,
    this.onReviewAdded,
    this.backgroundGradient,
  }) : super(key: key);

  @override
  State<VenueReviewsSection> createState() => _VenueReviewsSectionState();
}

class _VenueReviewsSectionState extends State<VenueReviewsSection> {
  final Set<String> _likedReviewIds = <String>{};
  final Map<String, int> _localHelpfulCounts = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final reviews = widget.reviews;
    final canAddReview = _canAddReview();
    final gradient = widget.backgroundGradient ?? _reviewsSectionGradient;
    final children = <Widget>[];

    if (canAddReview) {
      children
        ..add(_buildAddReviewCallout())
        ..add(Gap(18.h));
    }

    if (reviews.isEmpty) {
      children.add(_buildEmptyStateContent());
    } else {
      for (var i = 0; i < reviews.length; i++) {
        children.add(_buildReviewCard(reviews[i]));
        if (i != reviews.length - 1) {
          children.add(Gap(18.h));
        }
      }
    }

    return SingleChildScrollView(
      primary: false,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withOpacity(0.18),
              blurRadius: 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildAddReviewCallout() {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary.withOpacity(0.25),
            ColorsManager.primary.withOpacity(0.12),
          ],
        ),
        border: Border.all(color: ColorsManager.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: Colors.white,
            size: 28.sp,
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your experience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(6.h),
                Text(
                  'Help fellow players understand what it\'s like to book this venue.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Gap(16.w),
          ElevatedButton(
            onPressed: _showWriteReviewDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ColorsManager.primary,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              'Review',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateContent() {
    final canAddReview = _canAddReview();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Gap(24.h),
        Icon(
          Icons.star_border_rounded,
          size: 64.sp,
          color: Colors.white.withOpacity(0.25),
        ),
        Gap(18.h),
        Text(
          'No reviews yet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(10.h),
        Text(
          'Be the first to share your experience with this venue.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 13.sp,
            height: 1.5,
          ),
        ),
        if (canAddReview) ...[
          Gap(22.h),
          ElevatedButton(
            onPressed: _showWriteReviewDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              'Write a Review',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(VenueReview review) {
    final ratingLabel = review.rating.toStringAsFixed(1);
    final displayTitle =
        review.title.isNotEmpty ? review.title : 'Rated $ratingLabel / 5';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 220.w;

        return Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            color: const Color(0xFF14112D).withOpacity(0.9),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact)
                _buildCompactHeader(
                  ratingLabel: ratingLabel,
                  review: review,
                )
              else
                _buildStandardHeader(
                  ratingLabel: ratingLabel,
                  review: review,
                ),
              Gap(12.h),
          Text(
            displayTitle,
            style: TextStyle(
              color: ColorsManager.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
          Gap(10.h),
          Text(
            review.comment,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          if (review.categories.isNotEmpty) ...[
            Gap(12.h),
            _buildCategoryChips(review),
          ],
          if (review.images.isNotEmpty) ...[
            Gap(12.h),
            SizedBox(
              height: 72.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => Gap(8.w),
                itemBuilder: (context, index) {
                  final imageUrl = review.images[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 80.w,
                      height: 72.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80.w,
                        height: 72.h,
                        alignment: Alignment.center,
                        color: Colors.white.withOpacity(0.08),
                        child: SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80.w,
                        height: 72.h,
                        color: Colors.white.withOpacity(0.08),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
        );
      },
    );
  }

  Widget _buildCategoryChips(VenueReview review) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      children: review.categories.map((category) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: ColorsManager.primary,
                size: 14.sp,
              ),
              Gap(6.w),
              Text(
                '${category.name} • ${category.rating.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _canAddReview() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null;
  }

  void _openPublicProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.of(context).pushNamed(
      Routes.communityUserProfile,
      arguments: userId,
    );
  }

  Widget _buildStandardHeader({
    required String ratingLabel,
    required VenueReview review,
  }) {
    return Row(
      children: [
        _buildRatingChip(ratingLabel),
        Gap(12.w),
        Expanded(child: _buildReviewerInfo(review)),
        Gap(8.w),
        _buildHelpfulControls(review),
      ],
    );
  }

  Widget _buildCompactHeader({
    required String ratingLabel,
    required VenueReview review,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingChip(ratingLabel),
            Gap(12.w),
            Expanded(child: _buildReviewerInfo(review)),
          ],
        ),
        Gap(10.h),
        _buildHelpfulControls(review),
      ],
    );
  }

  Widget _buildRatingChip(String ratingLabel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: const Color(0xFFFFC56F),
            size: 16.sp,
          ),
          Gap(4.w),
          Text(
            ratingLabel,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewerInfo(VenueReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openPublicProfile(review.userId),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  review.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorsManager.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (review.isVerified) ...[
                Gap(8.w),
                Icon(
                  Icons.verified,
                  color: Colors.blueAccent,
                  size: 16.sp,
                ),
              ],
            ],
          ),
        ),
        Gap(4.h),
        Text(
          _formatDate(review.createdAt),
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildHelpfulControls(VenueReview review) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _toggleHelpful(review),
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: _isReviewLiked(review)
                    ? ColorsManager.primary.withOpacity(0.6)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Icon(
              Icons.thumb_up_alt_rounded,
              size: 16.sp,
              color: _isReviewLiked(review)
                  ? ColorsManager.primary
                  : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        Gap(6.w),
        Text(
          '${_localHelpfulCounts[review.id] ?? review.helpfulCount}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  void _showWriteReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => _WriteReviewDialog(
        venueId: widget.venueId,
        onReviewAdded: () {
          widget.onReviewAdded?.call();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleHelpful(VenueReview review) {
    setState(() {
      final currentCount = _localHelpfulCounts.putIfAbsent(
        review.id,
        () => review.helpfulCount,
      );

      if (_isReviewLiked(review)) {
        _likedReviewIds.remove(review.id);
        _localHelpfulCounts[review.id] = (currentCount - 1).clamp(0, 9999);
      } else {
        _likedReviewIds.add(review.id);
        _localHelpfulCounts[review.id] = currentCount + 1;
      }
    });
  }

  bool _isReviewLiked(VenueReview review) {
    return _likedReviewIds.contains(review.id);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _WriteReviewDialog extends StatefulWidget {
  final String venueId;
  final VoidCallback onReviewAdded;

  const _WriteReviewDialog({
    required this.venueId,
    required this.onReviewAdded,
  });

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate() || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating and comment')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final review = VenueReview(
        id: '',
        venueId: widget.venueId,
        userId: 'current_user_id', // TODO: Get from auth service
        userName: 'Current User', // TODO: Get from user profile
        rating: _rating,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await VenueService.createReview(review);
      widget.onReviewAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write Review'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rating
              Text(
                'Rating',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: List.generate(5, (index) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 62,
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Comment
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Your Review *',
                  border: OutlineInputBorder(),
                  hintText: 'Share your experience...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write a review';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
