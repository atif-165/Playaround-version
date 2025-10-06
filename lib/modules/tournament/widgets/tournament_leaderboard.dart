import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';
import '../models/tournament_team_registration.dart';

/// Tournament leaderboard widget showing team standings
class TournamentLeaderboard extends StatefulWidget {
  final Tournament tournament;
  final List<TournamentTeamRegistration> teams;
  final Map<String, int> teamPoints;
  final Function(String)? onTeamTap;

  const TournamentLeaderboard({
    super.key,
    required this.tournament,
    required this.teams,
    required this.teamPoints,
    this.onTeamTap,
  });

  @override
  State<TournamentLeaderboard> createState() => _TournamentLeaderboardState();
}

class _TournamentLeaderboardState extends State<TournamentLeaderboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardSortOption _sortOption = LeaderboardSortOption.points;

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
    final sortedTeams = _getSortedTeams();

    return Column(
      children: [
        _buildHeader(),
        _buildTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboard(sortedTeams),
              _buildStatsView(sortedTeams),
              _buildRecentMatches(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        border: Border(
          bottom: BorderSide(color: ColorsManager.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Leaderboard',
            style: TextStyles.font20DarkBlueBold,
          ),
          const Spacer(),
          PopupMenuButton<LeaderboardSortOption>(
            icon: Icon(
              Icons.sort,
              color: ColorsManager.textSecondary,
            ),
            onSelected: (option) {
              setState(() {
                _sortOption = option;
              });
            },
            itemBuilder: (context) => LeaderboardSortOption.values.map((option) {
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (_sortOption == option) ...[
                      Icon(
                        Icons.check,
                        color: ColorsManager.primary,
                        size: 16.sp,
                      ),
                      Gap(8.w),
                    ],
                    Text(option.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: ColorsManager.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: ColorsManager.primary,
        unselectedLabelColor: ColorsManager.textSecondary,
        indicatorColor: ColorsManager.primary,
        tabs: const [
          Tab(text: 'Standings'),
          Tab(text: 'Stats'),
          Tab(text: 'Recent'),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(List<TournamentTeamRegistration> sortedTeams) {
    if (sortedTeams.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: sortedTeams.length,
      itemBuilder: (context, index) {
        final team = sortedTeams[index];
        final points = widget.teamPoints[team.teamId] ?? 0;
        final position = index + 1;

        return _buildTeamCard(team, position, points);
      },
    );
  }

  Widget _buildTeamCard(TournamentTeamRegistration team, int position, int points) {
    final isTopThree = position <= 3;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Card(
        elevation: isTopThree ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: isTopThree 
              ? BorderSide(color: _getPositionColor(position), width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => widget.onTeamTap?.call(team.teamId),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                _buildPosition(position),
                Gap(16.w),
                _buildTeamInfo(team),
                const Spacer(),
                _buildPoints(points, position),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosition(int position) {
    final isTopThree = position <= 3;
    
    return Container(
      width: 32.w,
      height: 32.h,
      decoration: BoxDecoration(
        color: isTopThree 
            ? _getPositionColor(position)
            : ColorsManager.textSecondary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$position',
          style: TextStyles.font14DarkBlueMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInfo(TournamentTeamRegistration team) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team.teamName,
            style: TextStyles.font16DarkBlueBold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap(4.h),
          Text(
            'Captain: ${team.captainName}',
            style: TextStyles.font12Grey400Weight.copyWith(
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
    );
  }

  Widget _buildPoints(int points, int position) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$points',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: _getPositionColor(position),
          ),
        ),
        Text(
          'points',
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView(List<TournamentTeamRegistration> teams) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildStatsCard('Total Teams', '${teams.length}'),
          _buildStatsCard('Active Teams', '${teams.where((t) => widget.teamPoints[t.teamId] != null).length}'),
          _buildStatsCard('Total Matches', '${widget.tournament.matches.length}'),
          _buildStatsCard('Completed Matches', '${widget.tournament.matches.where((m) => m.status == MatchStatus.completed).length}'),
          Gap(24.h),
          _buildTopPerformers(teams),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyles.font14DarkBlueMedium,
          ),
          Text(
            value,
            style: TextStyles.font16DarkBlueBold.copyWith(
              color: ColorsManager.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(List<TournamentTeamRegistration> teams) {
    final topTeams = teams.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performers',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(16.h),
        ...topTeams.asMap().entries.map((entry) {
          final index = entry.key;
          final team = entry.value;
          final points = widget.teamPoints[team.teamId] ?? 0;
          
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _getPositionColor(index + 1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: _getPositionColor(index + 1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: Text(
                    team.teamName,
                    style: TextStyles.font14DarkBlueMedium,
                  ),
                ),
                Text(
                  '$points pts',
                  style: TextStyles.font14DarkBlueMedium.copyWith(
                    color: _getPositionColor(index + 1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecentMatches() {
    final recentMatches = widget.tournament.matches
        .where((m) => m.status == MatchStatus.completed)
        .take(5)
        .toList();

    if (recentMatches.isEmpty) {
      return _buildEmptyMatches();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: recentMatches.length,
      itemBuilder: (context, index) {
        final match = recentMatches[index];
        return _buildMatchCard(match);
      },
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
          Text(
            match.round,
            style: TextStyles.font12Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
          Gap(8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.team1Name,
                  style: TextStyles.font14DarkBlueMedium,
                ),
              ),
              Text(
                '${match.team1Score ?? 0}',
                style: TextStyles.font16DarkBlueBold,
              ),
            ],
          ),
          Gap(4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.team2Name,
                  style: TextStyles.font14DarkBlueMedium,
                ),
              ),
              Text(
                '${match.team2Score ?? 0}',
                style: TextStyles.font16DarkBlueBold,
              ),
            ],
          ),
          if (match.winnerTeamName != null) ...[
            Gap(8.h),
            Text(
              'Winner: ${match.winnerTeamName}',
              style: TextStyles.font12Grey400Weight.copyWith(
                color: ColorsManager.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64.sp,
              color: ColorsManager.textSecondary,
            ),
            Gap(16.h),
            Text(
              'No Teams Yet',
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              'Teams will appear here once they register',
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

  Widget _buildEmptyMatches() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              Icons.sports_cricket_outlined,
              size: 64.sp,
              color: ColorsManager.textSecondary,
            ),
            Gap(16.h),
            Text(
              'No Recent Matches',
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              'Completed matches will appear here',
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

  List<TournamentTeamRegistration> _getSortedTeams() {
    final teams = List<TournamentTeamRegistration>.from(widget.teams);
    
    switch (_sortOption) {
      case LeaderboardSortOption.points:
        teams.sort((a, b) {
          final pointsA = widget.teamPoints[a.teamId] ?? 0;
          final pointsB = widget.teamPoints[b.teamId] ?? 0;
          return pointsB.compareTo(pointsA);
        });
        break;
      case LeaderboardSortOption.name:
        teams.sort((a, b) => a.teamName.compareTo(b.teamName));
        break;
      case LeaderboardSortOption.members:
        teams.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        break;
    }
    
    return teams;
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[600]!;
      default:
        return ColorsManager.textSecondary;
    }
  }
}

enum LeaderboardSortOption {
  points,
  name,
  members;

  String get displayName {
    switch (this) {
      case LeaderboardSortOption.points:
        return 'Points';
      case LeaderboardSortOption.name:
        return 'Name';
      case LeaderboardSortOption.members:
        return 'Members';
    }
  }
}
