import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../models/venue_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/venue_service.dart';
import '../widgets/add_review_dialog.dart';

/// Widget for displaying venue reviews
class VenueReviewsSection extends StatefulWidget {
  final String venueId;
  final VenueModel venue;

  const VenueReviewsSection({
    super.key,
    required this.venueId,
    required this.venue,
  });

  @override
  State<VenueReviewsSection> createState() => _VenueReviewsSectionState();
}

class _VenueReviewsSectionState extends State<VenueReviewsSection> {
  final VenueService _venueService = VenueService();
  bool _showAllReviews = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews',
                style: TextStyles.font16DarkBlueBold,
              ),
              _buildAddReviewButton(),
            ],
          ),
          Gap(12.h),
          StreamBuilder<List<VenueReview>>(
            stream: _venueService.getVenueReviews(widget.venueId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CustomProgressIndicator());
              }

              if (snapshot.hasError) {
                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 16.sp,
                      ),
                      Gap(8.w),
                      Expanded(
                        child: Text(
                          'Failed to load reviews',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 16.sp,
                        color: Colors.grey[600],
                      ),
                      Gap(8.w),
                      Text(
                        'No reviews yet. Be the first to review!',
                        style: TextStyles.font12Grey400Weight,
                      ),
                    ],
                  ),
                );
              }

              final displayedReviews = _showAllReviews 
                  ? reviews 
                  : reviews.take(3).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...displayedReviews.map((review) => _buildReviewItem(review)),
                  if (reviews.length > 3) _buildShowMoreButton(reviews.length),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(VenueReview review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.1),
                backgroundImage: (review.userProfilePicture != null && review.userProfilePicture!.isNotEmpty)
                    ? NetworkImage(review.userProfilePicture!)
                    : null,
                child: (review.userProfilePicture == null || review.userProfilePicture!.isEmpty)
                    ? Text(
                        review.userName.isNotEmpty 
                            ? review.userName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: ColorsManager.mainBlue,
                        ),
                      )
                    : null,
              ),
              Gap(8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyles.font12DarkBlue600Weight,
                    ),
                    Gap(2.h),
                    Row(
                      children: [
                        _buildStarRating(review.rating),
                        Gap(8.w),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyles.font10Grey400Weight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(8.h),
          Text(
            review.comment,
            style: TextStyles.font12Grey400Weight,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          size: 12.sp,
          color: Colors.amber,
        );
      }),
    );
  }

  Widget _buildShowMoreButton(int totalReviews) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllReviews = !_showAllReviews;
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: ColorsManager.mainBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: ColorsManager.mainBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showAllReviews 
                  ? 'Show Less'
                  : 'Show All Reviews ($totalReviews)',
              style: TextStyles.font12MainBlue500Weight,
            ),
            Gap(4.w),
            Icon(
              _showAllReviews 
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 16.sp,
              color: ColorsManager.mainBlue,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildAddReviewButton() {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Don't show button if user is not logged in
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Don't show button if user is the venue owner
    if (currentUser.uid == widget.venue.ownerId) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () => _showAddReviewDialog(),
      icon: Icon(
        Icons.rate_review,
        size: 16.sp,
        color: Colors.white,
      ),
      label: Text(
        'Add Review',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        elevation: 2,
      ),
    );
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        venue: widget.venue,
        onReviewAdded: () {
          // Refresh the reviews by rebuilding the widget
          setState(() {});
        },
      ),
    );
  }
}
