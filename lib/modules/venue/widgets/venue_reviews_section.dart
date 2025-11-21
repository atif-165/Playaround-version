import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../models/venue_model.dart';
import '../../../routing/routes.dart';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: StreamBuilder<List<VenueReview>>(
        stream: _venueService.getVenueReviews(widget.venueId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CustomProgressIndicator(),
            );
          }

          final reviews = snapshot.data ?? [];
          return _buildReviewsContent(reviews);
        },
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
    if (!_canAddReview()) {
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

  Widget _buildReviewsContent(List<VenueReview> reviews) {
    final reviewCount =
        reviews.isNotEmpty ? reviews.length : widget.venue.totalReviews;
    final averageRating = reviews.isNotEmpty
        ? reviews.fold<double>(
                0, (sum, review) => sum + (review.rating)) /
            reviews.length
        : widget.venue.averageRating;
    final canAddReview = _canAddReview();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF181536).withOpacity(0.92),
            const Color(0xFF0F0D28).withOpacity(0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewsHeader(averageRating, reviewCount),
          Gap(18.h),
          if (canAddReview) _buildAddReviewCallout(),
          if (reviews.isEmpty)
            _buildEmptyState()
          else
            ...reviews.map(_buildReviewCard),
        ],
      ),
    );
  }

  Widget _buildReviewsHeader(double averageRating, int reviewCount) {
    final displayRating =
        averageRating > 0 ? averageRating.toStringAsFixed(1) : '—';
    final canAddReview = _canAddReview();

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                color: const Color(0xFFFFC56F),
                size: 22.sp,
              ),
              Gap(8.w),
              Text(
                displayRating,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
        Gap(14.w),
        Expanded(
          child: Text(
            reviewCount > 0
                ? '$reviewCount experience${reviewCount == 1 ? '' : 's'} shared'
                : 'No reviews yet. Be the first to review!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (canAddReview) _buildAddReviewButton(),
      ],
    );
  }

  Widget _buildAddReviewCallout() {
    final venueName = widget.venue.title;

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
                  'Help other players know what it\'s like to book $venueName.',
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
            onPressed: _showAddReviewDialog,
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

  Widget _buildReviewCard(VenueReview review) {
    final ratingLabel = review.rating.toStringAsFixed(1);
    final primaryHighlight = 'Rated $ratingLabel / 5';

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        color: const Color(0xFF14112D).withOpacity(0.9),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
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
              ),
              Gap(12.w),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openPublicProfile(review.userId),
                  child: Text(
                    review.userName,
                    style: TextStyle(
                      color: ColorsManager.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            primaryHighlight,
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
              color: Colors.white.withOpacity(0.75),
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Be the first to share your experience with ${widget.venue.title}.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13.sp,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.red.withOpacity(0.12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 20.sp,
          ),
          Gap(12.w),
          Expanded(
            child: Text(
              'We couldn\'t load the reviews right now. Please try again later.',
              style: TextStyle(
                color: Colors.redAccent.withOpacity(0.8),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canAddReview() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.uid != widget.venue.ownerId;
  }

  void _openPublicProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.of(context).pushNamed(
      Routes.communityUserProfile,
      arguments: userId,
    );
  }
}
