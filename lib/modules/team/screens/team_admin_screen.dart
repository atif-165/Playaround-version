import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/config/app_config.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/team_service.dart';
import '../widgets/team_admin_data_tab.dart';
import '../../coach/services/coach_service.dart';
import '../../../models/coach_profile.dart';
import '../../tournament/services/tournament_service.dart';
import '../../tournament/models/tournament_model.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Screen for team administration and management
class TeamAdminScreen extends StatefulWidget {
  final String teamId;
  final String teamName;
  final bool isReadOnly;

  const TeamAdminScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    this.isReadOnly = false,
  });

  @override
  State<TeamAdminScreen> createState() => _TeamAdminScreenState();
}

class _TeamAdminScreenState extends State<TeamAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();
  final CoachService _coachService = CoachService();
  final TournamentService _tournamentService = TournamentService();
  Team? _team;
  final Uuid _uuid = const Uuid();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  bool get _isReadOnly => !AppConfig.enablePublicTeamAdmin && widget.isReadOnly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          '${widget.teamName} Admin',
          style: TextStyles.font18DarkBlue600Weight.copyWith(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isReadOnly)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'View Only',
                  style: TextStyles.font12White500Weight,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(64.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: _buildGlassPanel(
              borderRadius: 24,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicator: BoxDecoration(
                  gradient: ColorsManager.primaryGradient,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                tabs: const [
                  Tab(text: 'Members'),
                  Tab(text: 'Join Requests'),
                  Tab(text: 'Settings'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Coaches'),
                  Tab(text: 'Tournaments'),
                  Tab(text: 'Data'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMembersTab(),
            _buildJoinRequestsTab(),
            _buildSettingsTab(),
            _buildAnalyticsTab(),
            _buildCoachesTab(),
            _buildTournamentsTab(),
            TeamAdminDataTab(
              team: _team!,
              isReadOnly: _isReadOnly,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Coaches Tab ----------------
  Widget _buildCoachesTab() {
    final coaches = _team?.coaches ?? [];
    return _wrapReadOnlyOverlay(
      message: 'Coaches are view-only for non-admin users.',
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Add Coach'),
            Gap(12.h),
            _CoachSearchBox(
              isDisabled: _isReadOnly,
              onPick: (coach) async {
                try {
                  await _teamService.addMemberToTeam(
                    teamId: _team!.id,
                    userId: coach.uid,
                    userName: coach.fullName,
                    userImageUrl: coach.profilePictureUrl,
                    role: TeamRole.coach,
                  );
                  await _loadTeam();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Added ${coach.fullName} as team coach.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add coach: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            Gap(24.h),
            _buildSectionHeader('Current Coaches'),
            Gap(12.h),
            if (coaches.isEmpty)
              _buildGlassPanel(
                child: Text(
                  'No coaches linked yet.',
                  style: TextStyles.font14White500Weight
                      .copyWith(color: Colors.white70),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: coaches.length,
                  itemBuilder: (context, index) {
                    final coach = coaches[index];
                    return _buildMemberManagementCard(coach);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- Tournaments Tab ----------------
  Widget _buildTournamentsTab() {
    return _wrapReadOnlyOverlay(
      message: 'Tournaments are view-only for non-admin users.',
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Link Tournament (Display only)'),
            Gap(12.h),
            _TournamentSearchBox(
              isDisabled: _isReadOnly,
              onPick: (tournament) async {
                try {
                  final entry = TeamTournamentEntry(
                    id: _uuid.v4(),
                    tournamentName: tournament.name,
                    status: tournament.status.displayName,
                    stage: 'Linked',
                    startDate: tournament.startDate,
                    tournamentId: tournament.id,
                    logoUrl: tournament.imageUrl,
                  );
                  await _teamService.upsertTournamentEntry(_team!.id, entry);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Linked tournament "${tournament.name}" to team profile.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to link tournament: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            Gap(24.h),
            _buildSectionHeader('Team Tournaments'),
            Gap(12.h),
            Expanded(
              child: StreamBuilder<List<TeamTournamentEntry>>(
                stream: _teamService.watchTeamTournaments(_team!.id),
                builder: (context, snapshot) {
                  final entries = snapshot.data ?? const <TeamTournamentEntry>[];
                  if (entries.isEmpty) {
                    return _buildGlassPanel(
                      child: Text(
                        'No tournaments linked yet.',
                        style: TextStyles.font14White500Weight
                            .copyWith(color: Colors.white70),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => Gap(8.h),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _buildGlassPanel(
                        child: ListTile(
                          leading: entry.logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    entry.logoUrl!,
                                    width: 36.w,
                                    height: 36.w,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.emoji_events,
                                  color: Colors.amber),
                          title: Text(
                            entry.tournamentName,
                            style: TextStyles.font14White600Weight,
                          ),
                          subtitle: Text(
                            entry.startDate != null
                                ? _dateFormat.format(entry.startDate!)
                                : 'Linked',
                            style: TextStyles.font12White500Weight
                                .copyWith(color: Colors.white70),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Search Widgets ----------------
  // Lightweight inline search components to keep file self-contained
  // Coach search box
  Widget _CoachSearchBox({
    required bool isDisabled,
    required void Function(CoachProfile coach) onPick,
  }) {
    final controller = TextEditingController();
    List<CoachProfile> results = [];
    bool searching = false;

    Future<void> _search(String q) async {
      if (q.isEmpty) {
        setState(() {});
        return;
      }
      searching = true;
      setState(() {});
      try {
        results = await _coachService.searchCoachesByName(q, limit: 20);
      } catch (_) {
        results = [];
      } finally {
        searching = false;
        if (mounted) setState(() {});
      }
    }

    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            enabled: !isDisabled,
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Search coaches...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => _search(v.trim()),
          ),
          if (searching) ...[
            Gap(8.h),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (results.isNotEmpty) ...[
            Gap(8.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 240.h),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final coach = results[index];
                  final sports = coach.specializationSports.join(', ');
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: coach.profilePictureUrl != null
                          ? NetworkImage(coach.profilePictureUrl!)
                          : null,
                      child: coach.profilePictureUrl == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    title: Text(coach.fullName,
                        style: TextStyles.font14White600Weight),
                    subtitle: Text(
                      sports.isEmpty ? 'Coach' : sports,
                      style: TextStyles.font12White500Weight
                          .copyWith(color: Colors.white70),
                    ),
                    trailing: TextButton(
                      onPressed: isDisabled ? null : () => onPick(coach),
                      child: const Text('Add'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Tournament search box
  Widget _TournamentSearchBox({
    required bool isDisabled,
    required void Function(Tournament tournament) onPick,
  }) {
    final controller = TextEditingController();
    List<Tournament> results = [];
    bool searching = false;

    Future<void> _search(String q) async {
      if (q.isEmpty) {
        setState(() {});
        return;
      }
      searching = true;
      setState(() {});
      try {
        results = await _tournamentService.searchTournaments(q);
      } catch (_) {
        results = [];
      } finally {
        searching = false;
        if (mounted) setState(() {});
      }
    }

    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            enabled: !isDisabled,
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Search tournaments...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => _search(v.trim()),
          ),
          if (searching) ...[
            Gap(8.h),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (results.isNotEmpty) ...[
            Gap(8.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 240.h),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final t = results[index];
                  return ListTile(
                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
                    title:
                        Text(t.name, style: TextStyles.font14White600Weight),
                    subtitle: Text(
                      t.location ?? 'Online / TBA',
                      style: TextStyles.font12White500Weight
                          .copyWith(color: Colors.white70),
                    ),
                    trailing: TextButton(
                      onPressed: isDisabled ? null : () => onPick(t),
                      child: const Text('Add'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildMembersTab() {
    final members = _team?.members ?? [];

    final listView = ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberManagementCard(member);
      },
    );
    return _wrapReadOnlyOverlay(
      child: listView,
      message: 'Members are view-only for non-admin users.',
    );
  }

  Widget _buildJoinRequestsTab() {
    return StreamBuilder<List<TeamJoinRequest>>(
      stream: _teamService.getTeamJoinRequests(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _wrapReadOnlyOverlay(
            child: const Center(child: CircularProgressIndicator()),
            message:
                'Join requests are view-only until a team admin signs in.',
          );
        }

        if (snapshot.hasError) {
          return _wrapReadOnlyOverlay(
            child: Center(
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
            ),
            message:
                'Join requests are view-only until a team admin signs in.',
          );
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _wrapReadOnlyOverlay(
            child: Center(
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
            ),
            message:
                'Join requests are view-only until a team admin signs in.',
          );
        }

        final listView = ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildJoinRequestCard(request);
          },
        );

        return _wrapReadOnlyOverlay(
          child: listView,
          message:
              'Join requests are view-only until a team admin signs in.',
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
    return _buildGlassPanel(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.r,
            backgroundImage: member.profileImageUrl != null
                ? NetworkImage(member.profileImageUrl!)
                : null,
            backgroundColor:
                PublicProfileTheme.panelAccentColor.withOpacity(0.15),
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
                  style:
                      TextStyles.font16White600Weight.copyWith(height: 1.2),
                ),
                Gap(4.h),
                Text(
                  member.role.displayName,
                  style: TextStyles.font14White500Weight
                      .copyWith(color: Colors.white70),
                ),
                Gap(4.h),
                Text(
                  'Joined ${_formatDate(member.joinedAt)}',
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !_isReadOnly,
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
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRequestCard(TeamJoinRequest request) {
    return _buildGlassPanel(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor:
                    PublicProfileTheme.panelAccentColor.withOpacity(0.25),
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
                      style: TextStyles.font16White600Weight,
                    ),
                    Gap(4.h),
                    Text(
                      'Requested ${_formatDate(request.createdAt)}',
                      style: TextStyles.font12White500Weight
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Pending',
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
          if (request.message != null && request.message!.isNotEmpty) ...[
            Gap(12.h),
            Text(
              request.message!,
              style: TextStyles.font14White500Weight
                  .copyWith(color: Colors.white70),
            ),
          ],
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isReadOnly
                      ? null
                      : () => _handleJoinRequest(request.id, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.success.withOpacity(0.2),
                    foregroundColor: ColorsManager.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: const Text('Approve'),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isReadOnly
                      ? null
                      : () => _handleJoinRequest(request.id, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.error.withOpacity(0.15),
                    foregroundColor: ColorsManager.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
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
    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Details',
            style: TextStyles.font16White600Weight,
          ),
          Gap(16.h),
          _buildInfoRow('Team Name', _team?.name ?? ''),
          _buildInfoRow('Sport', _team?.sportType.displayName ?? ''),
          _buildInfoRow('Members',
              '${_team?.members.length ?? 0}/${_team?.maxMembers ?? 0}'),
          _buildInfoRow(
              'Visibility', _team?.isPublic == true ? 'Public' : 'Private'),
          _buildInfoRow('Created', _formatDate(_team?.createdAt)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return _buildGlassPanel(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.visibility, color: Colors.white70),
            title: Text(
              'Team Visibility',
              style: TextStyles.font14White600Weight,
            ),
            subtitle: Text(
              _team?.isPublic == true ? 'Public' : 'Private',
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white60),
            ),
            trailing: Switch(
              activeColor: ColorsManager.mainBlue,
              value: _team?.isPublic ?? true,
              onChanged:
                  _isReadOnly ? null : (value) => _updateTeamVisibility(value),
            ),
          ),
          Divider(color: Colors.white12, height: 1.h),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white70),
            title: Text(
              'Max Members',
              style: TextStyles.font14White600Weight,
            ),
            subtitle: Text(
              '${_team?.maxMembers ?? 0} members',
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white60),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
            onTap: _isReadOnly ? null : _updateMaxMembers,
          ),
          Divider(color: Colors.white12, height: 1.h),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white70),
            title: Text(
              'Edit Team Info',
              style: TextStyles.font14White600Weight,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
            onTap: _isReadOnly ? null : _editTeamInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger Zone',
            style: TextStyles.font16White600Weight
                .copyWith(color: Colors.redAccent),
          ),
          Gap(16.h),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: Text(
              'Delete Team',
              style: TextStyles.font14White600Weight
                  .copyWith(color: Colors.redAccent),
            ),
            subtitle: Text(
              'This action cannot be undone',
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white60),
            ),
            trailing: OutlinedButton(
              onPressed: _isReadOnly ? null : _deleteTeam,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Statistics',
            style: TextStyles.font16White600Weight,
          ),
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    'Total Members', '${_team?.members.length ?? 0}'),
              ),
              Expanded(
                child: _buildStatItem(
                    'Active Members', '${_team?.activeMembersCount ?? 0}'),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Tournaments',
                    '${_team?.tournamentsParticipated.length ?? 0}'),
              ),
              Expanded(
                child: _buildStatItem(
                    'Venues Played', '${_team?.venuesPlayed.length ?? 0}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberActivityCard() {
    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyles.font16White600Weight,
          ),
          Gap(16.h),
          Text(
            'Activity tracking coming soon...',
            style: TextStyles.font14White500Weight
                .copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
    );
  }

  Widget _wrapReadOnlyOverlay({
    required Widget child,
    required String message,
  }) {
    if (!_isReadOnly) return child;

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: 64.h),
            child: child,
          ),
        ),
        Positioned(
          left: 16.w,
          right: 16.w,
          top: 8.h,
          child: _buildReadOnlyBanner(message),
        ),
      ],
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 20,
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
            padding: padding ?? EdgeInsets.all(16.w),
            decoration: PublicProfileTheme.glassPanelDecoration(
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyBanner(String message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility,
            color: Colors.white,
            size: 16.sp,
          ),
          Gap(8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyles.font12White500Weight,
            ),
          ),
        ],
      ),
    );
  }

  bool _requireEditPermission({String? message}) {
    if (!_isReadOnly) return true;
    _showReadOnlySnack(
      message ?? 'Only team admins can perform this action.',
    );
    return false;
  }

  void _showReadOnlySnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
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
              style: TextStyles.font14White500Weight
                  .copyWith(color: Colors.white60),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.font14White600Weight,
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
          style: TextStyles.font20DarkBlue600Weight
              .copyWith(color: Colors.white),
        ),
        Text(
          label,
          style:
              TextStyles.font12White500Weight.copyWith(color: Colors.white60),
        ),
      ],
    );
  }

  void _handleMemberAction(String action, TeamMember member) {
    if (action != 'view_profile' &&
        !_requireEditPermission(message: 'Only admins can manage members.')) {
      return;
    }

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
    if (!_requireEditPermission(message: 'Only admins can change roles.')) {
      return;
    }
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
    if (!_requireEditPermission(message: 'Only admins can remove members.')) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Are you sure you want to remove ${member.userName} from the team?'),
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
    if (!_requireEditPermission(message: 'Only admins can change roles.')) {
      return;
    }
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
            content: Text(
                '${member.userName} role changed to ${newRole.displayName}'),
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
    if (!_requireEditPermission(message: 'Only admins can remove members.')) {
      return;
    }
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
    if (!_requireEditPermission(message: 'Only admins can manage requests.')) {
      return;
    }
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
    if (!_requireEditPermission(
        message: 'Only admins can update team visibility.')) {
      return;
    }
    // TODO: Implement team visibility update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team visibility update coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _updateMaxMembers() {
    if (!_requireEditPermission(
        message: 'Only admins can update maximum members.')) {
      return;
    }
    // TODO: Implement max members update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Max members update coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editTeamInfo() {
    if (!_requireEditPermission(message: 'Only admins can edit team info.')) {
      return;
    }
    // TODO: Implement team info editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team info editing coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteTeam() {
    if (!_requireEditPermission(message: 'Only team owners can delete.')) {
      return;
    }
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
