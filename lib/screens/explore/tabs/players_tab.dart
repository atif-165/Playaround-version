import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../data/models/player_model.dart';
import '../../../data/repositories/discovery_repository.dart';
import '../../../services/location_service.dart';
import '../../../theming/colors.dart';
import '../screens/player_matchmaking_screen.dart';
import '../widgets/player_discovery_card.dart';

/// Players tab for explore screen
class PlayersTab extends StatefulWidget {
  const PlayersTab({
    super.key,
    required this.searchQuery,
    required this.filters,
  });

  final String searchQuery;
  final Map<String, dynamic> filters;

  @override
  State<PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends State<PlayersTab> {
  final DiscoveryRepository _repository = DiscoveryRepository();
  final LocationService _locationService = LocationService();

  List<PlayerModel> _players = [];
  bool _loading = true;
  String? _error;
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  void didUpdateWidget(covariant PlayersTab oldWidget) {
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
      final players = await _repository.loadPlayers();
      _players = players;
      _applyFilters();
    } catch (error) {
      setState(() {
        _error = 'Failed to load players';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _initialLoad();
  }

  List<PlayerModel> _filteredPlayers = [];

  void _applyFilters() {
    final query = widget.searchQuery.toLowerCase();
    final sportsFilter =
        (widget.filters['sports'] as List<dynamic>? ?? const []).cast<String>();
    final radiusKm = widget.filters['radiusKm'] as double?;
    final minSkill = widget.filters['minSkill'] as int?;
    final maxSkill = widget.filters['maxSkill'] as int?;

    List<PlayerModel> filtered = _players.where((player) {
      final matchesSearch = query.isEmpty ||
          player.fullName.toLowerCase().contains(query) ||
          player.location.toLowerCase().contains(query);

      final matchesSports = sportsFilter.isEmpty ||
          player.sports.any(
            (sport) => sportsFilter.any(
              (selected) =>
                  sport.toLowerCase().contains(selected.toLowerCase()),
            ),
          );

      final skillAverage = player.skillRatings.isEmpty
          ? player.experienceLevel * 100
          : player.skillRatings.values.reduce((a, b) => a + b) /
              player.skillRatings.length *
              100;

      final matchesSkill = minSkill == null ||
          maxSkill == null ||
          (skillAverage >= minSkill && skillAverage <= maxSkill);

      final matchesDistance = radiusKm == null ||
          _userLocation == null ||
          _distanceFor(player) != null && _distanceFor(player)! <= radiusKm;

      return matchesSearch && matchesSports && matchesSkill && matchesDistance;
    }).toList();

    if (_userLocation != null) {
      filtered.sort((a, b) {
        final distanceA = _distanceFor(a) ?? double.infinity;
        final distanceB = _distanceFor(b) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }

    setState(() {
      _filteredPlayers = filtered;
      _loading = false;
      _error = null;
    });
  }

  double? _distanceFor(PlayerModel player) {
    if (_userLocation == null ||
        player.latitude == null ||
        player.longitude == null) {
      return null;
    }
    final playerPoint = GeoPoint(player.latitude!, player.longitude!);
    return _locationService.calculateDistance(_userLocation!, playerPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'players_tab_fab',
        onPressed: _openMatchmaking,
        backgroundColor: ColorsManager.mainBlue,
        icon: const Icon(Icons.swipe, color: Colors.white),
        label: Text(
          'Matchmaking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
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

    if (_filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48.sp, color: Colors.grey[400]),
            Gap(16.h),
            Text(
              'No players found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Gap(8.h),
            Text(
              'Try expanding your filters or search',
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
        itemCount: _filteredPlayers.length,
        itemBuilder: (context, index) {
          final player = _filteredPlayers[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: PlayerDiscoveryCard(
              player: player,
              distanceKm: _distanceFor(player),
              onTap: () => _showPlayerProfile(player),
            ),
          );
        },
      ),
    );
  }

  void _showPlayerProfile(PlayerModel player) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Player profile for ${player.fullName} coming soon')),
    );
  }

  void _openMatchmaking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerMatchmakingScreen(
          userLocation: _userLocation,
        ),
      ),
    );
  }
}
