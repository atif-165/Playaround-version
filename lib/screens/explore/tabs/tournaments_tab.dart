import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../../models/geo_models.dart';
import '../../../services/location_service.dart';
import '../widgets/tournament_card.dart';
import '../../../core/widgets/progress_indicaror.dart';

/// Tournaments tab for explore screen
class TournamentsTab extends StatefulWidget {
  final String searchQuery;
  final Map<String, dynamic> filters;

  const TournamentsTab({
    super.key,
    required this.searchQuery,
    required this.filters,
  });

  @override
  State<TournamentsTab> createState() => _TournamentsTabState();
}

class _TournamentsTabState extends State<TournamentsTab> {
  final LocationService _locationService = LocationService();
  List<GeoTournament> _tournaments = [];
  bool _isLoading = true;
  String? _error;
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void didUpdateWidget(TournamentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.filters != widget.filters) {
      _loadTournaments();
    }
  }

  Future<void> _initializeLocation() async {
    _userLocation = await _locationService.getCurrentLocation();
    await _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get tournaments from Firestore
      Query query = FirebaseFirestore.instance.collection('tournaments');

      // Apply search filter
      if (widget.searchQuery.isNotEmpty) {
        query = query.where('name', 
            isGreaterThanOrEqualTo: widget.searchQuery)
            .where('name', 
            isLessThanOrEqualTo: '${widget.searchQuery}\uf8ff');
      }

      // Apply sport filter
      if (widget.filters['sports'] != null && 
          (widget.filters['sports'] as List).isNotEmpty) {
        query = query.where('sportType', 
            whereIn: widget.filters['sports']);
      }

      // Apply public filter and upcoming tournaments
      query = query.where('isPublic', isEqualTo: true)
                  .where('status', whereIn: ['upcoming', 'registration_open']);

      final querySnapshot = await query.get();
      
      List<GeoTournament> tournaments = querySnapshot.docs
          .map((doc) => GeoTournament.fromFirestore(doc))
          .toList();

      // Apply distance filter if user location is available
      if (_userLocation != null && widget.filters['radiusKm'] != null) {
        final radiusKm = widget.filters['radiusKm'] as double;
        tournaments = tournaments.where((tournament) {
          if (tournament.geoPoint == null) {
            // Try to get approximate location from string
            final approxLocation = _locationService
                .getApproximateLocationFromString(tournament.location);
            if (approxLocation != null) {
              final distance = _locationService
                  .calculateDistance(_userLocation!, approxLocation);
              return distance <= radiusKm;
            }
            return false;
          }
          
          final distance = _locationService
              .calculateDistance(_userLocation!, tournament.geoPoint!);
          return distance <= radiusKm;
        }).toList();
      }

      // Sort by start date (upcoming first)
      tournaments.sort((a, b) => a.startDate.compareTo(b.startDate));

      // Then sort by distance if user location is available
      if (_userLocation != null) {
        tournaments = _locationService.sortByDistance<GeoTournament>(
          tournaments,
          _userLocation!,
          (tournament) => tournament.geoPoint ?? 
              _locationService.getApproximateLocationFromString(tournament.location) ??
              const GeoPoint(0, 0),
        );
      }

      if (mounted) {
        setState(() {
          _tournaments = tournaments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load tournaments: $e';
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
              onPressed: _loadTournaments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No tournaments found',
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
      onRefresh: _loadTournaments,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          final tournament = _tournaments[index];
          double? distance;
          
          if (_userLocation != null) {
            final tournamentLocation = tournament.geoPoint ?? 
                _locationService.getApproximateLocationFromString(tournament.location);
            if (tournamentLocation != null) {
              distance = _locationService.calculateDistance(
                _userLocation!, 
                tournamentLocation,
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: TournamentCard(
              tournament: tournament,
              distance: distance,
              onTap: () => _onTournamentTap(tournament),
            ),
          );
        },
      ),
    );
  }

  void _onTournamentTap(GeoTournament tournament) {
    // Navigate to tournament details
    // TODO: Implement tournament details navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tournament details for ${tournament.name}')),
    );
  }
}
