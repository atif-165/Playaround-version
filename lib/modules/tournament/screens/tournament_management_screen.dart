import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';
import '../widgets/tournament_list_widget.dart';
import 'tournament_detail_screen.dart';
import '../../team/models/models.dart';
import '../../team/services/team_service.dart';

/// Screen for managing tournaments
class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key});

  @override
  State<TournamentManagementScreen> createState() =>
      _TournamentManagementScreenState();
}

class _TournamentManagementScreenState extends State<TournamentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TournamentService _tournamentService = TournamentService();
  final TeamService _teamService = TeamService();

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
      appBar: AppBar(
        title: Text(
          'Tournaments',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.darkBlue),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.mainBlue,
          unselectedLabelColor: ColorsManager.gray,
          indicatorColor: ColorsManager.mainBlue,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My Tournaments'),
            Tab(text: 'Registrations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTournamentsTab(),
          _buildMyTournamentsTab(),
          _buildRegistrationsTab(),
        ],
      ),
    );
  }

  Widget _buildBrowseTournamentsTab() {
    return StreamBuilder<List<Tournament>>(
      stream: _tournamentService.getPublicTournaments(),
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
                  'Error loading tournaments',
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

        final tournaments = snapshot.data ?? [];
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: TournamentListWidget(
            tournaments: tournaments,
            onTournamentTap: _navigateToTournamentDetails,
            onRegisterTournament: _showTeamSelectionDialog,
            showRegisterButton: true,
            isLoading: false,
          ),
        );
      },
    );
  }

  Widget _buildMyTournamentsTab() {
    return StreamBuilder<List<Tournament>>(
      stream: _tournamentService.getUserTournaments(),
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
                  'Error loading tournaments',
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

        final tournaments = snapshot.data ?? [];
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: TournamentListWidget(
            tournaments: tournaments,
            onTournamentTap: _navigateToTournamentDetails,
            isLoading: false,
          ),
        );
      },
    );
  }

  Widget _buildRegistrationsTab() {
    return StreamBuilder<List<TournamentRegistration>>(
      stream: _tournamentService.getUserRegistrations(),
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
                  'Error loading registrations',
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

        final registrations = snapshot.data ?? [];

        if (registrations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.app_registration,
                  size: 64.sp,
                  color: ColorsManager.gray,
                ),
                Gap(16.h),
                Text(
                  'No registrations',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  'Your tournament registrations will appear here',
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: registrations.length,
          itemBuilder: (context, index) {
            final registration = registrations[index];
            return _buildRegistrationCard(registration);
          },
        );
      },
    );
  }

  Widget _buildRegistrationCard(TournamentRegistration registration) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.tournamentName,
                      style: TextStyles.font16DarkBlue600Weight,
                    ),
                    Gap(4.h),
                    Text(
                      'Team: ${registration.teamName}',
                      style: TextStyles.font14Blue400Weight,
                    ),
                  ],
                ),
              ),
              _buildRegistrationStatusChip(registration.status),
            ],
          ),
          Gap(12.h),
          Text(
            'Registered on ${_formatDate(registration.registeredAt)}',
            style: TextStyles.font13Grey400Weight,
          ),
          if (registration.responseMessage != null &&
              registration.responseMessage!.isNotEmpty) ...[
            Gap(8.h),
            Text(
              'Response: ${registration.responseMessage}',
              style: TextStyles.font13Grey400Weight,
            ),
          ],
          if (registration.isPending) ...[
            Gap(12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _withdrawRegistration(registration.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Withdraw Registration',
                  style: TextStyles.font14White500Weight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistrationStatusChip(RegistrationStatus status) {
    Color color;
    switch (status) {
      case RegistrationStatus.pending:
        color = Colors.orange;
        break;
      case RegistrationStatus.approved:
        color = Colors.green;
        break;
      case RegistrationStatus.rejected:
        color = Colors.red;
        break;
      case RegistrationStatus.withdrawn:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        status.displayName,
        style: TextStyles.font12DarkBlue400Weight.copyWith(color: color),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToTournamentDetails(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(tournament: tournament),
      ),
    );
  }

  void _showTeamSelectionDialog(Tournament tournament) async {
    // Get user's teams
    final teams = await _teamService.getUserTeams().first;

    if (teams.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to create or join a team first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Team', style: TextStyles.font18DarkBlue600Weight),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: teams
                .map((team) => ListTile(
                      leading: const Icon(Icons.group,
                          color: ColorsManager.mainBlue),
                      title: Text(team.name,
                          style: TextStyles.font15DarkBlue500Weight),
                      subtitle: Text('${team.activeMembersCount} members',
                          style: TextStyles.font13Grey400Weight),
                      onTap: () {
                        Navigator.pop(context);
                        _registerTeamForTournament(tournament, team);
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyles.font14Blue400Weight),
            ),
          ],
        ),
      );
    }
  }

  void _registerTeamForTournament(Tournament tournament, Team team) async {
    try {
      await _tournamentService.registerTeamForTournament(
        tournamentId: tournament.id,
        teamId: team.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${team.name} registered for ${tournament.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _withdrawRegistration(String registrationId) async {
    try {
      await _tournamentService.withdrawRegistration(registrationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration withdrawn'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to withdraw: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
