import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../models/review.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onHelpful;

  const ReviewCard({
    super.key,
    required this.review,
    required this.onHelpful,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Gap(12.h),
          _buildRating(),
          Gap(12.h),
          _buildComment(),
          if (review.images.isNotEmpty) ...[
            Gap(12.h),
            _buildReviewImages(),
          ],
          Gap(12.h),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20.w,
          backgroundImage: review.userImage.isNotEmpty
              ? NetworkImage(review.userImage)
              : null,
          child: review.userImage.isEmpty
              ? Icon(
                  Icons.person,
                  size: 20.w,
                  color: ColorsManager.onSurfaceVariant,
                )
              : null,
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    review.userName,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (review.isVerified) ...[
                    Gap(4.w),
                    Icon(
                      Icons.verified,
                      size: 16.w,
                      color: ColorsManager.primary,
                    ),
                  ],
                ],
              ),
              Text(
                _formatDate(review.createdAt),
                style: AppTypography.bodySmall.copyWith(
                  color: ColorsManager.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < review.rating ? Icons.star : Icons.star_border,
          size: 16.w,
          color: ColorsManager.primary,
        );
      }),
    );
  }

  Widget _buildComment() {
    return Text(
      review.comment,
      style: AppTypography.bodyMedium,
    );
  }

  Widget _buildReviewImages() {
    return SizedBox(
      height: 80.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: review.images.length,
        itemBuilder: (context, index) {
          return Container(
            width: 80.w,
            height: 80.h,
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: ColorsManager.surfaceVariant,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                review.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image,
                    color: ColorsManager.onSurfaceVariant,
                    size: 32.w,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        AppTextButton(
          text: 'Helpful (${review.helpfulCount})',
          onPressed: onHelpful,
          icon: Icon(
            Icons.thumb_up_outlined,
            size: 16.w,
          ),
        ),
        const Spacer(),
        if (review.isVerified)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ColorsManager.primaryContainer,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Verified Purchase',
              style: AppTypography.labelSmall.copyWith(
                color: ColorsManager.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}
