import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../models/coach_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/coach_service.dart';
import '../widgets/coach_profile_card.dart';
import 'coach_detail_screen.dart';

/// Screen displaying all available coaches with search and filter functionality
class CoachListingScreen extends StatefulWidget {
  const CoachListingScreen({super.key});

  @override
  State<CoachListingScreen> createState() => _CoachListingScreenState();
}

class _CoachListingScreenState extends State<CoachListingScreen> {
  final CoachService _coachService = CoachService();
  final TextEditingController _searchController = TextEditingController();
  
  List<CoachProfile> _allCoaches = [];
  List<CoachProfile> _filteredCoaches = [];
  List<String> _availableSports = [];
  final List<String> _selectedSportFilters = [];
  bool _isLoading = true;
  bool _isCurrentUserCoach = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if current user is a coach
      _isCurrentUserCoach = await _coachService.isCurrentUserCoach();
      
      // Load available sports for filtering
      _availableSports = await _coachService.getAvailableSports();
      
      // Load coaches
      _coachService.getCoaches().listen((coaches) {
        if (mounted) {
          setState(() {
            _allCoaches = coaches;
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
            content: Text('Failed to load coaches: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    List<CoachProfile> filtered = _allCoaches;

    // Apply search filter
    if (query.isNotEmpty) {
      filtered = filtered.where((coach) {
        return coach.fullName.toLowerCase().contains(query) ||
               (coach.bio?.toLowerCase().contains(query) ?? false) ||
               coach.specializationSports.any((sport) => 
                   sport.toLowerCase().contains(query));
      }).toList();
    }

    // Apply sport filters
    if (_selectedSportFilters.isNotEmpty) {
      filtered = filtered.where((coach) {
        return coach.specializationSports.any((sport) => 
            _selectedSportFilters.contains(sport));
      }).toList();
    }

    setState(() {
      _filteredCoaches = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find a Coach',
          style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.primary),
        actions: [
          if (_isCurrentUserCoach)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: _navigateToMyProfile,
              tooltip: 'My Coach Profile',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CustomProgressIndicator())
                : _buildCoachesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search coaches by name, bio, or sport...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                  size: 20.sp,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[400],
                          size: 20.sp,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
          ),
          Gap(8.w),
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: _selectedSportFilters.isNotEmpty ? Colors.white : Colors.grey[400],
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: ColorsManager.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Filter Coaches',
                    style: TextStyles.font18DarkBlueBold,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSportFilters.clear();
                      });
                      _applyFilters();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyles.font14MainBlue500Weight,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sport Type',
                      style: TextStyles.font16DarkBlueBold,
                    ),
                    Gap(12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _availableSports.map((sport) {
                        final isSelected = _selectedSportFilters.contains(sport);
                        return FilterChip(
                          label: Text(sport),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSportFilters.add(sport);
                              } else {
                                _selectedSportFilters.remove(sport);
                              }
                            });
                          },
                          selectedColor: ColorsManager.primary.withValues(alpha: 0.2),
                          checkmarkColor: ColorsManager.primary,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: ColorsManager.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorsManager.textSecondary,
                        side: BorderSide(color: ColorsManager.textSecondary),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Gap(16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachesList() {
    if (_filteredCoaches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No coaches found',
              style: TextStyles.font16DarkBlueBold,
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
      onRefresh: _loadInitialData,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _filteredCoaches.length,
        itemBuilder: (context, index) {
          final coach = _filteredCoaches[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: CoachProfileCard(
              coach: coach,
              onTap: () => _navigateToCoachDetail(coach),
            ),
          );
        },
      ),
    );
  }

  void _navigateToCoachDetail(CoachProfile coach) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoachDetailScreen(coach: coach),
      ),
    );
  }

  void _navigateToMyProfile() async {
    final currentCoachProfile = await _coachService.getCurrentUserCoachProfile();
    if (currentCoachProfile != null) {
      _navigateToCoachDetail(currentCoachProfile);
    }
  }
}
