import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/listing_model.dart';
import '../../../models/rating_model.dart';
import '../../../services/rating_service.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../rating/widgets/star_rating_input.dart';

/// Card widget for displaying listing information with real-time ratings
class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final bool showRealTimeRatings;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.showRealTimeRatings = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Gap(12.h),
              _buildDescription(),
              Gap(12.h),
              _buildDetails(),
              Gap(12.h),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Profile picture or sport icon
        Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: ColorsManager.mainBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: listing.ownerProfilePicture != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(25.r),
                  child: CachedNetworkImage(
                    imageUrl: listing.ownerProfilePicture!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      _getSportIcon(),
                      color: ColorsManager.mainBlue,
                      size: 24.sp,
                    ),
                  ),
                )
              : Icon(
                  _getSportIcon(),
                  color: ColorsManager.mainBlue,
                  size: 24.sp,
                ),
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.title,
                style: TextStyles.font16DarkBlueBold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(4.h),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14.sp,
                    color: Colors.grey[600],
                  ),
                  Gap(4.w),
                  Expanded(
                    child: Text(
                      listing.ownerName,
                      style: TextStyles.font12Grey400Weight,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildTypeChip(),
      ],
    );
  }

  Widget _buildTypeChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: listing.type == ListingType.coach
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        listing.type == ListingType.coach ? 'Coach' : 'Venue',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: listing.type == ListingType.coach
              ? Colors.green[700]
              : Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      listing.description,
      style: TextStyles.font14Grey400Weight,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            icon: Icons.sports,
            text: listing.sportType.displayName,
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            icon: Icons.location_on,
            text: listing.location,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: ColorsManager.mainBlue,
        ),
        Gap(4.w),
        Expanded(
          child: Text(
            text,
            style: TextStyles.font12BlueRegular,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${listing.hourlyRate.toStringAsFixed(0)}/hour',
                style: TextStyles.font16DarkBlueBold,
                overflow: TextOverflow.ellipsis,
              ),
              if (showRealTimeRatings)
                _buildRealTimeRating()
              else if (listing.averageRating > 0) ...[
                Gap(2.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 14.sp,
                      color: Colors.amber,
                    ),
                    Gap(2.w),
                    Flexible(
                      child: Text(
                        '${listing.averageRating.toStringAsFixed(1)} (${listing.totalBookings})',
                        style: TextStyles.font12Grey400Weight,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Gap(8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ColorsManager.mainBlue,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'Book Now',
            style: TextStyles.font12WhiteMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildRealTimeRating() {
    final ratingType = listing.type == ListingType.coach
        ? RatingType.coach
        : RatingType.venue;

    final entityId = listing.type == ListingType.coach
        ? listing.ownerId
        : listing.id;

    return StreamBuilder<RatingStats>(
      stream: RatingService().getRatingStatsStream(entityId, ratingType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Gap(2.h);
        }

        final stats = snapshot.data;
        if (stats == null || stats.totalRatings == 0) {
          return Gap(2.h);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(2.h),
            RatingSummary(
              averageRating: stats.averageRating,
              totalRatings: stats.totalRatings,
              starSize: 14,
              textStyle: TextStyles.font12Grey400Weight,
            ),
          ],
        );
      },
    );
  }

  IconData _getSportIcon() {
    switch (listing.sportType) {
      case SportType.cricket:
        return Icons.sports_cricket;
      case SportType.football:
        return Icons.sports_soccer;
      case SportType.basketball:
        return Icons.sports_basketball;
      case SportType.tennis:
        return Icons.sports_tennis;
      case SportType.badminton:
        return Icons.sports_tennis;
      case SportType.volleyball:
        return Icons.sports_volleyball;
      case SportType.swimming:
        return Icons.pool;
      case SportType.running:
        return Icons.directions_run;
      case SportType.cycling:
        return Icons.directions_bike;
      case SportType.other:
        return Icons.sports;
    }
  }
}
