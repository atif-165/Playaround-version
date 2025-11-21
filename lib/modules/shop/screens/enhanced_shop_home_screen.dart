import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';

import '../models/sports_categories.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/shop_service.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../widgets/featured_deals_banner.dart';
import '../widgets/partner_shop_card.dart';
import '../widgets/product_card.dart' as shop_widgets;
import '../widgets/category_chip.dart';
import '../widgets/search_filter_bar.dart';
import '../../../routing/routes.dart';

class EnhancedShopHomeScreen extends StatefulWidget {
  const EnhancedShopHomeScreen({super.key});

  @override
  State<EnhancedShopHomeScreen> createState() => _EnhancedShopHomeScreenState();
}

class _EnhancedShopHomeScreenState extends State<EnhancedShopHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, featured, exclusive, sale
  String _sortBy = 'newest'; // newest, price_asc, price_desc, rating

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _exclusiveProducts = [];
  List<Product> _saleProducts = [];
  List<Shop> _partnerShops = [];
  List<Shop> _localShops = [];
  List<Shop> _onlineShops = [];

  bool _isLoading = true;
  int _cartItemCount = 0;

  final ProductService _productService = ProductService();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    _loadCartCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadProducts(),
        _loadFeaturedProducts(),
        _loadExclusiveProducts(),
        _loadSaleProducts(),
        _loadPartnerShops(),
        _loadLocalShops(),
        _loadOnlineShops(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
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

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final products = await _productService.getFeaturedProducts();
      setState(() {
        _featuredProducts = products;
      });
    } catch (e) {
      throw Exception('Failed to load featured products: $e');
    }
  }

  Future<void> _loadExclusiveProducts() async {
    try {
      final products = await _productService.getExclusiveProducts();
      setState(() {
        _exclusiveProducts = products;
      });
    } catch (e) {
      throw Exception('Failed to load exclusive products: $e');
    }
  }

  Future<void> _loadSaleProducts() async {
    try {
      final products = await _productService.getProductsOnSale();
      setState(() {
        _saleProducts = products;
      });
    } catch (e) {
      throw Exception('Failed to load sale products: $e');
    }
  }

  Future<void> _loadPartnerShops() async {
    try {
      final shops = await ShopService.getVerifiedShops();
      setState(() {
        _partnerShops = shops;
      });
    } catch (e) {
      throw Exception('Failed to load partner shops: $e');
    }
  }

  Future<void> _loadLocalShops() async {
    try {
      // For demo, using a default city
      final shops = await ShopService.getLocalShops('Mumbai');
      setState(() {
        _localShops = shops;
      });
    } catch (e) {
      throw Exception('Failed to load local shops: $e');
    }
  }

  Future<void> _loadOnlineShops() async {
    try {
      final shops = await ShopService.getOnlineShops();
      setState(() {
        _onlineShops = shops;
      });
    } catch (e) {
      throw Exception('Failed to load online shops: $e');
    }
  }

  Future<void> _loadCartCount() async {
    try {
      // For demo, using a default user ID
      final count = await CartService.getCartItemCount('demo_user_id');
      setState(() {
        _cartItemCount = count;
      });
    } catch (e) {
      // Handle error silently for cart count
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _performSearch();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterProducts();
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _filterProducts();
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      _loadProducts();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.searchProducts(_searchQuery);
      setState(() {
        _products = products;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
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

  Future<void> _filterProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Product> filteredProducts = [];

      switch (_selectedFilter) {
        case 'featured':
          filteredProducts = _featuredProducts;
          break;
        case 'exclusive':
          filteredProducts = _exclusiveProducts;
          break;
        case 'sale':
          filteredProducts = _saleProducts;
          break;
        default:
          filteredProducts = _products;
      }

      // Apply category filter
      if (_selectedCategory != 'All') {
        filteredProducts = filteredProducts
            .where((product) => product.category == _selectedCategory)
            .toList();
      }

      // Apply sorting
      switch (_sortBy) {
        case 'price_asc':
          filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'newest':
        default:
          filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      setState(() {
        _products = filteredProducts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filter failed: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Sports Shop',
        style: AppTypography.headlineSmall,
      ),
      backgroundColor: ColorsManager.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: ColorsManager.surfaceTint,
      actions: [
        NotificationBadge(
          count: _cartItemCount,
          child: IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: _navigateToCart,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: _navigateToOrders,
        ),
        PopupMenuButton<String>(
          onSelected: _onSortChanged,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'newest', child: Text('Newest First')),
            const PopupMenuItem(
                value: 'price_asc', child: Text('Price: Low to High')),
            const PopupMenuItem(
                value: 'price_desc', child: Text('Price: High to Low')),
            const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
          ],
          icon: const Icon(Icons.sort),
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
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: _searchQuery.isNotEmpty || _selectedFilter != 'all'
              ? _buildProductGrid()
              : _buildMainContent(),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildHomeTab(),
        _buildShopsTab(),
        _buildCategoriesTab(),
      ],
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeaturedDealsBanner(),
          Gap(24.h),
          _buildQuickFilters(),
          Gap(24.h),
          _buildFeaturedProducts(),
          Gap(24.h),
          _buildExclusiveProducts(),
          Gap(24.h),
          _buildSaleProducts(),
          Gap(24.h),
          _buildPartnerShops(),
          Gap(100.h), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildShopsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShopTabs(),
          Gap(16.h),
          _buildShopsContent(),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryGrid(),
          Gap(24.h),
          _buildCategoryProducts(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        boxShadow: [
          BoxShadow(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SearchFilterBar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onFilterChanged: _onFilterChanged,
            selectedFilter: _selectedFilter,
          ),
          Gap(16.h),
          _buildCategoryFilters(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ['All', ...SportsCategories.getAllCategories()];

    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: CategoryChip(
              category: category,
              isSelected: isSelected,
              onPressed: () => _onCategorySelected(category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedDealsBanner() {
    return FeaturedDealsBanner(
      products: _saleProducts.take(5).toList(),
      onProductTap: _navigateToProductDetail,
    );
  }

  Widget _buildQuickFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: CategoryChip(
              category: 'Featured',
              isSelected: _selectedFilter == 'featured',
              onPressed: () => _onFilterChanged('featured'),
            ),
          ),
          Gap(8.w),
          Expanded(
            child: CategoryChip(
              category: 'Exclusive',
              isSelected: _selectedFilter == 'exclusive',
              onPressed: () => _onFilterChanged('exclusive'),
            ),
          ),
          Gap(8.w),
          Expanded(
            child: CategoryChip(
              category: 'On Sale',
              isSelected: _selectedFilter == 'sale',
              onPressed: () => _onFilterChanged('sale'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    if (_featuredProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Products',
                style: AppTypography.headlineSmall,
              ),
              TextButton(
                onPressed: () => _onFilterChanged('featured'),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        Gap(16.h),
        SizedBox(
          height: 280.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _featuredProducts.length,
            itemBuilder: (context, index) {
              final product = _featuredProducts[index];
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: shop_widgets.ProductCard(
                  product: product,
                  onTap: () => _navigateToProductDetail(product),
                  onAddToCart: () => _addToCart(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExclusiveProducts() {
    if (_exclusiveProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exclusive Deals',
                style: AppTypography.headlineSmall,
              ),
              TextButton(
                onPressed: () => _onFilterChanged('exclusive'),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        Gap(16.h),
        SizedBox(
          height: 280.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _exclusiveProducts.length,
            itemBuilder: (context, index) {
              final product = _exclusiveProducts[index];
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: shop_widgets.ProductCard(
                  product: product,
                  onTap: () => _navigateToProductDetail(product),
                  onAddToCart: () => _addToCart(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaleProducts() {
    if (_saleProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'On Sale',
                style: AppTypography.headlineSmall,
              ),
              TextButton(
                onPressed: () => _onFilterChanged('sale'),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        Gap(16.h),
        SizedBox(
          height: 280.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _saleProducts.length,
            itemBuilder: (context, index) {
              final product = _saleProducts[index];
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: shop_widgets.ProductCard(
                  product: product,
                  onTap: () => _navigateToProductDetail(product),
                  onAddToCart: () => _addToCart(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerShops() {
    if (_partnerShops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Partner Shops',
            style: AppTypography.headlineSmall,
          ),
        ),
        Gap(16.h),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _partnerShops.length,
            itemBuilder: (context, index) {
              final shop = _partnerShops[index];
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: PartnerShopCard(
                  shop: shop,
                  onTap: () => _navigateToShopDetail(shop),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopTabs() {
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
          Tab(text: 'All Shops'),
          Tab(text: 'Local'),
          Tab(text: 'Online'),
        ],
      ),
    );
  }

  Widget _buildShopsContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildShopsList(_partnerShops),
        _buildShopsList(_localShops),
        _buildShopsList(_onlineShops),
      ],
    );
  }

  Widget _buildShopsList(List<Shop> shops) {
    if (shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 80.w,
              color: ColorsManager.onSurfaceVariant,
            ),
            Gap(16.h),
            Text(
              'No shops available',
              style: AppTypography.headlineSmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: PartnerShopCard(
            shop: shop,
            onTap: () => _navigateToShopDetail(shop),
            isListTile: true,
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    final categories = SportsCategories.getAllCategories();

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryChip(
            category: category,
            isSelected: _selectedCategory == category,
            onPressed: () => _onCategorySelected(category),
            isGridItem: true,
          );
        },
      ),
    );
  }

  Widget _buildCategoryProducts() {
    if (_selectedCategory == 'All') {
      return const SizedBox.shrink();
    }

    final categoryProducts = _products
        .where((product) => product.category == _selectedCategory)
        .toList();

    if (categoryProducts.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.sports,
              size: 80.w,
              color: ColorsManager.onSurfaceVariant,
            ),
            Gap(16.h),
            Text(
              'No products in this category',
              style: AppTypography.headlineSmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      padding: EdgeInsets.all(16.w),
      itemCount: categoryProducts.length,
      itemBuilder: (context, index) {
        final product = categoryProducts[index];
        return shop_widgets.ProductCard(
          product: product,
          onTap: () => _navigateToProductDetail(product),
          onAddToCart: () => _addToCart(product),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      padding: EdgeInsets.all(16.w),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return shop_widgets.ProductCard(
          product: product,
          onTap: () => _navigateToProductDetail(product),
          onAddToCart: () => _addToCart(product),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? Icons.search_off
                  : Icons.storefront_outlined,
              size: 80.w,
              color: ColorsManager.onSurfaceVariant,
            ),
            Gap(24.h),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'No products found'
                  : 'No products available',
              style: AppTypography.headlineSmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'Try adjusting your search or filters'
                  : 'Products will appear here once added',
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToCart() {
    Navigator.pushNamed(context, Routes.shopCart);
  }

  void _navigateToOrders() {
    Navigator.pushNamed(context, Routes.shopOrders);
  }

  void _navigateToProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      Routes.shopProductDetail,
      arguments: product,
    );
  }

  void _navigateToShopDetail(Shop shop) {
    Navigator.pushNamed(
      context,
      Routes.shopDetail,
      arguments: shop.id,
    );
  }

  Future<void> _addToCart(Product product) async {
    try {
      await CartService.addToCart(
        userId: 'demo_user_id', // Replace with actual user ID
        product: product,
        quantity: 1,
      );

      _loadCartCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} added to cart'),
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
    }
  }
}
