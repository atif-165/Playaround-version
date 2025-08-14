import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:gap/gap.dart';

import '../../../core/utils/image_utils.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../models/dashboard_models.dart';

/// Shop product card widget for displaying recommended products
class ShopProductCard extends StatelessWidget {
  final ShopProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const ShopProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200.w,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(),
            _buildProductInfo(),
            _buildProductActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
          child: SizedBox(
            height: 120.h,
            width: double.infinity,
            child: ImageUtils.buildSafeCachedImage(
              imageUrl: product.imageUrl,
              width: double.infinity,
              height: 120.h,
              fit: BoxFit.cover,
              fallbackIcon: Icons.shopping_bag,
              fallbackIconColor: ColorsManager.onSurfaceVariant,
              fallbackIconSize: 32.sp,
              backgroundColor: ColorsManager.surfaceVariant,
            ),
          ),
        ),
        if (product.isOnSale)
          Positioned(
            top: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6.w,
                vertical: 3.h,
              ),
              decoration: BoxDecoration(
                color: ColorsManager.error,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '${product.discountPercentage.toInt()}% OFF',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (product.isRecommended)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(
                color: ColorsManager.success,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: 12.sp,
              ),
            ),
          ),
        Positioned(
          top: 8.h,
          right: product.isRecommended ? 40.w : 8.w,
          child: GestureDetector(
            onTap: onFavorite,
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? ColorsManager.error : ColorsManager.onSurfaceVariant,
                size: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: AppTypography.titleSmall.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Gap(4.h),
          Text(
            product.category,
            style: AppTypography.labelSmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          Gap(8.h),
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 14.sp,
              ),
              Gap(2.w),
              Text(
                '${product.rating}',
                style: AppTypography.bodySmall.copyWith(
                  color: ColorsManager.onSurfaceVariant,
                ),
              ),
              Gap(4.w),
              Text(
                '(${product.reviewCount})',
                style: AppTypography.bodySmall.copyWith(
                  color: ColorsManager.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Text(
                product.priceText,
                style: AppTypography.titleMedium.copyWith(
                  color: ColorsManager.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (product.hasDiscount) ...[
                Gap(6.w),
                Text(
                  product.originalPriceText,
                  style: AppTypography.bodySmall.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductActions() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.w),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onAddToCart,
          icon: Icon(
            Icons.add_shopping_cart,
            size: 16.sp,
          ),
          label: Text(
            'Add to Cart',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: ColorsManager.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 8.h),
          ),
        ),
      ),
    );
  }
}

/// Compact product card for grid layouts
class CompactProductCard extends StatelessWidget {
  final ShopProduct product;
  final VoidCallback? onTap;

  const CompactProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ImageUtils.buildSafeCachedImage(
                        imageUrl: product.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.shopping_bag,
                        fallbackIconColor: ColorsManager.onSurfaceVariant,
                        fallbackIconSize: 24.sp,
                        backgroundColor: ColorsManager.surfaceVariant,
                      ),
                    ),
                  ),
                  if (product.isOnSale)
                    Positioned(
                      top: 6.h,
                      left: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: ColorsManager.error,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '${product.discountPercentage.toInt()}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.labelMedium.copyWith(
                        color: ColorsManager.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 12.sp,
                        ),
                        Gap(2.w),
                        Text(
                          '${product.rating}',
                          style: AppTypography.labelSmall.copyWith(
                            color: ColorsManager.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          product.priceText,
                          style: AppTypography.labelMedium.copyWith(
                            color: ColorsManager.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
