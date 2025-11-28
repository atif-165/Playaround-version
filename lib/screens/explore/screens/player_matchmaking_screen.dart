import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:gap/gap.dart';

import '../../../core/navigation/detail_navigator.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../data/models/match_decision_model.dart';
import '../../../data/models/player_model.dart';
import '../../../data/repositories/matchmaking_repository.dart';
import '../../../services/location_service.dart';
import '../../../theming/colors.dart';
import '../../dashboard/models/user_profile_dashboard_models.dart';
import '../../dashboard/services/user_profile_dashboard_service.dart';
import '../../../modules/chat/screens/matches_screen.dart';

const _matchBackgroundColor = Color(0xFF050414);
const LinearGradient _matchBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);
const LinearGradient _matchPanelGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF181536),
    Color(0xFF0E0D24),
  ],
);
const Color _matchPanelColor = Color(0xFF14112D);
const Color _matchOverlayColor = Color(0xFF1C1A3C);
const Color _matchAccentColor = Color(0xFFFFC56F);

/// Screen for swipe-based player matchmaking
class PlayerMatchmakingScreen extends StatefulWidget {
  const PlayerMatchmakingScreen({
    super.key,
    this.userLocation,
    this.repository,
    this.firebaseAuth,
    this.showBackButton = true,
  });

  final GeoPoint? userLocation;
  final MatchmakingRepository? repository;
  final FirebaseAuth? firebaseAuth;
  // Nullable internally to be resilient against stale/hot-reload states where this
  // value might momentarily be null. We always fall back to `true` in the UI.
  final bool? showBackButton;

  @override
  State<PlayerMatchmakingScreen> createState() =>
      _PlayerMatchmakingScreenState();
}

class _PlayerMatchmakingScreenState extends State<PlayerMatchmakingScreen> {
  static const Color _accentColor = _matchAccentColor;
  static const LinearGradient _backgroundGradient = _matchBackgroundGradient;
  static const LinearGradient _panelGradient = _matchPanelGradient;
  static const Color _panelColor = _matchPanelColor;
  static const Color _overlayColor = _matchOverlayColor;

  late final MatchmakingRepository _repository;
  FirebaseAuth? _auth;
  final SwipableStackController _controller = SwipableStackController();

