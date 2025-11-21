import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../data/models/listing_model.dart' as data;
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  final data.ListingModel listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              Gap(12.h),
              Text(
                listing.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.font14Grey400Weight,
              ),
              Gap(12.h),
              _infoRow(),
              Gap(12.h),
              _tags(),
              Gap(16.h),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: ColorsManager.mainBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            listing.category.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: ColorsManager.mainBlue,
            ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(4.h),
              Text(
                listing.providerName,
                style: TextStyles.font12Grey400Weight,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          '\$${listing.basePrice.toStringAsFixed(0)}',
          style: TextStyles.font16DarkBlueBold,
        ),
      ],
    );
  }

  Widget _infoRow() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.sports, color: ColorsManager.mainBlue, size: 18),
              Gap(6.w),
              Expanded(
                child: Text(
                  listing.sport,
                  style: TextStyles.font12BlueRegular,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.people_outline,
                  color: ColorsManager.mainBlue, size: 18),
              Gap(6.w),
              Expanded(
                child: Text(
                  '${listing.capacity} capacity',
                  style: TextStyles.font12BlueRegular,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tags() {
    final tags = listing.tags;
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8.w,
      runSpacing: 4.h,
      children: tags.take(3).map((tag) {
        return Chip(
          label: Text(tag),
          backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.08),
          labelStyle: TextStyle(
            fontSize: 10.sp,
            color: ColorsManager.mainBlue,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            Gap(4.w),
            Text(
              listing.rating.toStringAsFixed(1),
              style: TextStyles.font14DarkBlueBold,
            ),
            Gap(4.w),
            Text(
              '(${listing.reviewCount})',
              style: TextStyles.font12Grey400Weight,
            ),
          ],
        ),
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
}
