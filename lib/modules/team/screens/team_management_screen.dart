import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/team_service.dart';
import '../widgets/team_list_widget.dart';
import 'team_creation_screen.dart';
import 'team_profile_screen.dart';

/// Screen for managing user's teams
class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Refresh UI when tab changes
    });
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
      appBar: AppBar(
        title: Text(
          'Team Management',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.darkBlue),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120.h),
          child: Column(
            children: [
              // Search bar (only show on Browse Teams tab)
              if (_tabController.index == 1) _buildSearchBar(),
              TabBar(
                controller: _tabController,
                labelColor: ColorsManager.mainBlue,
                unselectedLabelColor: ColorsManager.gray,
                indicatorColor: ColorsManager.mainBlue,
                tabs: const [
                  Tab(text: 'My Teams'),
                  Tab(text: 'Browse Teams'),
                  Tab(text: 'Join Requests'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyTeamsTab(),
          _buildBrowseTeamsTab(),
          _buildJoinRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "team_management_fab",
        onPressed: _navigateToCreateTeam,
        backgroundColor: ColorsManager.mainBlue,
        child: const Icon(Icons.add, color: Colors.white),
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
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: TeamListWidget(
            teams: teams,
            onTeamTap: _navigateToTeamDetails,
            isLoading: false,
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64.sp,
                  color: ColorsManager.gray,
                ),
                Gap(16.h),
                Text(
                  'No teams found',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  'Try adjusting your search terms',
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (_searchQuery.isNotEmpty || _selectedSportFilter != null)
              _buildActiveFiltersChips(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: TeamListWidget(
                  teams: teams,
                  onTeamTap: _navigateToTeamDetails,
                  onJoinTeam: _sendJoinRequest,
                  showJoinButton: true,
                  isLoading: false,
                ),
              ),
            ),
          ],
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64.sp,
                  color: ColorsManager.gray,
                ),
                Gap(16.h),
                Text(
                  'No join requests',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  'Your team join requests will appear here',
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

  Widget _buildJoinRequestCard(TeamJoinRequest request) {
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
                child: Text(
                  request.teamName,
                  style: TextStyles.font16DarkBlue600Weight,
                ),
              ),
              _buildStatusChip(request.status),
            ],
          ),
          Gap(8.h),
          if (request.message != null && request.message!.isNotEmpty) ...[
            Text(
              'Message: ${request.message}',
              style: TextStyles.font14Blue400Weight,
            ),
            Gap(8.h),
          ],
          Text(
            'Requested on ${_formatDate(request.createdAt)}',
            style: TextStyles.font13Grey400Weight,
          ),
          if (request.responseMessage != null && request.responseMessage!.isNotEmpty) ...[
            Gap(8.h),
            Text(
              'Response: ${request.responseMessage}',
              style: TextStyles.font13Grey400Weight,
            ),
          ],
          if (request.isPending) ...[
            Gap(12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _cancelJoinRequest(request.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
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
        color = Colors.orange;
        break;
      case JoinRequestStatus.approved:
        color = Colors.green;
        break;
      case JoinRequestStatus.rejected:
        color = Colors.red;
        break;
      case JoinRequestStatus.cancelled:
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
          showJoinButton: false, // Don't show join button for teams user can already access
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teams by name...',
                hintStyle: TextStyles.font14Grey400Weight,
                prefixIcon: Icon(
                  Icons.search,
                  color: ColorsManager.gray,
                  size: 20.sp,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: ColorsManager.gray,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: ColorsManager.gray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: ColorsManager.mainBlue),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Gap(8.w),
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: _hasActiveFilters() ? ColorsManager.mainBlue : ColorsManager.gray,
              size: 24.sp,
            ),
          ),
        ],
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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Wrap(
        spacing: 8.w,
        children: activeFilters,
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedSportFilter != null || _selectedLocationFilter != null;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Teams'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sport Type',
              style: TextStyles.font14DarkBlue600Weight,
            ),
            Gap(8.h),
            DropdownButtonFormField<SportType>(
              value: _selectedSportFilter,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              hint: const Text('Select sport'),
              items: SportType.values.map((sport) {
                return DropdownMenuItem(
                  value: sport,
                  child: Text(sport.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSportFilter = value;
                });
              },
            ),
            Gap(16.h),
            Text(
              'Location',
              style: TextStyles.font14DarkBlue600Weight,
            ),
            Gap(8.h),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              onChanged: (value) {
                _selectedLocationFilter = value.isNotEmpty ? value : null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSportFilter = null;
                _selectedLocationFilter = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // Refresh the stream
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
