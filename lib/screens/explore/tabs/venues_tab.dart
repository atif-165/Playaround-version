import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../data/models/venue_model.dart';
import '../../../data/repositories/discovery_repository.dart';
import '../../../services/location_service.dart';
import '../widgets/venue_discovery_card.dart';

/// Venues tab for explore screen
class VenuesTab extends StatefulWidget {
  const VenuesTab({
    super.key,
    required this.searchQuery,
    required this.filters,
  });

  final String searchQuery;
  final Map<String, dynamic> filters;

  @override
  State<VenuesTab> createState() => _VenuesTabState();
}

class _VenuesTabState extends State<VenuesTab> {
  final DiscoveryRepository _repository = DiscoveryRepository();
  final LocationService _locationService = LocationService();

  List<VenueModel> _venues = [];
  List<VenueModel> _filteredVenues = [];
  bool _loading = true;
  String? _error;
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  void didUpdateWidget(covariant VenuesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.filters != widget.filters) {
      _applyFilters();
    }
  }

  Future<void> _initialLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _userLocation = await _locationService.getCurrentLocation();
      _venues = await _repository.loadVenues();
      _applyFilters();
    } catch (error) {
      setState(() {
        _loading = false;
        _error = 'Failed to load venues';
      });
    }
  }

  void _applyFilters() {
    final query = widget.searchQuery.toLowerCase();
    final sportsFilter =
        (widget.filters['sports'] as List<dynamic>? ?? const []).cast<String>();
    final radiusKm = widget.filters['radiusKm'] as double?;

    List<VenueModel> filtered = _venues.where((venue) {
      final matchesSearch = query.isEmpty ||
          venue.name.toLowerCase().contains(query) ||
          venue.city.toLowerCase().contains(query);
      final matchesSports = sportsFilter.isEmpty ||
          venue.sports.any(
            (sport) => sportsFilter.any(
              (selected) =>
                  sport.toLowerCase().contains(selected.toLowerCase()),
            ),
          );
      final matchesDistance = radiusKm == null ||
          _userLocation == null ||
          _distanceFor(venue) != null && _distanceFor(venue)! <= radiusKm;

      return matchesSearch && matchesSports && matchesDistance;
    }).toList();

    if (_userLocation != null) {
      filtered.sort((a, b) {
        final distanceA = _distanceFor(a) ?? double.infinity;
        final distanceB = _distanceFor(b) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }

    setState(() {
      _filteredVenues = filtered;
      _loading = false;
      _error = null;
    });
  }

  double? _distanceFor(VenueModel venue) {
    if (_userLocation == null ||
        venue.latitude == null ||
        venue.longitude == null) {
      return null;
    }
    final venuePoint = GeoPoint(venue.latitude!, venue.longitude!);
    return _locationService.calculateDistance(_userLocation!, venuePoint);
  }

  Future<void> _refresh() async {
    await _initialLoad();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CustomProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.grey[400]),
            Gap(16.h),
            Text(
              _error!,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            ElevatedButton(
              onPressed: _initialLoad,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredVenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city_outlined,
                size: 48.sp, color: Colors.grey[400]),
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
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _filteredVenues.length,
        itemBuilder: (context, index) {
          final venue = _filteredVenues[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: VenueDiscoveryCard(
              venue: venue,
              distanceKm: _distanceFor(venue),
              onTap: () => _onVenueTap(venue),
            ),
          );
        },
      ),
    );
  }

  void _onVenueTap(VenueModel venue) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Venue details for ${venue.name} coming soon')),
    );
  }
}
