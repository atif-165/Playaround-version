import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/rating_model.dart';
import '../../../services/rating_service.dart';
import '../widgets/star_rating_input.dart';
import '../widgets/rating_prompt.dart';

/// Screen for managing ratings and pending rating requests
class RatingManagementScreen extends StatefulWidget {
  const RatingManagementScreen({super.key});

  @override
  State<RatingManagementScreen> createState() => _RatingManagementScreenState();
}

class _RatingManagementScreenState extends State<RatingManagementScreen>
    with TickerProviderStateMixin {
  final RatingService _ratingService = RatingService();
  late TabController _tabController;

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ratings'),
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view ratings'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings'),
        backgroundColor: ColorsManager.mainBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Pending Ratings'),
            Tab(text: 'My Ratings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingRatingsTab(),
          _buildMyRatingsTab(),
        ],
      ),
    );
  }

  Widget _buildPendingRatingsTab() {
    return StreamBuilder<List<PendingRatingModel>>(
      stream: _ratingService.getPendingRatingsForUser(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'Error loading pending ratings',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                SizedBox(height: 8.h),
                Text(
                  snapshot.error.toString(),
                  style: TextStyles.font14Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final pendingRatings = snapshot.data ?? [];

        if (pendingRatings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64.sp,
                  color: Colors.green[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'All caught up!',
                  style: TextStyles.font18DarkBlue600Weight,
                ),
                SizedBox(height: 8.h),
                Text(
                  'No pending ratings at the moment',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: pendingRatings.length,
          itemBuilder: (context, index) {
            final pendingRating = pendingRatings[index];
            return _buildPendingRatingCard(pendingRating);
          },
        );
      },
    );
  }

  Widget _buildPendingRatingCard(PendingRatingModel pendingRating) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: ColorsManager.mainBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getIconForRatingType(pendingRating.ratingType),
                  color: ColorsManager.mainBlue,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate ${pendingRating.ratingType.displayName}',
                      style: TextStyles.font16DarkBlue500Weight,
                    ),
                    Text(
                      pendingRating.entityName,
                      style: TextStyles.font14Grey400Weight,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Booking Date: ${_formatDate(pendingRating.bookingDate)}',
            style: TextStyles.font12Grey400Weight,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showRatingPrompt(pendingRating),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Rate Now',
                style: TextStyles.font14White600Weight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRatingsTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.grey[50],
            child: TabBar(
              labelColor: ColorsManager.mainBlue,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: ColorsManager.mainBlue,
              tabs: const [
                Tab(text: 'Given'),
                Tab(text: 'Received'),
                Tab(text: 'Stats'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGivenRatingsTab(),
                _buildReceivedRatingsTab(),
                _buildRatingStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGivenRatingsTab() {
    return StreamBuilder<List<RatingModel>>(
      stream: _getGivenRatingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: ColorsManager.mainBlue),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading given ratings: ${snapshot.error}',
              style: TextStyles.font14Grey400Weight,
            ),
          );
        }

        final ratings = snapshot.data ?? [];

        if (ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No ratings given yet',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Rate your experiences to help others',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];
            return _buildGivenRatingCard(rating);
          },
        );
      },
    );
  }

  Widget _buildReceivedRatingsTab() {
    return StreamBuilder<List<RatingModel>>(
      stream: _getReceivedRatingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: ColorsManager.mainBlue),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading received ratings: ${snapshot.error}',
              style: TextStyles.font14Grey400Weight,
            ),
          );
        }

        final ratings = snapshot.data ?? [];

        if (ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No ratings received yet',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Complete bookings to receive ratings',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];
            return RatingCard(
              raterName: rating.ratedByName,
              raterProfilePicture: rating.ratedByProfilePicture,
              stars: rating.stars,
              feedback: rating.feedback,
              timestamp: rating.timestamp,
            );
          },
        );
      },
    );
  }

  Widget _buildRatingStatsTab() {
    return StreamBuilder<RatingStats>(
      stream: _getUserRatingStatsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: ColorsManager.mainBlue),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading rating stats: ${snapshot.error}',
              style: TextStyles.font14Grey400Weight,
            ),
          );
        }

        final stats = snapshot.data;
        if (stats == null || stats.totalRatings == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No rating statistics yet',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Complete more bookings to see your stats',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildStatsOverview(stats),
              SizedBox(height: 24.h),
              _buildRatingDistributionCard(stats),
            ],
          ),
        );
      },
    );
  }

  void _showRatingPrompt(PendingRatingModel pendingRating) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingPromptModal(
        pendingRating: pendingRating,
        onCompleted: () {
          Navigator.of(context).pop();
          // Refresh the pending ratings list
          setState(() {});
        },
      ),
    );
  }

  IconData _getIconForRatingType(RatingType type) {
    switch (type) {
      case RatingType.coach:
        return Icons.sports_tennis;
      case RatingType.player:
        return Icons.person;
      case RatingType.venue:
        return Icons.location_city;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper methods for streams
  Stream<List<RatingModel>> _getGivenRatingsStream() {
    // This would need to be implemented in RatingService
    // For now, return empty stream
    return Stream.value([]);
  }

  Stream<List<RatingModel>> _getReceivedRatingsStream() {
    // This would get ratings where ratedEntityId == currentUserId
    return _ratingService.getRatingsForEntity(
        _currentUserId!, RatingType.player);
  }

  Stream<RatingStats> _getUserRatingStatsStream() {
    // Get stats for current user as a player
    return _ratingService.getRatingStatsStream(
        _currentUserId!, RatingType.player);
  }

  Widget _buildGivenRatingCard(RatingModel rating) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rated ${rating.ratingType.displayName}',
                  style: TextStyles.font14DarkBlue500Weight,
                ),
              ),
              StarRatingDisplay(
                rating: rating.stars.toDouble(),
                starSize: 16,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (rating.feedback != null && rating.feedback!.isNotEmpty) ...[
            Text(
              rating.feedback!,
              style: TextStyles.font13Grey400Weight,
            ),
            SizedBox(height: 8.h),
          ],
          Text(
            _formatDate(rating.timestamp),
            style: TextStyles.font12Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(RatingStats stats) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            stats.formattedAverage,
            style: TextStyle(
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.mainBlue,
            ),
          ),
          StarRatingDisplay(
            rating: stats.averageRating,
            starSize: 24,
          ),
          SizedBox(height: 8.h),
          Text(
            '${stats.totalRatings} total ratings',
            style: TextStyles.font16DarkBlue500Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistributionCard(RatingStats stats) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Distribution',
            style: TextStyles.font16DarkBlue500Weight,
          ),
          SizedBox(height: 16.h),
          RatingDistribution(
            starDistribution: stats.starDistribution,
            totalRatings: stats.totalRatings,
          ),
        ],
      ),
    );
  }
}

