import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../helpers/admin_override_helper.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../models/models.dart';
import '../services/team_service.dart';
import 'team_admin_screen.dart';
import '../widgets/join_request_card.dart';
import '../widgets/team_member_card.dart';
import '../widgets/team_match_card.dart';
import '../widgets/player_profile_modal.dart';
import 'team_join_requests_screen.dart';
import 'team_match_detail_screen.dart';
import '../../coach/screens/coach_detail_screen.dart';
import '../../matchmaking/screens/match_profile_detail_screen.dart';
import '../../../models/coach_profile.dart';
import '../../../models/user_profile.dart';
import '../../matchmaking/models/matchmaking_models.dart';

class _AdminHeroActionButton extends StatelessWidget {
  const _AdminHeroActionButton({
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
          color: PublicProfileTheme.panelColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: PublicProfileTheme.defaultShadow(),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: PublicProfileTheme.panelAccentColor),
            Gap(6.w),
            Text(
              label,
              style: TextStyles.font12White600Weight.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamDetailScreenEnhanced extends StatefulWidget {
  final TeamModel team;

  const TeamDetailScreenEnhanced({
    super.key,
    required this.team,
  });

  @override
  State<TeamDetailScreenEnhanced> createState() =>
      _TeamDetailScreenEnhancedState();
}

class _TeamDetailScreenEnhancedState extends State<TeamDetailScreenEnhanced>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late final Random _randomSeed;
  late final List<Map<String, dynamic>> _achievementTimeline;
  late final List<Map<String, dynamic>> _playerSpotlight;
  late final List<Map<String, dynamic>> _trainingFocus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _randomSeed = Random(widget.team.id.hashCode);
    _achievementTimeline = _buildAchievementTimeline();
    _playerSpotlight = _buildPlayerSpotlight();
    _trainingFocus = _buildTrainingFocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasAdminOverride => AdminOverrideHelper.allowTeamOverride(widget.team);
  bool get _isAdmin => widget.team.isAdminOrOwner(_currentUserId) || _hasAdminOverride;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildTeamHeader(),
                _buildTabBar(),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildMembersTab(),
                _buildMatchesTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.h,
      floating: false,
      pinned: true,
      backgroundColor: ColorsManager.background,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Builder(
          builder: (context) {
            final mediaPadding = MediaQuery.of(context).padding;
            
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorsManager.primary.withValues(alpha: 0.1),
                    ColorsManager.background,
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.team.bannerImageUrl != null)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: widget.team.bannerImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: ColorsManager.primaryGradient,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ColorsManager.onPrimary,
                              strokeWidth: 2.w,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: ColorsManager.primaryGradient,
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: ColorsManager.onPrimary,
                            size: 48.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: ColorsManager.primaryGradient,
                      ),
                      child: Icon(
                        Icons.groups,
                        color: ColorsManager.onPrimary,
                        size: 64.sp,
                      ),
                    ),
                  // Overlay for better text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Admin button positioned like tournament detail screen
                  if (_isAdmin)
                    Positioned(
                      top: mediaPadding.top + 12.h,
                      right: 16.w,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 360),
                        tween: Tween<double>(begin: -18, end: 0),
                        curve: Curves.easeOutCubic,
                        builder: (context, offset, child) {
                          return Transform.translate(
                            offset: Offset(0, offset),
                            child: child,
                          );
                        },
                        child: _AdminHeroActionButton(
                          icon: Icons.dashboard_customize_outlined,
                          label: 'Admin',
                          onTap: _openAdminPanel,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openAdminPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          initialChildSize: 0.9,
          minChildSize: 0.65,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                gradient: ColorsManager.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                child: TeamAdminScreen(
                  teamId: widget.team.id,
                  teamName: widget.team.name,
                  isReadOnly: !_isAdmin,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // Main team info card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorsManager.surfaceVariant,
                  ColorsManager.background,
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: ColorsManager.primary.withValues(alpha: 0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  blurRadius: 20.r,
                  offset: Offset(0, 8.h),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildEnhancedTeamAvatar(),
                    Gap(16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.team.name,
                                  style: TextStyles.font20DarkBlue600Weight
                                      .copyWith(
                                    color: ColorsManager.onBackground,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildTeamStatusBadge(),
                            ],
                          ),
                          Gap(8.h),
                          _buildSportAndLocationRow(),
                          Gap(12.h),
                          _buildTeamStatsRow(),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.team.description != null &&
                    widget.team.description!.isNotEmpty) ...[
                  Gap(16.h),
                  _buildDescriptionSection(),
                ],
              ],
            ),
          ),
          Gap(16.h),
          // Join team button
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildEnhancedTeamAvatar() {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: ColorsManager.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.3),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17.r),
            color: ColorsManager.background,
          ),
          child: widget.team.profileImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(17.r),
                  child: CachedNetworkImage(
                    imageUrl: widget.team.profileImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: ColorsManager.primary,
                        strokeWidth: 2.w,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.groups,
                      color: ColorsManager.primary,
                      size: 32.sp,
                    ),
                  ),
                )
              : Icon(
                  Icons.groups,
                  color: ColorsManager.primary,
                  size: 32.sp,
                ),
        ),
      ),
    );
  }

  Widget _buildTeamStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: ColorsManager.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.3),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups,
            color: ColorsManager.onPrimary,
            size: 12.sp,
          ),
          Gap(4.w),
          Text(
            'TEAM',
            style: TextStyle(
              color: ColorsManager.onPrimary,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportAndLocationRow() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: ColorsManager.primary.withValues(alpha: 0.3),
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSportIcon(widget.team.sportType),
                size: 14.sp,
                color: ColorsManager.primary,
              ),
              Gap(4.w),
              Flexible(
                child: Text(
                  widget.team.sportType.displayName,
                  style: TextStyle(
                    color: ColorsManager.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (widget.team.city != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: ColorsManager.playerAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: ColorsManager.playerAccent.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14.sp,
                  color: ColorsManager.playerAccent,
                ),
                Gap(4.w),
                Flexible(
                  child: Text(
                    widget.team.city!,
                    style: TextStyle(
                      color: ColorsManager.playerAccent,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTeamStatsRow() {
    final stat = widget.team.stat;
    final winRate = stat['winPercentage'] is num
        ? (stat['winPercentage'] as num).toStringAsFixed(1)
        : '0.0';

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _buildStatContainer(
          icon: Icons.people,
          label: 'Players',
          value: '${widget.team.activePlayersCount}/${widget.team.maxPlayers}',
          color: ColorsManager.primary,
        ),
        _buildStatContainer(
          icon: Icons.emoji_events,
          label: 'Wins',
          value: widget.team.stat['matchesWon'].toString(),
          color: ColorsManager.playerAccent,
        ),
        _buildStatContainer(
          icon: Icons.sports_score,
          label: 'Matches',
          value: widget.team.stat['matchesPlayed'].toString(),
          color: Colors.blue,
        ),
        _buildStatContainer(
          icon: Icons.handshake_rounded,
          label: 'Draws',
          value: '${stat['matchesDrawn'] ?? 0}',
          color: Colors.orangeAccent,
        ),
        _buildStatContainer(
          icon: Icons.mood_bad_rounded,
          label: 'Losses',
          value: '${stat['matchesLost'] ?? 0}',
          color: Colors.redAccent,
        ),
        _buildStatContainer(
          icon: Icons.stacked_line_chart_rounded,
          label: 'Win %',
          value: winRate,
          color: ColorsManager.success,
        ),
        _buildStatContainer(
          icon: Icons.scoreboard_rounded,
          label: 'Points',
          value: '${stat['totalPoints'] ?? 0}',
          color: Colors.amberAccent,
        ),
      ],
    );
  }

  Widget _buildStatContainer({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16.sp),
          Gap(4.h),
          Text(
            value,
            style: TextStyle(
              color: ColorsManager.onBackground,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: ColorsManager.textSecondary,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.outline,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: ColorsManager.primary,
                size: 16.sp,
              ),
              Gap(8.w),
              Text(
                'About',
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Text(
            widget.team.description!,
            style: TextStyle(
              color: ColorsManager.onBackground,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      child: _buildJoinTeamButton(),
    );
  }

  Widget _buildJoinTeamButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: ColorsManager.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.3),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: _handleJoinTeam,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_add,
                  color: ColorsManager.onPrimary,
                  size: 20.sp,
                ),
                Gap(8.w),
                Text(
                  'Join Team',
                  style: TextStyle(
                    color: ColorsManager.onPrimary,
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

  Future<void> _handleJoinTeam() async {
    try {
      // Check if user is already a member
      if (widget.team.isMember(_currentUserId ?? '')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are already a member of this team'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if team is full
      if (widget.team.activePlayersCount >= widget.team.maxPlayers) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This team is full'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create join request
      await _teamService.createJoinRequest(
        teamId: widget.team.id,
        message: 'I would like to join this team',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join request sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send join request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20.sp),
                Gap(4.h),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamAvatar() {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ColorsManager.mainBlue,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: widget.team.profileImageUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.team.profileImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[700],
                  child: Icon(
                    Icons.groups,
                    color: Colors.grey[400],
                    size: 40.sp,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[700],
                  child: Icon(
                    Icons.groups,
                    color: Colors.grey[400],
                    size: 40.sp,
                  ),
                ),
              )
            : Container(
                color: ColorsManager.mainBlue.withOpacity(0.2),
                child: Center(
                  child: Text(
                    widget.team.nameInitial ??
                        widget.team.name[0].toUpperCase(),
                    style: TextStyle(
                      color: ColorsManager.mainBlue,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      (
        title: 'Members',
        value: '${widget.team.totalMembersCount}/${widget.team.maxRosterSize}',
        icon: Icons.people
      ),
      (
        title: 'Wins',
        value: widget.team.stat['matchesWon'].toString(),
        icon: Icons.emoji_events
      ),
      (
        title: 'Matches',
        value: widget.team.stat['matchesPlayed'].toString(),
        icon: Icons.sports_score
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          alignment:
              isWide ? WrapAlignment.spaceBetween : WrapAlignment.start,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 24.w) / 3
                      : (constraints.maxWidth - 12.w) / 2,
                  child: _buildStatCard(
                    label: stat.title,
                    value: stat.value,
                    icon: stat.icon,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: ColorsManager.primary, size: 22.sp),
          ),
          Gap(16.h),
          Text(
            value,
            style: TextStyles.font24DarkBlue600Weight,
          ),
          Gap(6.h),
          Text(
            label,
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.surfaceVariant,
            ColorsManager.background,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.55),
        indicator: BoxDecoration(
          gradient: ColorsManager.primaryGradient,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        isScrollable: true,
        tabs: [
          _buildTab('Overview', Icons.info_outline),
          _buildTab('Members', Icons.people),
          _buildTab('Matches', Icons.sports_score),
          _buildTab('Stats', Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildTab(String text, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp),
          Gap(6.w),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Bio
          if (widget.team.bio != null) ...[
            _buildInfoSection('About', [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  widget.team.bio!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
              ),
            ]),
            Gap(24.h),
          ],

          // Team Information
          _buildInfoSection('Team Information', [
            _buildInfoRow('Created', _formatDate(widget.team.createdAt)),
            _buildInfoRow('Sport', widget.team.sportType.displayName),
            if (widget.team.city != null)
              _buildInfoRow('City', widget.team.city!),
            _buildInfoRow(
                'Visibility', widget.team.isPublic ? 'Public' : 'Private'),
            _buildInfoRow(
                'Max Playing Members', widget.team.maxPlayers.toString()),
            _buildInfoRow(
                'Max Roster Size', widget.team.maxRosterSize.toString()),
          ]),
          Gap(24.h),

          _buildHighlightChips(),
          Gap(24.h),

          if (_achievementTimeline.isNotEmpty) ...[
            _buildInfoSection('Recent Achievements', [
              ..._achievementTimeline.map(_buildAchievementRow),
            ]),
            Gap(24.h),
          ],

          if (_trainingFocus.isNotEmpty) ...[
            _buildInfoSection('Training Focus', [
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: _trainingFocus
                    .map(
                      (focus) => _buildFocusChip(
                        focus['label'] as String,
                        focus['value'] as String,
                        focus['icon'] as IconData,
                      ),
                    )
                    .toList(),
              ),
            ]),
            Gap(24.h),
          ],

          // Join Team Button (for non-members)
          if (!_isAdmin && !widget.team.isMember(_currentUserId ?? ''))
            _buildJoinTeamButton(),
        ],
      ),
    );
  }

  void _showJoinRequestDialog() {
    final roleController = TextEditingController(text: 'player');
    final positionController = TextEditingController();
    final aboutYourselfController = TextEditingController();
    final whyJoinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Join Team Request',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Role',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
              Gap(8.h),
              DropdownButtonFormField<String>(
                value: 'player',
                dropdownColor: Colors.grey[800],
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'player', child: Text('Player')),
                  DropdownMenuItem(value: 'coach', child: Text('Coach')),
                ],
                onChanged: (value) {
                  roleController.text = value!;
                },
              ),
              Gap(16.h),
              Text(
                'Position (Optional)',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
              Gap(8.h),
              TextField(
                controller: positionController,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'e.g., Goalkeeper, Midfielder, Striker',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Gap(16.h),
              Text(
                'Tell me a little about yourself *',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600),
              ),
              Gap(8.h),
              TextField(
                controller: aboutYourselfController,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Describe your experience, skills, and background...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Gap(16.h),
              Text(
                'Why do you want to join this team? *',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600),
              ),
              Gap(8.h),
              TextField(
                controller: whyJoinController,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Explain your motivation and what you can contribute...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate required fields
              if (aboutYourselfController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please tell us about yourself'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (whyJoinController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please explain why you want to join this team'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _teamService.createJoinRequest(
                  teamId: widget.team.id,
                  message:
                      'Role: ${roleController.text}\nPosition: ${positionController.text.trim()}\nAbout Me: ${aboutYourselfController.text.trim()}\n\nWhy Join: ${whyJoinController.text.trim()}',
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Join request sent successfully!'),
                      backgroundColor: ColorsManager.mainBlue,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.mainBlue,
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await _teamService.approveJoinRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _teamService.rejectJoinRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMembersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Members Section (All members without separate headings)
          _buildMembersSection(),
          Gap(24.h),

          // Player Stats Section
          _buildPlayerStatsSection(),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    // Combine all members (coaches and players) into one list
    final allMembers = <TeamPlayer>[];
    allMembers.addAll(widget.team.coaches);
    allMembers.addAll(widget.team.players);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: ColorsManager.mainBlue, size: 20.sp),
            Gap(8.w),
            Text(
              'Members (${allMembers.length})',
              style: TextStyles.font18DarkBlue600Weight,
            ),
          ],
        ),
        Gap(12.h),
        if (allMembers.isEmpty)
          _buildEmptyMembersState()
        else
          ...allMembers.map((member) => _buildMemberCard(member)),
      ],
    );
  }

  Widget _buildPlayerStatsSection() {
    // Get only players with stats
    final playersWithStats = widget.team.players
        .where((player) =>
            player.playerStats != null && player.playerStats!.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: ColorsManager.mainBlue, size: 20.sp),
            Gap(8.w),
            Text(
              'Player Statistics',
              style: TextStyles.font18DarkBlue600Weight,
            ),
          ],
        ),
        Gap(12.h),
        if (playersWithStats.isEmpty)
          _buildEmptyStatsState()
        else
          ...playersWithStats.map((player) => _buildPlayerStatsCard(player)),
      ],
    );
  }

  Widget _buildMemberCard(TeamPlayer member) {
    final isCoach = widget.team.coaches.contains(member);

    return GestureDetector(
      onTap: () =>
          isCoach ? _showCoachProfile(member) : _showPlayerProfile(member),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: _getMemberColor(member).withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: _getMemberColor(member).withOpacity(0.2),
              backgroundImage: member.profileImageUrl != null
                  ? NetworkImage(member.profileImageUrl!)
                  : null,
              child: member.profileImageUrl == null
                  ? (isCoach
                      ? Icon(Icons.sports_esports,
                          color: _getMemberColor(member), size: 20.sp)
                      : Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(
                            color: _getMemberColor(member),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ))
                  : null,
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: TextStyles.font16DarkBlue600Weight,
                  ),
                  Gap(4.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getMemberColor(member).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          isCoach ? 'Coach' : member.role.displayName,
                          style: TextStyle(
                            color: _getMemberColor(member),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (member.position != null) ...[
                        Gap(8.w),
                        Text(
                          member.position!,
                          style: TextStyles.font12Grey400Weight,
                        ),
                      ],
                      if (member.jerseyNumber != null) ...[
                        Gap(8.w),
                        Text(
                          '#${member.jerseyNumber}',
                          style: TextStyle(
                            color: ColorsManager.mainBlue,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: ColorsManager.textSecondary, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Color _getMemberColor(TeamPlayer member) {
    if (widget.team.coaches.contains(member)) {
      return Colors.orange; // Coach color
    }
    return _getRoleColor(member.role); // Player role color
  }

  Widget _buildPlayerCard(TeamPlayer player) {
    return GestureDetector(
      onTap: () => _showPlayerProfile(player),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(18.r),
        border:
            Border.all(color: _getRoleColor(player.role).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: _getRoleColor(player.role).withOpacity(0.2),
                  backgroundImage: player.profileImageUrl != null
                      ? NetworkImage(player.profileImageUrl!)
                      : null,
                  child: player.profileImageUrl == null
                      ? Text(
                          player.name[0].toUpperCase(),
                          style: TextStyle(
                            color: _getRoleColor(player.role),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: TextStyles.font16DarkBlue600Weight,
                      ),
                      Gap(4.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color:
                                  _getRoleColor(player.role).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              player.role.displayName,
                              style: TextStyle(
                                color: _getRoleColor(player.role),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (player.position != null) ...[
                            Gap(8.w),
                            Text(
                              player.position!,
                              style: TextStyles.font12Grey400Weight,
                            ),
                          ],
                          if (player.jerseyNumber != null) ...[
                            Gap(8.w),
                            Text(
                              '#${player.jerseyNumber}',
                              style: TextStyle(
                                color: ColorsManager.mainBlue,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: ColorsManager.textSecondary, size: 16.sp),
              ],
            ),
            if (player.playerStats != null &&
                player.playerStats!.isNotEmpty) ...[
              Gap(12.h),
              _buildPlayerStats(player),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStats(TeamPlayer player) {
    final stats = player.playerStats!;
    final sportType = widget.team.sportType;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player Statistics',
            style: TextStyles.font14DarkBlue500Weight,
          ),
          Gap(8.h),
          _buildSportSpecificStatsDisplay(stats, sportType),
        ],
      ),
    );
  }

  Widget _buildSportSpecificStatsDisplay(
      Map<String, dynamic> stats, SportType sportType) {
    switch (sportType) {
      case SportType.football:
      case SportType.soccer:
        return _buildFootballStatsDisplay(stats);
      case SportType.basketball:
        return _buildBasketballStatsDisplay(stats);
      case SportType.cricket:
        return _buildCricketStatsDisplay(stats);
      case SportType.tennis:
        return _buildTennisStatsDisplay(stats);
      default:
        return _buildGenericStatsDisplay(stats);
    }
  }

  Widget _buildFootballStatsDisplay(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildStatDisplay('Goals', stats['goals']?.toString() ?? '0'),
        _buildStatDisplay('Assists', stats['assists']?.toString() ?? '0'),
        _buildStatDisplay('Matches', stats['matches']?.toString() ?? '0'),
        _buildStatDisplay('Rating', stats['rating']?.toString() ?? '0.0'),
      ],
    );
  }

  Widget _buildBasketballStatsDisplay(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildStatDisplay('Points', stats['points']?.toString() ?? '0'),
        _buildStatDisplay('Rebounds', stats['rebounds']?.toString() ?? '0'),
        _buildStatDisplay('Assists', stats['assists']?.toString() ?? '0'),
        _buildStatDisplay('Games', stats['games']?.toString() ?? '0'),
      ],
    );
  }

  Widget _buildCricketStatsDisplay(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildStatDisplay('Runs', stats['runs']?.toString() ?? '0'),
        _buildStatDisplay('Wickets', stats['wickets']?.toString() ?? '0'),
        _buildStatDisplay('Matches', stats['matches']?.toString() ?? '0'),
        _buildStatDisplay('Avg', stats['battingAvg']?.toString() ?? '0.0'),
      ],
    );
  }

  Widget _buildTennisStatsDisplay(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildStatDisplay('Wins', stats['wins']?.toString() ?? '0'),
        _buildStatDisplay('Losses', stats['losses']?.toString() ?? '0'),
        _buildStatDisplay('Sets', stats['setsWon']?.toString() ?? '0'),
        _buildStatDisplay('Rating', stats['rating']?.toString() ?? '0.0'),
      ],
    );
  }

  Widget _buildGenericStatsDisplay(Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildStatDisplay('Matches', stats['matches']?.toString() ?? '0'),
        _buildStatDisplay('Wins', stats['wins']?.toString() ?? '0'),
        _buildStatDisplay('Rating', stats['rating']?.toString() ?? '0.0'),
      ],
    );
  }

  Widget _buildStatDisplay(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: ColorsManager.mainBlue,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsCard(TeamPlayer player) {
    final stats = player.playerStats!;
    final sportType = widget.team.sportType;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.mainBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: ColorsManager.mainBlue.withOpacity(0.2),
                backgroundImage: player.profileImageUrl != null
                    ? NetworkImage(player.profileImageUrl!)
                    : null,
                child: player.profileImageUrl == null
                    ? Text(
                        player.name[0].toUpperCase(),
                        style: TextStyle(
                          color: ColorsManager.mainBlue,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (player.position != null)
                      Text(
                        player.position!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Gap(12.h),
          _buildSportSpecificStatsDisplay(stats, sportType),
        ],
      ),
    );
  }

  Widget _buildEmptyMembersState() {
    return Container(
      padding: EdgeInsets.all(32.h),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          Gap(16.h),
          Text(
            'No members yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(8.h),
          Text(
            'Team members will appear here once they join',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatsState() {
    return Container(
      padding: EdgeInsets.all(32.h),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          Gap(16.h),
          Text(
            'No player statistics yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(8.h),
          Text(
            'Player statistics will appear here once they are updated by team admins',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return Colors.purple;
      case TeamRole.captain:
        return Colors.blue;
      case TeamRole.viceCaptain:
        return Colors.green;
      case TeamRole.coach:
        return Colors.orange;
      case TeamRole.member:
        return Colors.grey;
    }
  }

  void _showCoachProfile(TeamPlayer coach) {
    // Navigate to coach detail screen (same as coaches listing)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CoachDetailScreen(coach: _convertToCoachProfile(coach)),
      ),
    );
  }

  void _showPlayerProfile(TeamPlayer player) {
    // Navigate to player profile screen (same as matching dashboard)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MatchProfileDetailScreen(profile: _convertToMatchProfile(player)),
      ),
    );
  }

  // Convert TeamPlayer to CoachProfile for navigation
  CoachProfile _convertToCoachProfile(TeamPlayer coach) {
    return CoachProfile(
      uid: coach.id,
      fullName: coach.name,
      gender: Gender.male, // Default value
      age: 25, // Default value
      location: '', // Default value
      profilePictureUrl: coach.profileImageUrl,
      isProfileComplete: true, // Default value
      createdAt: DateTime.now(), // Default value
      updatedAt: DateTime.now(), // Default value
      specializationSports: [widget.team.sportType.displayName],
      experienceYears: 0, // Default value
      hourlyRate: 0.0, // Default value
      availableTimeSlots: [], // Default value
      coachingType: TrainingType.inPerson, // Default value
      bio: '', // Default value
    );
  }

  // Convert TeamPlayer to MatchProfile for navigation
  MatchProfile _convertToMatchProfile(TeamPlayer player) {
    return MatchProfile(
      uid: player.userId,
      fullName: player.userName,
      age: 25, // Default age
      location: '', // Default value
      profilePictureUrl: player.profileImageUrl,
      photos: player.profileImageUrl != null ? [player.profileImageUrl!] : [],
      sportsOfInterest: [widget.team.sportType.displayName],
      skillLevel: SkillLevel.intermediate, // Default value
      bio: '', // Default value
      interests: [], // Default value
      distanceKm: 0.0, // Default value
      compatibilityScore: 85, // Default value
      role: UserRole.player, // Default value
      isOnline: true, // Default value
      lastActive: DateTime.now(), // Default value
      isMatched: false, // Default value
    );
  }

  Widget _buildMatchesTab() {
    // TODO: Implement team matches functionality
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 64.sp,
            color: ColorsManager.primary,
          ),
          Gap(16.h),
          Text(
            'Matches feature coming soon',
            style: TextStyles.font16DarkBlue400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16.w,
            runSpacing: 16.h,
            children: _buildStatHighlights(),
          ),
          Gap(24.h),
          _buildInfoSection('Roster Insights', _buildRosterInsights()),
          Gap(24.h),
          if (_playerSpotlight.isNotEmpty) ...[
            _buildInfoSection('Player Spotlight', [
              ..._playerSpotlight.map(_buildPlayerSpotlightCard),
            ]),
            Gap(24.h),
          ],
          if (_achievementTimeline.isNotEmpty) ...[
            _buildInfoSection('Season Milestones', [
              ..._achievementTimeline.map(_buildAchievementRow),
            ]),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStatHighlights() {
    final stat = widget.team.stat;
    return [
      _buildStatHighlight(
        title: 'Career Record',
        value: '${stat['matchesWon'] ?? 0}-${stat['matchesLost'] ?? 0}',
        subtitle: '${stat['matchesPlayed'] ?? 0} total fixtures',
        icon: Icons.analytics_rounded,
        color: ColorsManager.primary,
      ),
      _buildStatHighlight(
        title: 'Goal Differential',
        value: '${stat['goalsScored'] ?? 0} - ${stat['goalsConceded'] ?? 0}',
        subtitle:
            'Net ${(stat['goalsScored'] ?? 0) - (stat['goalsConceded'] ?? 0)} goals this season',
        icon: Icons.trending_up_rounded,
        color: ColorsManager.secondary,
      ),
      _buildStatHighlight(
        title: 'Win Efficiency',
        value:
            '${stat['winPercentage'] is num ? (stat['winPercentage'] as num).toStringAsFixed(1) : '0.0'}%',
        subtitle: 'Consistent performance curve',
        icon: Icons.percent_rounded,
        color: ColorsManager.playerAccent,
      ),
    ];
  }

  Widget _buildStatHighlight({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 170.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.22),
            color.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 18.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: Colors.white, size: 20.sp),
          ),
          Gap(12.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(6.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(6.h),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRosterInsights() {
    return [
      _buildInsightRow(
        'Roster Depth',
        '${widget.team.memberCount} total • ${widget.team.maxMembers} capacity',
        Icons.groups_rounded,
      ),
      _buildInsightRow(
        'Match Readiness',
        '${widget.team.activeMembersCount} players available right now',
        Icons.bolt_rounded,
      ),
      _buildInsightRow(
        'Tournaments Played',
        '${widget.team.tournamentsParticipated.length} major events contested',
        Icons.emoji_events_rounded,
      ),
    ];
  }

  Widget _buildInsightRow(String title, String detail, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: ColorsManager.primary, size: 18.sp),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                Gap(4.h),
                Text(
                  detail,
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
  }

  Widget _buildPlayerSpotlightCard(Map<String, dynamic> player) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: ColorsManager.primary.withOpacity(0.2),
            backgroundImage: player['avatar'] != null
                ? NetworkImage(player['avatar'] as String)
                : null,
            child: player['avatar'] == null
                ? Text(
                    (player['name'] as String).substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: ColorsManager.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['name'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                Gap(4.h),
                Text(
                  player['achievement'] as String,
                  style: TextStyle(
                    color: ColorsManager.playerAccent,
                    fontSize: 12.sp,
                  ),
                ),
                Gap(4.h),
                Text(
                  player['progress'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Gap(12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              color: ColorsManager.primary.withOpacity(0.18),
            ),
            child: Text(
              player['role'] as String,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightChips() {
    final stat = widget.team.stat;
    final highlights = [
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Founded',
        'value': _formatDate(widget.team.createdAt),
      },
      {
        'icon': Icons.bolt_rounded,
        'label': 'Momentum',
        'value':
            '${stat['matchesWon'] ?? 0}W • ${stat['matchesLost'] ?? 0}L • ${stat['matchesDrawn'] ?? 0}D',
      },
      {
        'icon': Icons.people_alt_rounded,
        'label': 'Roster Depth',
        'value':
            '${widget.team.activeMembersCount}/${widget.team.maxMembers} match-ready',
      },
      {
        'icon': Icons.equalizer_rounded,
        'label': 'Power Index',
        'value': '#${_randomSeed.nextInt(35) + 8} Regional',
      },
    ];

    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: highlights
          .map(
            (item) => Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: ColorsManager.primary,
                    size: 16.sp,
                  ),
                  Gap(10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11.sp,
                        ),
                      ),
                      Text(
                        item['value'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAchievementRow(Map<String, dynamic> item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: ColorsManager.primary,
              size: 16.sp,
            ),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                Gap(4.h),
                Text(
                  item['subtitle'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Gap(12.w),
          Text(
            item['period'] as String,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ColorsManager.secondary, size: 16.sp),
          Gap(10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11.sp,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildAchievementTimeline() {
    final achievements =
        widget.team.metadata?['achievements'] as List<dynamic>? ?? [];
    if (achievements.isNotEmpty) {
      return achievements.map((item) {
        return {
          'icon': Icons.auto_awesome_rounded,
          'title': item['title'] ?? 'Milestone Unlocked',
          'subtitle':
              item['description'] ?? 'Team logged a new performance landmark.',
          'period': item['period'] ?? 'Recently',
        };
      }).toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _buildPlayerSpotlight() {
    final players = widget.team.players;
    if (players.isNotEmpty) {
      return players.take(3).map((player) {
        return {
          'name': player.userName,
          'achievement':
              '${player.trophies} trophies • ${player.position ?? 'Utility'}',
          'progress':
              'Rating ${(player.rating ?? (3.5 + _randomSeed.nextDouble())).toStringAsFixed(1)} • Joined ${_formatDate(player.joinedAt)}',
          'avatar': player.profileImageUrl,
          'role': player.role.displayName,
        };
      }).toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _buildTrainingFocus() {
    // Return empty list - no dummy data
    return [];
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorsManager.surface,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          Gap(12.w),
          Flexible(
            child: Text(
              value,
              style: TextStyles.font14DarkBlue500Weight,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _editPlayer(TeamPlayer player) {
    // Note: Extended player properties (position, jersey, etc.) not yet implemented in TeamMember model
    final positionController = TextEditingController();
    final jerseyController = TextEditingController();
    final trophiesController = TextEditingController();
    double ratingValue = 0.0;
    bool isCaptain = player.role == TeamRole.captain;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Edit ${player.userName}',
            style: TextStyles.font18DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Position',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                Gap(8.h),
                TextField(
                  controller: positionController,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'e.g., Forward, Midfielder',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Gap(16.h),
                Text('Jersey Number',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                Gap(8.h),
                TextField(
                  controller: jerseyController,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g., 10',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Gap(16.h),
                Text('Trophies',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                Gap(8.h),
                TextField(
                  controller: trophiesController,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Number of trophies',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Gap(16.h),
                Text('Rating',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                Gap(8.h),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: ratingValue,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        activeColor: ColorsManager.mainBlue,
                        label: ratingValue.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() => ratingValue = value);
                        },
                      ),
                    ),
                    Gap(8.w),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: ColorsManager.mainBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${ratingValue.toStringAsFixed(1)} ⭐',
                        style: TextStyle(
                          color: ColorsManager.mainBlue,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(16.h),
                CheckboxListTile(
                  title: Text('Team Captain',
                      style: TextStyle(color: Colors.white)),
                  value: isCaptain,
                  onChanged: (value) {
                    setState(() => isCaptain = value ?? false);
                  },
                  activeColor: ColorsManager.mainBlue,
                  checkColor: Colors.white,
                  tileColor: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update member role if captain status changed
                  if (isCaptain && player.role != TeamRole.captain) {
                    await _teamService.updateMemberRole(
                      widget.team.id,
                      player.userId,
                      TeamRole.captain,
                    );
                  } else if (!isCaptain && player.role == TeamRole.captain) {
                    await _teamService.updateMemberRole(
                      widget.team.id,
                      player.userId,
                      TeamRole.member,
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Player role updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editCoach(TeamPlayer coach) {
    double ratingValue = 0.0;
    bool isHeadCoach = coach.role == TeamRole.coach;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Edit ${coach.userName}',
            style: TextStyles.font18DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rating',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              Gap(8.h),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: ratingValue,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      activeColor: ColorsManager.mainBlue,
                      label: ratingValue.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() => ratingValue = value);
                      },
                    ),
                  ),
                  Gap(8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: ColorsManager.mainBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${ratingValue.toStringAsFixed(1)} ⭐',
                      style: TextStyle(
                        color: ColorsManager.mainBlue,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(16.h),
              CheckboxListTile(
                title:
                    Text('Head Coach', style: TextStyle(color: Colors.white)),
                value: isHeadCoach,
                onChanged: (value) {
                  setState(() => isHeadCoach = value ?? false);
                },
                activeColor: ColorsManager.mainBlue,
                checkColor: Colors.white,
                tileColor: Colors.grey[850],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Coach role management - ensure they have the coach role
                  if (isHeadCoach && coach.role != TeamRole.coach) {
                    await _teamService.updateMemberRole(
                      widget.team.id,
                      coach.userId,
                      TeamRole.coach,
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coach role updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _removePlayer(String playerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Remove Player',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove this player from the team?',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _teamService.removeMember(
          widget.team.id,
          playerId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Player removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _removeCoach(String coachId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Remove Coach',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove this coach from the team?',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _teamService.removeMember(
          widget.team.id,
          coachId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coach removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // TODO: Re-implement when TeamMatch functionality is ready
  // void _navigateToMatchDetail(TeamMatch match) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => TeamMatchDetailScreen(matchId: match.id),
  //     ),
  //   );
  // }

  IconData _getSportIcon(SportType sportType) {
    switch (sportType) {
      case SportType.football:
      case SportType.soccer:
        return Icons.sports_soccer;
      case SportType.basketball:
        return Icons.sports_basketball;
      case SportType.cricket:
        return Icons.sports_cricket;
      case SportType.tennis:
        return Icons.sports_tennis;
      case SportType.badminton:
        return Icons.sports_tennis;
      case SportType.volleyball:
        return Icons.sports_volleyball;
      case SportType.hockey:
        return Icons.sports_hockey;
      case SportType.rugby:
        return Icons.sports_rugby;
      case SportType.baseball:
        return Icons.sports_baseball;
      default:
        return Icons.sports;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}
