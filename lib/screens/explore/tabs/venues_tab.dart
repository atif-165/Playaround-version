import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../../models/geo_models.dart';
import '../../../services/location_service.dart';
import '../widgets/venue_card.dart';
import '../../../core/widgets/progress_indicaror.dart';

/// Venues tab for explore screen
class VenuesTab extends StatefulWidget {
  final String searchQuery;
  final Map<String, dynamic> filters;

  const VenuesTab({
    super.key,
    required this.searchQuery,
    required this.filters,
  });

  @override
  State<VenuesTab> createState() => _VenuesTabState();
}

class _VenuesTabState extends State<VenuesTab> {
  final LocationService _locationService = LocationService();
  List<GeoVenue> _venues = [];
  bool _isLoading = true;
  String? _error;
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void didUpdateWidget(VenuesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.filters != widget.filters) {
      _loadVenues();
    }
  }

  Future<void> _initializeLocation() async {
    _userLocation = await _locationService.getCurrentLocation();
    await _loadVenues();
  }

  Future<void> _loadVenues() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get venues from Firestore
      Query query = FirebaseFirestore.instance.collection('venues');

      // Apply search filter
      if (widget.searchQuery.isNotEmpty) {
        query = query.where('title', 
            isGreaterThanOrEqualTo: widget.searchQuery)
            .where('title', 
            isLessThanOrEqualTo: '${widget.searchQuery}\uf8ff');
      }

      // Apply sport filter
      if (widget.filters['sports'] != null && 
          (widget.filters['sports'] as List).isNotEmpty) {
        query = query.where('sportType', 
            whereIn: widget.filters['sports']);
      }

      // Apply active filter
      query = query.where('isActive', isEqualTo: true);

      final querySnapshot = await query.get();
      
      List<GeoVenue> venues = querySnapshot.docs
          .map((doc) => GeoVenue.fromFirestore(doc))
          .toList();

      // Apply distance filter if user location is available
      if (_userLocation != null && widget.filters['radiusKm'] != null) {
        final radiusKm = widget.filters['radiusKm'] as double;
        venues = venues.where((venue) {
          if (venue.geoPoint == null) {
            // Try to get approximate location from string
            final approxLocation = _locationService
                .getApproximateLocationFromString(venue.location);
            if (approxLocation != null) {
              final distance = _locationService
                  .calculateDistance(_userLocation!, approxLocation);
              return distance <= radiusKm;
            }
            return false;
          }
          
          final distance = _locationService
              .calculateDistance(_userLocation!, venue.geoPoint!);
          return distance <= radiusKm;
        }).toList();
      }

      // Sort by distance if user location is available
      if (_userLocation != null) {
        venues = _locationService.sortByDistance<GeoVenue>(
          venues,
          _userLocation!,
          (venue) => venue.geoPoint ?? 
              _locationService.getApproximateLocationFromString(venue.location) ??
              const GeoPoint(0, 0),
        );
      }

      if (mounted) {
        setState(() {
          _venues = venues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load venues: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CustomProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            ElevatedButton(
              onPressed: _loadVenues,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_venues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No venues found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Gap(8.h),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVenues,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _venues.length,
        itemBuilder: (context, index) {
          final venue = _venues[index];
          double? distance;
          
          if (_userLocation != null) {
            final venueLocation = venue.geoPoint ?? 
                _locationService.getApproximateLocationFromString(venue.location);
            if (venueLocation != null) {
              distance = _locationService.calculateDistance(
                _userLocation!, 
                venueLocation,
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: VenueCard(
              venue: venue,
              distance: distance,
              onTap: () => _onVenueTap(venue),
            ),
          );
        },
      ),
    );
  }

  void _onVenueTap(GeoVenue venue) {
    // Navigate to venue details
    // TODO: Implement venue details navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Venue details for ${venue.title}')),
    );
  }
}
