import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../models/product.dart';

class FeaturedDealsBanner extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onProductTap;

  const FeaturedDealsBanner({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  State<FeaturedDealsBanner> createState() => _FeaturedDealsBannerState();
}

class _FeaturedDealsBannerState extends State<FeaturedDealsBanner>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    if (widget.products.isNotEmpty) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _animationController.repeat();
    _animationController.addListener(() {
      if (_animationController.isCompleted) {
        _nextSlide();
      }
    });
  }

  void _nextSlide() {
    if (widget.products.isEmpty) return;
    
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.products.length;
    });
    
    _pageController.animateToPage(
      _currentIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200.h,
      margin: EdgeInsets.all(16.w),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return _buildBannerItem(product);
            },
          ),
          if (widget.products.length > 1) ...[
            Positioned(
              bottom: 16.h,
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),
            Positioned(
              right: 16.w,
              top: 16.h,
              child: _buildDiscountBadge(widget.products[_currentIndex]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerItem(Product product) {
    return GestureDetector(
      onTap: () => widget.onProductTap(product),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsManager.primary.withValues(alpha: 0.8),
              ColorsManager.secondary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Special Offer',
                      style: AppTypography.labelMedium.copyWith(
                        color: ColorsManager.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    Gap(8.h),
                    Text(
                      product.title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: ColorsManager.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(8.h),
                    Text(
                      product.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: ColorsManager.onPrimary.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(16.h),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: AppTypography.headlineSmall.copyWith(
                            color: ColorsManager.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          Gap(8.w),
                          Text(
                            '₹${product.originalPrice!.toStringAsFixed(0)}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: ColorsManager.onPrimary.withValues(alpha: 0.7),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Gap(8.w),
                          Container(
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
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Gap(16.w),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorsManager.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.sports,
                                size: 60.w,
                                color: ColorsManager.onPrimary,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.sports,
                          size: 60.w,
                          color: ColorsManager.onPrimary,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.products.length,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: _currentIndex == index ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? ColorsManager.onPrimary
                : ColorsManager.onPrimary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountBadge(Product product) {
    if (!product.hasDiscount) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.error,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.error.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${product.discountPercentage.toStringAsFixed(0)}% OFF',
        style: AppTypography.labelMedium.copyWith(
          color: ColorsManager.onError,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
