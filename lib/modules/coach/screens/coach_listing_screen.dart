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
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00FFFF), // Neon blue
            Color(0xFF0080FF), // Darker neon blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search coaches by name, bio, or sport...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          ),
          Gap(12.h),
          // Sport filters
          if (_availableSports.isNotEmpty) _buildSportFilters(),
        ],
      ),
    );
  }

  Widget _buildSportFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Filter by Sport:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (_selectedSportFilters.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSportFilters.clear();
                  });
                  _applyFilters();
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        Gap(8.h),
        SizedBox(
          height: 40.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableSports.length,
            itemBuilder: (context, index) {
              final sport = _availableSports[index];
              final isSelected = _selectedSportFilters.contains(sport);
              
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: FilterChip(
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
                    _applyFilters();
                  },
                  selectedColor: ColorsManager.primary,
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? ColorsManager.primary : Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white,
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
