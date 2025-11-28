import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/navigation/detail_navigator.dart';
import '../../../models/coach_profile.dart';
import '../../../models/player_profile.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../team/models/team_model.dart';
import '../../../screens/venue/venue_profile_screen.dart';
import '../../../services/venue_service.dart';
import '../services/coach_service.dart';
import '../screens/coach_profile_edit_screen.dart';

/// Detailed coach profile screen
class CoachDetailScreen extends StatefulWidget {
  final CoachProfile coach;

  const CoachDetailScreen({
    super.key,
    required this.coach,
  });

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  final CoachService _coachService = CoachService();
  final UserRepository _userRepository = UserRepository();
  bool _isCurrentUser = false;
  bool _isLoading = false;
  List<dynamic> _coachVenues = [];
  List<dynamic> _coachTeams = [];
  List<Map<String, dynamic>> _coachPlayers = [];
  List<Map<String, dynamic>> _coachReviews = [];
  bool _isLoadingTabs = false;

  String get _primarySport =>
      widget.coach.specializationSports.isNotEmpty
          ? widget.coach.specializationSports.first
          : 'Sports';

  String _formatReviewDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final safeDate = date.toLocal();
    return '${months[safeDate.month - 1]} ${safeDate.day}, ${safeDate.year}';
  }

  Widget _buildBadgeChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: ColorsManager.primary,
          ),
          Gap(6.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64.sp,
          color: Colors.white.withOpacity(0.25),
        ),
        Gap(18.h),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13.sp,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildAddReviewCallout() {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary.withOpacity(0.25),
            ColorsManager.primary.withOpacity(0.12),
          ],
        ),
        border: Border.all(color: ColorsManager.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: Colors.white,
            size: 28.sp,
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your experience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(6.h),
                Text(
                  'Help other athletes understand what it is like to train with ${widget.coach.fullName.split(' ').first}.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Gap(16.w),
          ElevatedButton(
            onPressed: _addReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ColorsManager.primary,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              'Review',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating']?.toString() ?? '4.8';
    final date = review['date'] is DateTime
        ? _formatReviewDate(review['date'] as DateTime)
        : 'Recently';
    final reviewerName = (review['reviewer'] as String?) ?? 'Athlete';
    final reviewerId = (review['reviewerId'] as String?) ??
        (review['reviewerUid'] as String?) ??
        (review['uid'] as String?);
    final hasProfile = reviewerId != null && reviewerId.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        color: const Color(0xFF14112D).withOpacity(0.9),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFFFFC56F),
                      size: 16.sp,
                    ),
                    Gap(4.w),
                    Text(
                      rating,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(12.w),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openUserProfileById(
                    reviewerId,
                    displayName: reviewerName,
                  ),
                  child: Text(
                    reviewerName,
                    style: TextStyle(
                      color: hasProfile ? ColorsManager.primary : Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      decoration: hasProfile
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            review['highlight'] as String,
            style: TextStyle(
              color: ColorsManager.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
          Gap(10.h),
          Text(
            review['feedback'] as String,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkIfCurrentUser();
    _loadTabData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkIfCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    _isCurrentUser = currentUser?.uid == widget.coach.uid;
  }

  List<Map<String, dynamic>> _generateFallbackVenues() {
    final random = Random(widget.coach.uid.hashCode);
    final baseCity = widget.coach.location;
    final sport = _primarySport;

    return List.generate(3, (index) {
      final venueNames = [
        '$sport Performance Dome',
        '$sport Elite Training Hub',
        '$sport High-Performance Lab',
      ];

      final ambience = [
        'Premium indoor arena with smart tracking',
        'Open-air stadium with tactical analysis suite',
        'Boutique studio with recovery lounge',
      ];

      return {
        'id': 'fallback_venue_${widget.coach.uid}_$index',
        'name': venueNames[index % venueNames.length],
        'location': '$baseCity • ${18 + index * 5} mins away',
        'sportType': sport,
        'sessionsHosted': 45 + index * 30 + random.nextInt(15),
        'rating':
            (4.5 + random.nextDouble() * 0.4).clamp(4.5, 4.9).toStringAsFixed(1),
        'highlight': ambience[index % ambience.length],
        'image':
            'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=${900 + index * 20}&q=80',
      };
    });
  }

  List<Map<String, dynamic>> _generateFallbackTeams() {
    final random = Random(widget.coach.uid.hashCode + 13);
    final sport = _primarySport;

    return List.generate(3, (index) {
      final teamTitles = [
        '${sport.split(' ').first} Velocity Club',
        '${sport.split(' ').first} Titans',
        '${sport.split(' ').first} Rising Stars',
      ];
      final achievements = [
        'City Champions • 2025',
        'Top 3 National League',
        'U18 Elite Finals',
      ];

      final played = 18 + random.nextInt(8);
      final wins = (played * 0.72).round();

      return {
        'id': 'fallback_team_${widget.coach.uid}_$index',
        'name': teamTitles[index % teamTitles.length],
        'sportType': sport,
        'memberCount': 16 + index * 2,
        'maxMembers': 20,
        'achievement': achievements[index % achievements.length],
        'winRate': '${((wins / played) * 100).round()}% win rate',
        'badge':
            'https://images.unsplash.com/photo-1505843513577-22bb7d21e455?auto=format&fit=crop&w=${500 + index * 15}&q=80',
      };
    });
  }

  List<Map<String, dynamic>> _generateShowcaseAthletes() {
    final random = Random(widget.coach.uid.hashCode + 29);
    final sport = _primarySport;

    final athletes = [
      {
        'uid': 'fallback_player_${widget.coach.uid}_0',
        'name': 'Ayesha Malik',
        'achievement': 'National Trials Qualifier',
        'progress': '+18% speed, +12% accuracy',
        'avatar':
            'https://images.unsplash.com/photo-1552058544-f2b08422138a?auto=format&fit=crop&w=400&q=80',
        'sport': sport,
      },
      {
        'uid': 'fallback_player_${widget.coach.uid}_1',
        'name': 'Bilal Khan',
        'achievement': 'Regional MVP 2024',
        'progress': '+26% agility index',
        'avatar':
            'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?auto=format&fit=crop&w=400&q=80',
        'sport': sport,
      },
      {
        'uid': 'fallback_player_${widget.coach.uid}_2',
        'name': 'Sara Qureshi',
        'achievement': 'Youth Elite Squad',
        'progress': '+32% endurance rating',
        'avatar':
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=400&q=80',
        'sport': sport,
      },
    ];

    return athletes
        .map(
          (athlete) => {
            ...athlete,
            'sessionsCompleted': 40 + random.nextInt(25),
            'focusArea': [
              'Technique Refinement',
              'High-Performance Conditioning',
              'Mental Toughness',
            ][random.nextInt(3)],
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _generateCoachReviews() {
    final random = Random(widget.coach.uid.hashCode + 47);
    final testimonials = [
      {
        'reviewer': 'Hamza Raza',
        'highlight': 'Game strategy transformed',
        'feedback':
            'Coach ${widget.coach.fullName.split(' ').first} rebuilt my footwork from the ground up. The personalized drills and match analysis made a huge difference within weeks.',
      },
      {
        'reviewer': 'Mehak Saleem',
        'highlight': 'Elite mindset coaching',
        'feedback':
            'Loved the energy and structure. Each session included performance tracking, recovery guidance and mental conditioning. Highly recommended for competitive athletes.',
      },
      {
        'reviewer': 'Rohan Siddiqui',
        'highlight': 'Professional and encouraging',
        'feedback':
            'From nutrition to match prep, everything is planned. The training dashboards keep me accountable, and my stats continue to improve month over month.',
      },
    ];

    return testimonials
        .map(
          (review) => {
            ...review,
            'rating': (4.6 + random.nextDouble() * 0.4)
                .clamp(4.6, 5.0)
                .toStringAsFixed(1),
            'date': DateTime.now()
                .subtract(Duration(days: random.nextInt(120)))
                .toLocal(),
          },
        )
        .toList();
  }

  Future<void> _loadTabData() async {
    setState(() {
      _isLoadingTabs = true;
    });

    try {
      // Load venues owned by the coach
      final venues = await _coachService.getCoachVenues(widget.coach.uid);

      // Load teams where the coach is owner or captain
      final teams = await _coachService.getCoachTeams(widget.coach.uid);
      final players = await _coachService.getCoachPlayers(widget.coach.uid);

      if (mounted) {
        setState(() {
          // Use actual data only - no fallback dummy data
          // This ensures each coach shows their own unique data
          _coachVenues = venues;
          _coachTeams = teams;
          _coachPlayers = players;
          // TODO: Load actual reviews from database when review system is implemented
          // For now, use empty list - reviews will show "No reviews yet"
          _coachReviews = [];
          _isLoadingTabs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTabs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = _createTabBar();

    return Scaffold(
      backgroundColor: const Color(0xFF050414),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B1848),
                  Color(0xFF080612),
                ],
              ),
            ),
          ),
          NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    Gap(12.h),
                    _buildHighlightMetrics(),
                    Gap(24.h),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CoachTabBarDelegate(
                  tabBar: tabBar,
                ),
              ),
            ],
            body: _buildTabBarView(),
          ),
        ],
      ),
      bottomNavigationBar: _isCurrentUser ? null : _buildConsultButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.coach.fullName,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: LayoutBuilder(
          builder: (context, constraints) {
            final percentage = (constraints.maxHeight - kToolbarHeight) /
                (260.h - kToolbarHeight);
            return Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'coach-${widget.coach.uid}',
                  child: widget.coach.profilePictureUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.coach.profilePictureUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white54),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF1C1A3C),
                            child: Icon(
                              Icons.person,
                              color: Colors.white.withOpacity(0.8),
                              size: 72.sp,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1C1A3C),
                          child: Icon(
                            Icons.person,
                            color: Colors.white.withOpacity(0.8),
                            size: 72.sp,
                          ),
                        ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x0012123a),
                        Color(0xCC0B0A1C),
                      ],
                    ),
                  ),
                ),
                // Admin icon in top right (same style as public profile)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8.h,
                  right: 16.w,
                  child: Row(
                    children: [
                      if (_isCurrentUser)
                        _HeroActionButton(
                          icon: Icons.dashboard_customize_outlined,
                          label: 'Admin',
                          onTap: _editProfile,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30.h,
                  left: 20.w,
                  right: 20.w,
                  child: Opacity(
                    opacity: percentage.clamp(0, 1),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                              Gap(8.w),
                              Text(
                                'Elite ${_primarySport} Program',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        if (!_isCurrentUser)
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white),
            onPressed: () {},
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF181536).withOpacity(0.95),
              const Color(0xFF0E0D24).withOpacity(0.9),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.coach.fullName,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Gap(10.h),
                      _buildRatingRow(),
                      Gap(10.h),
                      _buildLocationRow(),
                    ],
                  ),
                ),
                _buildCoachBadge(),
              ],
            ),
            Gap(20.h),
            _buildExperienceInfo(),
            Gap(24.h),
            _buildBio(),
            Gap(22.h),
            _buildSpecializations(),
            if (widget.coach.certifications != null &&
                widget.coach.certifications!.isNotEmpty) ...[
              Gap(22.h),
              _buildCertifications(),
            ],
            if (widget.coach.availableTimeSlots.isNotEmpty) ...[
              Gap(22.h),
              _buildAvailability(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightMetrics() {
    // Use actual player count from coach's players
    final athleteCount = _coachPlayers.length;
    
    // Calculate actual average rating from reviews - only if reviews exist
    final hasReviews = _coachReviews.isNotEmpty;
    final averageRating = hasReviews
        ? _coachReviews
                .map((review) {
                  final ratingValue = review['rating'];
                  if (ratingValue is num) {
                    return ratingValue.toDouble();
                  } else if (ratingValue is String) {
                    return double.tryParse(ratingValue) ?? 0.0;
                  }
                  return 0.0;
                })
                .where((value) => value > 0)
                .fold<double>(0.0, (sum, value) => sum + value) /
            _coachReviews.length
        : null; // No rating if no reviews
    
    // Calculate completion rate based on actual time slots and experience
    // More time slots and experience = higher completion rate
    final baseRate = 70.0;
    final timeSlotBonus = widget.coach.availableTimeSlots.length * 2.0;
    final experienceBonus = widget.coach.experienceYears * 1.5;
    final completionRate = min(99.0, baseRate + timeSlotBonus + experienceBonus);

    final cards = [
      {
        'icon': Icons.people_outline,
        'title': 'Athletes mentored',
        'value': athleteCount > 0 ? '$athleteCount${athleteCount >= 10 ? '+' : ''}' : '0',
        'subtitle': athleteCount > 0 
            ? 'Personal coaching journeys' 
            : 'No athletes yet',
      },
      if (hasReviews && averageRating != null)
        {
          'icon': Icons.star_half_rounded,
          'title': 'Session rating',
          'value': averageRating.toStringAsFixed(2),
          'subtitle': 'Coach satisfaction score',
        },
      {
        'icon': Icons.show_chart_rounded,
        'title': 'Plan adherence',
        'value': '$completionRate%',
        'subtitle': 'Training blocks completed',
      },
    ];

    return SizedBox(
      height: 190.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => Gap(14.w),
        itemBuilder: (context, index) {
          final metric = cards[index];
          return SizedBox(
            width: 180.w,
            child: _MetricHighlightTile(
              icon: metric['icon'] as IconData,
              title: metric['title'] as String,
              value: metric['value'] as String,
              subtitle: metric['subtitle'] as String,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingRow() {
    // Calculate actual rating from reviews
    final reviewCount = _coachReviews.length;
    
    // Only calculate rating if there are actual reviews
    if (reviewCount == 0) {
      return Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_border_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 20.sp,
                ),
                Gap(6.w),
                Text(
                  'No rating',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Text(
              'No reviews yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Calculate actual rating from reviews
    final rating = _coachReviews
        .map((review) {
          final ratingValue = review['rating'];
          if (ratingValue is num) {
            return ratingValue.toDouble();
          } else if (ratingValue is String) {
            return double.tryParse(ratingValue) ?? 0.0;
          }
          return 0.0;
        })
        .where((value) => value > 0)
        .fold<double>(0.0, (sum, value) => sum + value) /
        reviewCount;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                color: const Color(0xFFFFC56F),
                size: 20.sp,
              ),
              Gap(6.w),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
        Gap(12.w),
        Expanded(
          child: Text(
            '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: ColorsManager.primary,
          size: 18.sp,
        ),
        Gap(4.w),
        Text(
          widget.coach.location,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCoachBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary,
            ColorsManager.primary.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports,
            color: Colors.white,
            size: 16.sp,
          ),
          Gap(4.w),
          Text(
            'COACH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceInfo() {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: [
        _buildInfoCard(
          icon: Icons.timeline_rounded,
          title: 'Experience',
          value: '${widget.coach.experienceYears}+ years',
        ),
        _buildInfoCard(
          icon: Icons.payments_outlined,
          title: 'Session Rate',
          value: '\$${widget.coach.hourlyRate.toStringAsFixed(0)} / 60min',
        ),
        _buildInfoCard(
          icon: Icons.sports_martial_arts_outlined,
          title: 'Training Mode',
          value: widget.coach.coachingType.displayName,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: 160.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: const Color(0xFF15122C).withOpacity(0.9),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorsManager.primary.withOpacity(0.18),
            ),
            padding: EdgeInsets.all(8.w),
            child: Icon(
              icon,
              color: ColorsManager.primary,
              size: 18.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Gap(4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    final copy = widget.coach.bio;
    final defaultBio =
        'Purpose-built programs around performance analytics, mindset coaching, and recovery protocols to elevate every training block.';

    return Text(
      copy?.isNotEmpty == true ? copy! : defaultBio,
      style: TextStyle(
        color: Colors.white.withOpacity(0.78),
        fontSize: 14.sp,
        height: 1.6,
      ),
    );
  }

  Widget _buildSpecializations() {
    if (widget.coach.specializationSports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signature Focus Areas',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: widget.coach.specializationSports.map((sport) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withOpacity(0.16),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: ColorsManager.primary.withOpacity(0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: ColorsManager.primary,
                    size: 16.sp,
                  ),
                  Gap(8.w),
                  Text(
                    sport,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCertifications() {
    if (widget.coach.certifications == null ||
        widget.coach.certifications!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certifications',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: widget.coach.certifications!.map((cert) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: ColorsManager.primary,
                    size: 16.sp,
                  ),
                  Gap(8.w),
                  Flexible(
                    child: Text(
                      cert,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailability() {
    if (widget.coach.availableTimeSlots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        Gap(12.h),
        ...widget.coach.availableTimeSlots.map((slot) {
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: ColorsManager.primary,
                  size: 18.sp,
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.day,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        '${slot.startTime} - ${slot.endTime}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  TabBar _createTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.white.withOpacity(0.55),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary,
            ColorsManager.primary.withOpacity(0.7),
          ],
        ),
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12.sp,
        letterSpacing: 0.4,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12.sp,
      ),
      tabs: const [
        Tab(text: 'Venues'),
        Tab(text: 'Teams'),
        Tab(text: 'Players'),
        Tab(text: 'Reviews'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildVenuesTab(),
          _buildTeamsTab(),
          _buildPlayersTab(),
          _buildReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildVenuesTab() {
    if (_isLoadingTabs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coachVenues.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_off_outlined,
        title: 'No partner venues yet',
        subtitle:
            'Reach out to explore training locations and private studio sessions.',
      );
    }

    return ListView.separated(
      primary: false,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 40.h),
      itemCount: _coachVenues.length,
      separatorBuilder: (_, __) => Gap(18.h),
      itemBuilder: (context, index) {
        final venue = _coachVenues[index];
        final imageUrl = venue['image'] ??
            'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=1200&q=80';
        final venueId = venue['id'] as String?;
        final venueName =
            (venue['name'] as String?)?.trim().isNotEmpty == true
                ? (venue['name'] as String).trim()
                : 'Training Venue';
        final hasVenueProfile = venueId != null &&
            venueId.isNotEmpty &&
            !venueId.toLowerCase().startsWith('fallback_');

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            color: const Color(0xFF15112F).withOpacity(0.88),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 160.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openVenueProfileById(
                              venueId,
                              displayName: venueName,
                            ),
                            child: Text(
                              venueName,
                              style: TextStyle(
                                color: hasVenueProfile
                                    ? ColorsManager.primary
                                    : Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                decoration: hasVenueProfile
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: ColorsManager.primary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: const Color(0xFFFFC56F),
                                size: 16.sp,
                              ),
                              Gap(4.w),
                              Text(
                                (venue['rating'] ?? '4.8').toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Gap(10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white.withOpacity(0.6),
                          size: 16.sp,
                        ),
                        Gap(6.w),
                        Expanded(
                          child: Text(
                            venue['location'] ?? 'Location updates soon',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 13.sp,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(12.h),
                    Text(
                      venue['highlight'] ??
                          'High-performance facility with smart analytics & recovery zones.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),
                    Gap(14.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: [
                        _buildBadgeChip(
                          icon: Icons.sports_soccer_outlined,
                          text: venue['sportType'] ?? _primarySport,
                        ),
                        _buildBadgeChip(
                          icon: Icons.event_available_outlined,
                          text:
                              '${venue['sessionsHosted'] ?? 40}+ sessions hosted',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    if (_isLoadingTabs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coachTeams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.groups_2_outlined,
        title: 'No teams on record',
        subtitle:
            'Coach ${widget.coach.fullName.split(' ').first} is onboarding squads. Check back soon.',
      );
    }

    return ListView.separated(
      primary: false,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 40.h),
      itemCount: _coachTeams.length,
      separatorBuilder: (_, __) => Gap(18.h),
      itemBuilder: (context, index) {
        final team = _coachTeams[index];
        final badge = team['badge'] ??
            'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?auto=format&fit=crop&w=600&q=80';
        final teamId = team['id']?.toString();
        final teamName = team['name']?.toString() ?? 'Team Spotlight';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22.r),
            onTap: () => _openTeamProfile(
              teamId,
              teamName,
              fallbackData: team,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                color: const Color(0xFF16122E).withOpacity(0.92),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 26,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              padding: EdgeInsets.all(18.w),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: CachedNetworkImage(
                      imageUrl: badge,
                      width: 62.w,
                      height: 62.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Gap(16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (team['sportType'] != null) ...[
                          Gap(4.h),
                          Text(
                            team['sportType'].toString(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                        Gap(6.h),
                        Text(
                          team['achievement'] ??
                              'Competitive squad in development',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12.sp,
                          ),
                        ),
                        Gap(8.h),
                        Wrap(
                          spacing: 10.w,
                          runSpacing: 8.h,
                          children: [
                            _buildBadgeChip(
                              icon: Icons.people_alt_outlined,
                              text:
                                  '${team['memberCount'] ?? '-'} / ${team['maxMembers'] ?? '-'} roster',
                            ),
                            _buildBadgeChip(
                              icon: Icons.military_tech_outlined,
                              text: team['winRate'] ?? 'Season prep in progress',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    if (_coachPlayers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_outline,
        title: 'Player roster coming soon',
        subtitle:
            'We are curating standout player journeys and progress reports.',
      );
    }

    return ListView.builder(
      primary: false,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 40.h),
      itemCount: _coachPlayers.length,
      itemBuilder: (context, index) {
        final player = _coachPlayers[index];
        final playerName = (player['name'] as String?) ?? 'Athlete';
        final playerId = (player['uid'] as String?) ??
            (player['userId'] as String?) ??
            (player['playerId'] as String?);
        final hasProfile = playerId != null && playerId.isNotEmpty;
        final avatarUrl = (player['avatar'] as String?) ??
            'https://images.unsplash.com/photo-1552058544-f2b08422138a?auto=format&fit=crop&w=400&q=80';
        final teamName = player['teamName']?.toString();
        final teamId = player['teamId']?.toString();
        final sportLabel = player['sport']?.toString() ?? _primarySport;
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            color: const Color(0xFF14102C).withOpacity(0.92),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: EdgeInsets.all(18.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 60.w,
                  height: 60.w,
                  fit: BoxFit.cover,
                ),
              ),
              Gap(16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openUserProfileById(
                        playerId,
                        displayName: playerName,
                      ),
                      child: Text(
                        playerName,
                        style: TextStyle(
                          color: hasProfile
                              ? ColorsManager.primary
                              : Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          decoration: hasProfile
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    Gap(4.h),
                    if (teamName != null) ...[
                      Text(
                        teamName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (teamId != null && teamId.isNotEmpty) ...[
                        Gap(2.h),
                        GestureDetector(
                          onTap: () => _openTeamProfile(
                            teamId,
                            teamName,
                            fallbackData:
                                player['team'] is Map<String, dynamic>
                                    ? Map<String, dynamic>.from(
                                        player['team'] as Map<String, dynamic>,
                                      )
                                    : {
                                        'id': teamId,
                                        'name': teamName,
                                        'sportType': sportLabel,
                                        'memberCount': player['memberCount'],
                                        'achievement': player['achievement'],
                                      },
                          ),
                          child: Text(
                            'View team profile',
                            style: TextStyle(
                              color: ColorsManager.primary,
                              fontSize: 11.sp,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                      Gap(6.h),
                    ] else
                      Gap(4.h),
                    Text(
                      (player['achievement'] as String?) ??
                          'Star performer across drills',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.sp,
                      ),
                    ),
                    Gap(8.h),
                    Text(
                      (player['progress'] as String?) ?? 'Tracking progress weekly',
                      style: TextStyle(
                        color: ColorsManager.primary.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                    Gap(10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: [
                        _buildBadgeChip(
                          icon: Icons.sports_handball_outlined,
                          text: sportLabel,
                        ),
                        _buildBadgeChip(
                          icon: Icons.schedule_rounded,
                          text:
                              '${player['sessionsCompleted'] ?? 0} sessions completed',
                        ),
                      ],
                    ),
                    Gap(12.h),
                    Text(
                      (player['focusArea'] as String?) ?? 'General Training',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final reviews = _coachReviews;

    return ListView(
      primary: false,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 40.h),
      children: [
        if (!_isCurrentUser) _buildAddReviewCallout(),
        if (reviews.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60.h),
            child: _buildEmptyState(
              icon: Icons.star_border_rounded,
              title: 'No reviews yet',
              subtitle: 'Be the first to share your experience working together.',
            ),
          )
        else
          ...reviews.map((review) => _buildReviewCard(review)).toList(),
        Gap(60.h),
      ],
    );
  }

  Widget _buildConsultButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.05),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _consultNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat,
                        size: 20.sp,
                      ),
                      Gap(8.w),
                      Text(
                        'Consult Now',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _consultNow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _ensureChatParticipants();

      final chatRoom =
          await _chatService.getOrCreateDirectChat(widget.coach.uid);

      if (chatRoom != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
      } else {
        throw Exception('Unable to start chat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _ensureChatParticipants() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentProfile =
        await _userRepository.getUserProfile(currentUser.uid);
    if (currentProfile == null) {
      final now = DateTime.now();
      final fallbackSports = widget.coach.specializationSports.isNotEmpty
          ? widget.coach.specializationSports.take(2).toList()
          : ['Fitness Training'];

      final fallbackProfile = PlayerProfile(
        uid: currentUser.uid,
        fullName: currentUser.displayName?.trim().isNotEmpty == true
            ? currentUser.displayName!.trim()
            : 'Player ${currentUser.uid.substring(0, 6)}',
        nickname: currentUser.displayName,
        bio: 'Auto-generated profile for quick consultations.',
        gender: Gender.other,
        age: 25,
        location: widget.coach.location.isNotEmpty
            ? widget.coach.location
            : 'Unknown',
        profilePictureUrl: currentUser.photoURL,
        isProfileComplete: false,
        createdAt: now,
        updatedAt: now,
        sportsOfInterest: fallbackSports,
        skillLevel: SkillLevel.intermediate,
        availability: const [
          TimeSlot(day: 'Flexible', startTime: 'Anytime', endTime: 'Anytime'),
        ],
        preferredTrainingType: TrainingType.both,
      );

      await _userRepository.saveUserProfile(fallbackProfile);
    }

    final coachProfile =
        await _userRepository.getUserProfile(widget.coach.uid);
    if (coachProfile == null) {
      await _userRepository.saveUserProfile(widget.coach);
    }
  }

  Future<void> _openVenueProfileById(
    String? venueId, {
    required String displayName,
  }) async {
    if (venueId == null ||
        venueId.isEmpty ||
        venueId.toLowerCase().startsWith('fallback_')) {
      _showVenueUnavailable(displayName);
      return;
    }

    try {
      final venue = await VenueService.getVenueById(venueId);
      if (!mounted) return;

      if (venue == null) {
        _showVenueUnavailable(displayName);
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenueProfileScreen(venue: venue),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showVenueUnavailable(displayName, showGenericError: true);
    }
  }

  Future<void> _openTeamProfile(
    String? teamId,
    String? displayName, {
    Map<String, dynamic>? fallbackData,
  }) async {
    if (!mounted) return;
    final success = await DetailNavigator.openTeam(
      context,
      teamId: teamId,
    );
    if (success) return;

    if (fallbackData != null) {
      final fallbackTeam = _buildTeamModelFromMap(
        fallbackData,
        fallbackId: teamId,
        displayName: displayName,
      );
      if (fallbackTeam != null) {
        final opened = await DetailNavigator.openTeam(
          context,
          team: fallbackTeam,
        );
        if (opened) return;
      }
    }

      final label =
          (displayName != null && displayName.trim().isNotEmpty) ? displayName : 'This team';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label details are not available yet.'),
        ),
      );
  }

  void _showVenueUnavailable(
    String? name, {
    bool showGenericError = false,
  }) {
    if (!mounted) return;
    final trimmed = name?.trim();
    final venueLabel =
        (trimmed != null && trimmed.isNotEmpty) ? trimmed : 'This venue';
    final message = showGenericError
        ? 'Unable to open $venueLabel right now. Please try again later.'
        : '$venueLabel details are not available yet.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openUserProfileById(
    String? userId, {
    String? displayName,
  }) async {
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        _showProfileUnavailable(displayName);
      }
      return;
    }
    final success = await DetailNavigator.openPlayer(
      context,
      userId: userId,
      userName: displayName,
    );
    if (success || !mounted) return;

      _showProfileUnavailable(displayName);
    }

  TeamModel? _buildTeamModelFromMap(
    Map<String, dynamic> data, {
    String? fallbackId,
    String? displayName,
  }) {
    final rawName =
        (data['name'] ?? displayName)?.toString().trim();
    if (rawName == null || rawName.isEmpty) return null;

    String _clean(dynamic value) => value?.toString().trim() ?? '';

    final id = _clean(data['id']).isNotEmpty
        ? _clean(data['id'])
        : (fallbackId?.isNotEmpty == true
            ? fallbackId!
            : 'coach_${widget.coach.uid}_${rawName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}');

    final description = _clean(data['description']).isNotEmpty
        ? _clean(data['description'])
        : (_clean(data['achievement']).isNotEmpty
            ? _clean(data['achievement'])
            : 'High-performance squad curated by ${widget.coach.fullName}.');

    final sportType = _resolveSportType(
      data['sportType'] ?? data['sport'] ?? data['sportCategory'],
    );

    final now = DateTime.now();
    final badge = _clean(data['badge'] ?? data['logoUrl']);
    final city =
        _clean(data['location'] ?? data['city'] ?? widget.coach.location);

    final members = _buildTeamMembersFor(
      teamId: id,
      teamName: rawName,
      now: now,
    );

    return TeamModel(
      id: id,
      name: rawName,
      description: description,
      bio: _clean(data['bio']).isNotEmpty ? _clean(data['bio']) : null,
      sportType: sportType,
      ownerId: widget.coach.uid,
      members: members,
      maxMembers: _tryParseInt(data['maxMembers']) ??
          _tryParseInt(data['memberCount']) ??
          20,
      isPublic: true,
      teamImageUrl: badge.isNotEmpty ? badge : null,
      backgroundImageUrl: _clean(data['backgroundImageUrl']),
      location: city.isNotEmpty ? city : widget.coach.location,
      coachId: widget.coach.uid,
      coachName: widget.coach.fullName,
      venuesPlayed: const [],
      tournamentsParticipated: const [],
      createdAt: now,
      updatedAt: now,
      metadata: _buildTeamMetadata(data),
    );
  }

  List<TeamMember> _buildTeamMembersFor({
    required String teamId,
    required String teamName,
    required DateTime now,
  }) {
    final members = <TeamMember>[
      TeamMember(
        userId: widget.coach.uid,
        userName: widget.coach.fullName,
        profileImageUrl: widget.coach.profilePictureUrl,
        role: TeamRole.coach,
        joinedAt: now,
        trophies: widget.coach.experienceYears,
        rating: 5,
      ),
    ];

    final rosterPlayers = _coachPlayers.where((player) {
      final playerTeamId = (player['teamId'] ?? '').toString();
      final playerTeamName = (player['teamName'] ?? '').toString();
      return playerTeamId == teamId ||
          (playerTeamId.isEmpty &&
              playerTeamName.isNotEmpty &&
              playerTeamName.toLowerCase() == teamName.toLowerCase());
    }).toList();

    if (rosterPlayers.isEmpty &&
        teamName.toLowerCase().contains(_primarySport.toLowerCase())) {
      rosterPlayers.addAll(_coachPlayers.take(4));
    }

    for (var i = 0; i < rosterPlayers.length; i++) {
      final player = rosterPlayers[i];
      final userId =
          (player['uid'] ?? player['userId'] ?? player['playerId'])?.toString() ??
              'player_${teamId}_$i';
      final userName =
          (player['name'] ?? player['playerName'] ?? 'Athlete ${i + 1}')
              .toString();

      members.add(
        TeamMember(
          userId: userId,
          userName: userName,
          profileImageUrl: player['avatar']?.toString(),
          role: TeamRole.member,
          joinedAt: now.subtract(Duration(days: i * 12)),
          position: player['position']?.toString(),
          jerseyNumber: _tryParseInt(player['jerseyNumber']),
          trophies: _tryParseInt(player['trophies']) ?? 0,
          rating: (player['rating'] as num?)?.toDouble(),
        ),
      );
    }

    return members;
  }

  Map<String, dynamic>? _buildTeamMetadata(Map<String, dynamic> data) {
    final metadata = <String, dynamic>{};
    void addValue(String key, dynamic value) {
      if (value == null) return;
      metadata[key] = value;
    }

    addValue('achievement', data['achievement']);
    addValue('winRate', data['winRate']);
    addValue('memberCount', data['memberCount']);
    addValue('sportType', data['sportType']);

    return metadata.isEmpty ? null : metadata;
  }

  SportType _resolveSportType(dynamic raw) {
    if (raw is SportType) return raw;
    final label = raw?.toString().trim();
    if (label == null || label.isEmpty) {
      return SportType.other;
    }

    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final target = normalize(label);

    SportType match = SportType.values.firstWhere(
      (type) {
        final name = normalize(type.name);
        final display = normalize(type.displayName);
        return name == target || display == target;
      },
      orElse: () => SportType.other,
    );

    if (match == SportType.other) {
      final fallback = normalize(_primarySport);
      match = SportType.values.firstWhere(
        (type) {
          final name = normalize(type.name);
          final display = normalize(type.displayName);
          return name == fallback || display == fallback;
        },
        orElse: () => SportType.other,
      );
    }

    return match;
  }

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  void _showProfileUnavailable(String? name) {
    if (!mounted) return;
    final trimmed = name?.trim();
    final displayName =
        (trimmed != null && trimmed.isNotEmpty) ? '$trimmed\'s' : 'This';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$displayName profile is not available yet.'),
      ),
    );
  }

  void _editProfile() {
    // Navigate to the coach profile edit screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoachProfileEditScreen(coach: widget.coach),
      ),
    );
  }

  void _addReview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ReviewDialog(coachName: widget.coach.fullName);
      },
    );
  }
}

class _MetricHighlightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _MetricHighlightTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorsManager.primary.withOpacity(0.18),
            ),
            padding: EdgeInsets.all(10.w),
            child: Icon(
              icon,
              color: ColorsManager.primary,
              size: 20.sp,
            ),
          ),
          Gap(14.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(6.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Gap(6.h),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding a review
class _ReviewDialog extends StatefulWidget {
  final String coachName;

  const _ReviewDialog({required this.coachName});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: Color(0xFF00FFFF), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Review ${widget.coachName}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Gap(16.h),

            // Rating
            Text(
              'Rating:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Gap(8.h),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFF00FFFF), // Neon blue
                    size: 32.sp,
                  ),
                );
              }),
            ),
            Gap(16.h),

            // Review Text
            Text(
              'Review:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Gap(8.h),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Share your experience with this coach...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFF00FFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide:
                      const BorderSide(color: Color(0xFF00FFFF), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
            Gap(20.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: ColorsManager.primary,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Implement actual review submission to Firebase
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Color(0xFF00FFFF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CoachTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _CoachTabBarDelegate({required this.tabBar});

  final TabBar tabBar;

  // Calculate padding values and round to avoid floating point issues
  double get _verticalPadding => ((10.h) * 100).round() / 100.0;
  double get _innerPadding => ((4.h) * 100).round() / 100.0;
  double get _extraPadding => ((2.h) * 100).round() / 100.0;

  // Calculate extent with precise rounding to prevent floating point errors
  double _getExtent() {
    // Use the getters to ensure consistency
    final verticalPadding = _verticalPadding;
    final innerPadding = _innerPadding;
    final extraPadding = _extraPadding;
    final tabBarHeight = (kTextTabBarHeight * 100).round() / 100.0;
    
    // Calculate total extent with all rounded values
    final total = tabBarHeight + 
                  (verticalPadding * 2) + 
                  extraPadding + 
                  (innerPadding * 2);
    
    // Round to 2 decimal places and use a very small epsilon to ensure layoutExtent <= paintExtent
    // This prevents the tiny floating point differences (e.g., 0.00000000000002) that cause the error
    final rounded = (total * 100).round() / 100.0;
    
    // Subtract a minimal epsilon (0.0001) to ensure layoutExtent is always <= paintExtent
    // This is a workaround for Flutter's internal geometry calculation precision issues
    // The epsilon is small enough to not cause visual differences but prevents the error
    return (rounded * 10000 - 1).floor() / 10000.0;
  }

  @override
  double get minExtent => _getExtent();

  @override
  double get maxExtent => _getExtent();

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final baseColor = const Color(0xFF050414);
    final extent = minExtent;

    return SizedBox(
      height: extent,
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withOpacity(0.98),
            baseColor.withOpacity(0.94),
          ],
        ),
        boxShadow: [
          if (overlapsContent)
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 22),
            ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: _verticalPadding,
        bottom: _verticalPadding + _extraPadding,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: _innerPadding),
            child: tabBar,
          ),
        ),
      ),
    ),
    );
  }

  @override
  bool shouldRebuild(covariant _CoachTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}

/// Hero action button widget (same style as public profile)
class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: PublicProfileTheme.panelColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: PublicProfileTheme.panelAccentColor),
            Gap(6.w),
            Text(
              label,
              style: TextStyles.font12White600Weight.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

