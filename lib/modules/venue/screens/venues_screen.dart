import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../models/venue_model.dart';
import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/venue_service.dart';
import '../widgets/venue_card.dart';
import '../widgets/venue_filter_sheet.dart';
import 'add_venue_screen.dart';
import 'venue_detail_screen.dart';
import 'my_venue_bookings_screen.dart';
import 'owner_bookings_screen.dart';

/// Screen displaying all available venues
class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  final VenueService _venueService = VenueService();
  final TextEditingController _searchController = TextEditingController();
  
  SportType? _selectedSportType;
  String? _selectedLocation;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Venues',
          style: TextStyles.font16White600Weight.copyWith(fontSize: 18.sp),
        ),
        backgroundColor: ColorsManager.neonBlue,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'my_bookings',
                child: Row(
                  children: [
                    Icon(Icons.book_online, size: 20),
                    SizedBox(width: 8),
                    Text('My Bookings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'owner_bookings',
                child: Row(
                  children: [
                    Icon(Icons.business, size: 20),
                    SizedBox(width: 8),
                    Text('Owner Bookings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildVenuesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "venues_fab",
        onPressed: _showAddVenueScreen,
        backgroundColor: ColorsManager.mainBlue,
        foregroundColor: Colors.white,
        tooltip: 'Add New Venue',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search venues...',
                  hintStyle: TextStyles.font14Grey400Weight,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),
          Gap(12.w),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _hasActiveFilters() ? ColorsManager.mainBlue : Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _hasActiveFilters() ? ColorsManager.mainBlue : Colors.grey[300]!,
                ),
              ),
              child: Icon(
                Icons.filter_list,
                color: _hasActiveFilters() ? Colors.white : Colors.grey[600],
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenuesList() {
    return StreamBuilder<List<VenueModel>>(
      stream: _venueService.getVenues(
        sportType: _selectedSportType,
        location: _selectedLocation,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomProgressIndicator());
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          final isPermissionError = error.contains('permission-denied');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermissionError ? Icons.lock_outline : Icons.error_outline,
                  size: 48.sp,
                  color: Colors.grey[400],
                ),
                Gap(16.h),
                Text(
                  isPermissionError ? 'Permission Error' : 'Error loading venues',
                  style: TextStyles.font16Grey400Weight,
                ),
                Gap(8.h),
                Text(
                  isPermissionError
                      ? 'Unable to access venues. Please check your connection and try again.'
                      : error,
                  style: TextStyles.font12Grey400Weight,
                  textAlign: TextAlign.center,
                ),
                Gap(16.h),
                ElevatedButton(
                  onPressed: () => setState(() {}),
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

        final venues = snapshot.data ?? [];

        if (venues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_city_outlined,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                Gap(16.h),
                Text(
                  'No venues found',
                  style: TextStyles.font18DarkBlue600Weight,
                ),
                Gap(8.h),
                Text(
                  _hasActiveFilters() || _searchQuery.isNotEmpty
                      ? 'Try adjusting your search or filters'
                      : 'Be the first to add a venue!',
                  style: TextStyles.font14Grey400Weight,
                  textAlign: TextAlign.center,
                ),
                Gap(24.h),
                ElevatedButton.icon(
                  onPressed: _showAddVenueScreen,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Venue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.mainBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: venues.length,
            itemBuilder: (context, index) {
              final venue = venues[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: VenueCard(
                  venue: venue,
                  onTap: () => _navigateToVenueDetail(venue),
                ),
              );
            },
          ),
        );
      },
    );
  }

  bool _hasActiveFilters() {
    return _selectedSportType != null || 
           (_selectedLocation != null && _selectedLocation!.isNotEmpty);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VenueFilterSheet(
        selectedSportType: _selectedSportType,
        selectedLocation: _selectedLocation,
        onFiltersApplied: (sportType, location) {
          setState(() {
            _selectedSportType = sportType;
            _selectedLocation = location;
          });
        },
        onFiltersCleared: () {
          setState(() {
            _selectedSportType = null;
            _selectedLocation = null;
          });
        },
      ),
    );
  }

  void _showAddVenueScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddVenueScreen(),
      ),
    );
  }

  void _navigateToVenueDetail(VenueModel venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueDetailScreen(venue: venue),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'my_bookings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyVenueBookingsScreen(),
          ),
        );
        break;
      case 'owner_bookings':
        _showOwnerBookingsScreen();
        break;
    }
  }

  void _showOwnerBookingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OwnerBookingsScreen(),
      ),
    );
  }
}
