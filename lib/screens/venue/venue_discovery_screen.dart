import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/widgets/error_widget.dart';
import '../../core/widgets/progress_indicaror.dart';
import '../../models/venue.dart';
import '../../models/venue_review.dart';
import '../../services/venue_service.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../venue/venue_profile_screen.dart';
import '../venue/widgets/venue_filters_bottom_sheet.dart';
import '../venue/widgets/venue_showcase_card.dart';

class VenueDiscoveryScreen extends StatefulWidget {
  const VenueDiscoveryScreen({super.key});

  @override
  State<VenueDiscoveryScreen> createState() => _VenueDiscoveryScreenState();
}

class _VenueDiscoveryScreenState extends State<VenueDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Venue> _venues = [];
  List<Venue> _filteredVenues = [];
  bool _isLoading = true;
  String? _error;
  VenueFilter _currentFilter = VenueFilter();

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVenues({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      // Test direct fetch first (commented out - for debugging only)
      // await VenueService.testFetchVenues();
      
      final venues = await VenueService.getVenues(
        filter: _currentFilter,
      );

      if (!mounted) return;

      print('🔍 VenueDiscoveryScreen: Received ${venues.length} venues from service');
      
      final activeVenues =
          venues.where((venue) => venue.isActive).toList(growable: false);
      
      print('🔍 VenueDiscoveryScreen: ${activeVenues.length} active venues after filtering');
      
      // Use actual venues from Firestore, not fallback
      // Only use fallback if there's an error, not if list is empty
      final resolvedVenues = activeVenues;
      
      if (resolvedVenues.isEmpty && venues.isNotEmpty) {
        print('⚠️ Warning: All ${venues.length} venues are inactive');
      } else if (resolvedVenues.isEmpty) {
        print('⚠️ Warning: No venues fetched from Firestore');
      }

      setState(() {
        _venues = resolvedVenues;
        _filteredVenues = _filterVenues(resolvedVenues);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Venue> _filterVenues(List<Venue> source) {
    final query = _currentFilter.searchQuery?.trim().toLowerCase() ?? '';
    if (query.isEmpty) {
      return List<Venue>.from(source);
    }

    return source.where((venue) {
      final loweredQuery = query;
      final loweredName = venue.name.toLowerCase();
      final loweredDescription = venue.description.toLowerCase();
      final loweredAddress = venue.address.toLowerCase();
      final sportsMatch = venue.sports
          .any((sport) => sport.toLowerCase().contains(loweredQuery));

      return loweredName.contains(loweredQuery) ||
          loweredDescription.contains(loweredQuery) ||
          loweredAddress.contains(loweredQuery) ||
          sportsMatch;
    }).toList();
  }

  void _onSearchChanged(String query) {
    final trimmedQuery = query.trim();

    setState(() {
      _currentFilter = trimmedQuery.isEmpty
          ? _currentFilter.copyWith(searchQuery: '')
          : _currentFilter.copyWith(searchQuery: trimmedQuery);
      _filteredVenues = _filterVenues(_venues);
    });
  }

  Future<void> _showFilters() async {
    final VenueFilter? result = await showModalBottomSheet<VenueFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VenueFiltersBottomSheet(
        currentFilter: _currentFilter,
        onApplyFilters: (filter) {
          setState(() {
            _currentFilter = filter;
          });
          _loadVenues();
        },
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
        if (result.searchQuery != null) {
          _searchController.text = result.searchQuery!;
        }
      });
      _loadVenues();
    }
  }

  void _navigateToVenueProfile(Venue venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueProfileScreen(venue: venue),
      ),
    );
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _currentFilter = VenueFilter();
      _filteredVenues = _venues;
    });
    _loadVenues();
  }

  void _removeFilterChip(String type, [String? value]) {
    setState(() {
      switch (type) {
        case 'query':
          _searchController.clear();
          _currentFilter = _currentFilter.copyWith(searchQuery: '');
          break;
        case 'sport':
          final sports = [..._currentFilter.sports]..remove(value);
          _currentFilter = _currentFilter.copyWith(sports: sports);
          break;
        case 'city':
          _currentFilter = _currentFilter.copyWith(city: null);
          break;
        case 'price':
          _currentFilter =
              _currentFilter.copyWith(minPrice: null, maxPrice: null);
          break;
        case 'rating':
          _currentFilter = _currentFilter.copyWith(minRating: null);
          break;
        case 'verified':
          _currentFilter = _currentFilter.copyWith(isVerified: null);
          break;
      }
      _filteredVenues = _filterVenues(_venues);
    });
    _loadVenues();
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
              Gap(16.h),
              _buildScreenHeader(),
              Gap(20.h),
              _buildSearchAndFilters(),
              _buildActiveFilters(),
              Gap(16.h),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildContent(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Premium Venues',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(6.h),
                Text(
                  'Book elite facilities with verified amenities and pro-grade surfaces.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (_currentFilter.isActive)
            TextButton(
              onPressed: _resetFilters,
              child: Text(
                'Clear',
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by venue, sport, or location',
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
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Gap(12.w),
                ElevatedButton.icon(
                  onPressed: _showFilters,
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
    final chips = <Widget>[];

    if (_currentFilter.searchQuery?.isNotEmpty ?? false) {
      chips.add(
        _ActiveFilterChip(
          label: 'Query: "${_currentFilter.searchQuery}"',
          onRemove: () => _removeFilterChip('query'),
        ),
      );
    }

    for (final sport in _currentFilter.sports) {
      chips.add(
        _ActiveFilterChip(
          label: sport,
          onRemove: () => _removeFilterChip('sport', sport),
        ),
      );
    }

    if (_currentFilter.city != null && _currentFilter.city!.isNotEmpty) {
      chips.add(
        _ActiveFilterChip(
          label: _currentFilter.city!,
          onRemove: () => _removeFilterChip('city'),
        ),
      );
    }

    if (_currentFilter.minPrice != null || _currentFilter.maxPrice != null) {
      final min = _currentFilter.minPrice?.toInt();
      final max = _currentFilter.maxPrice?.toInt();
      final labelSegments = <String>[];
      if (min != null) {
        labelSegments.add('Min ${min.toString()}');
      }
      if (max != null) {
        labelSegments.add('Max ${max.toString()}');
      }
      final label = labelSegments.join(' • ');

      chips.add(
        _ActiveFilterChip(
          label: label.isEmpty ? 'Price filter' : label,
          onRemove: () => _removeFilterChip('price'),
        ),
      );
    }

    if (_currentFilter.minRating != null) {
      chips.add(
        _ActiveFilterChip(
          label: 'Rated ${_currentFilter.minRating!.toStringAsFixed(1)}+',
          onRemove: () => _removeFilterChip('rating'),
        ),
      );
    }

    if (_currentFilter.isVerified == true) {
      chips.add(
        _ActiveFilterChip(
          label: 'Verified only',
          onRemove: () => _removeFilterChip('verified'),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(top: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              chips[i],
              if (i != chips.length - 1) Gap(10.w),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CustomProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: AppErrorWidget(
          message: _error!,
          onRetry: () => _loadVenues(),
        ),
      );
    }

    if (_filteredVenues.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadVenues(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
          children: [
            Icon(
              Icons.location_city_rounded,
              size: 72.sp,
              color: Colors.white.withOpacity(0.35),
            ),
            Gap(24.h),
            Text(
              'No venues match your filters',
              textAlign: TextAlign.center,
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: Colors.white,
              ),
            ),
            Gap(12.h),
            Text(
              'Try adjusting your filters or clear them to explore our full venue lineup.',
              textAlign: TextAlign.center,
              style: TextStyles.font14Grey400Weight.copyWith(
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            Gap(24.h),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: const Text('Show all venues'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadVenues(showLoader: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        itemBuilder: (context, index) {
          final venue = _filteredVenues[index];
          return VenueShowcaseCard(
            venue: venue,
            onTap: () => _navigateToVenueProfile(venue),
          );
        },
        separatorBuilder: (_, __) => Gap(18.h),
        itemCount: _filteredVenues.length,
      ),
    );
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyles.font12White500Weight.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          Gap(6.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14.sp,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

final List<Venue> _fallbackVenues = _buildFallbackVenues();

List<Venue> _buildFallbackVenues() {
  final weeklyHours = {
    'Monday': DayHours(isOpen: true, openTime: '06:00', closeTime: '22:00'),
    'Tuesday': DayHours(isOpen: true, openTime: '06:00', closeTime: '22:00'),
    'Wednesday': DayHours(isOpen: true, openTime: '06:00', closeTime: '22:00'),
    'Thursday': DayHours(isOpen: true, openTime: '06:00', closeTime: '22:00'),
    'Friday': DayHours(isOpen: true, openTime: '06:00', closeTime: '22:00'),
    'Saturday': DayHours(isOpen: true, openTime: '08:00', closeTime: '23:00'),
    'Sunday': DayHours(isOpen: true, openTime: '08:00', closeTime: '21:00'),
  };

  Venue createVenue({
    required String id,
    required String name,
    required String description,
    required String address,
    required String city,
    required double latitude,
    required double longitude,
    required List<String> sports,
    required List<String> images,
    required List<String> amenities,
    required double hourlyRate,
    double rating = 4.7,
    int totalReviews = 48,
    bool isVerified = true,
    String? phoneNumber,
    String? googleMapsLink,
  }) {
    final now = DateTime.now().toUtc();

    return Venue(
      id: id,
      name: name,
      description: description,
      address: address,
      city: city,
      state: 'Punjab',
      country: 'Pakistan',
      latitude: latitude,
      longitude: longitude,
      sports: sports,
      images: images,
      amenities: amenities
          .map(
            (amenity) => VenueAmenity(
              id: '${id}_$amenity',
              name: amenity,
              icon: '',
              description: amenity,
              isAvailable: true,
            ),
          )
          .toList(),
      pricing: VenuePricing(
        hourlyRate: hourlyRate,
        dailyRate: hourlyRate * 6,
        weeklyRate: hourlyRate * 25,
        currency: 'PKR',
      ),
      hours: VenueHours(
        weeklyHours: weeklyHours.map(
          (key, value) => MapEntry(key, value),
        ),
      ),
      rating: rating,
      totalReviews: totalReviews,
      coachIds: const [],
      isVerified: isVerified,
      ownerId: 'playaround_demo',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isActive: true,
      phoneNumber: phoneNumber,
      googleMapsLink: googleMapsLink,
      metadata: {
        'phoneNumber': phoneNumber,
        'googleMapsLink': googleMapsLink,
        'sportsOffered': sports,
      }..removeWhere((key, value) => value == null),
    );
  }

  return [
    createVenue(
      id: 'demo_prime_tennis',
      name: 'Prime Tennis Academy',
      description:
          'Professional tennis hub with acrylic courts, flood lighting, and certified coaching support.',
      address: 'Rawalpindi, Pakistan',
      city: 'Rawalpindi',
      latitude: 33.5842918415,
      longitude: 73.0350594106,
      sports: const ['Tennis'],
      images: const [
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1628779238951-1dc555961fdd?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=1920&auto=format&fit=crop',
      ],
      amenities: const [
        'Parking',
        'Changing Rooms',
        'Showers',
        'Equipment Rental',
        'Café',
        'First Aid',
      ],
      hourlyRate: 1000,
      rating: 4.9,
      totalReviews: 76,
      phoneNumber: '(+92) 300-1234567',
      googleMapsLink:
          'https://www.google.com/maps/dir/?api=1&destination=33.5842918415,73.0350594106',
    ),
    createVenue(
      id: 'demo_aurora_dome',
      name: 'Aurora Sports Dome',
      description:
          'Climate-controlled multi-sport arena with LED lighting and a pro-grade sprint track.',
      address: 'Islamabad, Pakistan',
      city: 'Islamabad',
      latitude: 33.6844,
      longitude: 73.0479,
      sports: const ['Football', 'Futsal', 'Athletics'],
      images: const [
        'https://images.unsplash.com/photo-1517976487492-5750f3195933?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1508606572321-901ea443707f?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1502810190503-8303352d0dd1?w=1920&auto=format&fit=crop',
      ],
      amenities: const [
        'Locker Rooms',
        'LED Lighting',
        'On-site Cafe',
        'Recovery Lounge',
      ],
      hourlyRate: 1900,
      phoneNumber: '(+92) 345-9876543',
      googleMapsLink:
          'https://www.google.com/maps/dir/?api=1&destination=33.6844,73.0479',
    ),
    createVenue(
      id: 'demo_velocity_cricket',
      name: 'Velocity Cricket Arena',
      description:
          'High-performance cricket center with turf wickets, Hawk-Eye analytics, and a coach lounge.',
      address: 'Rawalpindi, Pakistan',
      city: 'Rawalpindi',
      latitude: 33.6261,
      longitude: 72.9980,
      sports: const ['Cricket'],
      images: const [
        'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1517341722334-15d20b7daeba?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?w=1920&auto=format&fit=crop',
      ],
      amenities: const [
        'Practice Nets',
        'Coach Lounge',
        'Live Scoreboard',
        'Sports Physio',
      ],
      hourlyRate: 2100,
      phoneNumber: '(+92) 321-4455667',
      googleMapsLink:
          'https://www.google.com/maps/dir/?api=1&destination=33.6261,72.9980',
    ),
    createVenue(
      id: 'demo_summit_complex',
      name: 'Summit Multi-Sports Complex',
      description:
          'Indoor-outdoor hybrid facility covering basketball, volleyball, and track events with spa access.',
      address: 'Karachi, Pakistan',
      city: 'Karachi',
      latitude: 24.8607,
      longitude: 67.0011,
      sports: const ['Basketball', 'Volleyball', 'Athletics'],
      images: const [
        'https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1465311440653-ba9b1d9b0f5b?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1508609349937-5ec4ae374ebf?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1509228627152-72ae9ae6848d?w=1920&auto=format&fit=crop',
      ],
      amenities: const [
        'Indoor Track',
        'Spa & Sauna',
        'Nutrition Kiosk',
        'Strength Lab',
      ],
      hourlyRate: 2400,
      phoneNumber: '(+92) 300-7788990',
      googleMapsLink:
          'https://www.google.com/maps/dir/?api=1&destination=24.8607,67.0011',
    ),
    createVenue(
      id: 'demo_zenith_courts',
      name: 'Zenith Tennis Courts',
      description:
          'Six-court professional tennis academy with shaded spectator decks and a hydration bar.',
      address: 'Lahore, Pakistan',
      city: 'Lahore',
      latitude: 31.5204,
      longitude: 74.3587,
      sports: const ['Tennis', 'Pickleball'],
      images: const [
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1499028344343-cd173ffc68a9?w=1920&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1920&auto=format&fit=crop',
      ],
      amenities: const [
        'Ball Machine',
        'Shaded Seating',
        'Hydration Bar',
        'Stringing Pro Shop',
      ],
      hourlyRate: 1700,
      phoneNumber: '(+92) 301-2233445',
      googleMapsLink:
          'https://www.google.com/maps/dir/?api=1&destination=31.5204,74.3587',
    ),
  ];
}
