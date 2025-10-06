import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/listing_model.dart';
import '../models/tournament_model.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_filters.dart';

/// Enhanced tournament discovery screen with filters and search
class TournamentDiscoveryScreen extends StatefulWidget {
  const TournamentDiscoveryScreen({super.key});

  @override
  State<TournamentDiscoveryScreen> createState() => _TournamentDiscoveryScreenState();
}

class _TournamentDiscoveryScreenState extends State<TournamentDiscoveryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter state
  SportType? _selectedSportType;
  TournamentFormat? _selectedFormat;
  TournamentStatus? _selectedStatus;
  double? _maxEntryFee;
  String? _location;
  bool _showFreeOnly = false;
  bool _showPaidOnly = false;

  // Search and sort
  String _searchQuery = '';
  TournamentSortOption _sortOption = TournamentSortOption.startDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Discover Tournaments',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.primary,
          unselectedLabelColor: ColorsManager.textSecondary,
          indicatorColor: ColorsManager.primary,
          tabs: const [
            Tab(text: 'All Tournaments'),
            Tab(text: 'Nearby'),
            Tab(text: 'My Level'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
          ),
          IconButton(
            onPressed: _showSortOptions,
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildActiveFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentList(),
                _buildNearbyTournaments(),
                _buildLevelBasedTournaments(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: ColorsManager.surface,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tournaments...',
          hintStyle: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: ColorsManager.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.clear,
                    color: ColorsManager.textSecondary,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: ColorsManager.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: ColorsManager.primary),
          ),
          filled: true,
          fillColor: ColorsManager.cardBackground,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _performSearch();
        },
      ),
    );
  }

  Widget _buildActiveFilters() {
    final activeFilters = <Widget>[];
    
    if (_selectedSportType != null) {
      activeFilters.add(_buildFilterChip(
        '${_selectedSportType!.displayName}',
        () => setState(() => _selectedSportType = null),
      ));
    }
    
    if (_selectedFormat != null) {
      activeFilters.add(_buildFilterChip(
        '${_selectedFormat!.displayName}',
        () => setState(() => _selectedFormat = null),
      ));
    }
    
    if (_selectedStatus != null) {
      activeFilters.add(_buildFilterChip(
        '${_selectedStatus!.displayName}',
        () => setState(() => _selectedStatus = null),
      ));
    }
    
    if (_maxEntryFee != null) {
      activeFilters.add(_buildFilterChip(
        'Under \$${_maxEntryFee!.toStringAsFixed(0)}',
        () => setState(() => _maxEntryFee = null),
      ));
    }
    
    if (_showFreeOnly) {
      activeFilters.add(_buildFilterChip(
        'Free Only',
        () => setState(() => _showFreeOnly = false),
      ));
    }
    
    if (_showPaidOnly) {
      activeFilters.add(_buildFilterChip(
        'Paid Only',
        () => setState(() => _showPaidOnly = false),
      ));
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Filters: ',
              style: TextStyles.font14DarkBlueMedium.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
            ...activeFilters,
            TextButton(
              onPressed: _clearAllFilters,
              child: Text(
                'Clear All',
                style: TextStyles.font14MainBlue500Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      child: Chip(
        label: Text(
          label,
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.primary,
          ),
        ),
        deleteIcon: const Icon(
          Icons.close,
          size: 16,
          color: ColorsManager.primary,
        ),
        onDeleted: onRemove,
        backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
        side: BorderSide(color: ColorsManager.primary.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildTournamentList() {
    return _buildTournamentGrid();
  }

  Widget _buildNearbyTournaments() {
    return _buildTournamentGrid(isNearby: true);
  }

  Widget _buildLevelBasedTournaments() {
    return _buildTournamentGrid(isLevelBased: true);
  }

  Widget _buildTournamentGrid({
    bool isNearby = false,
    bool isLevelBased = false,
  }) {
    // TODO: Replace with actual data from service
    final tournaments = <Tournament>[];

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
        ),
      );
    }

    if (tournaments.isEmpty) {
      return _buildEmptyState(
        isNearby ? 'No nearby tournaments' : 
        isLevelBased ? 'No tournaments for your level' : 'No tournaments found',
        isNearby ? 'Try expanding your search area' :
        isLevelBased ? 'Check back later for tournaments matching your skill level' :
        'Try adjusting your filters or search terms',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTournaments,
      child: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final tournament = tournaments[index];
          return TournamentCard(
            tournament: tournament,
            onTap: () => _navigateToTournamentDetail(tournament),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_cricket_outlined,
              size: 64.sp,
              color: ColorsManager.textSecondary,
            ),
            Gap(16.h),
            Text(
              title,
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              subtitle,
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TournamentFilters(
        selectedSportType: _selectedSportType,
        selectedFormat: _selectedFormat,
        selectedStatus: _selectedStatus,
        maxEntryFee: _maxEntryFee,
        location: _location,
        showFreeOnly: _showFreeOnly,
        showPaidOnly: _showPaidOnly,
        onApply: (filters) {
          setState(() {
            _selectedSportType = filters.sportType;
            _selectedFormat = filters.format;
            _selectedStatus = filters.status;
            _maxEntryFee = filters.maxEntryFee;
            _location = filters.location;
            _showFreeOnly = filters.showFreeOnly;
            _showPaidOnly = filters.showPaidOnly;
          });
          _performSearch();
        },
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort Tournaments',
              style: TextStyles.font18DarkBlueBold,
            ),
            Gap(16.h),
            ...TournamentSortOption.values.map((option) => ListTile(
              title: Text(option.displayName),
              leading: Radio<TournamentSortOption>(
                value: option,
                groupValue: _sortOption,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortOption = value;
                    });
                    Navigator.pop(context);
                    _performSearch();
                  }
                },
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _performSearch();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedSportType = null;
      _selectedFormat = null;
      _selectedStatus = null;
      _maxEntryFee = null;
      _location = null;
      _showFreeOnly = false;
      _showPaidOnly = false;
    });
    _performSearch();
  }

  void _performSearch() {
    // TODO: Implement actual search logic
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _refreshTournaments() async {
    _performSearch();
  }

  void _navigateToTournamentDetail(Tournament tournament) {
    // TODO: Navigate to tournament detail screen
  }
}

/// Tournament sort options
enum TournamentSortOption {
  startDate,
  entryFee,
  prizePool,
  popularity,
  distance;

  String get displayName {
    switch (this) {
      case TournamentSortOption.startDate:
        return 'Start Date';
      case TournamentSortOption.entryFee:
        return 'Entry Fee';
      case TournamentSortOption.prizePool:
        return 'Prize Pool';
      case TournamentSortOption.popularity:
        return 'Popularity';
      case TournamentSortOption.distance:
        return 'Distance';
    }
  }
}
