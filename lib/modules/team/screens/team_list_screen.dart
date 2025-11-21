import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../cubit/team_cubit.dart';
import '../models/team_model.dart';
import '../widgets/team_card.dart';
import '../widgets/team_filter_sheet.dart';
import 'add_team_screen.dart';
import 'create_dummy_team_screen.dart';
import 'team_profile_screen.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  SportType? _selectedSportFilter;
  String? _selectedCityFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load initial data
    context.read<TeamCubit>().loadTeams();
  }

  Widget _buildHeader(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canPop) _buildBackButton(context),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elite Teams',
                      style: TextStyles.font24WhiteBold,
                    ),
                    Gap(4.h),
                    Text(
                      'Discover high-performing squads, track stats and join the action.',
                      style: TextStyles.font12Grey400Weight,
                    ),
                  ],
                ),
              ),
              Gap(12.w),
              _buildHeaderAction(
                icon: Icons.filter_list_rounded,
                tooltip: 'Filter teams',
                onTap: _showFilterSheet,
              ),
              Gap(10.w),
              _buildHeaderAction(
                icon: Icons.auto_fix_high_rounded,
                tooltip: 'Generate demo team',
                onTap: _navigateToDummyTeam,
                gradient: ColorsManager.successGradient,
              ),
            ],
          ),
          Gap(16.h),
          BlocBuilder<TeamCubit, TeamState>(
            builder: (context, state) {
              final teams = _teamsFromState(state);
              final isLoading =
                  state.maybeWhen(loading: () => true, orElse: () => false);

              if (isLoading) {
                return _buildSummarySkeleton();
              }

              if (teams.isEmpty) {
                return _buildSummarySkeleton(
                  label: 'No teams yet? Create your first squad!',
                );
              }

              return _buildSummaryRow(teams);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w, top: 2.h),
      child: Material(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => Navigator.of(context).maybePop(),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: ColorsManager.onBackground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    LinearGradient gradient = ColorsManager.primaryGradient,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.last.withOpacity(0.35),
                  blurRadius: 12.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: ColorsManager.onPrimary,
              size: 18.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTeamFab() {
    return FloatingActionButton.extended(
      onPressed: _navigateToAddTeam,
      heroTag: 'create-team-fab',
      backgroundColor: ColorsManager.primary,
      foregroundColor: ColorsManager.onPrimary,
      icon: const Icon(Icons.add),
      label: const Text('Create Team'),
    );
  }

  List<TeamModel> _teamsFromState(TeamState state) {
    return state.maybeWhen(
      loaded: (teams) => teams,
      searchResults: (teams) => teams,
      userTeamsLoaded: (teams) => teams,
      orElse: () => const [],
    );
  }

  Widget _buildSummaryRow(List<TeamModel> teams) {
    final totalTeams = teams.length;
    final totalMembers =
        teams.fold<int>(0, (sum, team) => sum + team.memberCount);
    final totalWins = teams.fold<int>(
        0, (sum, team) => sum + (team.stat['matchesWon'] as int? ?? 0));
    final totalMatches = teams.fold<int>(
        0, (sum, team) => sum + (team.stat['matchesPlayed'] as int? ?? 0));
    final winRate = totalMatches > 0 ? (totalWins / totalMatches) * 100 : 0.0;
    final rosterFill = teams.isNotEmpty
        ? teams.fold<double>(
                0,
                (sum, team) =>
                    sum +
                    (team.maxMembers == 0
                        ? 0
                        : team.memberCount / team.maxMembers)) /
            teams.length
        : 0.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: Row(
        key: ValueKey(
          '${totalTeams}_${totalMembers}_${winRate.toStringAsFixed(1)}',
        ),
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.groups_rounded,
              title: 'Active Teams',
              value: '$totalTeams',
              description: 'Curated squads ready to compete',
              color: ColorsManager.primary,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.people_alt_rounded,
              title: 'Rostered Players',
              value: '$totalMembers',
              description: 'Across all visible teams',
              color: ColorsManager.secondary,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.emoji_events_rounded,
              title: 'Win Rate',
              value: '${winRate.toStringAsFixed(1)}%',
              description:
                  'Avg roster utilization ${(rosterFill * 100).toStringAsFixed(0)}%',
              color: ColorsManager.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: ColorsManager.onPrimary,
                  size: 18.sp,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: ColorsManager.onBackground,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            title,
            style: TextStyles.font14White600Weight,
          ),
          Gap(4.h),
          Text(
            description,
            style: TextStyles.font12Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySkeleton({String? label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: ColorsManager.primary,
              size: 20.sp,
            ),
          ),
          Gap(14.w),
          Expanded(
            child: Text(
              label ?? 'Crunching live team insights...',
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          if (label == null)
            SizedBox(
              height: 20.w,
              width: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorsManager.primary,
              ),
            )
          else
            TextButton(
              onPressed: _navigateToAddTeam,
              child: Text(
                'Create',
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      backgroundColor: ColorsManager.background,
      floatingActionButton: _buildCreateTeamFab(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorsManager.primary.withOpacity(0.12),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllTeamsTab(),
                    _buildMyTeamsTab(),
                    _buildNearbyTeamsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Icon(
                Icons.search_rounded,
                color: ColorsManager.primary,
                size: 22.sp,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyles.font14White500Weight,
                cursorColor: ColorsManager.primary,
                decoration: InputDecoration(
                  hintText: 'Search teams, cities or sports...',
                  hintStyle: TextStyles.font14Grey400Weight,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {});
                  _performSearch(value);
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: ColorsManager.textSecondary,
                  size: 20.sp,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  _performSearch('');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: ColorsManager.primaryGradient,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.primary.withOpacity(0.4),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: ColorsManager.onPrimary,
          unselectedLabelColor: ColorsManager.textSecondary,
          labelStyle: TextStyles.font14White600Weight,
          unselectedLabelStyle: TextStyles.font14Grey400Weight,
          onTap: _onTabChanged,
          tabs: const [
            Tab(text: 'All Teams'),
            Tab(text: 'My Teams'),
            Tab(text: 'Nearby'),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTeamsTab() {
    return BlocBuilder<TeamCubit, TeamState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(
            child: Text(
              'Welcome to Teams',
              style: TextStyle(color: Colors.white),
            ),
          ),
          loading: () => const Center(child: CustomProgressIndicator()),
          loaded: (teams) => _buildTeamsList(teams),
          searchResults: (teams) => _buildTeamsList(teams),
          userTeamsLoaded: (teams) => _buildTeamsList(teams),
          teamDetails: (team) => const SizedBox.shrink(),
          teamCreated: (teamId) => const SizedBox.shrink(),
          teamUpdated: () => const SizedBox.shrink(),
          teamDeleted: () => const SizedBox.shrink(),
          playerAdded: () => const SizedBox.shrink(),
          playerRemoved: () => const SizedBox.shrink(),
          error: (message) => Center(
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
                  'Error: $message',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                Gap(16.h),
                ElevatedButton(
                  onPressed: () => context.read<TeamCubit>().loadTeams(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyTeamsTab() {
    return BlocBuilder<TeamCubit, TeamState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(
            child: Text(
              'Loading your teams...',
              style: TextStyle(color: Colors.white),
            ),
          ),
          loading: () => const Center(child: CustomProgressIndicator()),
          userTeamsLoaded: (teams) => _buildTeamsList(teams),
          loaded: (teams) => _buildTeamsList(teams),
          searchResults: (teams) => _buildTeamsList(teams),
          teamDetails: (team) => const SizedBox.shrink(),
          teamCreated: (teamId) => const SizedBox.shrink(),
          teamUpdated: () => const SizedBox.shrink(),
          teamDeleted: () => const SizedBox.shrink(),
          playerAdded: () => const SizedBox.shrink(),
          playerRemoved: () => const SizedBox.shrink(),
          error: (message) => Center(
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
                  'Error: $message',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                Gap(16.h),
                ElevatedButton(
                  onPressed: _loadMyTeams,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNearbyTeamsTab() {
    return BlocBuilder<TeamCubit, TeamState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(
            child: Text(
              'Loading nearby teams...',
              style: TextStyle(color: Colors.white),
            ),
          ),
          loading: () => const Center(child: CustomProgressIndicator()),
          loaded: (teams) => _buildTeamsList(teams),
          searchResults: (teams) => _buildTeamsList(teams),
          userTeamsLoaded: (teams) => _buildTeamsList(teams),
          teamDetails: (team) => const SizedBox.shrink(),
          teamCreated: (teamId) => const SizedBox.shrink(),
          teamUpdated: () => const SizedBox.shrink(),
          teamDeleted: () => const SizedBox.shrink(),
          playerAdded: () => const SizedBox.shrink(),
          playerRemoved: () => const SizedBox.shrink(),
          error: (message) => Center(
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
                  'Error: $message',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                Gap(16.h),
                ElevatedButton(
                  onPressed: _loadNearbyTeams,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsList(List<TeamModel> teams) {
    if (teams.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorsManager.primary.withOpacity(0.25),
                ColorsManager.primary.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.primary.withOpacity(0.35),
                blurRadius: 24.r,
                offset: Offset(0, 12.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_motion_rounded,
                size: 48.sp,
                color: ColorsManager.onPrimary,
              ),
              Gap(16.h),
              Text(
                'No teams match the filters',
                style: TextStyles.font20DarkBlue600Weight
                    .copyWith(color: ColorsManager.onPrimary),
                textAlign: TextAlign.center,
              ),
              Gap(8.h),
              Text(
                'Create a new squad or tweak the filters to discover more teams.',
                style: TextStyles.font14White500Weight
                    .copyWith(color: ColorsManager.onPrimary.withOpacity(0.85)),
                textAlign: TextAlign.center,
              ),
              Gap(20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _applyFilters();
                    },
                    child: Text(
                      'Reset filters',
                      style: TextStyle(
                        color: ColorsManager.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Gap(16.w),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.onPrimary,
                      foregroundColor: ColorsManager.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 26.w,
                        vertical: 12.h,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Team'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TeamCubit>().loadTeams();
      },
      color: ColorsManager.primary,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
        physics: const BouncingScrollPhysics(),
        itemCount: teams.length,
        separatorBuilder: (_, __) => Gap(18.h),
        itemBuilder: (context, index) {
          final team = teams[index];
          return TeamCard(
            team: team,
            onTap: () => _navigateToTeamDetail(team),
          );
        },
      ),
    );
  }

  void _onTabChanged(int index) {
    switch (index) {
      case 0:
        context.read<TeamCubit>().loadTeams(
              sportType: _selectedSportFilter,
              city: _selectedCityFilter,
            );
        break;
      case 1:
        _loadMyTeams();
        break;
      case 2:
        _loadNearbyTeams();
        break;
    }
  }

  void _loadMyTeams() {
    // Get current user ID from auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<TeamCubit>().loadUserTeams(user.uid);
    } else {
      // Show login prompt or handle unauthenticated state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view your teams'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _loadNearbyTeams() {
    // TODO: Implement location-based team loading
    context.read<TeamCubit>().loadTeams(
          sportType: _selectedSportFilter,
          city: _selectedCityFilter,
        );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TeamFilterSheet(
        currentFilters: {
          'sports': _selectedSportFilter != null
              ? [_selectedSportFilter!.displayName]
              : [],
          'city': _selectedCityFilter,
        },
        onFiltersApplied: (filters) {
          setState(() {
            // Extract sport from filters
            final sportNames = filters['sports'] as List<String>?;
            if (sportNames != null && sportNames.isNotEmpty) {
              // Find the SportType enum that matches the display name
              try {
                _selectedSportFilter = SportType.values.firstWhere(
                  (sport) => sport.displayName == sportNames.first,
                );
              } catch (e) {
                _selectedSportFilter = null;
              }
            } else {
              _selectedSportFilter = null;
            }
            _selectedCityFilter = filters['city'] as String?;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      context.read<TeamCubit>().loadTeams(
            sportType: _selectedSportFilter,
            city: _selectedCityFilter,
          );
    } else {
      context.read<TeamCubit>().searchTeams(trimmed);
    }
  }

  void _applyFilters() {
    context.read<TeamCubit>().loadTeams(
          sportType: _selectedSportFilter,
          city: _selectedCityFilter,
        );
  }

  void _navigateToAddTeam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTeamScreen(),
      ),
    );
  }

  void _navigateToTeamDetail(TeamModel team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamProfileScreen(team: team),
      ),
    );
  }

  void _navigateToDummyTeam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateDummyTeamScreen(),
      ),
    );
  }
}
