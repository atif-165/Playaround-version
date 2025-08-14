import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../services/matchmaking_service.dart';
import '../../core/widgets/progress_indicator.dart';
import '../../theming/colors.dart';
import 'widgets/match_request_card.dart';

/// Screen for viewing and managing match requests
class MatchRequestsScreen extends StatefulWidget {
  const MatchRequestsScreen({super.key});

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen>
    with SingleTickerProviderStateMixin {
  final MatchmakingService _matchmakingService = MatchmakingService();
  
  late TabController _tabController;
  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMatchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchRequests() async {
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

      // Load received requests
      final receivedRequests = await _matchmakingService.getMatchRequests(user.uid);
      
      // Load sent requests (we'll need to modify the service for this)
      final sentRequests = await _matchmakingService.getSentMatchRequests(user.uid);

      if (mounted) {
        setState(() {
          _receivedRequests = receivedRequests;
          _sentRequests = sentRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load match requests: $e';
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
          'Match Requests',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadMatchRequests,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.mainBlue,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: ColorsManager.mainBlue,
          tabs: [
            Tab(
              text: 'Received (${_receivedRequests.length})',
            ),
            Tab(
              text: 'Sent (${_sentRequests.length})',
            ),
          ],
        ),
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
              onPressed: _loadMatchRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildReceivedRequestsTab(),
        _buildSentRequestsTab(),
      ],
    );
  }

  Widget _buildReceivedRequestsTab() {
    if (_receivedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No match requests',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Gap(8.h),
            Text(
              'When someone wants to team up with you,\ntheir requests will appear here',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatchRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _receivedRequests.length,
        itemBuilder: (context, index) {
          final request = _receivedRequests[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: MatchRequestCard(
              request: request,
              isReceived: true,
              onAccept: () => _handleRequestResponse(request['id'], true),
              onDecline: () => _handleRequestResponse(request['id'], false),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentRequestsTab() {
    if (_sentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No sent requests',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Gap(8.h),
            Text(
              'Use the matchmaking feature to find\nand request matches with other players',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatchRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: MatchRequestCard(
              request: request,
              isReceived: false,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRequestResponse(String requestId, bool accepted) async {
    try {
      await _matchmakingService.respondToMatchRequest(
        requestId: requestId,
        accepted: accepted,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepted ? 'Match request accepted!' : 'Match request declined',
            ),
            backgroundColor: accepted ? Colors.green : Colors.orange,
          ),
        );
        
        // Reload requests
        _loadMatchRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to respond to request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
