import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../listing/services/listing_service.dart';
import '../../listing/widgets/sport_type_dropdown.dart';
import '../widgets/listing_card.dart';
import 'booking_flow_screen.dart';

/// Screen displaying all available listings for booking
class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final _listingService = ListingService();
  final _searchController = TextEditingController();

  SportType? _selectedSportFilter;
  ListingType? _selectedTypeFilter;
  List<ListingModel> _allListings = [];
  List<ListingModel> _filteredListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _listingService.getActiveListings().listen((listings) {
        if (mounted) {
          setState(() {
            _allListings = listings;
            _applyFilters();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load listings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<ListingModel> filtered = List.from(_allListings);

    // Apply sport type filter
    if (_selectedSportFilter != null) {
      filtered = filtered
          .where((listing) => listing.sportType == _selectedSportFilter)
          .toList();
    }

    // Apply listing type filter
    if (_selectedTypeFilter != null) {
      filtered = filtered
          .where((listing) => listing.type == _selectedTypeFilter)
          .toList();
    }

    // Apply search filter
    final searchTerm = _searchController.text.toLowerCase().trim();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((listing) {
        return listing.title.toLowerCase().contains(searchTerm) ||
            listing.description.toLowerCase().contains(searchTerm) ||
            listing.location.toLowerCase().contains(searchTerm);
      }).toList();
    }

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
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CustomProgressIndicator())
                : _buildListingsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search listings...',
              prefixIcon: const Icon(Icons.search, color: ColorsManager.mainBlue),
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
          // Filters
          Row(
            children: [
              Expanded(
                child: SportTypeDropdown(
                  selectedSportType: _selectedSportFilter,
                  hintText: 'All Sports',
                  onChanged: (sportType) {
                    setState(() {
                      _selectedSportFilter = sportType;
                    });
                    _applyFilters();
                  },
                ),
              ),
              Gap(12.w),
              Expanded(
                child: DropdownButtonFormField<ListingType>(
                  value: _selectedTypeFilter,
                  decoration: InputDecoration(
                    hintText: 'All Types',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: ColorsManager.mainBlue),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<ListingType>(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...ListingType.values.map((type) {
                      return DropdownMenuItem<ListingType>(
                        value: type,
                        child: Text(
                          type == ListingType.coach ? 'Coaches' : 'Venues',
                        ),
                      );
                    }),
                  ],
                  onChanged: (type) {
                    setState(() {
                      _selectedTypeFilter = type;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingsGrid() {
    if (_filteredListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No listings found',
              style: TextStyles.font18DarkBlueBold,
            ),
            Gap(8.h),
            Text(
              'Try adjusting your search or filters',
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

  void _navigateToBookingFlow(ListingModel listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingFlowScreen(listing: listing),
      ),
    );
  }
}
