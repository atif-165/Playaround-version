import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/material3/material3_components.dart';

import '../models/models.dart';
import '../services/team_service.dart';

/// Screen for displaying detailed team profile information
class TeamProfileScreen extends StatefulWidget {
  final Team team;
  final bool showJoinButton;

  const TeamProfileScreen({
    super.key,
    required this.team,
    this.showJoinButton = false,
  });

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();
  
  bool _isJoining = false;
  Team? _currentTeam;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                _buildHistoryTab(),
                _buildTournamentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.h,
      pinned: true,
      backgroundColor: ColorsManager.mainBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: _currentTeam?.backgroundImageUrl != null
            ? CachedNetworkImage(
                imageUrl: _currentTeam!.backgroundImageUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: ColorsManager.mainBlue,
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              )
            : Container(
                color: ColorsManager.mainBlue,
                child: const Icon(
                  Icons.groups,
                  color: Colors.white,
                  size: 64,
                ),
              ),
      ),
      actions: [
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

  Widget _buildTeamHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Row(
            children: [
              // Team Avatar
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.w),
                ),
                child: ClipOval(
                  child: _currentTeam?.teamImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: _currentTeam!.teamImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: ColorsManager.mainBlue,
                            child: Icon(
                              Icons.groups,
                              color: Colors.white,
                              size: 40.sp,
                            ),
                          ),
                        )
                      : Container(
                          color: ColorsManager.mainBlue,
                          child: Icon(
                            Icons.groups,
                            color: Colors.white,
                            size: 40.sp,
                          ),
                        ),
                ),
              ),
              Gap(16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTeam?.name ?? 'Unknown Team',
                      style: TextStyles.font18DarkBlue600Weight,
                    ),
                    Gap(4.h),
                    Text(
                      _currentTeam?.sportType.displayName ?? 'Unknown Sport',
                      style: TextStyles.font14Blue400Weight,
                    ),
                    Gap(4.h),
                    if (_currentTeam?.location != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16.sp,
                            color: ColorsManager.gray,
                          ),
                          Gap(4.w),
                          Text(
                            _currentTeam!.location!,
                            style: TextStyles.font12Grey400Weight,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          Gap(16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Members',
                '${_currentTeam?.members.length ?? 0}/${_currentTeam?.maxMembers ?? 0}',
                Icons.people,
              ),
              _buildTournamentStatCard(),
              _buildStatCard(
                'Venues',
                '${_currentTeam?.venuesPlayed.length ?? 0}',
                Icons.location_city,
              ),
            ],
          ),
          if (_currentTeam?.description != null) ...[
            Gap(16.h),
            Text(
              _currentTeam!.description,
              style: TextStyles.font14DarkBlue500Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentStatCard() {
    final tournamentCount = _currentTeam?.tournamentsParticipated.length ?? 0;
    final hasWins = _hasWinningTournaments();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: hasWins
            ? ColorsManager.success.withValues(alpha: 0.1)
            : ColorsManager.mainBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: hasWins
            ? Border.all(color: ColorsManager.success, width: 1)
            : null,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Icon(
                Icons.emoji_events,
                color: hasWins ? ColorsManager.success : ColorsManager.mainBlue,
                size: 24.sp,
              ),
              if (hasWins)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: ColorsManager.warning,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'WIN',
                      style: TextStyle(
                        fontSize: 6.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Gap(4.h),
          Text(
            '$tournamentCount',
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: hasWins ? ColorsManager.success : null,
            ),
          ),
          Text(
            'Tournaments',
            style: TextStyles.font12Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: ColorsManager.mainBlue, size: 24.sp),
          Gap(4.h),
          Text(value, style: TextStyles.font16DarkBlue600Weight),
          Text(label, style: TextStyles.font12Grey400Weight),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: ColorsManager.mainBlue,
        unselectedLabelColor: ColorsManager.gray,
        indicatorColor: ColorsManager.mainBlue,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Members'),
          Tab(text: 'History'),
          Tab(text: 'Tournaments'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentTeam?.bio != null) ...[
            _buildSectionHeader('About the Team'),
            Gap(8.h),
            Text(
              _currentTeam!.bio!,
              style: TextStyles.font14DarkBlue500Weight,
            ),
            Gap(20.h),
          ],
          _buildSectionHeader('Team Details'),
          Gap(12.h),
          _buildDetailRow('Sport', _currentTeam?.sportType.displayName ?? 'Unknown'),
          _buildDetailRow('Created', _formatDate(_currentTeam?.createdAt)),
          _buildDetailRow('Team Type', _currentTeam?.isPublic == true ? 'Public' : 'Private'),
          _buildDetailRow('Max Members', '${_currentTeam?.maxMembers ?? 0}'),
          if (_currentTeam?.coachName != null)
            _buildDetailRow('Coach', _currentTeam!.coachName!),
          Gap(20.h),
          if (_hasTeamActions()) _buildTeamActions(),
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

  Widget _buildHistoryTab() {
    final venues = _currentTeam?.venuesPlayed ?? [];
    
    if (venues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64.sp,
              color: ColorsManager.gray,
            ),
            Gap(16.h),
            Text(
              'No venues played yet',
              style: TextStyles.font16DarkBlue500Weight,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: venues.length,
      itemBuilder: (context, index) {
        final venue = venues[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(venue),
            subtitle: const Text('Venue played'),
          ),
        );
      },
    );
  }

  Widget _buildTournamentsTab() {
    final tournaments = _currentTeam?.tournamentsParticipated ?? [];
    
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64.sp,
              color: ColorsManager.gray,
            ),
            Gap(16.h),
            Text(
              'No tournaments yet',
              style: TextStyles.font16DarkBlue500Weight,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: const Icon(Icons.emoji_events),
            title: Text(tournament),
            subtitle: const Text('Tournament participated'),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyles.font16DarkBlue600Weight,
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyles.font14DarkBlue500Weight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(TeamMember member) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.profileImageUrl != null
              ? NetworkImage(member.profileImageUrl!)
              : null,
          child: member.profileImageUrl == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(member.userName),
        subtitle: Text(_getRoleDisplayName(member.role)),
        trailing: _buildMemberActions(member),
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
        _buildSectionHeader('Actions'),
        Gap(12.h),
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
              child: AppOutlinedButton(
                text: 'Share Team',
                onPressed: _shareTeam,
                icon: const Icon(Icons.share),
              ),
            ),
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

  /// Check if team has winning tournaments
  bool _hasWinningTournaments() {
    // TODO: This should check if the team has won any tournaments
    // For now, return false as placeholder
    return false;
  }
}
