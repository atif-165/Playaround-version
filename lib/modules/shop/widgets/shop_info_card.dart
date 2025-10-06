import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../models/shop.dart';

class ShopInfoCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;

  const ShopInfoCard({
    super.key,
    required this.shop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorsManager.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: ColorsManager.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            _buildShopImage(),
            Gap(12.w),
            Expanded(
              child: _buildShopDetails(),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.w,
              color: ColorsManager.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopImage() {
    return Container(
      width: 60.w,
      height: 60.h,
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: shop.images.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                shop.images.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.storefront,
                    size: 24.w,
                    color: ColorsManager.onSurfaceVariant,
                  );
                },
              ),
            )
          : Icon(
              Icons.storefront,
              size: 24.w,
              color: ColorsManager.onSurfaceVariant,
            ),
    );
  }

  Widget _buildShopDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shop.name,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (shop.isVerified) ...[
              Gap(4.w),
              Icon(
                Icons.verified,
                size: 16.w,
                color: ColorsManager.primary,
              ),
            ],
          ],
        ),
        Gap(4.h),
        Text(
          shop.description,
          style: AppTypography.bodySmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Gap(8.h),
        Row(
          children: [
            Icon(
              Icons.star,
              size: 14.w,
              color: ColorsManager.primary,
            ),
            Gap(4.w),
            Text(
              shop.rating.toStringAsFixed(1),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8.w),
            Text(
              '(${shop.reviewCount} reviews)',
              style: AppTypography.bodySmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Gap(4.h),
        Row(
          children: [
            Icon(
              shop.isLocal ? Icons.location_on : Icons.language,
              size: 14.w,
              color: ColorsManager.onSurfaceVariant,
            ),
            Gap(4.w),
            Expanded(
              child: Text(
                shop.isLocal ? shop.city : 'Online Store',
                style: AppTypography.bodySmall.copyWith(
                  color: ColorsManager.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
