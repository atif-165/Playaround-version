import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../core/widgets/safe_cached_image.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool showShopName;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.showShopName = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  _buildPrice(),
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

  Widget _buildImage() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 160.h,
          decoration: BoxDecoration(
            color: ColorsManager.surfaceVariant,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: product.images.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                  child: SafeCachedImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    fallbackIcon: Icons.sports,
                    fallbackIconColor: ColorsManager.onSurfaceVariant,
                    backgroundColor: ColorsManager.surfaceVariant,
                  ),
                )
              : Icon(
                  Icons.sports,
                  size: 48.w,
                  color: ColorsManager.onSurfaceVariant,
                ),
        ),
        if (product.hasDiscount) _buildDiscountBadge(),
        if (product.isFeatured) _buildFeaturedBadge(),
        if (product.isExclusive) _buildExclusiveBadge(),
        Positioned(
          top: 8.h,
          right: 8.w,
          child: _buildWishlistButton(),
        ),
      ],
    );
  }

  Widget _buildDiscountBadge() {
    return Positioned(
      top: 8.h,
      left: 8.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: ColorsManager.error,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          '${product.discountPercentage.toStringAsFixed(0)}% OFF',
          style: AppTypography.labelSmall.copyWith(
            color: ColorsManager.onError,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Positioned(
      top: 8.h,
      left: product.hasDiscount ? 80.w : 8.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: ColorsManager.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          'Featured',
          style: AppTypography.labelSmall.copyWith(
            color: ColorsManager.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExclusiveBadge() {
    return Positioned(
      top: 8.h,
      left:
          (product.hasDiscount ? 80.w : 8.w) + (product.isFeatured ? 80.w : 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: ColorsManager.secondary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          'Exclusive',
          style: AppTypography.labelSmall.copyWith(
            color: ColorsManager.onSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {
          // TODO: Implement wishlist functionality
        },
        icon: Icon(
          Icons.favorite_border,
          size: 20.w,
          color: ColorsManager.onSurfaceVariant,
        ),
        padding: EdgeInsets.all(8.w),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (showShopName) ...[
          Gap(4.h),
          Text(
            product.shopName,
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.primary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      product.description,
      style: AppTypography.bodySmall.copyWith(
        color: ColorsManager.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPrice() {
    return Row(
      children: [
        Text(
          '₹${product.price.toStringAsFixed(0)}',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorsManager.primary,
          ),
        ),
        if (product.hasDiscount) ...[
          Gap(8.w),
          Text(
            '₹${product.originalPrice!.toStringAsFixed(0)}',
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 14.w,
                    color: ColorsManager.primary,
                  ),
                  Gap(4.w),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(4.w),
                  Text(
                    '(${product.reviewCount})',
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Gap(4.h),
              Text(
                '${product.stock} left',
                style: AppTypography.bodySmall.copyWith(
                  color: product.stock < 10
                      ? ColorsManager.error
                      : ColorsManager.onSurfaceVariant,
                  fontWeight:
                      product.stock < 10 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onAddToCart,
          icon: const Icon(Icons.add_shopping_cart),
        ),
      ],
    );
  }
}
