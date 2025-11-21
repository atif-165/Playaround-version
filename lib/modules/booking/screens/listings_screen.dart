import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../data/models/listing_model.dart' as data;
import '../../../data/repositories/booking_repository.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../widgets/listing_card.dart';
import 'booking_flow_screen.dart';

/// Screen displaying all available listings for booking
class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key, this.repository});

  final BookingRepository? repository;

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  late final BookingRepository _repository;
  final _searchController = TextEditingController();

  List<data.ListingModel> _allListings = [];
  List<data.ListingModel> _filteredListings = [];
  data.ListingCategory? _selectedCategory;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BookingRepository();
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repository.init();
      final listings = await _repository.loadListings();
      setState(() {
        _allListings = listings;
        _applyFilters();
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _error = 'Unable to load listings';
      });
    }
  }

  void _applyFilters() {
    final searchTerm = _searchController.text.toLowerCase().trim();
    List<data.ListingModel> filtered = _allListings.where((listing) {
      final matchesCategory =
          _selectedCategory == null || listing.category == _selectedCategory;
      final matchesSearch = searchTerm.isEmpty ||
          listing.title.toLowerCase().contains(searchTerm) ||
          listing.description.toLowerCase().contains(searchTerm) ||
          listing.sport.toLowerCase().contains(searchTerm);
      return matchesCategory && matchesSearch;
    }).toList();

    setState(() {
      _filteredListings = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book a Session',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
      ),
      body: Column(
        children: [
          _buildSearchFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CustomProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _buildListingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search listings…',
              prefixIcon:
                  const Icon(Icons.search, color: ColorsManager.mainBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: ColorsManager.mainBlue),
              ),
            ),
            onChanged: (_) => _applyFilters(),
          ),
          Gap(12.h),
          DropdownButtonFormField<data.ListingCategory>(
            value: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'All categories',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: ColorsManager.mainBlue),
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All categories'),
              ),
              ...data.ListingCategory.values.map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.name.toUpperCase()),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListingList() {
    if (_filteredListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64.sp, color: Colors.grey[400]),
            Gap(16.h),
            Text(
              'No listings found',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(8.h),
            Text(
              'Try adjusting your filters or search term',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _filteredListings.length,
        itemBuilder: (context, index) {
          final listing = _filteredListings[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: ListingCard(
              listing: listing,
              onTap: () => _navigateToBookingFlow(listing),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.grey[400]),
          Gap(16.h),
          Text(
            _error!,
            style: TextStyles.font14Grey400Weight,
          ),
          Gap(16.h),
          ElevatedButton(
            onPressed: _loadListings,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.mainBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToBookingFlow(data.ListingModel listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingFlowScreen(listing: listing),
      ),
    );
  }
}
