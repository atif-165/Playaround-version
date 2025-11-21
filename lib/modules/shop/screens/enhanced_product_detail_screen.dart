import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';

import '../models/product.dart';
import '../models/shop.dart';
import '../models/review.dart';
import '../services/product_service.dart';
import '../services/shop_service.dart';
import '../services/cart_service.dart';
import '../services/review_service.dart';
import '../widgets/product_image_gallery.dart';
import '../widgets/product_specifications.dart';
import '../widgets/review_card.dart';
import '../widgets/shop_info_card.dart';
import '../widgets/product_card.dart' as shop_widgets;
import '../../../routing/routes.dart';

class EnhancedProductDetailScreen extends StatefulWidget {
  final Product product;

  const EnhancedProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<EnhancedProductDetailScreen> createState() =>
      _EnhancedProductDetailScreenState();
}

class _EnhancedProductDetailScreenState
    extends State<EnhancedProductDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  final _productService = ProductService();

  Product? _product;
  Shop? _shop;
  List<Review> _reviews = [];
  List<Product> _relatedProducts = [];
  ReviewSummary? _reviewSummary;

  bool _isLoading = true;
  bool _isAddingToCart = false;
  int _selectedImageIndex = 0;
  String _selectedSize = '';
  String _selectedColor = '';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _product = widget.product;
    _selectedSize = _product!.sizes.isNotEmpty ? _product!.sizes.first : '';
    _selectedColor = _product!.colors.isNotEmpty ? _product!.colors.first : '';

    _loadProductDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadShopDetails(),
        _loadReviews(),
        _loadRelatedProducts(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading product details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadShopDetails() async {
    try {
      final shop = await ShopService.getShopById(_product!.shopId);
      setState(() {
        _shop = shop;
      });
    } catch (e) {
      throw Exception('Failed to load shop details: $e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewService.getProductReviews(_product!.id);
      final summary = await ReviewService.getProductReviewSummary(_product!.id);

      setState(() {
        _reviews = reviews;
        _reviewSummary = summary;
      });
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  Future<void> _loadRelatedProducts() async {
    try {
      final products = await _productService.getRelatedProducts(_product!.id);

      setState(() {
        _relatedProducts = products;
      });
    } catch (e) {
      throw Exception('Failed to load related products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _product?.title ?? 'Product Details',
        style: AppTypography.titleMedium,
      ),
      backgroundColor: ColorsManager.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: ColorsManager.surfaceTint,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareProduct,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: _toggleWishlist,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: ColorsManager.primary,
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageGallery(),
          _buildProductInfo(),
          _buildTabs(),
          _buildTabContent(),
          _buildRelatedProducts(),
          Gap(100.h), // Bottom padding for bottom bar
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return ProductImageGallery(
      images: _product!.images,
      selectedIndex: _selectedImageIndex,
      onImageSelected: (index) {
        setState(() {
          _selectedImageIndex = index;
        });
      },
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleAndRating(),
          Gap(16.h),
          _buildPrice(),
          Gap(16.h),
          _buildShopInfo(),
          Gap(16.h),
          _buildSizeAndColorSelection(),
          Gap(16.h),
          _buildQuantitySelector(),
          Gap(16.h),
          _buildProductTags(),
        ],
      ),
    );
  }

  Widget _buildTitleAndRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _product!.title,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap(8.h),
        Row(
          children: [
            Icon(
              Icons.star,
              size: 20.w,
              color: ColorsManager.primary,
            ),
            Gap(4.w),
            Text(
              _product!.rating.toStringAsFixed(1),
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(8.w),
            Text(
              '(${_product!.reviewCount} reviews)',
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (_product!.isFeatured)
              Container(
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
            if (_product!.isExclusive) ...[
              Gap(8.w),
              Container(
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
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPrice() {
    return Row(
      children: [
        Text(
          '₹${_product!.price.toStringAsFixed(0)}',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorsManager.primary,
          ),
        ),
        if (_product!.hasDiscount) ...[
          Gap(12.w),
          Text(
            '₹${_product!.originalPrice!.toStringAsFixed(0)}',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
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
              '${_product!.discountPercentage.toStringAsFixed(0)}% OFF',
              style: AppTypography.labelSmall.copyWith(
                color: ColorsManager.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShopInfo() {
    if (_shop == null) return const SizedBox.shrink();

    return ShopInfoCard(
      shop: _shop!,
      onTap: _navigateToShop,
    );
  }

  Widget _buildSizeAndColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_product!.sizes.isNotEmpty) ...[
          Text(
            'Size',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          Wrap(
            spacing: 8.w,
            children: _product!.sizes.map((size) {
              final isSelected = _selectedSize == size;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSize = size;
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorsManager.primary
                        : ColorsManager.surfaceVariant,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? ColorsManager.primary
                          : ColorsManager.outline,
                    ),
                  ),
                  child: Text(
                    size,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? ColorsManager.onPrimary
                          : ColorsManager.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Gap(16.h),
        ],
        if (_product!.colors.isNotEmpty) ...[
          Text(
            'Color',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          Wrap(
            spacing: 8.w,
            children: _product!.colors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: _getColorFromString(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? ColorsManager.primary
                          : ColorsManager.outline,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: ColorsManager.onPrimary,
                          size: 20.w,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text(
          'Quantity',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ColorsManager.outline),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _quantity > 1 ? _decreaseQuantity : null,
                icon: const Icon(Icons.remove),
                iconSize: 20.w,
              ),
              Container(
                width: 40.w,
                alignment: Alignment.center,
                child: Text(
                  _quantity.toString(),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    _quantity < _product!.stock ? _increaseQuantity : null,
                icon: const Icon(Icons.add),
                iconSize: 20.w,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductTags() {
    if (_product!.tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _product!.tags.map((tag) {
            return AppChip(
              label: tag,
              variant: ChipVariant.assist,
              size: ChipSize.small,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: ColorsManager.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        labelColor: ColorsManager.onPrimary,
        unselectedLabelColor: ColorsManager.onSurfaceVariant,
        tabs: const [
          Tab(text: 'Description'),
          Tab(text: 'Specifications'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      height: 400.h,
      margin: EdgeInsets.all(16.w),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildDescriptionTab(),
          _buildSpecificationsTab(),
          _buildReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(16.h),
          Text(
            _product!.description,
            style: AppTypography.bodyMedium,
          ),
          Gap(24.h),
          _buildStockInfo(),
        ],
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    return ProductSpecifications(
      specifications: _product!.specifications,
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_reviewSummary != null) _buildReviewSummary(),
          Gap(16.h),
          ..._reviews.map((review) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: ReviewCard(
                  review: review,
                  onHelpful: () => _markReviewHelpful(review.id),
                ),
              )),
          if (_reviews.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.reviews,
                    size: 48.w,
                    color: ColorsManager.onSurfaceVariant,
                  ),
                  Gap(16.h),
                  Text(
                    'No reviews yet',
                    style: AppTypography.titleMedium.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                  ),
                  Gap(8.h),
                  Text(
                    'Be the first to review this product',
                    style: AppTypography.bodyMedium.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Overall Rating',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _reviewSummary!.averageRating.toStringAsFixed(1),
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.primary,
                ),
              ),
              Gap(8.w),
              Icon(
                Icons.star,
                color: ColorsManager.primary,
                size: 24.w,
              ),
            ],
          ),
          Gap(16.h),
          Text(
            'Based on ${_reviewSummary!.totalReviews} reviews',
            style: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _product!.stock < 10
            ? ColorsManager.errorContainer
            : ColorsManager.primaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            _product!.stock < 10 ? Icons.warning : Icons.inventory,
            color: _product!.stock < 10
                ? ColorsManager.onErrorContainer
                : ColorsManager.onPrimaryContainer,
          ),
          Gap(12.w),
          Expanded(
            child: Text(
              _product!.stock < 10
                  ? 'Only ${_product!.stock} left in stock!'
                  : '${_product!.stock} items available',
              style: AppTypography.bodyMedium.copyWith(
                color: _product!.stock < 10
                    ? ColorsManager.onErrorContainer
                    : ColorsManager.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    if (_relatedProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Related Products',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Gap(16.h),
        SizedBox(
          height: 280.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _relatedProducts.length,
            itemBuilder: (context, index) {
              final product = _relatedProducts[index];
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: SizedBox(
                  width: 200.w,
                  child: shop_widgets.ProductCard(
                    product: product,
                    onTap: () => _navigateToProduct(product),
                    onAddToCart: () => _addToCart(product),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        boxShadow: [
          BoxShadow(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppOutlinedButton(
              text: 'Add to Cart',
              onPressed: _addToCart,
              icon: _isAddingToCart
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorsManager.primary,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          Gap(16.w),
          Expanded(
            child: AppFilledButton(
              text: 'Buy Now',
              onPressed: _buyNow,
              icon: const Icon(Icons.flash_on),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'gray':
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _increaseQuantity() {
    if (_quantity < _product!.stock) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _addToCart([Product? product]) async {
    final productToAdd = product ?? _product!;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      await CartService.addToCart(
        userId: 'demo_user_id', // Replace with actual user ID
        product: productToAdd,
        quantity: product != null ? 1 : _quantity,
        size: _selectedSize,
        color: _selectedColor,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${productToAdd.title} added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: _navigateToCart,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to cart: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  void _buyNow() {
    // TODO: Implement buy now functionality
    _navigateToCheckout();
  }

  void _shareProduct() {
    // TODO: Implement share functionality
  }

  void _toggleWishlist() {
    // TODO: Implement wishlist functionality
  }

  void _markReviewHelpful(String reviewId) {
    // TODO: Implement mark review as helpful
  }

  void _navigateToShop() {
    if (_shop != null) {
      Navigator.pushNamed(
        context,
        Routes.shopDetail,
        arguments: _shop!.id,
      );
    }
  }

  void _navigateToProduct(Product product) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedProductDetailScreen(product: product),
      ),
    );
  }

  void _navigateToCart() {
    Navigator.pushNamed(context, Routes.shopCart);
  }

  void _navigateToCheckout() {
    Navigator.pushNamed(context, Routes.shopCheckout);
  }
}