  List<PlayerModel> _profiles = [];
  bool _loading = true;
  String? _error;
  bool _syncing = false;
  int _superLikes = 0;
  bool _isProfileModalOpen = false;
  static const int _superLikeLimit = 3;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MatchmakingRepository();
    try {
      _auth = widget.firebaseAuth ?? FirebaseAuth.instance;
    } catch (_) {
      _auth = widget.firebaseAuth;
    }
    _loadProfiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repository.init();
      await _repository.syncMatchDecisions();
      final players = await _repository.loadPlayers();
      final currentUser = _auth?.currentUser;
      _profiles =
          players.where((player) => player.id != currentUser?.uid).toList();
      setState(() {
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _error = 'Unable to load matchmaking profiles';
      });
    }
  }

  Future<void> _handleSwipe(
    int index,
    SwipeDirection direction,
  ) async {
    if (index >= _profiles.length) return;
    final player = _profiles[index];
    final currentUser = _auth?.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to continue')),
      );
      return;
    }

    MatchDecisionType decision;
    switch (direction) {
      case SwipeDirection.right:
        decision = MatchDecisionType.like;
        break;
      case SwipeDirection.up:
        if (_superLikes >= _superLikeLimit) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Super like limit reached')),
          );
          decision = MatchDecisionType.like;
        } else {
          decision = MatchDecisionType.superLike;
          _superLikes += 1;
        }
        break;
      default:
        decision = MatchDecisionType.dislike;
        break;
    }

    setState(() {});

    await _repository.updateMatchDecision(
      swiperId: currentUser.uid,
      targetId: player.id,
      decision: decision,
    );
  }

  Future<void> _triggerSync() async {
    setState(() => _syncing = true);
    await _repository.syncMatchDecisions();
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Synced decisions')),
    );
  }

  void _openMatches() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MatchesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _matchBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 16,
        title: const Text(
          'Swipe matches',
          style: TextStyle(
            color: ColorsManager.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        // We fully control the back button to ensure the main navigation
        // entry has no back/close icon, while secondary entries do.
        automaticallyImplyLeading: false,
        leading: (widget.showBackButton ?? true)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: ColorsManager.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: _openMatches,
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final topOffset = mediaQuery.padding.top + kToolbarHeight;

    Widget wrap(Widget child) {
      return Container(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            // Add extra bottom padding so swipe actions sit above any custom
            // navigation bars (e.g. main navigation screen) while still
            // respecting the device's safe area in other entry points.
            padding: EdgeInsets.only(
              bottom: safeBottom + (widget.showBackButton ?? true ? 24.h : 80.h),
            ),
            child: child,
          ),
        ),
      );
    }

    if (_loading) {
      return wrap(
        const Center(child: CustomProgressIndicator()),
      );
    }

    if (_error != null) {
      return wrap(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 52.sp,
                color: Colors.white.withOpacity(0.6),
              ),
              Gap(16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              Gap(20.h),
              ElevatedButton(
                onPressed: _loadProfiles,
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return wrap(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_satisfied_alt,
                size: 64.sp,
                color: Colors.white.withOpacity(0.6),
              ),
              Gap(18.h),
              Text(
                'You are all caught up!',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Gap(10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  'Check back later for more scouting opportunities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              Gap(26.h),
              ElevatedButton(
                onPressed: _loadProfiles,
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reload'),
              ),
            ],
          ),
        ),
      );
    }

    return wrap(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topOffset + 16.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: SwipableStack(
                controller: _controller,
                stackClipBehaviour: Clip.none,
                itemCount: _profiles.length,
                onSwipeCompleted: _handleSwipe,
                builder: (context, properties) {
                  final player = _profiles[properties.index];
                  return _MatchCard(
                    player: player,
                    distanceKm: _distance(player),
                    onInfoTap: () => _showProfile(player),
                  );
                },
              ),
            ),
          ),
          _buildActions(),
          Gap(32.h),
        ],
      ),
    );
  }

  double? _distance(PlayerModel player) {
    if (widget.userLocation == null ||
        player.latitude == null ||
        player.longitude == null) {
      return null;
    }
    final playerPoint = GeoPoint(player.latitude!, player.longitude!);
    return LocationService()
        .calculateDistance(widget.userLocation!, playerPoint);
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MatchActionButton(
            buttonKey: const Key('dislike_button'),
            icon: Icons.close,
            color: Colors.redAccent,
            onTap: () => _controller.next(
              swipeDirection: SwipeDirection.left,
            ),
          ),
          _MatchActionButton(
            buttonKey: const Key('super_like_button'),
            icon: Icons.star,
            color: Colors.amber,
            scale: 1.3,
            onTap: () => _controller.next(
              swipeDirection: SwipeDirection.up,
            ),
            disabled: _superLikes >= _superLikeLimit,
          ),
          _MatchActionButton(
            buttonKey: const Key('like_button'),
            icon: Icons.favorite,
            color: Colors.green,
            onTap: () => _controller.next(
              swipeDirection: SwipeDirection.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfile(PlayerModel player) {
    // Prevent multiple modals from opening simultaneously
    if (_isProfileModalOpen) return;
    
    final distance = _distance(player);
    _isProfileModalOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlayerDetailSheet(
        player: player,
        distanceKm: distance,
      ),
    ).whenComplete(() {
      // Reset flag when modal is dismissed
      if (mounted) {
        setState(() {
          _isProfileModalOpen = false;
        });
      }
    });
  }
}

class _MatchCard extends StatefulWidget {
  const _MatchCard({
    required this.player,
    required this.onInfoTap,
    this.distanceKm,
  });

  final PlayerModel player;
  final double? distanceKm;
  final VoidCallback onInfoTap;

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  late final int _matchPercentage;

  @override
  void initState() {
    super.initState();
    // Generate random match percentage between 50-80
    final random = Random();
    _matchPercentage = 50 + random.nextInt(31); // 50 + (0-30) = 50-80
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      // Smaller ratio = more height for the same width (taller card)
      // Changed to 2/3 to make card taller and give more space to image
      aspectRatio: 2 / 3,
      child: Card(
        elevation: 18,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.r)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackgroundImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Match percentage circle in top right
            Positioned(
              top: 16.h,
              right: 16.w,
              child: _buildMatchPercentageCircle(),
            ),
            Positioned(
              bottom: 18.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.player.fullName,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Gap(4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 14.sp,
                        color: Colors.white70,
                      ),
                      Gap(5.w),
                      Expanded(
                        child: Text(
                          '${widget.player.age} • ${widget.player.location}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.distanceKm != null) ...[
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.pin_drop_outlined,
                          size: 14.sp,
                          color: Colors.white70,
                        ),
                        Gap(5.w),
                        Text(
                          '${widget.distanceKm!.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.player.sports.isNotEmpty) ...[
                    Gap(10.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: widget.player.sports.take(3).map((sport) {
                        return Chip(
                          label: Text(
                            sport,
                            style: TextStyle(fontSize: 11.sp),
                          ),
                          backgroundColor:
                              Colors.white.withOpacity(0.18),
                          labelStyle: const TextStyle(color: Colors.white),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  Gap(12.h),
                  ElevatedButton.icon(
                    onPressed: widget.onInfoTap,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.22),
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(Icons.info_outline, size: 16.sp),
                    label: Text(
                      'View details',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchPercentageCircle() {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.4),
        border: Border.all(
          color: _matchAccentColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$_matchPercentage%',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    if (widget.player.avatarUrl != null && widget.player.avatarUrl!.isNotEmpty) {
      return Image.network(
        widget.player.avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackImage(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildFallbackImage(),
              Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: Colors.white70,
                ),
              ),
            ],
          );
        },
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A2740),
            Color(0xFF0D1325),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        color: Colors.white.withOpacity(0.6),
        size: 72.sp,
      ),
    );
  }
}

class _MatchActionButton extends StatelessWidget {
  const _MatchActionButton({
    this.buttonKey,
    required this.icon,
    required this.color,
    required this.onTap,
    this.scale = 1.0,
    this.disabled = false,
  });

  final Key? buttonKey;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double scale;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: disabled ? null : onTap,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: disabled ? color.withValues(alpha: 0.2) : Colors.white,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 28.sp,
          ),
        ),
      ),
    );
  }
}

