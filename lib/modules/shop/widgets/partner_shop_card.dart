import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../models/shop.dart';

class PartnerShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;
  final bool isListTile;

  const PartnerShopCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.isListTile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isListTile) {
      return _buildListTile();
    }
    return _buildCard();
  }

  Widget _buildCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200.w,
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.outline.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Gap(8.h),
                  _buildDescription(),
                  Gap(12.h),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.outline.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              _buildImage(isListTile: true),
              Gap(16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Gap(8.h),
                    _buildDescription(),
                    Gap(12.h),
                    _buildFooter(),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.w,
                color: ColorsManager.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage({bool isListTile = false}) {
    return Container(
      width: isListTile ? 80.w : double.infinity,
      height: isListTile ? 80.h : 120.h,
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(isListTile ? 12.r : 16.r),
      ),
      child: shop.images.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(isListTile ? 12.r : 16.r),
              child: Image.network(
                shop.images.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.storefront,
                    size: isListTile ? 32.w : 48.w,
                    color: ColorsManager.onSurfaceVariant,
                  );
                },
              ),
            )
          : Icon(
              Icons.storefront,
              size: isListTile ? 32.w : 48.w,
              color: ColorsManager.onSurfaceVariant,
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
    );
  }

  Widget _buildDescription() {
    return Text(
      shop.description,
      style: AppTypography.bodySmall.copyWith(
        color: ColorsManager.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star,
              size: 16.w,
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
              '(${shop.reviewCount})',
              style: AppTypography.bodySmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Gap(8.h),
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
        if (shop.categories.isNotEmpty) ...[
          Gap(8.h),
          Wrap(
            spacing: 4.w,
            runSpacing: 4.h,
            children: shop.categories.take(2).map((category) {
              return AppChip(
                label: category,
                variant: ChipVariant.assist,
                size: ChipSize.small,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
