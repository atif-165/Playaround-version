import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../services/cart_service.dart';
import '../../../routing/routes.dart';
import '../services/product_service.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/sports_categories.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _products = ProductService();
  Future<List<CartItem>>? _future;

  @override
  void initState() {
    super.initState();
    _future = CartService.getCartItems(_getCurrentUserId());
  }

  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<double> _computeTotal(List<CartItem> items) async {
    double total = 0;
    for (final item in items) {
      final p = await _products.getProduct(item.productId);
      if (p != null) total += p.price * item.quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Shopping Cart',
        style: AppTypography.headlineSmall,
      ),
      backgroundColor: ColorsManager.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: ColorsManager.surfaceTint,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: _showClearCartDialog,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<CartItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.primary,
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyCart();
        }

        return _buildCartContent(items);
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80.w,
              color: ColorsManager.onSurfaceVariant,
            ),
            Gap(24.h),
            Text(
              'Your cart is empty',
              style: AppTypography.headlineSmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
            Gap(16.h),
            Text(
              'Add some products to get started',
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(32.h),
            AppFilledButton(
              text: 'Continue Shopping',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.shopping_bag),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(List<CartItem> items) {
    return FutureBuilder<double>(
      future: _computeTotal(items),
      builder: (context, snap) {
        final total = snap.data ?? 0;
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildCartItem(item);
                },
              ),
            ),
            _buildCartSummary(total),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return FutureBuilder<Product?>(
      future: _products.getProduct(item.productId),
      builder: (context, snapshot) {
        final product = snapshot.data;

        return AppCard(
          variant: CardVariant.outlined,
          margin: EdgeInsets.only(bottom: 12.h),
          onTap: product != null ? () {
            Navigator.of(context).pushNamed(Routes.shopProductDetail, arguments: product);
          } : null,
          child: Row(
            children: [
              // Product Image
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: product?.images.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          product!.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(product),
                        ),
                      )
                    : _buildImagePlaceholder(product),
              ),
              Gap(12.w),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.title ?? 'Loading...',
                      style: AppTypography.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(4.h),
                    if (product != null) ...[
                      AppChip(
                        label: product.category,
                        variant: ChipVariant.assist,
                        size: ChipSize.small,
                      ),
                      Gap(8.h),
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: AppTypography.priceText.copyWith(
                              fontSize: 16.sp,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Qty: ${item.quantity}',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                      Gap(8.h),
                      Text(
                        'Total: ₹${(product.price * item.quantity).toStringAsFixed(0)}',
                        style: AppTypography.titleSmall.copyWith(
                          color: ColorsManager.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: () => _removeFromCart(item.productId),
                    icon: const Icon(Icons.delete_outline),
                    color: ColorsManager.error,
                    iconSize: 20.w,
                  ),
                  Gap(8.h),
                  _buildQuantityControls(item),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder(Product? product) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Icon(
          product != null
              ? SportsCategories.getCategoryIcon(product.category)
              : Icons.sports,
          size: 32.w,
          color: ColorsManager.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ColorsManager.outline),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _updateQuantity(item.productId, item.quantity + 1),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Icon(
                Icons.add,
                size: 16.w,
                color: ColorsManager.primary,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            child: Text(
              item.quantity.toString(),
              style: AppTypography.labelMedium,
            ),
          ),
          InkWell(
            onTap: item.quantity > 1
                ? () => _updateQuantity(item.productId, item.quantity - 1)
                : null,
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Icon(
                Icons.remove,
                size: 16.w,
                color: item.quantity > 1
                    ? ColorsManager.primary
                    : ColorsManager.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(double total) {
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: AppTypography.titleLarge,
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: AppTypography.priceText,
                ),
              ],
            ),
            Gap(16.h),
            AppFilledButton(
              text: 'Proceed to Checkout',
              fullWidth: true,
              onPressed: () => Navigator.of(context).pushNamed(
                Routes.shopCheckout,
                arguments: total,
              ),
              icon: const Icon(Icons.payment),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _showClearCartDialog() {
    AppConfirmationDialog.show(
      context: context,
      title: 'Clear Cart',
      content: 'Are you sure you want to remove all items from your cart?',
      confirmText: 'Clear',
      confirmVariant: ButtonVariant.error,
      icon: Icons.delete_sweep,
      iconColor: ColorsManager.error,
      onConfirm: () async {
        // TODO: Implement clear cart functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clear cart functionality coming soon!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _removeFromCart(String productId) async {
    try {
      await CartService.removeFromCart(
        userId: _getCurrentUserId(),
        cartItemId: productId,
      );
      setState(() {
        _future = CartService.getCartItems(_getCurrentUserId());
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from cart'),
            backgroundColor: ColorsManager.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: $e'),
            backgroundColor: ColorsManager.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _updateQuantity(String productId, int newQuantity) async {
    try {
      await CartService.updateCartItemQuantity(
        userId: _getCurrentUserId(),
        cartItemId: productId,
        quantity: newQuantity,
      );
      setState(() {
        _future = CartService.getCartItems(_getCurrentUserId());
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quantity: $e'),
            backgroundColor: ColorsManager.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