/// Screen for viewing detailed ratings for a specific entity
class EntityRatingsScreen extends StatefulWidget {
  final String entityId;
  final RatingType ratingType;
  final String entityName;

  const EntityRatingsScreen({
    super.key,
    required this.entityId,
    required this.ratingType,
    required this.entityName,
  });

  @override
  State<EntityRatingsScreen> createState() => _EntityRatingsScreenState();
}

class _EntityRatingsScreenState extends State<EntityRatingsScreen> {
  final RatingService _ratingService = RatingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.entityName} Ratings'),
        backgroundColor: ColorsManager.mainBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Rating Summary Header
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.grey[50],
            child: StreamBuilder<RatingStats>(
              stream: _ratingService.getRatingStatsStream(
                widget.entityId,
                widget.ratingType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorsManager.mainBlue,
                    ),
                  );
                }

                final stats = snapshot.data ??
                    RatingStats.empty(widget.entityId, widget.ratingType);

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                stats.formattedAverage,
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.bold,
                                  color: ColorsManager.mainBlue,
                                ),
                              ),
                              StarRatingDisplay(
                                rating: stats.averageRating,
                                starSize: 20,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${stats.totalRatings} reviews',
                                style: TextStyles.font14Grey400Weight,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 24.w),
                        Expanded(
                          flex: 2,
                          child: RatingDistribution(
                            starDistribution: stats.starDistribution,
                            totalRatings: stats.totalRatings,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Ratings List
          Expanded(
            child: StreamBuilder<List<RatingModel>>(
              stream: _ratingService.getRatingsForEntity(
                widget.entityId,
                widget.ratingType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorsManager.mainBlue,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading ratings: ${snapshot.error}',
                      style: TextStyles.font14Grey400Weight,
                    ),
                  );
                }

                final ratings = snapshot.data ?? [];

                if (ratings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_border,
                          size: 64.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No ratings yet',
                          style: TextStyles.font16DarkBlue500Weight,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Be the first to leave a review!',
                          style: TextStyles.font14Grey400Weight,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return RatingCard(
                      raterName: rating.ratedByName,
                      raterProfilePicture: rating.ratedByProfilePicture,
                      stars: rating.stars,
                      feedback: rating.feedback,
                      timestamp: rating.timestamp,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
