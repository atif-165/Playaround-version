import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/navigation/detail_navigator.dart';
import '../../../helpers/admin_override_helper.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../../../routing/routes.dart';
import '../../../models/venue_model.dart';
import '../../../models/venue.dart';

import '../models/models.dart';
import '../models/team_match_model.dart';
import '../services/team_service.dart';
import 'team_performance_screen.dart';
import 'team_schedule_screen.dart';
import 'team_matches_overview_screen.dart';
import 'team_achievements_screen.dart';
import 'team_statistics_screen.dart';
import 'team_admin_settings_screen.dart';
import '../../tournament/services/tournament_service.dart';
import '../../tournament/screens/tournament_detail_screen.dart';
import '../../venue/services/venue_service.dart';
import '../../../screens/venue/venue_profile_screen.dart';
import '../../tournament/models/tournament_model.dart';
import '../widgets/team_communication_widget.dart';
import '../widgets/team_match_card.dart';

/// Screen for displaying detailed team profile information
class TeamProfileScreen extends StatefulWidget {
  final Team team;
  final bool showJoinButton;
  final bool showAdminEntry;

  const TeamProfileScreen({
    super.key,
    required this.team,
    this.showJoinButton = false,
    this.showAdminEntry = true,
  });

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();
  final VenueService _venueService = VenueService();
  final TournamentService _tournamentService = TournamentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isJoining = false;
  Team? _currentTeam;
  int _historyLimit = 10;
  int _tournamentLimit = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _currentTeam = widget.team;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: CustomScrollView(
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
                  _buildCoachesTab(),
                  _buildSquadTab(),
                  _buildScheduleTab(),
                  _buildPerformanceTab(),
                  _buildHistoryTab(),
                  _buildTournamentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final bannerImage = _currentTeam?.backgroundImageUrl;

    return SliverAppBar(
      expandedHeight: 360.h,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final progress = ((constraints.maxHeight - kToolbarHeight) /
                  (360.h - kToolbarHeight))
              .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              if (bannerImage != null && bannerImage.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: bannerImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: PublicProfileTheme.panelOverlayColor,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => _buildBannerFallback(),
                )
              else
                _buildBannerFallback(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      PublicProfileTheme.backgroundColor.withOpacity(0.9),
                      Colors.transparent,
                      PublicProfileTheme.backgroundColor,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20.w,
                right: 20.w,
                bottom: 32.h,
                child: Opacity(
                  opacity: progress,
                  child: _buildHeroSummary(),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        _buildAdminActionButton(),
        if (widget.showJoinButton)
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: AppFilledButton(
              text: 'Join Team',
              onPressed: _isJoining ? null : _sendJoinRequest,
              isLoading: _isJoining,
              size: ButtonSize.small,
            ),
          ),
      ],
    );
  }

