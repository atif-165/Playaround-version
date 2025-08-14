import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../helpers/extensions.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';
import 'match_scheduling_screen.dart';
import 'score_update_screen.dart';
import 'winner_declaration_screen.dart';

/// Comprehensive dashboard for tournament management
class TournamentManagementDashboard extends StatefulWidget {
  final Tournament tournament;

  const TournamentManagementDashboard({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentManagementDashboard> createState() => _TournamentManagementDashboardState();
}

class _TournamentManagementDashboardState extends State<TournamentManagementDashboard> with TickerProviderStateMixin {
  final _tournamentService = TournamentService();
  late TabController _tabController;

  // State
  bool _isLoading = false;
  UserProfile? _currentUserProfile;
  List<TournamentTeamRegistration> _pendingRegistrations = [];
  List<TournamentTeamRegistration> _approvedTeams = [];
  List<TournamentMatch> _matches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserProfile();
    _loadTournamentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
      });
    }
  }

  Future<void> _loadTournamentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load pending registrations
      final pendingRegistrations = await _tournamentService.getTournamentTeamRegistrations(
        tournamentId: widget.tournament.id,
        status: TeamRegistrationStatus.pending,
      );

      // Load approved teams
      final approvedTeams = await _tournamentService.getTournamentTeamRegistrations(
        tournamentId: widget.tournament.id,
        status: TeamRegistrationStatus.approved,
      );

      setState(() {
        _pendingRegistrations = pendingRegistrations;
        _approvedTeams = approvedTeams;
        _matches = widget.tournament.matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        context.showSnackBar('Failed to load tournament data: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is tournament owner
    if (_currentUserProfile?.uid != widget.tournament.organizerId) {
      return _buildUnauthorizedScreen();
    }

    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Manage Tournament',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorsManager.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.primary,
          unselectedLabelColor: ColorsManager.textSecondary,
          indicatorColor: ColorsManager.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_actions, size: 16),
                  Gap(4.w),
                  const Text('Requests'),
                  if (_pendingRegistrations.isNotEmpty) ...[
                    Gap(4.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: ColorsManager.warning,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${_pendingRegistrations.length}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Teams'),
            const Tab(text: 'Matches'),
            const Tab(text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CustomProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildTeamsTab(),
                _buildMatchesTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Access Denied',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorsManager.textPrimary),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64.sp,
                color: ColorsManager.textSecondary,
              ),
              Gap(16.h),
              Text(
                'Access Denied',
                style: TextStyles.font20DarkBlueBold.copyWith(
                  color: ColorsManager.textPrimary,
                ),
              ),
              Gap(8.h),
              Text(
                'Only the tournament organizer can access this management dashboard.',
                style: TextStyles.font14Grey400Weight.copyWith(
                  color: ColorsManager.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(24.h),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ TAB BUILDERS ============

  Widget _buildRequestsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Pending Registrations',
            _pendingRegistrations.length,
            ColorsManager.warning,
          ),
          Gap(16.h),
          if (_pendingRegistrations.isEmpty)
            _buildEmptyState(
              'No pending registrations',
              Icons.pending_actions_outlined,
              'All team registration requests will appear here',
            )
          else
            ..._pendingRegistrations.map((registration) => 
              _buildRegistrationCard(registration)
            ).toList(),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                'Registered Teams',
                _approvedTeams.length,
                ColorsManager.success,
              ),
              Text(
                '${_approvedTeams.length}/${widget.tournament.maxTeams}',
                style: TextStyles.font14DarkBlueMedium.copyWith(
                  color: ColorsManager.primary,
                ),
              ),
            ],
          ),
          Gap(16.h),
          if (_approvedTeams.isEmpty)
            _buildEmptyState(
              'No teams registered yet',
              Icons.groups_outlined,
              'Approved teams will appear here',
            )
          else
            ..._approvedTeams.map((team) => 
              _buildTeamCard(team)
            ).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                'Tournament Matches',
                _matches.length,
                ColorsManager.primary,
              ),
              ElevatedButton.icon(
                onPressed: _navigateToMatchScheduling,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
              ),
            ],
          ),
          Gap(16.h),
          if (_matches.isEmpty)
            _buildEmptyState(
              'No matches scheduled',
              Icons.sports_cricket_outlined,
              'Use the Schedule button to create matches',
            )
          else
            ..._matches.map((match) => 
              _buildMatchCard(match)
            ).toList(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Tournament Settings',
            0,
            ColorsManager.primary,
          ),
          Gap(16.h),
          _buildSettingCard(
            icon: Icons.edit,
            title: 'Edit Tournament',
            subtitle: 'Update tournament details, rules, and settings',
            onTap: _editTournament,
            enabled: widget.tournament.canBeEdited,
          ),
          _buildSettingCard(
            icon: Icons.emoji_events,
            title: 'Declare Winner',
            subtitle: 'Complete tournament and declare winner',
            onTap: _navigateToWinnerDeclaration,
            enabled: _approvedTeams.length >= 2,
          ),
          _buildSettingCard(
            icon: Icons.delete_outline,
            title: 'Delete Tournament',
            subtitle: 'Permanently delete this tournament',
            onTap: _deleteTournament,
            enabled: widget.tournament.canBeDeleted,
            isDestructive: true,
          ),
          Gap(24.h),
          _buildTournamentStatsWidget(),
        ],
      ),
    );
  }

  // ============ HELPER WIDGETS ============

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 24.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        Gap(8.w),
        Text(
          title,
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        if (count > 0) ...[
          Gap(8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '$count',
              style: TextStyles.font12Grey400Weight.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64.sp,
              color: ColorsManager.textSecondary,
            ),
            Gap(16.h),
            Text(
              title,
              style: TextStyles.font16DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              subtitle,
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(TournamentTeamRegistration registration) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.groups,
                  color: ColorsManager.primary,
                  size: 24.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.teamName,
                      style: TextStyles.font16DarkBlueBold.copyWith(
                        color: ColorsManager.textPrimary,
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      'Captain: ${registration.captainName}',
                      style: TextStyles.font14Grey400Weight.copyWith(
                        color: ColorsManager.textSecondary,
                      ),
                    ),
                    Text(
                      '${registration.memberCount} members • ${DateFormat('MMM dd, HH:mm').format(registration.registrationDate)}',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: ColorsManager.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (registration.qualifyingAnswers.isNotEmpty) ...[
            Gap(12.h),
            Text(
              'Registration Answers:',
              style: TextStyles.font14DarkBlueMedium.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            ...registration.qualifyingAnswers.map((answer) =>
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q: ${answer.question}',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: ColorsManager.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Gap(2.h),
                    Text(
                      'A: ${answer.answer}',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: ColorsManager.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            ).toList(),
          ],
          if (registration.notes != null) ...[
            Gap(8.h),
            Text(
              'Notes: ${registration.notes}',
              style: TextStyles.font12Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRegistration(registration),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectRegistration(registration),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsManager.error,
                    side: BorderSide(color: ColorsManager.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(TournamentTeamRegistration team) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ColorsManager.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.groups,
              color: ColorsManager.success,
              size: 24.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.teamName,
                  style: TextStyles.font16DarkBlueBold.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
                Gap(4.h),
                Text(
                  'Captain: ${team.captainName}',
                  style: TextStyles.font14Grey400Weight.copyWith(
                    color: ColorsManager.textSecondary,
                  ),
                ),
                Text(
                  '${team.memberCount} members',
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: ColorsManager.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: ColorsManager.textSecondary,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, color: ColorsManager.error, size: 16),
                    Gap(8.w),
                    const Text('Remove Team'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'chat',
                child: Row(
                  children: [
                    Icon(Icons.chat, color: ColorsManager.primary, size: 16),
                    Gap(8.w),
                    const Text('Open Group Chat'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'remove':
                  _removeTeam(team);
                  break;
                case 'chat':
                  _openGroupChat();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.round,
                style: TextStyles.font14DarkBlueMedium.copyWith(
                  color: ColorsManager.primary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getMatchStatusColor(match.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  match.status.displayName,
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: _getMatchStatusColor(match.status),
                  ),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Text(
            '${match.team1Name} vs ${match.team2Name}',
            style: TextStyles.font16DarkBlueBold.copyWith(
              color: ColorsManager.textPrimary,
            ),
          ),
          Gap(4.h),
          Text(
            DateFormat('EEEE, MMM dd, yyyy at HH:mm').format(match.scheduledDate),
            style: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
          if (match.team1Score != null && match.team2Score != null) ...[
            Gap(8.h),
            Text(
              'Score: ${match.team1Score} - ${match.team2Score}',
              style: TextStyles.font14DarkBlueMedium.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
          ],
          if (match.winnerTeamName != null) ...[
            Gap(4.h),
            Text(
              'Winner: ${match.winnerTeamName}',
              style: TextStyles.font14DarkBlueMedium.copyWith(
                color: ColorsManager.success,
              ),
            ),
          ],
          Gap(12.h),
          Row(
            children: [
              if (match.status != MatchStatus.completed) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateMatchScore(match),
                    icon: const Icon(Icons.scoreboard, size: 16),
                    label: const Text('Update Score'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                Gap(8.w),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editMatch(match),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsManager.primary,
                    side: BorderSide(color: ColorsManager.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? ColorsManager.error : ColorsManager.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        enabled: enabled,
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(enabled ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: enabled ? color : ColorsManager.textSecondary,
            size: 24.sp,
          ),
        ),
        title: Text(
          title,
          style: TextStyles.font16DarkBlueBold.copyWith(
            color: enabled ? ColorsManager.textPrimary : ColorsManager.textSecondary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        trailing: enabled
            ? Icon(
                Icons.arrow_forward_ios,
                color: ColorsManager.textSecondary,
                size: 16.sp,
              )
            : null,
        onTap: enabled ? onTap : null,
        tileColor: ColorsManager.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: ColorsManager.dividerColor),
        ),
      ),
    );
  }

  // ============ ACTION METHODS ============

  Future<void> _approveRegistration(TournamentTeamRegistration registration) async {
    try {
      await _tournamentService.approveTeamRegistration(
        registrationId: registration.id,
        tournamentId: widget.tournament.id,
      );

      if (mounted) {
        context.showSnackBar('Team approved successfully!');
        _loadTournamentData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to approve team: ${e.toString()}');
      }
    }
  }

  Future<void> _rejectRegistration(TournamentTeamRegistration registration) async {
    // Show reason dialog
    final reason = await _showReasonDialog('Reject Team Registration');
    if (reason == null) return;

    try {
      await _tournamentService.rejectTeamRegistration(
        registrationId: registration.id,
        reason: reason.isEmpty ? null : reason,
      );

      if (mounted) {
        context.showSnackBar('Team registration rejected');
        _loadTournamentData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to reject team: ${e.toString()}');
      }
    }
  }

  Future<void> _removeTeam(TournamentTeamRegistration team) async {
    final reason = await _showReasonDialog('Remove Team from Tournament');
    if (reason == null) return;

    try {
      await _tournamentService.removeTeamFromTournament(
        tournamentId: widget.tournament.id,
        teamId: team.teamId,
        reason: reason.isEmpty ? null : reason,
      );

      if (mounted) {
        context.showSnackBar('Team removed successfully');
        _loadTournamentData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to remove team: ${e.toString()}');
      }
    }
  }

  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsManager.cardBackground,
        title: Text(
          title,
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter reason (optional)',
            hintStyle: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _navigateToMatchScheduling() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchSchedulingScreen(
          tournament: widget.tournament,
        ),
      ),
    ).then((_) => _loadTournamentData());
  }

  void _updateMatchScore(TournamentMatch match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreUpdateScreen(
          tournament: widget.tournament,
        ),
      ),
    ).then((_) => _loadTournamentData());
  }

  void _editMatch(TournamentMatch match) {
    // TODO: Implement match editing
    context.showSnackBar('Match editing coming soon!');
  }

  void _navigateToWinnerDeclaration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WinnerDeclarationScreen(
          tournament: widget.tournament,
        ),
      ),
    ).then((_) => _loadTournamentData());
  }

  void _editTournament() {
    // TODO: Navigate to edit tournament screen
    context.showSnackBar('Tournament editing coming soon!');
  }

  Future<void> _deleteTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsManager.cardBackground,
        title: Text(
          'Delete Tournament',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.error,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this tournament? This action cannot be undone.',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Add delete method to tournament service
        // await _tournamentService.deleteTournament(widget.tournament.id);

        if (mounted) {
          context.showSnackBar('Tournament deleted successfully');
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          context.showSnackBar('Failed to delete tournament: ${e.toString()}');
        }
      }
    }
  }

  void _openGroupChat() {
    if (widget.tournament.groupChatId != null) {
      // TODO: Navigate to group chat
      context.showSnackBar('Opening group chat...');
    } else {
      context.showSnackBar('No group chat available');
    }
  }

  Widget _buildTournamentStatsWidget() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Statistics',
            style: TextStyles.font16DarkBlueBold.copyWith(
              color: ColorsManager.textPrimary,
            ),
          ),
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Teams',
                  '${widget.tournament.currentTeamsCount}/${widget.tournament.maxTeams}',
                  Icons.groups,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Matches',
                  '${_matches.length}',
                  Icons.sports_cricket,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              if (widget.tournament.entryFee != null)
                Expanded(
                  child: _buildStatItem(
                    'Entry Fee',
                    '\$${widget.tournament.entryFee!.toStringAsFixed(0)}',
                    Icons.attach_money,
                  ),
                ),
              if (widget.tournament.winningPrize != null)
                Expanded(
                  child: _buildStatItem(
                    'Prize',
                    '\$${widget.tournament.winningPrize!.toStringAsFixed(0)}',
                    Icons.emoji_events,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
        Gap(4.h),
        Text(
          value,
          style: TextStyles.font16DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getMatchStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return ColorsManager.primary;
      case MatchStatus.inProgress:
        return ColorsManager.warning;
      case MatchStatus.completed:
        return ColorsManager.success;
      case MatchStatus.cancelled:
        return ColorsManager.error;
    }
  }
}
