import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/team_model.dart';

class TeamDetailScreen extends StatefulWidget {
  final TeamModel team;

  const TeamDetailScreen({
    super.key,
    required this.team,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                _buildPlayersTab(),
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
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor: ColorsManager.background,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.team.bannerImageUrl != null)
              CachedNetworkImage(
                imageUrl: widget.team.bannerImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => _buildBannerFallback(),
              )
            else
              _buildBannerFallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 32.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.team.name,
                    style: TextStyles.font28White700Weight,
                  ),
                  Gap(8.h),
                  Row(
                    children: [
                      Icon(
                        _getSportIcon(widget.team.sportType),
                        color: Colors.white70,
                        size: 18.sp,
                      ),
                      Gap(6.w),
                      Text(
                        widget.team.sportType.displayName,
                        style: TextStyles.font16White400Weight,
                      ),
                      if (widget.team.city != null) ...[
                        Gap(16.w),
                        Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 18.sp,
                        ),
                        Gap(4.w),
                        Text(
                          widget.team.city!,
                          style: TextStyles.font16White400Weight,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: ColorsManager.primaryGradient,
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Icon(
            _getSportIcon(widget.team.sportType),
            color: Colors.white24,
            size: 72.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamAvatar(),
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
                              style: TextStyles.font24DarkBlue700Weight,
                            ),
                          ),
                          if (widget.team.isPublic)
                            _buildVisibilityChip('Public', Icons.public)
                          else
                            _buildVisibilityChip('Private', Icons.lock),
                        ],
                      ),
                      Gap(8.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 8.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildInfoChip(
                            icon: _getSportIcon(widget.team.sportType),
                            label: widget.team.sportType.displayName,
                          ),
                          if (widget.team.city != null)
                            _buildInfoChip(
                              icon: Icons.location_on,
                              label: widget.team.city!,
                            ),
                          _buildInfoChip(
                            icon: Icons.calendar_month,
                            label:
                                'Since ${_formatDate(widget.team.createdAt)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.team.description != null &&
                widget.team.description!.trim().isNotEmpty) ...[
              Gap(20.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.team.description!,
                  style: TextStyles.font14Grey400Weight,
                ),
              ),
            ],
            Gap(24.h),
            _buildQuickStats(),
          ],
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

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: ColorsManager.primary,
            size: 16.sp,
          ),
          Gap(6.w),
          Text(
            label,
            style: TextStyles.font12BlueRegular,
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.primary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14.sp,
          ),
          Gap(6.w),
          Text(
            label,
            style: TextStyles.font12White500Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      (
        title: 'Players',
        value: '${widget.team.activePlayersCount}/${widget.team.maxPlayers}',
        icon: Icons.people
      ),
      (
        title: 'Coaches',
        value: widget.team.coaches.length.toString(),
        icon: Icons.school
      ),
      (
        title: 'Wins',
        value: (widget.team.stat['matchesWon'] ?? 0).toString(),
        icon: Icons.emoji_events
      ),
      (
        title: 'Matches',
        value: (widget.team.stat['matchesPlayed'] ?? 0).toString(),
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
                      ? (constraints.maxWidth - 36.w) / 4
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: ColorsManager.primary,
            size: 26.sp,
          ),
          Gap(12.h),
          Text(
            value,
            style: TextStyles.font24DarkBlue600Weight,
          ),
          Gap(4.h),
          Text(
            label,
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: ColorsManager.surfaceVariant,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicator: BoxDecoration(
            color: ColorsManager.primary,
            borderRadius: BorderRadius.circular(12.r),
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Players'),
            Tab(text: 'Stats'),
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
          _buildInfoSection('Team Information', [
            _buildInfoRow('Created', _formatDate(widget.team.createdAt)),
            _buildInfoRow('Sport', widget.team.sportType.displayName),
            if (widget.team.city != null)
              _buildInfoRow('City', widget.team.city!),
            _buildInfoRow(
                'Visibility', widget.team.isPublic ? 'Public' : 'Private'),
            _buildInfoRow('Max Players', widget.team.maxPlayers.toString()),
          ]),
          Gap(24.h),
          _buildInfoSection('Recent Activity', [
            _buildActivityItem(
                'Team created', _formatDate(widget.team.createdAt)),
            // Add more activity items here
          ]),
        ],
      ),
    );
  }

  Widget _buildPlayersTab() {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: widget.team.players.length,
      itemBuilder: (context, index) {
        final player = widget.team.players[index];
        return _buildPlayerCard(player);
      },
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Match Statistics', [
            _buildInfoRow('Matches Played',
                (widget.team.stat['matchesPlayed'] ?? 0).toString()),
            _buildInfoRow('Matches Won',
                (widget.team.stat['matchesWon'] ?? 0).toString()),
            _buildInfoRow('Matches Lost',
                (widget.team.stat['matchesLost'] ?? 0).toString()),
            _buildInfoRow('Matches Drawn',
                (widget.team.stat['matchesDrawn'] ?? 0).toString()),
            _buildInfoRow('Win Percentage',
                '${((widget.team.stat['winPercentage'] ?? 0.0) as num).toStringAsFixed(1)}%'),
          ]),
          Gap(24.h),
          _buildInfoSection('Tournament Statistics', [
            _buildInfoRow('Tournament Wins',
                (widget.team.stat['tournamentWins'] ?? 0).toString()),
            _buildInfoRow('Total Points',
                (widget.team.stat['totalPoints'] ?? 0).toString()),
          ]),
        ],
      ),
    );
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
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.font14Grey400Weight,
          ),
          Text(
            value,
            style: TextStyles.font14DarkBlue500Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: ColorsManager.primary,
              shape: BoxShape.circle,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity,
                  style: TextStyles.font14DarkBlue500Weight,
                ),
                Text(
                  time,
                  style: TextStyles.font12Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(TeamPlayer player) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: ColorsManager.mainBlue.withOpacity(0.2),
            backgroundImage: player.profileImageUrl != null
                ? CachedNetworkImageProvider(player.profileImageUrl!)
                : null,
            child: player.profileImageUrl == null
                ? Text(
                    player.name[0].toUpperCase(),
                    style: TextStyle(
                      color: ColorsManager.mainBlue,
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
                Text(
                  player.role.displayName,
                  style: TextStyles.font14BlueRegular,
                ),
              ],
            ),
          ),
          if (player.jerseyNumber != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ColorsManager.mainBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '#${player.jerseyNumber}',
                style: TextStyle(
                  color: ColorsManager.mainBlue,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

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
