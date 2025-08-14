import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../models/geo_models.dart';
import '../../../services/matchmaking_service.dart';
import '../widgets/match_card.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/colors.dart';

/// Screen for intelligent player matchmaking
class PlayerMatchmakingScreen extends StatefulWidget {
  final GeoPoint? userLocation;

  const PlayerMatchmakingScreen({
    super.key,
    this.userLocation,
  });

  @override
  State<PlayerMatchmakingScreen> createState() => _PlayerMatchmakingScreenState();
}

class _PlayerMatchmakingScreenState extends State<PlayerMatchmakingScreen> {
  final MatchmakingService _matchmakingService = MatchmakingService();

  List<PlayerMatch> _matches = [];
  bool _isLoading = true;
  String? _error;
  GeoPlayer? _currentPlayer;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlayerAndMatches();
  }

  Future<void> _loadCurrentPlayerAndMatches() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current player profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      _currentPlayer = GeoPlayer.fromFirestore(userDoc);

      // Find matches
      final matches = await _matchmakingService.findMatches(
        currentPlayer: _currentPlayer!,
        userLocation: widget.userLocation,
        maxDistance: 20.0, // 20km radius
        skillTolerance: 10, // ±10 skill points
        maxResults: 20,
      );

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to find matches: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Find Your Match',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadCurrentPlayerAndMatches,
          ),
        ],
      ),
      body: _buildBody(),
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
              onPressed: _loadCurrentPlayerAndMatches,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No matches found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Gap(8.h),
            Text(
              'Try expanding your search criteria or check back later',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            ElevatedButton(
              onPressed: _loadCurrentPlayerAndMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Search Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header info
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${_matches.length} potential matches',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Gap(4.h),
              Text(
                'Based on your skills, location, and preferences',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Matches list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCurrentPlayerAndMatches,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: MatchCard(
                    match: match,
                    onRequestMatch: () => _requestMatch(match),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestMatch(PlayerMatch match) async {
    try {
      await _matchmakingService.sendMatchRequest(
        fromPlayerId: _currentPlayer!.uid,
        toPlayerId: match.player.uid,
        matchScore: match.matchScore,
        commonSports: match.commonSports,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match request sent to ${match.player.fullName}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send match request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
