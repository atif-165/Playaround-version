import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../models/coach_profile.dart';
import '../../../routing/routes.dart';
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
            coach.specializationSports
                .any((sport) => sport.toLowerCase().contains(query));
      }).toList();
    }

    // Apply sport filters
    if (_selectedSportFilters.isNotEmpty) {
      filtered = filtered.where((coach) {
        return coach.specializationSports
            .any((sport) => _selectedSportFilters.contains(sport));
      }).toList();
    }

    setState(() {
      _filteredCoaches = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF11123D),
              Color(0xFF070616),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScreenHeader(),
              Gap(18.h),
              _buildSearchAndFilters(),
              _buildActiveFilters(),
              Gap(12.h),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isLoading
                      ? const Center(child: CustomProgressIndicator())
                      : _buildCoachesList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Your Perfect Coach',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(6.h),
                Text(
                  'Browse curated professional coaches, filtered by sport, goals and vibe.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          if (_isCurrentUserCoach)
            IconButton(
              onPressed: _navigateToMyProfile,
              icon: const Icon(
                Icons.person,
                color: Colors.white,
              ),
              tooltip: 'My Coach Profile',
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                    cursorColor: ColorsManager.primary,
                    decoration: InputDecoration(
                      hintText: 'Search by coach, sport, or speciality',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: ColorsManager.primary.withOpacity(0.9),
                        size: 22.sp,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              splashRadius: 18.r,
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.white.withOpacity(0.6),
                                size: 18.sp,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Gap(12.w),
                ElevatedButton.icon(
                  onPressed: _showFilterDialog,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    backgroundColor: ColorsManager.primary.withOpacity(0.18),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 18.sp,
                  ),
                  label: Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (_selectedSportFilters.isEmpty && _searchController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final chips = [
      if (_searchController.text.isNotEmpty)
        _ActiveFilterChip(
          label: 'Query: "${_searchController.text}"',
          onRemove: () {
            _searchController.clear();
            _applyFilters();
          },
        ),
      ..._selectedSportFilters.map(
        (sport) => _ActiveFilterChip(
          label: sport,
          onRemove: () {
            setState(() {
              _selectedSportFilters.remove(sport);
              _applyFilters();
            });
          },
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(top: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .expand((chip) => [chip, Gap(10.w)])
              .toList()
            ..removeLast(),
        ),
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
                        final isSelected =
                            _selectedSportFilters.contains(sport);
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
                          selectedColor:
                              ColorsManager.primary.withValues(alpha: 0.2),
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
      return RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Icon(
              Icons.self_improvement_outlined,
              size: 84.sp,
              color: Colors.white.withOpacity(0.25),
            ),
            Gap(20.h),
            Center(
              child: Text(
                'No coaches match your filters',
                style: TextStyles.font16DarkBlueBold.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Gap(10.h),
            Center(
              child: Text(
                'Try browsing all sports or refining your search keywords.',
                style: TextStyles.font14Grey400Weight.copyWith(
                  color: Colors.white.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 220.h),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 26.h),
        itemCount: _filteredCoaches.length,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        separatorBuilder: (_, __) => Gap(18.h),
        itemBuilder: (context, index) {
          final coach = _filteredCoaches[index];
          return Hero(
            tag: 'coach-${coach.uid}',
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
    try {
      final currentCoachProfile =
          await _coachService.getCurrentUserCoachProfile();
      if (currentCoachProfile != null) {
        // Navigate to profile edit screen instead of detail screen
        Navigator.of(context).pushNamed(
          Routes.coachProfileEditScreen,
          arguments: currentCoachProfile,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coach profile not found. Please complete your profile setup.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(8.w),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.16),
              ),
              padding: EdgeInsets.all(4.w),
              child: Icon(
                Icons.close,
                size: 12.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
