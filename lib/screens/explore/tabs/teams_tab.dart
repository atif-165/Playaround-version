import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../data/models/team_model.dart' as legacy;
import '../../../data/repositories/discovery_repository.dart';
import '../../../modules/team/models/models.dart';
import '../../../services/location_service.dart';
import '../widgets/team_discovery_card.dart';

/// Teams tab for explore screen
class TeamsTab extends StatefulWidget {
  const TeamsTab({
    super.key,
    required this.searchQuery,
    required this.filters,
  });

  final String searchQuery;
  final Map<String, dynamic> filters;

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  final DiscoveryRepository _repository = DiscoveryRepository();
  final LocationService _locationService = LocationService();

  List<legacy.TeamModel> _teams = [];
  List<legacy.TeamModel> _filteredTeams = [];
  bool _loading = true;
  String? _error;
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  void didUpdateWidget(covariant TeamsTab oldWidget) {
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
      _teams = await _repository.loadTeams();
      _applyFilters();
    } catch (error) {
      setState(() {
        _error = 'Failed to load teams';
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final query = widget.searchQuery.toLowerCase();
    final sportsFilter =
        (widget.filters['sports'] as List<dynamic>? ?? const []).cast<String>();
    final radiusKm = widget.filters['radiusKm'] as double?;

    final List<legacy.TeamModel> filtered = _teams.where((team) {
      final matchesSearch = query.isEmpty ||
          team.name.toLowerCase().contains(query) ||
          team.city.toLowerCase().contains(query);

      final matchesSport = sportsFilter.isEmpty ||
          sportsFilter.any(
            (sport) => team.sport.toLowerCase().contains(sport.toLowerCase()),
          );

      final matchesDistance = radiusKm == null ||
          _userLocation == null ||
          _distanceFor(team) != null && _distanceFor(team)! <= radiusKm;

      return matchesSearch && matchesSport && matchesDistance;
    }).toList();

    if (_userLocation != null) {
      filtered.sort((a, b) {
        final distanceA = _distanceFor(a) ?? double.infinity;
        final distanceB = _distanceFor(b) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }

    setState(() {
      _filteredTeams = filtered;
      _loading = false;
      _error = null;
    });
  }

  double? _distanceFor(legacy.TeamModel team) {
    if (_userLocation == null) return null;
    final geo = _locationService.getApproximateLocationFromString(team.city);
    if (geo == null) return null;
    return _locationService.calculateDistance(_userLocation!, geo);
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

    if (_filteredTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 48.sp, color: Colors.grey[400]),
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
        itemCount: _filteredTeams.length,
        itemBuilder: (context, index) {
          final team = _filteredTeams[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: TeamDiscoveryCard(
              team: team,
              distanceKm: _distanceFor(team),
              onTap: () => _onTeamTap(team),
            ),
          );
        },
      ),
    );
  }

  void _onTeamTap(legacy.TeamModel team) {
    final teamModel = Team(
      id: team.id,
      name: team.name,
      description: '',
      sportType: _getSportTypeFromString(team.sport),
      ownerId: team.memberIds.isEmpty ? '' : team.memberIds.first,
      members: [],
      location: team.city,
      teamImageUrl: team.logoUrl,
      createdAt: team.createdAt,
      updatedAt: team.updatedAt,
    );

    Navigator.pushNamed(
      context,
      '/teamProfileScreen',
      arguments: teamModel,
    );
  }

  SportType _getSportTypeFromString(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'cricket':
        return SportType.cricket;
      case 'football':
        return SportType.football;
      case 'basketball':
        return SportType.basketball;
      case 'volleyball':
        return SportType.volleyball;
      case 'tennis':
        return SportType.tennis;
      case 'badminton':
        return SportType.badminton;
      default:
        return SportType.other;
    }
  }
}
