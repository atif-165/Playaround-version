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
          style: TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'My Teams'),
              Tab(text: 'Browse Teams'),
              Tab(text: 'Join Requests'),
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
            _buildSearchBar(),
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
                          selectedColor: ColorsManager.primary.withValues(alpha: 0.2),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      ),
                      onChanged: (value) {
                        _selectedLocationFilter = value.isNotEmpty ? value : null;
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
