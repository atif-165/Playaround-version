import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../../models/geo_models.dart';
import '../../../services/location_service.dart';
import '../widgets/player_card.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/colors.dart';
import '../screens/player_matchmaking_screen.dart';

/// Players tab for explore screen
class PlayersTab extends StatefulWidget {
  final String searchQuery;
  final Map<String, dynamic> filters;

  const PlayersTab({
    super.key,
    required this.searchQuery,
    required this.filters,
  });

  @override
  State<PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends State<PlayersTab> {
  final LocationService _locationService = LocationService();
  List<GeoPlayer> _players = [];
  bool _isLoading = true;
  String? _error;
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void didUpdateWidget(PlayersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.filters != widget.filters) {
      _loadPlayers();
    }
  }

  Future<void> _initializeLocation() async {
    _userLocation = await _locationService.getCurrentLocation();
    await _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get players from Firestore
      Query query = FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'player');

      // Apply search filter
      if (widget.searchQuery.isNotEmpty) {
        query = query.where('fullName', 
            isGreaterThanOrEqualTo: widget.searchQuery)
            .where('fullName', 
            isLessThanOrEqualTo: '${widget.searchQuery}\uf8ff');
      }

      // Apply active filter
      query = query.where('isActive', isEqualTo: true);

      final querySnapshot = await query.get();
      
      List<GeoPlayer> players = querySnapshot.docs
          .map((doc) => GeoPlayer.fromFirestore(doc))
          .toList();

      // Apply sport filter
      if (widget.filters['sports'] != null && 
          (widget.filters['sports'] as List).isNotEmpty) {
        final selectedSports = widget.filters['sports'] as List<String>;
        players = players.where((player) {
          return player.sportsOfInterest.any((sport) => 
              selectedSports.contains(sport));
        }).toList();
      }

      // Apply skill range filter
      if (widget.filters['minSkill'] != null && 
          widget.filters['maxSkill'] != null) {
        final minSkill = widget.filters['minSkill'] as int;
        final maxSkill = widget.filters['maxSkill'] as int;
        players = players.where((player) {
          final avgSkill = player.averageSkillScore;
          return avgSkill >= minSkill && avgSkill <= maxSkill;
        }).toList();
      }

      // Apply distance filter if user location is available
      if (_userLocation != null && widget.filters['radiusKm'] != null) {
        final radiusKm = widget.filters['radiusKm'] as double;
        players = players.where((player) {
          if (player.geoPoint == null) {
            // Try to get approximate location from string
            final approxLocation = _locationService
                .getApproximateLocationFromString(player.location);
            if (approxLocation != null) {
              final distance = _locationService
                  .calculateDistance(_userLocation!, approxLocation);
              return distance <= radiusKm;
            }
            return false;
          }
          
          final distance = _locationService
              .calculateDistance(_userLocation!, player.geoPoint!);
          return distance <= radiusKm;
        }).toList();
      }

      // Sort by distance if user location is available
      if (_userLocation != null) {
        players = _locationService.sortByDistance<GeoPlayer>(
          players,
          _userLocation!,
          (player) => player.geoPoint ?? 
              _locationService.getApproximateLocationFromString(player.location) ??
              const GeoPoint(0, 0),
        );
      }

      if (mounted) {
        setState(() {
          _players = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load players: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "players_tab_fab",
        onPressed: _openMatchmaking,
        backgroundColor: ColorsManager.mainBlue,
        icon: const Icon(Icons.search, color: Colors.white),
        label: Text(
          'Find Match',
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
              onPressed: _loadPlayers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 48.sp,
              color: Colors.grey[400],
            ),
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
      onRefresh: _loadPlayers,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          double? distance;
          
          if (_userLocation != null) {
            final playerLocation = player.geoPoint ?? 
                _locationService.getApproximateLocationFromString(player.location);
            if (playerLocation != null) {
              distance = _locationService.calculateDistance(
                _userLocation!, 
                playerLocation,
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: PlayerCard(
              player: player,
              distance: distance,
              onTap: () => _onPlayerTap(player),
            ),
          );
        },
      ),
    );
  }

  void _onPlayerTap(GeoPlayer player) {
    // Navigate to player profile
    // TODO: Implement player profile navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Player profile for ${player.fullName}')),
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