class _PlayerDetailSheet extends StatefulWidget {
  const _PlayerDetailSheet({
    required this.player,
    this.distanceKm,
  });

  final PlayerModel player;
  final double? distanceKm;

  @override
  State<_PlayerDetailSheet> createState() => _PlayerDetailSheetState();
}

class _PlayerDetailSheetState extends State<_PlayerDetailSheet> {
  final PublicProfileService _service = PublicProfileService();
  final PageController _pageController = PageController();

  MatchmakingShowcase? _showcase;
  List<String> _gallery = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadMatchmaking();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchmaking() async {
    try {
      final data = await _service.fetchProfile(widget.player.id);
      if (!mounted) return;
      setState(() {
        _showcase = data.matchmaking;
        _gallery = List<String>.from(data.matchmaking.images);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
        _gallery = widget.player.gallery;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1B1848),
        Color(0xFF080612),
      ],
    );

    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.92;

    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: themeGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error || _showcase == null) {
      return _buildFallbackContent();
    }

    final showcase = _showcase!;
    final List<String> images = _gallery.isNotEmpty
        ? _gallery
        : (widget.player.gallery.isNotEmpty
            ? widget.player.gallery
            : widget.player.avatarUrl != null
                ? [widget.player.avatarUrl!]
                : const []);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 60.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          Gap(20.h),
          if (images.isNotEmpty) ...[
            _buildGallery(images),
            Gap(16.h),
          ],
          Text(
            showcase.tagline,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Gap(12.h),
          Text(
            showcase.about,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.5,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          Gap(16.h),
          _buildQuickInfo(showcase),
          Gap(20.h),
          _buildSports(showcase),
          if (showcase.allowMessagesFromFriendsOnly) ...[
            Gap(16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white70),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      'Messages open for mutual connections only.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Gap(20.h),
          _buildFeaturedAssociations(showcase),
        ],
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    return Column(
      children: [
        SizedBox(
          height: 230.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.white.withOpacity(0.08)),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          Gap(10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                height: 6.h,
                width: _currentIndex == index ? 26.w : 8.w,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? _matchAccentColor
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickInfo(MatchmakingShowcase showcase) {
    final List<Widget> rows = [];

    rows.add(_buildInfoRow(
      icon: Icons.pin_drop_outlined,
      text: '${showcase.city} • ${widget.player.age} yrs',
    ));

    if (widget.distanceKm != null) {
      rows.add(_buildInfoRow(
        icon: Icons.map_outlined,
        text: '${widget.distanceKm!.toStringAsFixed(1)} km away',
      ));
    } else if (showcase.distanceKm != null) {
      rows.add(_buildInfoRow(
        icon: Icons.map_outlined,
        text: '${showcase.distanceKm!.toStringAsFixed(1)} km away',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, color: _matchAccentColor, size: 18.sp),
          Gap(10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSports(MatchmakingShowcase showcase) {
    final sports = showcase.sports;
    if (sports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plays',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: sports
              .map(
                (sport) => Chip(
                  label: Text(sport),
                  backgroundColor: _matchAccentColor.withOpacity(0.18),
                  labelStyle: TextStyle(
                    color: _matchAccentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFeaturedAssociations(MatchmakingShowcase showcase) {
    final entries = <Widget>[];

    void addTile(
      String label,
      AssociationCardData? data, {
      VoidCallback? onTap,
    }) {
      if (data == null) return;
      entries.add(
        _FeaturedAssociationTile(
          title: label,
          data: data,
          onTap: onTap,
        ),
      );
    }

    addTile(
      'Featured team',
      showcase.featuredTeam,
      onTap: showcase.featuredTeam == null
          ? null
          : () => DetailNavigator.openTeam(
                context,
                teamId: showcase.featuredTeam!.id,
              ),
    );
    addTile(
      'Preferred venue',
      showcase.featuredVenue,
      onTap: showcase.featuredVenue == null
          ? null
          : () => DetailNavigator.openVenue(
                context,
                venueId: showcase.featuredVenue!.id,
              ),
    );
    addTile(
      'Primary coach',
      showcase.featuredCoach,
      onTap: showcase.featuredCoach == null
          ? null
          : () => DetailNavigator.openCoach(
                context,
                coachId: showcase.featuredCoach!.id,
              ),
    );
    addTile(
      'Tournament spotlight',
      showcase.featuredTournament,
      onTap: showcase.featuredTournament == null
          ? null
          : () => DetailNavigator.openTournament(
                context,
                tournamentId: showcase.featuredTournament!.id,
              ),
    );

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Highlights',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Gap(12.h),
        ...entries.expand(
          (entry) => [
            entry,
            Gap(12.h),
          ],
        ).toList()
          ..removeLast(),
      ],
    );
  }

  Widget _buildFallbackContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 60.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          Gap(20.h),
          Text(
            widget.player.fullName,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Gap(8.h),
          Text(
            widget.player.bio ?? 'No matchmaking details available yet.',
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.5,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          Gap(16.h),
          if (widget.player.gallery.isNotEmpty)
            SizedBox(
              height: 140.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.player.gallery.length,
                separatorBuilder: (_, __) => Gap(12.w),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: CachedNetworkImage(
                    imageUrl: widget.player.gallery[index],
                    width: 160.w,
                    height: 120.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedAssociationTile extends StatelessWidget {
  const _FeaturedAssociationTile({
    required this.title,
    required this.data,
    this.onTap,
  });

  final String title;
  final AssociationCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: CachedNetworkImage(
                imageUrl: data.imageUrl,
                width: 48.w,
                height: 48.w,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            subtitle: Text(
              data.title,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
