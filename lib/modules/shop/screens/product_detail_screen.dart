import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/sports_categories.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = ProductService();
  final _cart = CartService();
  Future<Product?>? _future;
  int _quantity = 1;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getProduct(widget.productId);
  }

  void _showAddReviewSheet(Product p) {
    final ratingCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    AppBottomSheet.show(
      context: context,
      title: 'Add Review',
      isScrollControlled: true,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gap(16.h),
            AppTextField(
              controller: ratingCtrl,
              labelText: 'Rating (1-5)',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.star_outline),
            ),
            Gap(16.h),
            AppTextField(
              controller: commentCtrl,
              labelText: 'Comment',
              hintText: 'Share your experience with this product...',
              maxLines: 3,
              prefixIcon: const Icon(Icons.comment_outlined),
            ),
            Gap(24.h),
            AppFilledButton(
              text: 'Submit Review',
              fullWidth: true,
              onPressed: () async {
                final rating = int.tryParse(ratingCtrl.text.trim()) ?? 0;
                if (rating < 1 || rating > 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rating must be between 1-5')),
                  );
                  return;
                }
                final r = Review(
                  id: '',
                  userId: '',
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                  timestamp: DateTime.now(),
                );
                final nav = Navigator.of(context);
                await _service.addReview(p.id, r);
                if (!mounted) return;
                nav.maybePop();
                if (!mounted) return;
                setState(() {});
              },
              icon: const Icon(Icons.rate_review),
            ),
            Gap(16.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FutureBuilder<Product?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: ColorsManager.primary,
              ),
            );
          }
          final p = snapshot.data;
          if (p == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.w,
                    color: ColorsManager.onSurfaceVariant,
                  ),
                  Gap(16.h),
                  Text(
                    'Product not found',
                    style: AppTypography.headlineSmall.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return _buildProductContent(p);
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Product Details',
        style: AppTypography.headlineSmall,
      ),
      backgroundColor: ColorsManager.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: ColorsManager.surfaceTint,
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? ColorsManager.error : null,
          ),
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isFavorite
                      ? 'Added to favorites'
                      : 'Removed from favorites',
                ),
                backgroundColor: ColorsManager.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share functionality coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductContent(Product p) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(p),
          _buildProductInfo(p),
          _buildDescription(p),
          _buildReviewsSection(p),
          Gap(100.h), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildProductImage(Product p) {
    return Container(
      height: 300.h,
      width: double.infinity,
      color: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
      child: p.images.isNotEmpty
          ? ClipRRect(
              child: Image.network(
                p.images.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(p),
              ),
            )
          : _buildImagePlaceholder(p),
    );
  }

  Widget _buildImagePlaceholder(Product p) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorsManager.surfaceVariant,
      ),
      child: Center(
        child: Icon(
          SportsCategories.getCategoryIcon(p.category),
          size: 80.w,
          color: ColorsManager.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildProductInfo(Product p) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppChip(
                label: p.category,
                variant: ChipVariant.assist,
                size: ChipSize.small,
                avatar: Icon(
                  SportsCategories.getCategoryIcon(p.category),
                  size: 16.w,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: ColorsManager.warning,
                    size: 16.w,
                  ),
                  Gap(4.w),
                  Text(
                    '4.5 (123 reviews)',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          Gap(12.h),
          Text(
            p.title,
            style: AppTypography.headlineMedium,
          ),
          Gap(8.h),
          Text(
            '₹${p.price.toStringAsFixed(0)}',
            style: AppTypography.priceText,
          ),
          Gap(16.h),
          _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text(
          'Quantity:',
          style: AppTypography.titleMedium,
        ),
        Gap(16.w),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ColorsManager.outline),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _quantity > 1 ? () {
                  setState(() {
                    _quantity--;
                  });
                } : null,
                icon: const Icon(Icons.remove),
                iconSize: 20.w,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  _quantity.toString(),
                  style: AppTypography.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _quantity++;
                  });
                },
                icon: const Icon(Icons.add),
                iconSize: 20.w,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Product p) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTypography.titleLarge,
          ),
          Gap(8.h),
          Text(
            p.description,
            style: AppTypography.bodyMedium,
          ),
          Gap(24.h),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(Product p) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reviews',
                style: AppTypography.titleLarge,
              ),
              const Spacer(),
              AppTextButton(
                text: 'Add Review',
                onPressed: () => _showAddReviewSheet(p),
                icon: const Icon(Icons.rate_review_outlined),
              ),
            ],
          ),
          Gap(16.h),
          FutureBuilder<List<Review>>(
            future: _service.getReviews(p.id),
            builder: (context, snap) {
              final reviews = snap.data ?? [];
              if (reviews.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48.w,
                          color: ColorsManager.onSurfaceVariant,
                        ),
                        Gap(16.h),
                        Text(
                          'No reviews yet',
                          style: AppTypography.bodyMedium.copyWith(
                            color: ColorsManager.onSurfaceVariant,
                          ),
                        ),
                        Gap(8.h),
                        Text(
                          'Be the first to review this product',
                          style: AppTypography.bodySmall.copyWith(
                            color: ColorsManager.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: reviews.map((r) => AppCard(
                  variant: CardVariant.outlined,
                  size: CardSize.small,
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: ColorsManager.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: ColorsManager.onPrimaryContainer,
                          size: 20.w,
                        ),
                      ),
                      Gap(12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(5, (index) => Icon(
                                  index < r.rating ? Icons.star : Icons.star_border,
                                  color: ColorsManager.warning,
                                  size: 16.w,
                                )),
                                Gap(8.w),
                                Text(
                                  '${r.rating}/5',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                            if (r.comment.isNotEmpty) ...[
                              Gap(4.h),
                              Text(
                                r.comment,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                text: 'Buy Now',
                onPressed: () async {
                  final p = await _future;
                  if (p != null && mounted) {
                    // TODO: Implement buy now functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Buy now functionality coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.flash_on),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AppFilledButton(
                text: 'Add to Cart',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final p = await _future;
                  if (!mounted) return;
                  if (p != null) {
                    await _cart.addToCart(p.id, quantity: _quantity);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Added $_quantity ${p.title} to cart'),
                        backgroundColor: ColorsManager.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

