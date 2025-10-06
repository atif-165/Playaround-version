import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/team_service.dart';

/// Screen for team administration and management
class TeamAdminScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamAdminScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamAdminScreen> createState() => _TeamAdminScreenState();
}

class _TeamAdminScreenState extends State<TeamAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();
  Team? _team;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeam();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    try {
      final team = await _teamService.getTeam(widget.teamId);
      if (mounted) {
        setState(() {
          _team = team;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load team: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_team == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.teamName} Admin',
          style: TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.mainBlue,
          unselectedLabelColor: ColorsManager.gray,
          indicatorColor: ColorsManager.mainBlue,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Join Requests'),
            Tab(text: 'Settings'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(),
          _buildJoinRequestsTab(),
          _buildSettingsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    final members = _team?.members ?? [];
    
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberManagementCard(member);
      },
    );
  }

  Widget _buildJoinRequestsTab() {
    return StreamBuilder<List<TeamJoinRequest>>(
      stream: _teamService.getTeamJoinRequests(widget.teamId),
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
                  'Error loading join requests',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64.sp,
                  color: ColorsManager.gray,
                ),
                Gap(16.h),
                Text(
                  'No pending requests',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  'Join requests will appear here',
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildJoinRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Team Information'),
          Gap(16.h),
          _buildTeamInfoCard(),
          Gap(24.h),
          _buildSectionHeader('Team Settings'),
          Gap(16.h),
          _buildSettingsCard(),
          Gap(24.h),
          _buildSectionHeader('Danger Zone'),
          Gap(16.h),
          _buildDangerZoneCard(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Team Analytics'),
          Gap(16.h),
          _buildAnalyticsCard(),
          Gap(20.h),
          _buildSectionHeader('Member Activity'),
          Gap(16.h),
          _buildMemberActivityCard(),
        ],
      ),
    );
  }

  Widget _buildMemberManagementCard(TeamMember member) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.r,
            backgroundImage: member.profileImageUrl != null
                ? NetworkImage(member.profileImageUrl!)
                : null,
            child: member.profileImageUrl == null
                ? Text(
                    member.userName.isNotEmpty 
                        ? member.userName[0].toUpperCase()
                        : 'M',
                    style: TextStyles.font16White600Weight,
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
                  style: TextStyles.font16DarkBlue600Weight.copyWith(color: Colors.white),
                ),
                Gap(4.h),
                Text(
                  member.role.displayName,
                  style: TextStyles.font14Grey400Weight,
                ),
                Gap(4.h),
                Text(
                  'Joined ${_formatDate(member.joinedAt)}',
                  style: TextStyles.font12Grey400Weight,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMemberAction(value, member),
            itemBuilder: (context) => [
              if (member.role != TeamRole.owner) ...[
                const PopupMenuItem(
                  value: 'change_role',
                  child: Text('Change Role'),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove Member'),
                ),
              ],
              const PopupMenuItem(
                value: 'view_profile',
                child: Text('View Profile'),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              color: ColorsManager.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRequestCard(TeamJoinRequest request) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundImage: request.requesterProfileImageUrl != null
                    ? NetworkImage(request.requesterProfileImageUrl!)
                    : null,
                child: request.requesterProfileImageUrl == null
                    ? Text(
                        request.requesterName.isNotEmpty 
                            ? request.requesterName[0].toUpperCase()
                            : 'U',
                        style: TextStyles.font14White600Weight,
                      )
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName,
                      style: TextStyles.font16DarkBlue600Weight.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Requested to join ${_formatDate(request.createdAt)}',
                      style: TextStyles.font13Grey400Weight,
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
                  style: TextStyles.font12DarkBlue400Weight.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (request.message != null && request.message!.isNotEmpty) ...[
            Gap(12.h),
            Text(
              'Message: ${request.message}',
              style: TextStyles.font14DarkBlue500Weight,
            ),
          ],
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleJoinRequest(request.id, true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Approve'),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleJoinRequest(request.id, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Details',
            style: TextStyles.font16DarkBlue600Weight,
          ),
          Gap(16.h),
          _buildInfoRow('Team Name', _team?.name ?? ''),
          _buildInfoRow('Sport', _team?.sportType.displayName ?? ''),
          _buildInfoRow('Members', '${_team?.members.length ?? 0}/${_team?.maxMembers ?? 0}'),
          _buildInfoRow('Visibility', _team?.isPublic == true ? 'Public' : 'Private'),
          _buildInfoRow('Created', _formatDate(_team?.createdAt)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Team Visibility'),
            subtitle: Text(_team?.isPublic == true ? 'Public' : 'Private'),
            trailing: Switch(
              value: _team?.isPublic ?? true,
              onChanged: (value) => _updateTeamVisibility(value),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Max Members'),
            subtitle: Text('${_team?.maxMembers ?? 0} members'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _updateMaxMembers,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Team Info'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _editTeamInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger Zone',
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: Colors.red,
            ),
          ),
          Gap(16.h),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'Delete Team',
              style: TextStyles.font14DarkBlue500Weight.copyWith(
                color: Colors.red,
              ),
            ),
            subtitle: const Text('This action cannot be undone'),
            trailing: OutlinedButton(
              onPressed: _deleteTeam,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Statistics',
            style: TextStyles.font16DarkBlue600Weight,
          ),
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Members', '${_team?.members.length ?? 0}'),
              ),
              Expanded(
                child: _buildStatItem('Active Members', '${_team?.activeMembersCount ?? 0}'),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Tournaments', '${_team?.tournamentsParticipated.length ?? 0}'),
              ),
              Expanded(
                child: _buildStatItem('Venues Played', '${_team?.venuesPlayed.length ?? 0}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberActivityCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyles.font16DarkBlue600Weight,
          ),
          Gap(16.h),
          Text(
            'Activity tracking coming soon...',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyles.font18DarkBlue600Weight,
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
              value,
              style: TextStyles.font14DarkBlue500Weight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyles.font20DarkBlue600Weight,
        ),
        Text(
          label,
          style: TextStyles.font12Grey400Weight,
        ),
      ],
    );
  }

  void _handleMemberAction(String action, TeamMember member) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(member);
        break;
      case 'remove':
        _showRemoveMemberDialog(member);
        break;
      case 'view_profile':
        // TODO: Navigate to member profile
        break;
    }
  }

  void _showChangeRoleDialog(TeamMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${member.userName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TeamRole.values
              .where((role) => role != TeamRole.owner)
              .map((role) => ListTile(
                    title: Text(role.displayName),
                    onTap: () {
                      Navigator.pop(context);
                      _changeMemberRole(member, role);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(TeamMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.userName} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(member);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeMemberRole(TeamMember member, TeamRole newRole) async {
    try {
      await _teamService.assignMemberRole(
        teamId: widget.teamId,
        memberId: member.userId,
        newRole: newRole,
      );
      await _loadTeam();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.userName} role changed to ${newRole.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(TeamMember member) async {
    try {
      await _teamService.removeMember(widget.teamId, member.userId);
      await _loadTeam();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.userName} removed from team'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleJoinRequest(String requestId, bool approve) async {
    try {
      if (approve) {
        await _teamService.approveJoinRequest(requestId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Join request approved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _teamService.rejectJoinRequest(requestId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Join request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      await _loadTeam();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to handle request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateTeamVisibility(bool isPublic) {
    // TODO: Implement team visibility update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team visibility update coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _updateMaxMembers() {
    // TODO: Implement max members update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Max members update coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editTeamInfo() {
    // TODO: Implement team info editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team info editing coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteTeam() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text(
          'Are you sure you want to delete this team? This action cannot be undone and will remove all team data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _teamService.deleteTeam(widget.teamId);
                if (mounted) {
                  Navigator.pop(context); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Team deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete team: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}
