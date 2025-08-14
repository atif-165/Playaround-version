import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';


import '../models/tournament_model.dart';

import '../widgets/tournament_teams_list.dart';
import 'tournament_team_registration_screen.dart';
import 'match_scheduling_screen.dart';
import 'score_update_screen.dart';
import 'winner_declaration_screen.dart';
import 'tournament_management_dashboard.dart';

/// Screen displaying detailed tournament information
class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> with TickerProviderStateMixin {

  bool _isRegistering = false;

  // Tab controller for different sections
  late TabController _tabController;

  // User profile for checking permissions
  UserProfile? _currentUserProfile;

  // Tournament data
  List<TournamentMatch> _pastMatches = [];
  List<TournamentMatch> _todayMatches = [];
  List<TournamentMatch> _futureMatches = [];
  Map<String, int> _teamStandings = {};

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

  void _loadTournamentData() {
    // Separate matches by date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _pastMatches = widget.tournament.matches.where((match) {
      final matchDate = DateTime(match.scheduledDate.year, match.scheduledDate.month, match.scheduledDate.day);
      return matchDate.isBefore(today);
    }).toList();

    _todayMatches = widget.tournament.matches.where((match) {
      final matchDate = DateTime(match.scheduledDate.year, match.scheduledDate.month, match.scheduledDate.day);
      return matchDate.isAtSameMomentAs(today);
    }).toList();

    _futureMatches = widget.tournament.matches.where((match) {
      final matchDate = DateTime(match.scheduledDate.year, match.scheduledDate.month, match.scheduledDate.day);
      return matchDate.isAfter(today);
    }).toList();

    // Load team standings
    _teamStandings = Map.from(widget.tournament.teamPoints);
  }

  bool get _isOwner => _currentUserProfile?.uid == widget.tournament.organizerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          widget.tournament.name,
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorsManager.textPrimary),
        actions: [
          if (_isOwner) ...[
            IconButton(
              onPressed: _showManagementOptions,
              icon: Icon(
                Icons.settings,
                color: ColorsManager.textPrimary,
              ),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.primary,
          unselectedLabelColor: ColorsManager.textSecondary,
          indicatorColor: ColorsManager.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Matches'),
            Tab(text: 'Standings'),
            Tab(text: 'Teams'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMatchesTab(),
          _buildStandingsTab(),
          _buildTeamsTab(),
        ],
      ),
      floatingActionButton: _buildJoinButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTournamentHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tournament.name,
                      style: TextStyles.font20DarkBlueBold,
                    ),
                    Gap(4.h),
                    Text(
                      widget.tournament.sportType.displayName,
                      style: TextStyles.font14MainBlue500Weight,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          Gap(12.h),
          Text(
            widget.tournament.description,
            style: TextStyles.font14Grey400Weight,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
      ),
      child: Text(
        widget.tournament.status.displayName,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.tournament.status) {
      case TournamentStatus.registrationOpen:
        return Colors.green;
      case TournamentStatus.registrationClosed:
        return Colors.orange;
      case TournamentStatus.ongoing:
      case TournamentStatus.inProgress:
        return ColorsManager.mainBlue;
      case TournamentStatus.completed:
        return Colors.purple;
      case TournamentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTournamentInfo() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Details',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(12.h),
          _buildInfoRow(
            icon: Icons.emoji_events,
            label: 'Format',
            value: widget.tournament.format.displayName,
          ),
          Gap(8.h),
          _buildInfoRow(
            icon: Icons.groups,
            label: 'Teams',
            value: '${widget.tournament.currentTeamsCount}/${widget.tournament.maxTeams}',
          ),
          Gap(8.h),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Start Date',
            value: DateFormat('MMM dd, yyyy • hh:mm a').format(widget.tournament.startDate),
          ),
          Gap(8.h),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Registration Deadline',
            value: DateFormat('MMM dd, yyyy').format(widget.tournament.registrationEndDate),
          ),
          Gap(8.h),
          _buildInfoRow(
            icon: Icons.person,
            label: 'Organizer',
            value: widget.tournament.organizerName,
          ),
        ],
      ),
    );
  }

  Widget _buildVenueInfo() {
    if (widget.tournament.venueId == null && widget.tournament.location == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Venue Information',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(12.h),
          if (widget.tournament.venueName != null)
            _buildInfoRow(
              icon: Icons.location_city,
              label: 'Venue',
              value: widget.tournament.venueName!,
            ),
          if (widget.tournament.location != null) ...[
            if (widget.tournament.venueName != null) Gap(8.h),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: widget.tournament.location!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    if (widget.tournament.rules.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rules & Regulations',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(12.h),
          ...widget.tournament.rules.asMap().entries.map((entry) =>
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}. ',
                    style: TextStyles.font14DarkBlue600Weight,
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyles.font14Grey400Weight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: ColorsManager.mainBlue,
        ),
        Gap(8.w),
        Text(
          '$label: ',
          style: TextStyles.font12DarkBlue600Weight,
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.font12Grey400Weight,
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton() {
    if (widget.tournament.status != TournamentStatus.registrationOpen) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ElevatedButton(
        onPressed: _isRegistering ? null : _navigateToTeamRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 4,
        ),
        child: _isRegistering
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add,
                    size: 20.sp,
                  ),
                  Gap(8.w),
                  Text(
                    'Register Team',
                    style: TextStyles.font16White600Weight,
                  ),
                ],
              ),
      ),
    );
  }

  void _navigateToTeamRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentTeamRegistrationScreen(
          tournament: widget.tournament,
        ),
      ),
    );
  }

  // ============ TAB BUILDERS ============

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTournamentHeader(),
          Gap(16.h),
          _buildTournamentInfo(),
          Gap(16.h),
          _buildVenueInfo(),
          Gap(16.h),
          _buildRulesSection(),
          Gap(100.h), // Space for floating action button
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
          if (_todayMatches.isNotEmpty) ...[
            _buildMatchSection('Today\'s Matches', _todayMatches, ColorsManager.primary),
            Gap(24.h),
          ],
          if (_futureMatches.isNotEmpty) ...[
            _buildMatchSection('Upcoming Matches', _futureMatches, ColorsManager.secondary),
            Gap(24.h),
          ],
          if (_pastMatches.isNotEmpty) ...[
            _buildMatchSection('Past Matches', _pastMatches, ColorsManager.textSecondary),
            Gap(24.h),
          ],
          if (_todayMatches.isEmpty && _futureMatches.isEmpty && _pastMatches.isEmpty)
            _buildEmptyState('No matches scheduled yet', Icons.sports_cricket),
          Gap(100.h),
        ],
      ),
    );
  }

  Widget _buildStandingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Standings',
            style: TextStyles.font20DarkBlueBold.copyWith(
              color: ColorsManager.textPrimary,
            ),
          ),
          Gap(16.h),
          if (_teamStandings.isNotEmpty)
            _buildStandingsTable()
          else
            _buildEmptyState('No standings available yet', Icons.leaderboard),
          Gap(100.h),
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
              Text(
                'Registered Teams',
                style: TextStyles.font20DarkBlueBold.copyWith(
                  color: ColorsManager.textPrimary,
                ),
              ),
              Text(
                '${widget.tournament.currentTeamsCount}/${widget.tournament.maxTeams}',
                style: TextStyles.font16DarkBlueBold.copyWith(
                  color: ColorsManager.primary,
                ),
              ),
            ],
          ),
          Gap(16.h),
          TournamentTeamsList(tournamentId: widget.tournament.id),
          Gap(100.h),
        ],
      ),
    );
  }

  // ============ HELPER METHODS ============

  Widget _buildMatchSection(String title, List<TournamentMatch> matches, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
          ],
        ),
        Gap(12.h),
        ...matches.map((match) => _buildMatchCard(match)).toList(),
      ],
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
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
              Text(
                DateFormat('MMM dd, HH:mm').format(match.scheduledDate),
                style: TextStyles.font12Grey400Weight.copyWith(
                  color: ColorsManager.textSecondary,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.team1Name,
                  style: TextStyles.font16DarkBlueBold.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
              ),
              if (match.team1Score != null)
                Text(
                  match.team1Score.toString(),
                  style: TextStyles.font16DarkBlueBold.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
            ],
          ),
          Gap(4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.team2Name,
                  style: TextStyles.font16DarkBlueBold.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
              ),
              if (match.team2Score != null)
                Text(
                  match.team2Score.toString(),
                  style: TextStyles.font16DarkBlueBold.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
            ],
          ),
          if (match.winnerTeamName != null) ...[
            Gap(8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ColorsManager.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Winner: ${match.winnerTeamName}',
                style: TextStyles.font12Grey400Weight.copyWith(
                  color: ColorsManager.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandingsTable() {
    final sortedTeams = _teamStandings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40.w,
                  child: Text(
                    'Pos',
                    style: TextStyles.font14DarkBlueMedium.copyWith(
                      color: ColorsManager.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Team',
                    style: TextStyles.font14DarkBlueMedium.copyWith(
                      color: ColorsManager.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60.w,
                  child: Text(
                    'Points',
                    style: TextStyles.font14DarkBlueMedium.copyWith(
                      color: ColorsManager.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ...sortedTeams.asMap().entries.map((entry) {
            final index = entry.key;
            final teamEntry = entry.value;
            final isWinner = index == 0 && widget.tournament.winnerTeamId == teamEntry.key;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ColorsManager.dividerColor,
                    width: index < sortedTeams.length - 1 ? 1 : 0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40.w,
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyles.font14DarkBlueMedium.copyWith(
                            color: ColorsManager.textPrimary,
                          ),
                        ),
                        if (isWinner) ...[
                          Gap(4.w),
                          Icon(
                            Icons.emoji_events,
                            color: ColorsManager.warning,
                            size: 16.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      teamEntry.key, // This should be team name, but we only have team ID
                      style: TextStyles.font14DarkBlueMedium.copyWith(
                        color: ColorsManager.textPrimary,
                        fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60.w,
                    child: Text(
                      teamEntry.value.toString(),
                      style: TextStyles.font14DarkBlueMedium.copyWith(
                        color: ColorsManager.textPrimary,
                        fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
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
              message,
              style: TextStyles.font16DarkBlueBold.copyWith(
                color: ColorsManager.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showManagementOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsManager.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tournament Management',
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(24.h),
            _buildManagementOption(
              icon: Icons.schedule,
              title: 'Schedule Matches',
              subtitle: 'Create and manage match schedules',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchSchedulingScreen(
                      tournament: widget.tournament,
                    ),
                  ),
                );
              },
            ),
            _buildManagementOption(
              icon: Icons.scoreboard,
              title: 'Update Scores',
              subtitle: 'Update match results and scores',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScoreUpdateScreen(
                      tournament: widget.tournament,
                    ),
                  ),
                );
              },
            ),
            _buildManagementOption(
              icon: Icons.emoji_events,
              title: 'Declare Winner',
              subtitle: 'Declare tournament winner',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WinnerDeclarationScreen(
                      tournament: widget.tournament,
                    ),
                  ),
                );
              },
            ),
            _buildManagementOption(
              icon: Icons.dashboard,
              title: 'Full Management Dashboard',
              subtitle: 'Complete tournament management interface',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentManagementDashboard(
                      tournament: widget.tournament,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
      ),
      title: Text(
        title,
        style: TextStyles.font16DarkBlueBold.copyWith(
          color: ColorsManager.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyles.font14Grey400Weight.copyWith(
          color: ColorsManager.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }
}
