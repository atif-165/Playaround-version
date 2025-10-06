import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/accessibility/accessibility_helpers.dart';
import '../models/sports_categories.dart';
import '../models/product.dart';
import '../../../routing/routes.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll create some sample products
      _products = _generateSampleProducts();
      _filterProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
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

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesCategory = _selectedCategory == 'All' ||
                               product.category == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
                             product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        backgroundColor: ColorsManager.primary,
        foregroundColor: ColorsManager.onPrimary,
        child: const Icon(Icons.add),
      ),
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
          count: 3, // Sample cart count
          child: IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: _navigateToCart,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: _navigateToOrders,
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
          child: _filteredProducts.isEmpty
              ? _buildEmptyState()
              : _buildProductGrid(),
        ),
      ],
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
          AppSearchField(
            controller: _searchController,
            hintText: 'Search sports equipment...',
            onChanged: _onSearchChanged,
            onClear: () => _onSearchChanged(''),
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
            child: AppChip(
              label: category,
              variant: ChipVariant.filter,
              selected: isSelected,
              onPressed: () => _onCategorySelected(category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return ResponsiveContainer(
      child: ResponsiveLayout(
        mobile: _buildMobileGrid(),
        tablet: _buildTabletGrid(),
        desktop: _buildDesktopGrid(),
      ),
    );
  }

  Widget _buildMobileGrid() {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return AccessibleListItem(
            title: product.title,
            subtitle: '₹${product.price.toStringAsFixed(0)}',
            position: index + 1,
            totalItems: _filteredProducts.length,
            onTap: () => _navigateToProductDetail(product),
            child: ProductCard(
              name: product.title,
              price: '₹${product.price.toStringAsFixed(0)}',
              imageUrl: product.images.isNotEmpty ? product.images.first : null,
              category: product.category,
              rating: 4.5,
              onTap: () => _navigateToProductDetail(product),
              onAddToCart: () => _addToCart(product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabletGrid() {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return AccessibleListItem(
            title: product.title,
            subtitle: '₹${product.price.toStringAsFixed(0)}',
            position: index + 1,
            totalItems: _filteredProducts.length,
            onTap: () => _navigateToProductDetail(product),
            child: ProductCard(
              name: product.title,
              price: '₹${product.price.toStringAsFixed(0)}',
              imageUrl: product.images.isNotEmpty ? product.images.first : null,
              category: product.category,
              rating: 4.5,
              onTap: () => _navigateToProductDetail(product),
              onAddToCart: () => _addToCart(product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          crossAxisSpacing: 20.w,
          mainAxisSpacing: 20.h,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return AccessibleListItem(
            title: product.title,
            subtitle: '₹${product.price.toStringAsFixed(0)}',
            position: index + 1,
            totalItems: _filteredProducts.length,
            onTap: () => _navigateToProductDetail(product),
            child: ProductCard(
              name: product.title,
              price: '₹${product.price.toStringAsFixed(0)}',
              imageUrl: product.images.isNotEmpty ? product.images.first : null,
              category: product.category,
              rating: 4.5,
              onTap: () => _navigateToProductDetail(product),
              onAddToCart: () => _addToCart(product),
            ),
          );
        },
      ),
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
            Gap(32.h),
            AppFilledButton(
              text: 'Add First Product',
              onPressed: _navigateToAddProduct,
              icon: const Icon(Icons.add),
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

  void _navigateToAddProduct() {
    Navigator.pushNamed(context, Routes.shopAddProduct);
  }

  void _navigateToProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      Routes.shopProductDetail,
      arguments: product,
    );
  }

  void _addToCart(Product product) {
    // TODO: Implement add to cart functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} added to cart'),
        backgroundColor: ColorsManager.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Announce to screen reader
    SemanticAnnouncements.announceItemAdded(context, product.title);
  }

  // Sample data generation (replace with actual API calls)
  List<Product> _generateSampleProducts() {
    return [
      Product(
        id: '1',
        title: 'Professional Football',
        description: 'High-quality leather football for professional matches',
        price: 2500.0,
        category: 'Football',
        ownerId: 'sample-owner',
        shopId: 'shop1',
        shopName: 'Sports Store',
        images: ['https://example.com/football.jpg'],
        sizes: ['M', 'L'],
        colors: ['Brown', 'White'],
        stock: 10,
        isAvailable: true,
        rating: 4.5,
        reviewCount: 25,
        tags: ['football', 'sports', 'professional'],
        specifications: {'material': 'Leather', 'weight': '400g'},
        isFeatured: true,
        isExclusive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '2',
        title: 'Basketball Shoes',
        description: 'Comfortable basketball shoes with excellent grip',
        price: 4500.0,
        category: 'Basketball',
        ownerId: 'sample-owner',
        shopId: 'shop1',
        shopName: 'Sports Store',
        images: ['https://example.com/basketball-shoes.jpg'],
        sizes: ['8', '9', '10', '11'],
        colors: ['Black', 'White', 'Red'],
        stock: 15,
        isAvailable: true,
        rating: 4.2,
        reviewCount: 18,
        tags: ['basketball', 'shoes', 'sports'],
        specifications: {'brand': 'Nike', 'type': 'Running'},
        isFeatured: false,
        isExclusive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '3',
        title: 'Tennis Racket',
        description: 'Lightweight tennis racket for beginners and professionals',
        price: 3200.0,
        category: 'Tennis',
        ownerId: 'sample-owner',
        shopId: 'shop1',
        shopName: 'Sports Store',
        images: ['https://example.com/tennis-racket.jpg'],
        sizes: ['M', 'L'],
        colors: ['Black', 'Red'],
        stock: 8,
        isAvailable: true,
        rating: 4.7,
        reviewCount: 32,
        tags: ['tennis', 'racket', 'sports'],
        specifications: {'weight': '280g', 'grip': '4 3/8'},
        isFeatured: true,
        isExclusive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '4',
        title: 'Cricket Bat',
        description: 'Premium willow cricket bat for serious players',
        price: 5500.0,
        category: 'Cricket',
        ownerId: 'sample-owner',
        shopId: 'shop1',
        shopName: 'Sports Store',
        images: ['https://example.com/cricket-bat.jpg'],
        sizes: ['SH', 'LH'],
        colors: ['Natural'],
        stock: 5,
        isAvailable: true,
        rating: 4.8,
        reviewCount: 12,
        tags: ['cricket', 'bat', 'willow'],
        specifications: {'wood': 'English Willow', 'weight': '2.8 lbs'},
        isFeatured: false,
        isExclusive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '5',
        title: 'Volleyball',
        description: 'Official size volleyball for indoor and outdoor play',
        price: 1800.0,
        category: 'Volleyball',
        ownerId: 'sample-owner',
        shopId: 'shop1',
        shopName: 'Sports Store',
        images: ['https://example.com/volleyball.jpg'],
        sizes: ['Standard'],
        colors: ['White', 'Blue'],
        stock: 20,
        isAvailable: true,
        rating: 4.3,
        reviewCount: 28,
        tags: ['volleyball', 'ball', 'sports'],
        specifications: {'size': 'Official', 'material': 'Synthetic leather'},
        isFeatured: false,
        isExclusive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '6',
        title: 'Badminton Racket Set',
        description: 'Complete badminton set with 2 rackets and shuttlecocks',
        price: 2800.0,
        category: 'Badminton',
        ownerId: 'sample-owner',
        shopId: 'shop1',
        shopName: 'Sports Store',
        images: ['https://example.com/badminton-set.jpg'],
        sizes: ['M', 'L'],
        colors: ['Black', 'Red'],
        stock: 12,
        isAvailable: true,
        rating: 4.1,
        reviewCount: 15,
        tags: ['badminton', 'racket', 'set'],
        specifications: {'includes': '2 rackets, 6 shuttlecocks'},
        isFeatured: false,
        isExclusive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

