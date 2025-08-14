import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../../models/geo_models.dart';
import '../../../services/location_service.dart';
import '../widgets/team_card.dart';
import '../../../core/widgets/progress_indicaror.dart';

/// Teams tab for explore screen
class TeamsTab extends StatefulWidget {
  final String searchQuery;
  final Map<String, dynamic> filters;

  const TeamsTab({
    super.key,
    required this.searchQuery,
    required this.filters,
  });

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  final LocationService _locationService = LocationService();
  List<GeoTeam> _teams = [];
  bool _isLoading = true;
  String? _error;
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void didUpdateWidget(TeamsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.filters != widget.filters) {
      _loadTeams();
    }
  }

  Future<void> _initializeLocation() async {
    _userLocation = await _locationService.getCurrentLocation();
    await _loadTeams();
  }

  Future<void> _loadTeams() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get teams from Firestore
      Query query = FirebaseFirestore.instance.collection('teams');

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

      // Apply active and public filters
      query = query.where('isActive', isEqualTo: true)
                  .where('isPublic', isEqualTo: true);

      final querySnapshot = await query.get();
      
      List<GeoTeam> teams = querySnapshot.docs
          .map((doc) => GeoTeam.fromFirestore(doc))
          .toList();

      // Apply skill range filter
      if (widget.filters['minSkill'] != null && 
          widget.filters['maxSkill'] != null && 
          teams.isNotEmpty) {
        final minSkill = widget.filters['minSkill'] as int;
        final maxSkill = widget.filters['maxSkill'] as int;
        teams = teams.where((team) {
          if (team.skillAverage == null) return true;
          return team.skillAverage! >= minSkill && team.skillAverage! <= maxSkill;
        }).toList();
      }

      // Apply distance filter if user location is available
      if (_userLocation != null && widget.filters['radiusKm'] != null) {
        final radiusKm = widget.filters['radiusKm'] as double;
        teams = teams.where((team) {
          if (team.geoPoint == null) {
            // Try to get approximate location from string
            final approxLocation = _locationService
                .getApproximateLocationFromString(team.location);
            if (approxLocation != null) {
              final distance = _locationService
                  .calculateDistance(_userLocation!, approxLocation);
              return distance <= radiusKm;
            }
            return false;
          }
          
          final distance = _locationService
              .calculateDistance(_userLocation!, team.geoPoint!);
          return distance <= radiusKm;
        }).toList();
      }

      // Sort by distance if user location is available
      if (_userLocation != null) {
        teams = _locationService.sortByDistance<GeoTeam>(
          teams,
          _userLocation!,
          (team) => team.geoPoint ?? 
              _locationService.getApproximateLocationFromString(team.location) ??
              const GeoPoint(0, 0),
        );
      }

      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load teams: $e';
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
              onPressed: _loadTeams,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No teams found',
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
      onRefresh: _loadTeams,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _teams.length,
        itemBuilder: (context, index) {
          final team = _teams[index];
          double? distance;
          
          if (_userLocation != null) {
            final teamLocation = team.geoPoint ?? 
                _locationService.getApproximateLocationFromString(team.location);
            if (teamLocation != null) {
              distance = _locationService.calculateDistance(
                _userLocation!, 
                teamLocation,
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: TeamCard(
              team: team,
              distance: distance,
              onTap: () => _onTeamTap(team),
            ),
          );
        },
      ),
    );
  }

  void _onTeamTap(GeoTeam team) {
    // Navigate to team details
    // TODO: Implement team details navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Team details for ${team.name}')),
    );
  }
}
