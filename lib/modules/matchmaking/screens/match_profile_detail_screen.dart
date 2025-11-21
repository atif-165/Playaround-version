import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/user_profile.dart';
import '../models/matchmaking_models.dart';
// import '../widgets/swipe_action_buttons.dart';
import '../widgets/match_dialog.dart';
import '../services/matchmaking_service.dart';

/// Detailed profile view screen for potential matches
class MatchProfileDetailScreen extends StatefulWidget {
  final MatchProfile profile;

  const MatchProfileDetailScreen({
    super.key,
    required this.profile,
  });

  @override
  State<MatchProfileDetailScreen> createState() =>
      _MatchProfileDetailScreenState();
}

class _MatchProfileDetailScreenState extends State<MatchProfileDetailScreen> {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;
  bool _isProcessingSwipe = false;

  Color get _accentColor {
    final sports = widget.profile.sportsOfInterest;
    if (sports.isEmpty) return ColorsManager.primary;
    final palette = [
      ColorsManager.primary,
      ColorsManager.secondary,
      ColorsManager.success,
      const Color(0xFF00B8FF),
      const Color(0xFFFF3B30),
    ];
    final seed = sports.first.codeUnitAt(0);
    return palette[seed % palette.length];
  }

  Widget _buildHeroSection(double topPadding) {
    final photos = widget.profile.allPhotos;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withOpacity(0.85),
            _accentColor.withOpacity(0.55),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.35),
            blurRadius: 36,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, topPadding + 12.h, 24.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photos.isEmpty)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF10162F),
                              Color(0xFF070B1D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.sports_handball,
                          size: 72.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      )
                    else
                      PageView.builder(
                        controller: _photoController,
                        onPageChanged: (index) =>
                            setState(() => _currentPhotoIndex = index),
                        itemCount: photos.length,
                        itemBuilder: (context, index) => CachedNetworkImage(
                          imageUrl: photos[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.black26),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.black45,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white.withOpacity(0.6),
                              size: 48.sp,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 160.h,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black87,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 24.h,
                      right: 24.w,
                      child: _buildSynergyBadge(),
                    ),
                    Positioned(
                      top: 24.h,
                      left: 24.w,
                      child: _buildStatusPill(),
                    ),
                    if (photos.length > 1)
                      Positioned(
                        bottom: 20.h,
                        left: 0,
                        right: 0,
                        child: _buildPhotoIndicators(photos.length),
                      ),
                  ],
                ),
              ),
            ),
            Gap(24.h),
            _buildHeroMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoIndicators(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isActive = index == _currentPhotoIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          height: 6.h,
          width: isActive ? 26.w : 10.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildSynergyBadge() {
    final synergyScore = widget.profile.compatibilityScore;
    final label =
        widget.profile.isMatched ? 'Already Matched' : 'Synergy Score';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          Gap(8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.bolt_rounded,
                color: ColorsManager.tertiary,
                size: 20.sp,
              ),
              Gap(6.w),
              Text(
                '$synergyScore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Gap(6.h),
          Text(
            _primarySport.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final isOnline = widget.profile.isOnline;
    final statusText =
        isOnline ? 'LIVE NOW' : 'ACTIVE ${_formatLastActive().toUpperCase()}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: Colors.black.withOpacity(0.4),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              color: isOnline ? ColorsManager.success : Colors.amberAccent,
              shape: BoxShape.circle,
            ),
          ),
          Gap(8.w),
          Text(
            statusText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: _mapSportToIcon(_primarySport),
            label: 'Primary Sport',
            value: _primarySport,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.emoji_events_rounded,
            label: 'Skill Level',
            value: widget.profile.skillLevel.displayName,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.route_rounded,
            label: 'Distance',
            value: widget.profile.formattedDistance,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: Colors.white,
          ),
          Gap(12.h),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          Gap(6.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatLastActive() {
    final diff = DateTime.now().difference(widget.profile.lastActive);
    if (diff.inMinutes < 2) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get _primarySport => widget.profile.sportsOfInterest.isNotEmpty
      ? widget.profile.sportsOfInterest.first
      : 'Multi-sport';

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ColorsManager.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBody(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 20.sp,
              ),
              onPressed: _showOptionsMenu,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + kToolbarHeight;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withOpacity(0.2),
            ColorsManager.background,
            ColorsManager.background,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(topPadding),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ColorsManager.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28.r),
                  topRight: Radius.circular(28.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, -12),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 140.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfo(),
                    Gap(20.h),
                    _buildHighlightBadges(),
                    Gap(24.h),
                    _buildAboutSection(),
                    Gap(24.h),
                    _buildSportsSection(),
                    Gap(24.h),
                    _buildInterestsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.profile.fullName,
          style: TextStyles.font28White700Weight.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        Gap(8.h),
        Text(
          '${widget.profile.age} yrs • ${widget.profile.role == UserRole.coach ? 'Coach' : 'Athlete'}',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        Gap(16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: ColorsManager.textSecondary,
              size: 18.sp,
            ),
            Gap(8.w),
            Expanded(
              child: Text(
                widget.profile.location,
                style: TextStyles.font16White400Weight.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyles.font16White600Weight.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    );
  }

  Widget _buildHighlightBadges() {
    final badges = <Widget>[
      _buildInfoChip(
        icon: Icons.calendar_month_rounded,
        label: '${widget.profile.age} yrs',
      ),
      _buildInfoChip(
        icon: widget.profile.role == UserRole.coach
            ? Icons.military_tech_rounded
            : Icons.person_pin_circle_outlined,
        label: widget.profile.role == UserRole.coach ? 'Coach' : 'Athlete',
      ),
    ];

    if (widget.profile.sportsOfInterest.length > 1) {
      badges.add(
        _buildInfoChip(
          icon: Icons.sports,
          label: '${widget.profile.sportsOfInterest.length} sports',
        ),
      );
    }

    badges.add(
      _buildInfoChip(
        icon: Icons.bolt_rounded,
        label: widget.profile.isMatched
            ? 'On your roster'
            : 'Synergy ${widget.profile.compatibilityScore}%',
      ),
    );

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: badges,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: ColorsManager.surfaceVariant.withOpacity(0.75),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: _accentColor,
          ),
          Gap(8.w),
          Text(
            label,
            style: TextStyles.font14White600Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    if (widget.profile.bio == null || widget.profile.bio!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PLAY STYLE NOTES'),
        Gap(12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: ColorsManager.surfaceVariant.withOpacity(0.78),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Text(
            widget.profile.bio!,
            style: TextStyles.font16White400Weight.copyWith(
              height: 1.6,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportsSection() {
    if (widget.profile.sportsOfInterest.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PREFERRED SPORTS'),
        Gap(12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: widget.profile.sportsOfInterest.map((sport) {
            final icon = _mapSportToIcon(sport);
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _accentColor.withOpacity(0.45)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accentColor.withOpacity(0.22),
                    ColorsManager.surfaceVariant.withOpacity(0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                  Gap(10.w),
                  Text(
                    sport,
                    style: TextStyles.font14White600Weight,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    if (widget.profile.interests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('OFF-COURT INTERESTS'),
        Gap(12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: widget.profile.interests.map((interest) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: ColorsManager.surfaceVariant.withOpacity(0.82),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Text(
                interest,
                style: TextStyles.font14White400Weight.copyWith(
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20.w,
          18.h,
          20.w,
          bottomInset + 22.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              _accentColor.withOpacity(0.95),
              _accentColor.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            _buildActionControl(
              icon: Icons.skip_next_rounded,
              label: 'Skip',
              gradientColors: [
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.08),
              ],
              foregroundColor: Colors.white,
              onTap: _isProcessingSwipe ? null : _handleDislike,
              shadowColor: Colors.black.withOpacity(0.2),
            ),
            Gap(12.w),
            _buildActionControl(
              icon: Icons.groups_3_rounded,
              label: 'Team Up',
              gradientColors: [
                ColorsManager.success.withOpacity(0.95),
                ColorsManager.success.withOpacity(0.75),
              ],
              foregroundColor: Colors.black,
              onTap: _isProcessingSwipe ? null : _handleLike,
              shadowColor: ColorsManager.success.withOpacity(0.35),
            ),
            Gap(12.w),
            _buildActionControl(
              icon: Icons.sports_martial_arts_rounded,
              label: 'Challenge',
              gradientColors: [
                ColorsManager.secondary.withOpacity(0.95),
                ColorsManager.primary.withOpacity(0.8),
              ],
              onTap: _isProcessingSwipe ? null : _handleSuperLike,
              shadowColor: ColorsManager.primary.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionControl({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    Color? foregroundColor,
    VoidCallback? onTap,
    Color? shadowColor,
  }) {
    final disabled = onTap == null;
    final textColor = foregroundColor ?? Colors.white;

    return Expanded(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.45 : 1,
        child: GestureDetector(
          onTap: disabled ? null : onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color:
                      (shadowColor ?? gradientColors.last).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 28.sp,
                  color: textColor,
                ),
                Gap(8.h),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _mapSportToIcon(String sport) {
    final normalized = sport.toLowerCase();
    if (normalized.contains('football') || normalized.contains('soccer')) {
      return Icons.sports_soccer;
    }
    if (normalized.contains('basket')) {
      return Icons.sports_basketball;
    }
    if (normalized.contains('cricket')) {
      return Icons.sports_cricket;
    }
    if (normalized.contains('tennis')) {
      return Icons.sports_tennis;
    }
    if (normalized.contains('run') || normalized.contains('athlet')) {
      return Icons.directions_run;
    }
    if (normalized.contains('swim')) {
      return Icons.pool;
    }
    if (normalized.contains('yoga') || normalized.contains('meditat')) {
      return Icons.self_improvement;
    }
    if (normalized.contains('volley')) {
      return Icons.sports_volleyball;
    }
    if (normalized.contains('hockey')) {
      return Icons.sports_hockey;
    }
    if (normalized.contains('baseball')) {
      return Icons.sports_baseball;
    }
    return Icons.sports;
  }

  Future<void> _handleDislike() async {
    await _handleSwipeAction(SwipeAction.dislike);
  }

  Future<void> _handleSuperLike() async {
    await _handleSwipeAction(SwipeAction.superLike);
  }

  Future<void> _handleLike() async {
    await _handleSwipeAction(SwipeAction.like);
  }

  Future<void> _handleSwipeAction(SwipeAction action) async {
    if (_isProcessingSwipe) return;

    setState(() => _isProcessingSwipe = true);

    try {
      final result = await _matchmakingService.recordSwipe(
        targetUserId: widget.profile.uid,
        action: action,
      );

      if (result.isMatch) {
        _showMatchDialog(result.match!);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to record action');
      setState(() => _isProcessingSwipe = false);
    }
  }

  void _showMatchDialog(Match match) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MatchDialog(
        match: match,
        currentUserId: currentUserId,
      ),
    ).then((_) {
      Navigator.pop(context); // Close profile detail screen
    });
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsManager.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report, color: ColorsManager.error),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _showErrorSnackBar('Report functionality coming soon');
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: ColorsManager.error),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _showErrorSnackBar('Block functionality coming soon');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorsManager.error,
      ),
    );
  }
}
