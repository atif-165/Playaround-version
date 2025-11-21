import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../routing/routes.dart';
import '../models/models.dart';
import '../services/team_service.dart';
import '../widgets/team_list_widget.dart';
import 'team_creation_screen.dart';
import 'team_profile_screen.dart';

/// Screen for managing user's teams
class TeamManagementScreen extends StatefulWidget {
  final String? teamId;

  const TeamManagementScreen({super.key, this.teamId});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  SportType? _selectedSportFilter;
  String? _selectedLocationFilter;

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF11123D),
      Color(0xFF070616),
    ],
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {}); // Refresh UI when tab changes
    });
  }

  Team _buildShowcaseTeam() {
    final now = DateTime.now();
    return Team(
      id: 'showcase-team',
      name: 'Thunder Warriors FC',
      description:
          'High-tempo football club with a disciplined core and elite coaching staff.',
      bio:
          'Preview team layout: this dummy squad shows off the new experience. Create your own to unlock scheduling, analytics and roster control.',
      sportType: SportType.football,
      ownerId: 'demo-owner',
      members: [
        TeamMember(
          userId: 'demo-owner',
          userName: 'You',
          role: TeamRole.owner,
          joinedAt: now,
          position: 'Forward',
          jerseyNumber: 10,
          trophies: 4,
          rating: 4.8,
        ),
        TeamMember(
          userId: 'demo-captain',
          userName: 'Ayan Malik',
          role: TeamRole.captain,
          joinedAt: now.subtract(const Duration(days: 42)),
          position: 'Midfielder',
          jerseyNumber: 8,
          trophies: 6,
          rating: 4.6,
        ),
        TeamMember(
          userId: 'demo-coach',
          userName: 'Coach Hina Qureshi',
          role: TeamRole.coach,
          joinedAt: now.subtract(const Duration(days: 120)),
          position: 'Head Coach',
          rating: 4.9,
        ),
      ],
      maxMembers: 22,
      isPublic: true,
      location: 'Lahore • Fortress Arena',
      createdAt: now.subtract(const Duration(days: 150)),
      updatedAt: now,
      metadata: {
        'matchesWon': 12,
        'matchesLost': 3,
        'matchesDrawn': 2,
        'matchesPlayed': 17,
        'goalsScored': 42,
        'goalsConceded': 18,
        'totalPoints': 38,
        'winPercentage': 70.5,
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: ColorsManager.primaryGradient,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.primary.withValues(alpha: 0.3),
                blurRadius: 14.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: ColorsManager.onPrimary,
            size: 22.sp,
          ),
        ),
        Gap(16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.font18DarkBlueBold.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                Gap(6.h),
                Text(
                  subtitle,
                  style: TextStyles.font13Grey400Weight.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ColorsManager.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: ColorsManager.primary.withValues(alpha: 0.35),
                  blurRadius: 18.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28.sp,
              color: Colors.white,
            ),
          ),
          Gap(18.h),
          Text(
            title,
            style: TextStyles.font16DarkBlue500Weight.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Gap(10.h),
          Text(
            subtitle,
            style: TextStyles.font13Grey400Weight.copyWith(
              color: Colors.white.withOpacity(0.7),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Team Management',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _backgroundGradient,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Team Chat',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _openTeamChat,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: ColorsManager.primaryGradient,
              borderRadius: BorderRadius.circular(22.r),
              boxShadow: [
                BoxShadow(
                  color: ColorsManager.primary.withValues(alpha: 0.35),
                  blurRadius: 16.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            labelColor: Colors.white,
            labelStyle: TextStyles.font14White500Weight,
            unselectedLabelColor: Colors.white.withOpacity(0.55),
            tabs: [
              Tab(
                child: _buildTabLabel(Icons.workspace_premium, 'My Teams'),
              ),
              Tab(
                child: _buildTabLabel(Icons.explore_outlined, 'Browse Teams'),
              ),
              Tab(
                child: _buildTabLabel(Icons.mail_outline, 'Join Requests'),
              ),
            ],
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: SafeArea(
          top: false,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyTeamsTab(),
              _buildBrowseTeamsTab(),
              _buildJoinRequestsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilters = _hasActiveFilters();
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: _showFilterDialog,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: hasFilters
              ? ColorsManager.primaryGradient
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: hasFilters
                ? ColorsManager.primary.withValues(alpha: 0.6)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              color: hasFilters
                  ? ColorsManager.onPrimary
                  : Colors.white.withOpacity(0.8),
              size: 18.sp,
            ),
            Gap(6.w),
            Text(
              'Filters',
              style: TextStyle(
                color: hasFilters
                    ? ColorsManager.onPrimary
                    : Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabLabel(IconData icon, String label) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18.sp),
          Gap(6.w),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMyTeamsTab() {
    return StreamBuilder<List<Team>>(
      stream: _teamService.getUserTeams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading teams',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  snapshot.error.toString(),
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final teams = snapshot.data ?? [];
        final displayTeams = teams.isEmpty ? [_buildShowcaseTeam()] : teams;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Icons.workspace_premium_rounded,
                title: teams.isEmpty ? 'Build Your First Squad' : 'Your Squads',
                subtitle: teams.isEmpty
                    ? 'Preview how your future teams will look. Create a team to unlock full management controls.'
                    : 'Manage the teams you lead or play with. Tap any squad to open its control center.',
              ),
              Gap(20.h),
              Expanded(
                child: TeamListWidget(
                  teams: displayTeams,
                  onTeamTap: _navigateToTeamDetails,
                  isLoading: false,
                  padding: EdgeInsets.only(bottom: 24.h),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrowseTeamsTab() {
    return StreamBuilder<List<Team>>(
      stream: _searchQuery.isNotEmpty
          ? _teamService.searchTeamsStream(
              _searchQuery,
              sportType: _selectedSportFilter,
              location: _selectedLocationFilter,
            )
          : _teamService.getPublicTeams(
              sportType: _selectedSportFilter,
            ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading teams',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  snapshot.error.toString(),
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final teams = snapshot.data ?? [];

        if (teams.isEmpty && _searchQuery.isNotEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
            child: _buildEmptyState(
              icon: Icons.search_off_outlined,
              title: 'No teams match this search',
              subtitle:
                  'Try a different sport, city or keyword to discover more squads.',
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              if (_searchQuery.isNotEmpty || _selectedSportFilter != null)
                _buildActiveFiltersChips(),
              Gap(12.h),
              Expanded(
                child: TeamListWidget(
                  teams: teams,
                  onTeamTap: _navigateToTeamDetails,
                  onJoinTeam: _sendJoinRequest,
                  showJoinButton: true,
                  isLoading: false,
                  padding: EdgeInsets.only(bottom: 24.h),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJoinRequestsTab() {
    return StreamBuilder<List<TeamJoinRequest>>(
      stream: _teamService.getUserJoinRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading requests',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  snapshot.error.toString(),
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
            child: _buildEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No join requests yet',
              subtitle:
                  'As you apply to teams their responses will flow back into this inbox.',
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Icons.mail_outline,
                title: 'Join Request Inbox',
                subtitle:
                    'Track approvals, get feedback from coaches and withdraw applications when needed.',
              ),
              Gap(20.h),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => Gap(14.h),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildJoinRequestCard(request);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJoinRequestCard(TeamJoinRequest request) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.surfaceVariant.withValues(alpha: 0.95),
            ColorsManager.background.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24.r,
            offset: Offset(0, 16.h),
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
                  request.teamName,
                  style: TextStyles.font18DarkBlueBold.copyWith(
                    color: ColorsManager.onBackground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildStatusChip(request.status),
            ],
          ),
          Gap(8.h),
          if (request.message != null && request.message!.isNotEmpty) ...[
            Text(
              'Message: ${request.message}',
              style: TextStyles.font14Blue400Weight
                  .copyWith(color: ColorsManager.onBackground),
            ),
            Gap(8.h),
          ],
          Text(
            'Requested on ${_formatDate(request.createdAt)}',
            style: TextStyles.font13Grey400Weight
                .copyWith(color: ColorsManager.textSecondary),
          ),
          if (request.responseMessage != null &&
              request.responseMessage!.isNotEmpty) ...[
            Gap(8.h),
            Text(
              'Response: ${request.responseMessage}',
              style: TextStyles.font13Grey400Weight
                  .copyWith(color: ColorsManager.textSecondary),
            ),
          ],
          if (request.isPending) ...[
            Gap(12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _cancelJoinRequest(request.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  elevation: 0,
                ),
                child: Text(
                  'Cancel Request',
                  style: TextStyles.font14White500Weight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(JoinRequestStatus status) {
    Color color;
    switch (status) {
      case JoinRequestStatus.pending:
        color = ColorsManager.secondary;
        break;
      case JoinRequestStatus.approved:
        color = ColorsManager.success;
        break;
      case JoinRequestStatus.rejected:
        color = ColorsManager.error;
        break;
      case JoinRequestStatus.cancelled:
        color = ColorsManager.textSecondary;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.24),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyles.font12DarkBlue400Weight.copyWith(
          color: ColorsManager.onBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToCreateTeam() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeamCreationScreen(),
      ),
    );

    if (result != null && mounted) {
      // Team was created successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navigateToTeamDetails(Team team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamProfileScreen(
          team: team,
          showJoinButton:
              false, // Don't show join button for teams user can already access
        ),
      ),
    );
  }

  void _sendJoinRequest(Team team) async {
    try {
      await _teamService.sendJoinRequest(teamId: team.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join request sent to ${team.name}'),
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

  void _openTeamChat() {
    Navigator.pushNamed(context, Routes.chatListScreen);
  }

  void _cancelJoinRequest(String requestId) async {
    try {
      await _teamService.cancelJoinRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request cancelled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search teams by name, sport or city...',
                    hintStyle: TextStyles.font14Grey400Weight.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.6),
                      size: 20.sp,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white.withOpacity(0.6),
                              size: 20.sp,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Gap(8.w),
              _buildFilterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final activeFilters = <Widget>[];

    if (_selectedSportFilter != null) {
      activeFilters.add(
        Chip(
          label: Text(_selectedSportFilter!.displayName),
          onDeleted: () {
            setState(() {
              _selectedSportFilter = null;
            });
          },
          backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.1),
          labelStyle: TextStyles.font12DarkBlue400Weight,
        ),
      );
    }

    if (_selectedLocationFilter != null) {
      activeFilters.add(
        Chip(
          label: Text(_selectedLocationFilter!),
          onDeleted: () {
            setState(() {
              _selectedLocationFilter = null;
            });
          },
          backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.1),
          labelStyle: TextStyles.font12DarkBlue400Weight,
        ),
      );
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: activeFilters,
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedSportFilter != null || _selectedLocationFilter != null;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: ColorsManager.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Filter Teams',
                    style: TextStyles.font18DarkBlueBold,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSportFilter = null;
                        _selectedLocationFilter = null;
                      });
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyles.font14MainBlue500Weight,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sport Type',
                      style: TextStyles.font16DarkBlueBold,
                    ),
                    Gap(12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: SportType.values.map((sport) {
                        final isSelected = _selectedSportFilter == sport;
                        return FilterChip(
                          label: Text(sport.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSportFilter = selected ? sport : null;
                            });
                          },
                          selectedColor:
                              ColorsManager.primary.withValues(alpha: 0.2),
                          checkmarkColor: ColorsManager.primary,
                        );
                      }).toList(),
                    ),
                    Gap(24.h),
                    Text(
                      'Location',
                      style: TextStyles.font16DarkBlueBold,
                    ),
                    Gap(12.h),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                      ),
                      onChanged: (value) {
                        _selectedLocationFilter =
                            value.isNotEmpty ? value : null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: ColorsManager.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorsManager.textSecondary,
                        side: BorderSide(color: ColorsManager.textSecondary),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {}); // Refresh the stream
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('Apply Filters'),
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
}