  Widget _buildBannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: PublicProfileTheme.backgroundGradient,
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Icon(
            Icons.groups,
            color: Colors.white.withOpacity(0.2),
            size: 90.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActionButton() {
    final canEdit = _isTeamAdmin();
    final padding = widget.showJoinButton
        ? EdgeInsets.only(right: 8.w)
        : EdgeInsets.only(right: 16.w);

    final shouldShowAdmin = widget.showAdminEntry;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: shouldShowAdmin
          ? Padding(
      padding: padding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: _openAdminPanel,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: PublicProfileTheme.panelColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: PublicProfileTheme.defaultShadow(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  size: 18.sp,
                  color: PublicProfileTheme.panelAccentColor,
                ),
                Gap(6.w),
                Text(
                  'Admin',
                  style: TextStyles.font12White600Weight.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 24,
  }) {
    final radius = borderRadius.r;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: PublicProfileTheme.defaultBlurSigma,
            sigmaY: PublicProfileTheme.defaultBlurSigma,
          ),
          child: Container(
            padding: padding ?? EdgeInsets.all(20.w),
            decoration: PublicProfileTheme.glassPanelDecoration(
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: _buildGlassPanel(
        borderRadius: 26,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 84.w,
                  height: 84.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: PublicProfileTheme.panelGradient,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: _currentTeam?.teamImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _currentTeam!.teamImageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  _buildAvatarFallback(),
                            )
                          : _buildAvatarFallback(),
                    ),
                  ),
                ),
                Gap(18.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentTeam?.name ?? 'Unknown Team',
                              style: TextStyles.font24WhiteBold,
                            ),
                          ),
                          _buildVisibilityPill(
                            _currentTeam?.isPublic ?? true,
                          ),
                        ],
                      ),
                      Gap(12.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 8.h,
                        children: [
                          _buildInfoChip(
                            icon: Icons.groups_2,
                            label:
                                '${_currentTeam?.members.length ?? 0} active members',
                          ),
                          if (_currentTeam?.coachName != null)
                            GestureDetector(
                              onTap: _openCoachProfileFromOverview,
                              child: _buildInfoChip(
                              icon: Icons.workspace_premium,
                              label: 'Coach ${_currentTeam!.coachName!}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentTeam?.description != null &&
                _currentTeam!.description.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: Text(
                    _currentTeam!.description,
                    style: TextStyles.font14White500Weight
                        .copyWith(color: Colors.white70),
                  ),
                ),
              ),
            Gap(24.h),
            _buildHeaderStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: PublicProfileTheme.panelAccentColor.withOpacity(0.12),
      child: Icon(
        Icons.groups,
        color: PublicProfileTheme.panelAccentColor,
        size: 36.sp,
      ),
    );
  }

  Widget _buildVisibilityPill(bool isPublic) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isPublic
            ? PublicProfileTheme.panelAccentColor.withOpacity(0.2)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            color:
                isPublic ? PublicProfileTheme.panelAccentColor : Colors.white,
            size: 14.sp,
          ),
          Gap(6.w),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyles.font12White500Weight.copyWith(
              color:
                  isPublic ? PublicProfileTheme.panelAccentColor : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: PublicProfileTheme.panelAccentColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: PublicProfileTheme.panelAccentColor, size: 16.sp),
          Gap(6.w),
          Flexible(
            child: Text(
            label,
            style:
                TextStyles.font12White500Weight.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    final items = [
      (
        title: 'Members',
        value:
            '${_currentTeam?.members.length ?? 0}/${_currentTeam?.maxMembers ?? 0}',
        icon: Icons.people_alt
      ),
      (
        title: 'Coaches',
        value: '${_currentTeam?.coaches.length ?? 0}',
        icon: Icons.school
      ),
      (
        title: 'Tournaments',
        value: '${_currentTeam?.tournamentsParticipated.length ?? 0}',
        icon: Icons.emoji_events
      ),
      (
        title: 'Venues',
        value: '${_currentTeam?.venuesPlayed.length ?? 0}',
        icon: Icons.location_city
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          alignment: isWide ? WrapAlignment.spaceBetween : WrapAlignment.start,
          children: items
              .map(
                (item) => SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 36.w) / 4
                      : (constraints.maxWidth - 12.w) / 2,
                  child: _buildStatCard(
                    label: item.title,
                    value: item.value,
                    icon: item.icon,
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
    return _buildGlassPanel(
      padding: EdgeInsets.all(18.w),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: PublicProfileTheme.panelAccentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              icon,
              color: PublicProfileTheme.panelAccentColor,
              size: 22.sp,
            ),
          ),
          Gap(14.h),
          Text(
            value,
            style: TextStyles.font24WhiteBold,
          ),
          Gap(6.h),
          Text(
            label,
            style:
                TextStyles.font14White500Weight.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: _buildGlassPanel(
        borderRadius: 22,
        padding: EdgeInsets.all(6.w),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          labelStyle: TextStyles.font14White600Weight.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          unselectedLabelStyle: TextStyles.font14White500Weight.copyWith(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade500,
          indicator: BoxDecoration(
            color: ColorsManager.mainBlue,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.mainBlue.withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Members'),
            Tab(text: 'Coaches'),
            Tab(text: 'Squad'),
            Tab(text: 'Schedule'),
            Tab(text: 'Performance'),
            Tab(text: 'History'),
            Tab(text: 'Tournaments'),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentTeam?.bio != null) ...[
            _buildInfoSection(
              'About the Team',
              [
                Text(
                  _currentTeam!.bio!,
                  style: TextStyles.font14White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
            Gap(20.h),
          ],
          if (_currentTeam != null) ...[
            _buildMatchesPreviewSection(),
            Gap(20.h),
            _buildAchievementsPreviewSection(),
            Gap(20.h),
            _buildStatisticsPreviewSection(),
          ],
          Gap(20.h),
          _buildCardSection(
            title: 'Communication Hub',
            child: TeamCommunicationWidget(
              teamId: _currentTeam?.id ?? '',
              teamName: _currentTeam?.name ?? '',
            ),
          ),
          Gap(20.h),
          _buildInfoSection(
            'Team Details',
            [
              _buildDetailRow(
                  'Sport', _currentTeam?.sportType.displayName ?? 'Unknown'),
              _buildDetailRow('Created', _formatDate(_currentTeam?.createdAt)),
              _buildDetailRow('Team Type',
                  _currentTeam?.isPublic == true ? 'Public' : 'Private'),
              _buildDetailRow(
                  'Max Members', '${_currentTeam?.maxMembers ?? 0}'),
              if (_currentTeam?.coachName != null)
                _buildCoachDetailRow(),
            ],
          ),
          if (_currentTeam?.coachName != null &&
              (_currentTeam?.coachId?.isNotEmpty ?? false)) ...[
            Gap(20.h),
            _buildCoachSection(),
          ],
          Gap(20.h),
        ],
      ),
    );
  }

  Widget _buildMatchesPreviewSection() {
    return StreamBuilder<List<TeamMatch>>(
      stream: _teamService.watchTeamScheduleMatches(_currentTeam!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCardSection(
            title: 'Matches',
            subtitle: 'Live • Upcoming • Completed',
            child: _buildPreviewLoader(),
          );
        }

        if (snapshot.hasError) {
          return _buildCardSection(
            title: 'Matches',
            subtitle: 'Live • Upcoming • Completed',
            child: _buildPreviewError('Unable to load matches right now.'),
          );
        }

        final matches = snapshot.data ?? [];
        final preview = matches.take(3).toList();

        return _buildCardSection(
          title: 'Matches',
          subtitle: 'Live • Upcoming • Completed',
          trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 20.sp),
          onTap: _openMatchesDetail,
          child: preview.isEmpty
              ? _buildPreviewEmpty(
                  'No matches scheduled',
                  'Create a match from the admin panel to see it here.',
                )
              : Column(
                  children: [
                    for (var index = 0; index < preview.length; index++) ...[
                      _buildMatchPreviewTile(preview[index]),
                      if (index != preview.length - 1) Gap(12.h),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAchievementsPreviewSection() {
    return StreamBuilder<List<TeamAchievement>>(
      stream: _teamService.watchTeamAchievements(_currentTeam!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCardSection(
            title: 'Team Achievements',
            subtitle: 'Celebrating milestones and trophies',
            child: _buildPreviewLoader(),
          );
        }

        if (snapshot.hasError) {
          return _buildCardSection(
            title: 'Team Achievements',
            subtitle: 'Celebrating milestones and trophies',
            child: _buildPreviewError('Unable to load achievements.'),
          );
        }

        final achievements = snapshot.data ?? [];
        final preview = achievements.take(3).toList();

        return _buildCardSection(
          title: 'Team Achievements',
          subtitle: 'Shared across Overview and Performance tabs',
          child: preview.isEmpty
              ? _buildPreviewEmpty(
                  'No achievements yet',
                  'Add achievements from the admin panel to highlight them here.',
                )
              : Column(
                  children: [
                    for (var index = 0; index < preview.length; index++) ...[
                      _buildAchievementPreviewTile(preview[index]),
                      if (index != preview.length - 1) Gap(12.h),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStatisticsPreviewSection() {
    return StreamBuilder<TeamPerformance>(
      stream: _teamService.watchTeamPerformance(_currentTeam!.id),
      builder: (context, performanceSnapshot) {
        if (performanceSnapshot.connectionState == ConnectionState.waiting) {
          return _buildCardSection(
            title: 'Team Statistics',
            subtitle: 'Key metrics and custom stats',
            child: _buildPreviewLoader(),
          );
        }

        if (performanceSnapshot.hasError) {
          return _buildCardSection(
            title: 'Team Statistics',
            subtitle: 'Key metrics and custom stats',
            child: _buildPreviewError('Unable to load statistics.'),
          );
        }

        final performance = performanceSnapshot.data;
        if (performance == null) {
          return _buildCardSection(
            title: 'Team Statistics',
            subtitle: 'Key metrics and custom stats',
            child: _buildPreviewEmpty(
              'No team stats yet',
              'Stats update automatically when matches are recorded.',
            ),
          );
        }

        return StreamBuilder<List<TeamCustomStat>>(
          stream: _teamService.watchTeamCustomStats(_currentTeam!.id),
          builder: (context, customStatsSnapshot) {
            final customStats = customStatsSnapshot.data ?? const [];

            return _buildCardSection(
              title: 'Team Statistics',
              subtitle: 'Live totals with manual overrides when needed',
              child: _buildStatisticHighlights(performance, customStats),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchPreviewTile(TeamMatch match) {
    if (_currentTeam == null) {
      return const SizedBox.shrink();
    }
    return TeamMatchCard(
      match: match,
      teamId: _currentTeam!.id,
      onTap: () => _openMatchDetailById(match.id),
    );
  }

  Widget _buildAchievementPreviewTile(TeamAchievement achievement) {
    final dateLabel = DateFormat('MMM d, yyyy').format(achievement.achievedAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: ColorsManager.warning.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            Icons.emoji_events,
            color: ColorsManager.warning,
            size: 20.sp,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyles.font14White600Weight,
              ),
              if (achievement.description.trim().isNotEmpty) ...[
                Gap(4.h),
                Text(
                  achievement.description,
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ],
              Gap(6.h),
              Text(
                dateLabel,
                style: TextStyles.font12White500Weight
                    .copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticHighlights(
    TeamPerformance performance,
    List<TeamCustomStat> customStats,
  ) {
    final points = performance.wins * 3 + performance.draws;
    final efficiency = performance.totalMatches == 0
        ? '0%'
        : '${((points / (performance.totalMatches * 3)) * 100).clamp(0, 100).toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [
            _buildStatisticPill(
              'Matches',
              performance.totalMatches.toString(),
              ColorsManager.mainBlue,
            ),
            _buildStatisticPill(
              'Wins',
              performance.wins.toString(),
              ColorsManager.success,
            ),
            _buildStatisticPill(
              'Points',
              points.toString(),
              ColorsManager.warning,
            ),
            _buildStatisticPill(
              'Efficiency',
              efficiency,
              ColorsManager.darkBlue,
            ),
          ],
        ),
        Gap(16.h),
        if (customStats.isNotEmpty) ...[
          Text(
            'Custom metrics',
            style: TextStyles.font12White500Weight
                .copyWith(color: Colors.white70),
          ),
          Gap(8.h),
          Column(
            children: customStats.take(2).map((stat) {
              final valueLabel =
                  stat.units != null && stat.units!.isNotEmpty
                      ? '${stat.value} ${stat.units}'
                      : stat.value;
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat.label,
                        style: TextStyles.font13White600Weight,
                      ),
                    ),
                    Text(
                      valueLabel,
                      style: TextStyles.font13White600Weight
                          .copyWith(color: PublicProfileTheme.panelAccentColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else
          Text(
            'No custom stats tracked yet.',
            style: TextStyles.font12White500Weight
                .copyWith(color: Colors.white54),
          ),
      ],
    );
  }

  Widget _buildPreviewLoader() {
    return SizedBox(
      height: 96.h,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildPreviewEmpty(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.font14White600Weight,
          ),
          Gap(6.h),
          Text(
            subtitle,
            style:
                TextStyles.font12White500Weight.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewError(String message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20.sp),
          Gap(10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.red.shade200),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMatchDateTime(DateTime dateTime) {
    return DateFormat('EEE, MMM d • h:mm a').format(dateTime);
  }

  Widget _buildStatisticPill(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyles.font16White600Weight.copyWith(color: color),
          ),
          Gap(4.h),
          Text(
            label,
            style:
                TextStyles.font12White500Weight.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    final members = _currentTeam?.members ?? [];

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildScheduleTab() {
    if (_currentTeam == null) return const SizedBox.shrink();

    return TeamMatchesOverviewScreen(
      teamId: _currentTeam!.id,
      teamName: _currentTeam!.name,
      showAppBar: false,
    );
  }

  Widget _buildCoachesTab() {
    final coaches = _currentTeam?.coaches ?? const <TeamMember>[];
    if (coaches.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 56, color: Colors.white38),
              Gap(12.h),
              Text(
                'No coaches linked yet',
                style: TextStyles.font16White600Weight,
              ),
              Gap(8.h),
              Text(
                'Team admins can add coaches from the admin panel.',
                style: TextStyles.font12White500Weight
                    .copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: coaches.length,
      itemBuilder: (context, index) {
        final coach = coaches[index];
        return _buildCoachCard(coach);
      },
    );
  }

  Widget _buildSquadTab() {
    final players = _currentTeam?.players ?? const <TeamMember>[];
    if (players.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups_2, size: 56, color: Colors.white38),
              Gap(12.h),
              Text(
                'No players in squad yet',
                style: TextStyles.font16White600Weight,
              ),
              Gap(8.h),
              Text(
                'Players appear here when they are added to the team.',
                style: TextStyles.font12White500Weight
                    .copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive columns: aim for ~220px tiles, clamp between 2 and 6 columns
        final targetTileWidth = 220.w;
        int computed = (constraints.maxWidth / targetTileWidth).floor();
        if (computed < 2) computed = 2;
        if (computed > 6) computed = 6;
        final crossAxisCount = computed;

        // Card aspect ratio (width / height) tuned to our card layout
        final childAspectRatio = 1.9;

        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.2,
          ),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            return _buildSquadPlayerCard(player);
          },
        );
      },
    );
  }

  Widget _buildSquadPlayerCard(TeamMember player) {
    final accent = ColorsManager.mainBlue;
    final isCaptain = player.role == TeamRole.captain;
    final position =
        (player.position ?? player.playerStats['position']?.toString() ?? '')
            .trim();
    final jersey = player.jerseyNumber;
    return _buildGlassPanel(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => _openMemberProfile(player),
          child: Container(
            decoration: isCaptain
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: ColorsManager.warning.withOpacity(0.6),
                      width: 1.2,
                    ),
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24.r,
                      backgroundColor: accent.withOpacity(0.18),
                      backgroundImage: player.profileImageUrl != null &&
                              player.profileImageUrl!.isNotEmpty
                          ? NetworkImage(player.profileImageUrl!)
                          : null,
                      child: (player.profileImageUrl == null ||
                              player.profileImageUrl!.isEmpty)
                          ? Text(
                              player.userName.isNotEmpty
                                  ? player.userName[0].toUpperCase()
                                  : 'P',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            )
                          : null,
                    ),
                    Gap(10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.font16White600Weight,
                          ),
                          Gap(2.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.28),
                                    ),
                                  ),
                                  child: Text(
                                    position.isNotEmpty ? position : 'N/A',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.font12White600Weight
                                        .copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ),
                              if (position.isNotEmpty && jersey != null)
                                Gap(6.w),
                              if (jersey != null)
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.18),
                                      ),
                                    ),
                                    child: Text(
                                      '#$jersey',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.font12White600Weight
                                          .copyWith(
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
                Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    gradient: LinearGradient(
                      colors: [
                        (isCaptain
                                ? ColorsManager.warning
                                : accent)
                            .withOpacity(0.55),
                        (isCaptain
                                ? ColorsManager.warning
                                : accent)
                            .withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildCoachCard(TeamMember coach) {
    final accentColor = ColorsManager.primary;
    return _buildGlassPanel(
      margin: EdgeInsets.only(bottom: 12.h),
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => _openCoachProfile(coach),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: accentColor.withOpacity(0.18),
                  backgroundImage: coach.profileImageUrl != null &&
                          coach.profileImageUrl!.isNotEmpty
                      ? NetworkImage(coach.profileImageUrl!)
                      : null,
                  child: (coach.profileImageUrl == null ||
                          coach.profileImageUrl!.isEmpty)
                      ? Text(
                          coach.userName.isNotEmpty
                              ? coach.userName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        )
                      : null,
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              coach.userName,
                              style: TextStyles.font16White600Weight,
                            ),
                          ),
                        ],
                      ),
                      Gap(8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 6.h,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6.r),
                              border:
                                  Border.all(color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Text(
                              'Coach',
                              style: TextStyles.font12White600Weight.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCoachProfile(TeamMember coach) async {
    final coachId = coach.userId;
    if (coachId.isEmpty) {
      _showSnackBarMessage('Coach profile is not linked yet.');
      return;
    }
    await DetailNavigator.openCoach(context, coachId: coachId);
  }

  Widget _buildPerformanceTab() {
    if (_currentTeam == null) return const SizedBox.shrink();

    return TeamPerformanceScreen(
      teamId: _currentTeam!.id,
      teamName: _currentTeam!.name,
    );
  }

  Widget _buildHistoryTab() {
    if (_currentTeam == null) return const SizedBox.shrink();

    return StreamBuilder<List<TeamHistoryEntry>>(
      stream:
          _teamService.watchTeamHistory(_currentTeam!.id, limit: _historyLimit),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.redAccent),
                Gap(12.h),
                Text(
                  'Failed to load venue history',
                  style: TextStyles.font14White600Weight,
                ),
                Gap(8.h),
                Text(
                  'Please try again later.',
                  style:
                      TextStyles.font12White500Weight.copyWith(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 56, color: Colors.white38),
                  Gap(12.h),
                  Text(
                    'No venue history yet',
                    style: TextStyles.font16White600Weight,
                  ),
                  Gap(8.h),
                  Text(
                    'Team admins can add historic matches from the admin panel.',
                    style: TextStyles.font12White500Weight
                        .copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final canLoadMore = history.length >= _historyLimit;

        return ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: history.length + (canLoadMore ? 1 : 0),
          separatorBuilder: (_, __) => Gap(12.h),
          itemBuilder: (context, index) {
            if (index == history.length) {
              return _buildLoadMoreButton(
                label: 'Load more history',
                onPressed: () {
                  setState(() {
                    _historyLimit += 10;
                  });
                },
              );
            }
            final entry = history[index];
            return _buildHistoryCard(entry);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(TeamHistoryEntry entry) {
    final dateLabel = DateFormat('MMM d, yyyy').format(entry.date);
    final resultColor = _historyResultColor(entry.result);

    final card = Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color:
                      PublicProfileTheme.panelAccentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.location_city,
                  color: PublicProfileTheme.panelAccentColor,
                  size: 20.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHistoryVenueLabel(entry),
                    Gap(4.h),
                    Text(
                      '$dateLabel • ${entry.matchType}',
                      style: TextStyles.font12White500Weight
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  entry.result,
                  style: TextStyles.font12White500Weight
                      .copyWith(color: resultColor),
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              const Icon(Icons.sports, size: 16, color: Colors.white54),
              Gap(6.w),
              Expanded(
                child: Text(
                  'vs ${entry.opponent}',
                  style: TextStyles.font13White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              const Icon(Icons.place, size: 16, color: Colors.white54),
              Gap(6.w),
              Expanded(
                child: Text(
                  entry.location,
                  style: TextStyles.font13White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          if (entry.summary.trim().isNotEmpty) ...[
            Gap(10.h),
            Text(
              entry.summary,
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white60),
            ),
          ],
        ],
      ),
    );

    return _buildGlassPanel(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => _openHistoryMatch(entry),
          child: card,
        ),
      ),
    );
  }

  Widget _buildHistoryVenueLabel(TeamHistoryEntry entry) {
    final isClickable =
        (entry.venueId != null && entry.venueId!.isNotEmpty) ||
            entry.venue.trim().isNotEmpty;
    final textStyle = TextStyles.font16White600Weight.copyWith(
      color: isClickable
          ? PublicProfileTheme.panelAccentColor
          : Colors.white,
      decoration:
          isClickable ? TextDecoration.underline : TextDecoration.none,
      decorationThickness: 1.5,
    );

    if (!isClickable) {
      return Text(entry.venue, style: textStyle);
    }

    return GestureDetector(
      onTap: () => _openVenueFromHistory(entry),
      child: Text(entry.venue, style: textStyle),
    );
  }

  Color _historyResultColor(String result) {
    final normalised = result.toLowerCase();
    if (normalised.contains('win')) return ColorsManager.success;
    if (normalised.contains('draw')) return ColorsManager.warning;
    if (normalised.contains('loss') ||
        normalised.contains('lost') ||
        normalised.contains('defeat')) {
      return ColorsManager.error;
    }
    return ColorsManager.primary;
  }


  Widget _buildLoadMoreButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: PublicProfileTheme.panelAccentColor,
          side: BorderSide(
            color: PublicProfileTheme.panelAccentColor.withOpacity(0.6),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTournamentCard(TeamTournamentEntry entry) {
    final dateLabel = DateFormat('MMM d, yyyy').format(entry.startDate);
    final statusColor = _tournamentStatusColor(entry.status);

    return _buildGlassPanel(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => _openTournamentDetail(entry),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: PublicProfileTheme.panelAccentColor
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: PublicProfileTheme.panelAccentColor,
                        size: 20.sp,
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.tournamentName,
                            style: TextStyles.font16White600Weight,
                          ),
                          Gap(4.h),
                          Text(
                            '$dateLabel • ${entry.stage}',
                            style: TextStyles.font12White500Weight
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        entry.status,
                        style: TextStyles.font12White500Weight
                            .copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
                Gap(12.h),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        size: 16, color: Colors.white54),
                    Gap(6.w),
                    Expanded(
                      child: Text(
                        'Stage: ${entry.stage}',
                        style: TextStyles.font13White500Weight
                            .copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                if (entry.logoUrl != null && entry.logoUrl!.isNotEmpty) ...[
                  Gap(10.h),
                  Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      image: DecorationImage(
                        image: NetworkImage(entry.logoUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _tournamentStatusColor(String status) {
    final normalised = status.toLowerCase();
    if (normalised.contains('upcoming') || normalised.contains('scheduled')) {
      return ColorsManager.mainBlue;
    }
    if (normalised.contains('completed') ||
        normalised.contains('finished') ||
        normalised.contains('won')) {
      return ColorsManager.success;
    }
    if (normalised.contains('cancel')) {
      return ColorsManager.error;
    }
    return ColorsManager.warning;
  }

  Widget _buildTournamentsTab() {
    if (_currentTeam == null) return const SizedBox.shrink();

    return StreamBuilder<List<TeamTournamentEntry>>(
      stream: _teamService.watchTeamTournaments(_currentTeam!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.redAccent),
                Gap(12.h),
                Text(
                  'Failed to load tournaments',
                  style: TextStyles.font14White600Weight,
                ),
                Gap(6.h),
                Text(
                  'Try refreshing later.',
                  style:
                      TextStyles.font12White500Weight.copyWith(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        final tournaments = snapshot.data ?? [];
        if (tournaments.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 56, color: Colors.white38),
                  Gap(16.h),
                  Text(
                    'No tournaments yet',
                    style: TextStyles.font16White600Weight,
                  ),
                  Gap(8.h),
                  Text(
                    'Team admins can record tournament participation from the admin panel.',
                    style: TextStyles.font12White500Weight
                        .copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final display =
            tournaments.take(_tournamentLimit).toList(growable: false);
        final canLoadMore = tournaments.length > display.length;

        return ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: display.length + (canLoadMore ? 1 : 0),
          separatorBuilder: (_, __) => Gap(12.h),
          itemBuilder: (context, index) {
            if (index == display.length) {
              return _buildLoadMoreButton(
                label: 'Load more tournaments',
                onPressed: () {
                  setState(() {
                    _tournamentLimit += 6;
                  });
                },
              );
            }
            final tournament = display[index];
            return _buildTournamentCard(tournament);
          },
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return _buildGlassPanel(
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.font18DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required Widget child,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.font18DarkBlue600Weight
                    .copyWith(color: Colors.white),
              ),
              if (subtitle != null) ...[
                Gap(6.h),
                Text(
                  subtitle,
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Gap(16.h),
        child,
      ],
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return _buildGlassPanel(
      borderRadius: 22,
      child: content,
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyles.font14White500Weight
                  .copyWith(color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyles.font14White500Weight,
            ),
          ),
        ],
      ),
    );
  }

  /// Coach row in the overview "Team Details" section with tap support.
  Widget _buildCoachDetailRow() {
    final coachName = _currentTeam!.coachName!;

    return GestureDetector(
      onTap: _openCoachProfileFromOverview,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: _buildDetailRow('Coach', coachName),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white70,
            size: 16.sp,
          ),
        ],
      ),
    );
  }

  /// Standalone coaching section similar to venue-style info cards.
  Widget _buildCoachSection() {
    final coachName = _currentTeam!.coachName!;

    return _buildCardSection(
      title: 'Coaching',
      subtitle: 'Tap to view full coach profile',
      child: InkWell(
        onTap: _openCoachProfileFromOverview,
        borderRadius: BorderRadius.circular(18.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: ColorsManager.mainBlue.withOpacity(0.15),
                child: Text(
                  coachName.isNotEmpty ? coachName[0].toUpperCase() : '?',
                  style: TextStyles.font16White600Weight,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coachName,
                      style: TextStyles.font15DarkBlue500Weight
                          .copyWith(color: Colors.white),
                    ),
                    Gap(4.h),
                    Text(
                      'Head coach assigned to this team',
                      style: TextStyles.font12White500Weight
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the coach detail screen when tapping coach name in overview.
  Future<void> _openCoachProfileFromOverview() async {
    final coachId = _currentTeam?.coachId;

    if (coachId == null || coachId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach profile is not linked yet.')),
      );
      return;
    }

    await DetailNavigator.openCoach(context, coachId: coachId);
  }

  Widget _buildMemberCard(TeamMember member) {
    return _buildGlassPanel(
      margin: EdgeInsets.only(bottom: 12.h),
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => _openMemberProfile(member),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor:
                      PublicProfileTheme.panelAccentColor.withOpacity(0.2),
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          color: PublicProfileTheme.panelAccentColor,
                          size: 20.sp,
                        )
                      : null,
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.userName,
                        style: TextStyles.font16White600Weight,
                      ),
                      Gap(4.h),
                      Text(
                        _getRoleDisplayName(member.role),
                        style: TextStyles.font12White500Weight
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (_buildMemberActions(member) != null)
                  _buildMemberActions(member)!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildMemberActions(TeamMember member) {
    // Add member-specific actions here if needed
    return null;
  }

  Widget _buildTeamActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppFilledButton(
                text: 'Team Chat',
                onPressed: _openTeamChat,
                icon: const Icon(Icons.chat),
                variant: ButtonVariant.secondary,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AppFilledButton(
                text: 'Dashboard',
                onPressed: _navigateToTeamDashboard,
                icon: const Icon(Icons.dashboard),
              ),
            ),
          ],
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                text: 'Schedule',
                onPressed: _navigateToTeamSchedule,
                icon: const Icon(Icons.calendar_today),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AppOutlinedButton(
                text: 'Management',
                onPressed: _navigateToTeamManagement,
                icon: const Icon(Icons.settings),
              ),
            ),
          ],
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                text: 'Share Team',
                onPressed: _shareTeam,
                icon: const Icon(Icons.share),
              ),
            ),
            if (_isTeamAdmin()) ...[
              Gap(12.w),
              Expanded(
                child: AppOutlinedButton(
                  text: 'Admin Panel',
                  onPressed: _openAdminPanel,
                  icon: const Icon(Icons.admin_panel_settings),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  bool _hasTeamActions() {
    // Show actions if user is a member or if it's a public team
    return true; // For now, always show actions
  }

  String _getRoleDisplayName(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return 'Owner';
      case TeamRole.captain:
        return 'Captain';
      case TeamRole.viceCaptain:
        return 'Vice Captain';
      case TeamRole.coach:
        return 'Coach';
      case TeamRole.member:
        return 'Member';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _sendJoinRequest() async {
    if (_currentTeam == null) return;

    setState(() {
      _isJoining = true;
    });

    try {
      await _teamService.sendJoinRequest(teamId: _currentTeam!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join request sent to ${_currentTeam!.name}'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _openTeamChat() async {
    if (_currentTeam == null) return;

    try {
      final hasChat = await _teamService.hasTeamGroupChat(_currentTeam!.id);

      if (!hasChat) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team chat not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Navigate to chat screen
      // This would require getting the ChatRoom object
      // For now, show a placeholder message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening team chat...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareTeam() {
    // Implement team sharing functionality
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share functionality coming soon!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _openMatchesDetail() {
    if (_currentTeam == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamMatchesOverviewScreen(
          teamId: _currentTeam!.id,
          teamName: _currentTeam!.name,
        ),
      ),
    );
  }

  void _openAchievementsDetail() {
    if (_currentTeam == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamAchievementsScreen(
          teamId: _currentTeam!.id,
          teamName: _currentTeam!.name,
        ),
      ),
    );
  }

  void _openStatisticsDetail() {
    if (_currentTeam == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamStatisticsScreen(
          teamId: _currentTeam!.id,
          teamName: _currentTeam!.name,
        ),
      ),
    );
  }

  void _openMemberProfile(TeamMember member) {
    if (member.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile not available for this member.'),
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed(
      Routes.communityUserProfile,
      arguments: member.userId,
    );
  }

  Future<void> _openMatchDetailById(String? matchId) async {
    if (matchId == null || matchId.isEmpty) {
      _showSnackBarMessage(
        'Match link unavailable. Ask an admin to add a match reference.',
      );
      return;
    }

    final success = await DetailNavigator.openMatch(
      context,
      matchId: matchId,
    );
    if (!success && mounted) {
      _showSnackBarMessage(
        'Unable to open match. Ask an admin to verify the reference.',
      );
    }
  }

  Future<void> _openVenueFromHistory(TeamHistoryEntry entry) async {
    VenueModel? venueModel;
    try {
      if (entry.venueId != null && entry.venueId!.isNotEmpty) {
        venueModel = await _venueService.getVenue(entry.venueId!);
      }
      venueModel ??= await _venueService.findVenueByName(entry.venue);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage('Unable to open venue: $error');
      return;
    }

    if (!mounted) return;

    if (venueModel == null) {
      _showSnackBarMessage(
        'Venue not found. Ask an admin to relink this history item.',
      );
      return;
    }

    final venueEntity = _convertVenueModelToVenue(venueModel);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueProfileScreen(venue: venueEntity),
      ),
    );
  }

  Venue _convertVenueModelToVenue(VenueModel model) {
    final metadata = Map<String, dynamic>.from(model.metadata ?? {});
    final sports = _extractVenueSports(metadata, model);
    final amenities = _buildVenueAmenities(model, metadata);
    final coachIds = _stringList(metadata['coachIds']);
    final coordinates = _decodeCoordinates(
      metadata['coordinates'],
      model.gpsCoordinates,
    );
    final currency = metadata['currency']?.toString() ??
        metadata['pricingCurrency']?.toString() ??
        'PKR';

    double _fallbackDaily() => model.hourlyRate > 0
        ? (model.hourlyRate * 6)
        : _parseDouble(metadata['dailyRate']);
    double _fallbackWeekly() => model.hourlyRate > 0
        ? (model.hourlyRate * 24)
        : _parseDouble(metadata['weeklyRate']);

    final pricing = VenuePricing(
      hourlyRate: model.hourlyRate,
      dailyRate: _positiveOrDefault(
        _parseDouble(metadata['dailyRate']),
        _fallbackDaily(),
      ),
      weeklyRate: _positiveOrDefault(
        _parseDouble(metadata['weeklyRate']),
        _fallbackWeekly(),
      ),
      currency: currency,
      tiers: const [],
      hasPeakPricing: false,
      peakRates: const {},
    );

    final hours = _buildVenueHoursFromModel(model);
    final mergedMetadata = {
      ...metadata,
      'legacyOwnerName': model.ownerName,
      'legacyOwnerAvatar': model.ownerProfilePicture,
    };

    return Venue(
      id: model.id,
      name: model.title,
      description: model.description,
      address: model.location,
      city: _deriveCity(model.location, metadata),
      state: _deriveRegion(metadata, 'state'),
      country: _deriveRegion(metadata, 'country'),
      latitude: coordinates.dx,
      longitude: coordinates.dy,
      sports: sports.isNotEmpty ? sports : [model.sportType.displayName],
      images: _resolveVenueImages(model, metadata),
      amenities: amenities,
      pricing: pricing,
      hours: hours,
      rating: model.averageRating,
      totalReviews: model.totalReviews,
      coachIds: coachIds,
      isVerified: metadata['isVerified'] == true || model.isActive,
      ownerId: model.ownerId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isActive: model.isActive,
      phoneNumber: model.contactInfo ?? metadata['phoneNumber']?.toString(),
      googleMapsLink: metadata['googleMapsLink']?.toString(),
      metadata: mergedMetadata,
    );
  }

  List<String> _extractVenueSports(
    Map<String, dynamic> metadata,
    VenueModel model,
  ) {
    final sports = _stringList(metadata['sports']);
    if (sports.isNotEmpty) {
      return sports;
    }
    return [model.sportType.displayName];
  }

  List<VenueAmenity> _buildVenueAmenities(
    VenueModel model,
    Map<String, dynamic> metadata,
  ) {
    final amenities = <VenueAmenity>[];
    if (model.amenities.isNotEmpty) {
      amenities.addAll(
        model.amenities.map(VenueAmenity.fromDynamic),
      );
    }

    final metadataAmenities = metadata['amenities'];
    if (metadataAmenities is List) {
      amenities.addAll(metadataAmenities.map(VenueAmenity.fromDynamic));
    } else if (metadataAmenities is Map) {
      amenities.addAll(
        metadataAmenities.values.map(VenueAmenity.fromDynamic),
      );
    }

    if (amenities.isEmpty) {
      amenities.add(
        VenueAmenity(
          id: 'training_surface',
          name: 'Training-grade surface',
          icon: '',
          description: 'High quality playing surface maintained daily.',
        ),
      );
    }
    return amenities;
  }

  VenueHours _buildVenueHoursFromModel(VenueModel model) {
    if (model.availableDays.isEmpty || model.availableTimeSlots.isEmpty) {
      return VenueHours(weeklyHours: {});
    }

    final slot = model.availableTimeSlots.first;
    final weeklyHours = <String, DayHours>{};
    for (final day in model.availableDays) {
      weeklyHours[day] = DayHours(
        isOpen: true,
        openTime: slot.start,
        closeTime: slot.end,
      );
    }
    return VenueHours(weeklyHours: weeklyHours);
  }

  String _deriveCity(String location, Map<String, dynamic> metadata) {
    final cityMeta = metadata['city']?.toString();
    if (cityMeta != null && cityMeta.trim().isNotEmpty) {
      return cityMeta.trim();
    }
    final segments = location.split(',');
    if (segments.length > 1) {
      return segments.last.trim();
    }
    return location;
  }

  String _deriveRegion(Map<String, dynamic> metadata, String key) {
    final value = metadata[key]?.toString();
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    return '';
  }

  Offset _decodeCoordinates(dynamic coords, String? fallback) {
    double lat = 0;
    double lng = 0;
    if (coords is Map) {
      lat = _parseDouble(coords['latitude']);
      lng = _parseDouble(coords['longitude']);
    }
    if ((lat == 0 && lng == 0) && fallback != null && fallback.contains(',')) {
      final parts = fallback.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim()) ?? lat;
        lng = double.tryParse(parts[1].trim()) ?? lng;
      }
    }
    return Offset(lat, lng);
  }

  List<String> _resolveVenueImages(
    VenueModel model,
    Map<String, dynamic> metadata,
  ) {
    final images = <String>[
      ...model.images,
    ];
    final metadataImages = metadata['images'];
    if (metadataImages is List) {
      images.addAll(
        metadataImages
            .map((e) => e.toString())
            .where((url) => url.trim().isNotEmpty),
      );
    }

    if (images.isEmpty) {
      images.add(
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=1200&q=80',
      );
    }
    return images;
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  double _positiveOrDefault(double candidate, double fallback) {
    return candidate > 0 ? candidate : (fallback > 0 ? fallback : 0);
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((element) => element.trim().isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  void _showSnackBarMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openHistoryMatch(TeamHistoryEntry entry) async {
    await _openMatchDetailById(entry.matchId);
  }

  Future<void> _openTournamentDetail(TeamTournamentEntry entry) async {
    final tournamentId = entry.tournamentId;
    if (tournamentId == null || tournamentId.isEmpty) {
      _showSnackBarMessage(
        'Tournament link unavailable. Ask a team admin to link it.',
      );
      return;
    }

    try {
      final tournament =
          await _tournamentService.getTournamentById(tournamentId);
      if (!mounted) return;

      if (tournament == null) {
        _showSnackBarMessage('Tournament not found.');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentDetailScreen(tournament: tournament),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage('Failed to open tournament: $error');
    }
  }

  /// Check if current user is team admin (owner or captain)
  bool _isTeamAdmin() {
    final team = _currentTeam;
    if (team == null) return false;
    if (AdminOverrideHelper.allowTeamOverride(team)) return true;
    final userId = _auth.currentUser?.uid;
    return team.isAdminOrOwner(userId);
  }

  /// Open team admin panel
  void _openAdminPanel() {
    final team = _currentTeam;
    if (team == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) => TeamAdminSettingsScreen(
          team: team,
          isReadOnly: !_isTeamAdmin(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final tween =
              Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero);
          return SlideTransition(
            position: tween.animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  /// Navigate to team management
  void _navigateToTeamManagement() {
    if (_currentTeam == null) return;

    Navigator.pushNamed(
      context,
      '/teamManagementScreen',
      arguments: _currentTeam!.id,
    );
  }

  /// Navigate to team schedule
  void _navigateToTeamSchedule() {
    if (_currentTeam == null) return;

    Navigator.pushNamed(
      context,
      '/teamScheduleScreen',
      arguments: {
        'teamId': _currentTeam!.id,
        'teamName': _currentTeam!.name,
      },
    );
  }

  /// Navigate to team dashboard
  void _navigateToTeamDashboard() {
    if (_currentTeam == null) return;

    Navigator.pushNamed(
      context,
      '/teamDashboardScreen',
      arguments: _currentTeam!.id,
    );
  }

  Widget _buildHeroSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentTeam?.name ?? 'Unknown Team',
          style: TextStyles.font32White700Weight,
        ),
        Gap(10.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 8.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildInfoChip(
              icon: Icons.sports,
              label: _currentTeam?.sportType.displayName ?? 'Unknown',
            ),
            if (_currentTeam?.location != null)
              _buildInfoChip(
                icon: Icons.location_on,
                label: _currentTeam!.location!,
              ),
            _buildInfoChip(
              icon: Icons.calendar_month,
              label: 'Since ${_formatDate(_currentTeam?.createdAt)}',
            ),
          ],
        ),
      ],
    );
  }
}
