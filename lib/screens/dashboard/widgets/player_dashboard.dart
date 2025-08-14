import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../routing/routes.dart';
import '../../../models/player_profile.dart';
import '../../../modules/team/models/models.dart';
import '../../../modules/team/services/team_service.dart';
import '../../../modules/team/screens/team_management_screen.dart';
import '../../../modules/tournament/models/models.dart';
import '../../../modules/tournament/services/tournament_service.dart';
import '../../../modules/tournament/screens/tournament_management_screen.dart';

/// Player-specific dashboard widget with player-related functionality
class PlayerDashboard extends StatefulWidget {
  final PlayerProfile playerProfile;
  final VoidCallback? onBookCoach;
  final VoidCallback? onUpcomingSessions;

  const PlayerDashboard({
    super.key,
    required this.playerProfile,
    this.onBookCoach,
    this.onUpcomingSessions,
  });

  @override
  State<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends State<PlayerDashboard> {
  final TeamService _teamService = TeamService();
  final TournamentService _tournamentService = TournamentService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          Gap(24.h),
          _buildQuickStatsSection(),
          Gap(24.h),
          _buildSuggestedForYouSection(),
          Gap(24.h),
          _buildActionButtonsSection(),
          Gap(24.h),
          _buildMyTeamsSection(),
          Gap(24.h),
          _buildMyTournamentsSection(),
          Gap(24.h),
          _buildUpcomingSessionsSection(),
          Gap(24.h),
          _buildRecommendedCoachesSection(),
          Gap(24.h),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.green.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to train?',
            style: TextStyles.font16White600Weight.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          Text(
            widget.playerProfile.fullName,
            style: TextStyles.font16White600Weight.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Gap(4.h),
          Text(
            '${widget.playerProfile.skillLevel.value.toUpperCase()} level player',
            style: TextStyles.font13Grey400Weight.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Sessions This Month',
                value: '12', // This would come from actual data
                icon: Icons.fitness_center,
                color: Colors.blue,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                title: 'Hours Trained',
                value: '24',
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                title: 'Skill Points',
                value: '850',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
        children: [
          Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
          Gap(8.h),
          Text(
            value,
            style: TextStyles.font18DarkBlue600Weight.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(4.h),
          Text(
            title,
            style: TextStyles.font13Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Manage Teams',
          subtitle: 'Create, join, and manage your teams',
          icon: Icons.group,
          color: Colors.blue,
          onPressed: _navigateToTeamManagement,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Tournaments',
          subtitle: 'Browse and register for tournaments',
          icon: Icons.emoji_events,
          color: Colors.purple,
          onPressed: _navigateToTournamentManagement,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Book Coach',
          subtitle: 'Schedule a session with a coach',
          icon: Icons.person_add,
          color: Colors.green,
          onPressed: widget.onBookCoach,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Upcoming Sessions',
          subtitle: 'View your scheduled sessions',
          icon: Icons.calendar_today,
          color: Colors.orange,
          onPressed: widget.onUpcomingSessions,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Skill Tracking',
          subtitle: 'Track your performance and set goals',
          icon: Icons.trending_up,
          color: ColorsManager.mainBlue,
          onPressed: _navigateToSkillDashboard,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Match Requests',
          subtitle: 'View and manage team-up requests',
          icon: Icons.handshake,
          color: Colors.orange,
          onPressed: _navigateToMatchRequests,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24.sp,
                  ),
                ),
                Gap(16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyles.font15DarkBlue500Weight,
                      ),
                      Gap(4.h),
                      Text(
                        subtitle,
                        style: TextStyles.font13Grey400Weight,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: ColorsManager.gray,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Sessions',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // This would come from actual data
            itemBuilder: (context, index) {
              return Container(
                width: 200.w,
                margin: EdgeInsets.only(right: 12.w),
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
                    Text(
                      'Training Session',
                      style: TextStyles.font14Blue400Weight,
                    ),
                    Gap(4.h),
                    Text(
                      'Tomorrow, 4:00 PM',
                      style: TextStyles.font13Grey400Weight,
                    ),
                    Gap(8.h),
                    Text(
                      'with Coach Smith',
                      style: TextStyles.font13Grey400Weight,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedCoachesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Coaches',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        SizedBox(
          height: 140.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // This would come from actual data
            itemBuilder: (context, index) {
              return Container(
                width: 160.w,
                margin: EdgeInsets.only(right: 12.w),
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
                  children: [
                    CircleAvatar(
                      radius: 25.r,
                      backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        color: ColorsManager.mainBlue,
                        size: 24.sp,
                      ),
                    ),
                    Gap(8.h),
                    Text(
                      'Coach ${index + 1}',
                      style: TextStyles.font14Blue400Weight,
                      textAlign: TextAlign.center,
                    ),
                    Gap(4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14.sp,
                        ),
                        Gap(2.w),
                        Text(
                          '4.8',
                          style: TextStyles.font13Grey400Weight,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        Container(
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
            children: [
              _buildActivityItem(
                title: 'Completed session with Coach Johnson',
                time: '2 hours ago',
                icon: Icons.check_circle,
              ),
              Divider(height: 24.h),
              _buildActivityItem(
                title: 'Joined Basketball Team Alpha',
                time: '1 day ago',
                icon: Icons.group,
              ),
              Divider(height: 24.h),
              _buildActivityItem(
                title: 'Booked session for tomorrow',
                time: '2 days ago',
                icon: Icons.book_online,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String time,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 20.sp,
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.font14Blue400Weight,
              ),
              Gap(2.h),
              Text(
                time,
                style: TextStyles.font13Grey400Weight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyTeamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Teams',
              style: TextStyles.font18DarkBlue600Weight,
            ),
            TextButton(
              onPressed: _navigateToTeamManagement,
              child: Text(
                'View All',
                style: TextStyles.font14Blue400Weight,
              ),
            ),
          ],
        ),
        Gap(12.h),
        StreamBuilder<List<Team>>(
          stream: _teamService.getUserTeams(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 120.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                height: 120.h,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    'Error loading teams',
                    style: TextStyles.font14Blue400Weight.copyWith(color: Colors.red),
                  ),
                ),
              );
            }

            final teams = snapshot.data ?? [];

            if (teams.isEmpty) {
              return Container(
                height: 120.h,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 32.sp,
                        color: ColorsManager.gray,
                      ),
                      Gap(8.h),
                      Text(
                        'No teams yet',
                        style: TextStyles.font14Blue400Weight,
                      ),
                      Gap(4.h),
                      Text(
                        'Create or join a team to get started',
                        style: TextStyles.font12DarkBlue400Weight,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: teams.take(5).length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return Container(
                    width: 200.w,
                    margin: EdgeInsets.only(right: 12.w),
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
                            Icon(
                              Icons.group,
                              color: ColorsManager.mainBlue,
                              size: 20.sp,
                            ),
                            Gap(8.w),
                            Expanded(
                              child: Text(
                                team.name,
                                style: TextStyles.font14Blue400Weight,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Gap(8.h),
                        Text(
                          team.sportType.displayName,
                          style: TextStyles.font13Grey400Weight,
                        ),
                        Gap(4.h),
                        Text(
                          '${team.activeMembersCount}/${team.maxMembers} members',
                          style: TextStyles.font13Grey400Weight,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMyTournamentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Tournaments',
              style: TextStyles.font18DarkBlue600Weight,
            ),
            TextButton(
              onPressed: _navigateToTournamentManagement,
              child: Text(
                'View All',
                style: TextStyles.font14Blue400Weight,
              ),
            ),
          ],
        ),
        Gap(12.h),
        StreamBuilder<List<Tournament>>(
          stream: _tournamentService.getUserTournaments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 120.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                height: 120.h,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    'Error loading tournaments',
                    style: TextStyles.font14Blue400Weight.copyWith(color: Colors.red),
                  ),
                ),
              );
            }

            final tournaments = snapshot.data ?? [];

            if (tournaments.isEmpty) {
              return Container(
                height: 120.h,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 32.sp,
                        color: ColorsManager.gray,
                      ),
                      Gap(8.h),
                      Text(
                        'No tournaments yet',
                        style: TextStyles.font14Blue400Weight,
                      ),
                      Gap(4.h),
                      Text(
                        'Register for tournaments to compete',
                        style: TextStyles.font12DarkBlue400Weight,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tournaments.take(5).length,
                itemBuilder: (context, index) {
                  final tournament = tournaments[index];
                  return Container(
                    width: 200.w,
                    margin: EdgeInsets.only(right: 12.w),
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
                            Icon(
                              Icons.emoji_events,
                              color: ColorsManager.mainBlue,
                              size: 20.sp,
                            ),
                            Gap(8.w),
                            Expanded(
                              child: Text(
                                tournament.name,
                                style: TextStyles.font14Blue400Weight,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Gap(8.h),
                        Text(
                          tournament.sportType.displayName,
                          style: TextStyles.font13Grey400Weight,
                        ),
                        Gap(4.h),
                        Text(
                          tournament.status.displayName,
                          style: TextStyles.font13Grey400Weight,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuggestedForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.recommend,
                  color: ColorsManager.mainBlue,
                  size: 20.sp,
                ),
                Gap(8.w),
                Text(
                  '🏅 Suggested For You',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Navigate to full suggestions screen
                Navigator.pushNamed(context, '/explore');
              },
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: ColorsManager.mainBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        Gap(16.h),

        // Suggested Coaches Section
        _buildSuggestedCoaches(),
        Gap(16.h),

        // Popular Tournaments Section
        _buildPopularTournaments(),
        Gap(16.h),

        // Nearby Teams Section
        _buildNearbyTeams(),
        Gap(16.h),

        // Trending Venues Section
        _buildTrendingVenues(),
      ],
    );
  }

  Widget _buildSuggestedCoaches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Coaches',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Gap(8.h),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Mock data
            itemBuilder: (context, index) {
              return Container(
                width: 100.w,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      margin: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: ColorsManager.mainBlue,
                        size: 20.sp,
                      ),
                    ),
                    Text(
                      'Coach ${index + 1}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(2.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Top Rated',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularTournaments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Tournaments',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Gap(8.h),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Mock data
            itemBuilder: (context, index) {
              return Container(
                width: 140.w,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.orange,
                          size: 24.sp,
                        ),
                      ),
                      Gap(8.h),
                      Text(
                        'Tournament ${index + 1}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(2.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Hot Today',
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyTeams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nearby Teams',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Gap(8.h),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Mock data
            itemBuilder: (context, index) {
              return Container(
                width: 120.w,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.groups,
                          color: Colors.purple,
                          size: 20.sp,
                        ),
                      ),
                      Gap(8.h),
                      Text(
                        'Team ${index + 1}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Gap(4.h),
                      Text(
                        '2.5km away',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: ColorsManager.mainBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Gap(2.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'New',
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingVenues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Venues',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Gap(8.h),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Mock data
            itemBuilder: (context, index) {
              return Container(
                width: 140.w,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.location_city,
                          color: Colors.teal,
                          size: 24.sp,
                        ),
                      ),
                      Gap(8.h),
                      Text(
                        'Venue ${index + 1}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹500/hr',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 8.sp,
                                  color: Colors.amber[700],
                                ),
                                Gap(2.w),
                                Text(
                                  '4.5',
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    color: Colors.amber[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToTeamManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeamManagementScreen(),
      ),
    );
  }

  void _navigateToTournamentManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TournamentManagementScreen(),
      ),
    );
  }

  void _navigateToSkillDashboard() {
    Navigator.pushNamed(
      context,
      Routes.skillDashboardScreen,
      arguments: widget.playerProfile.uid,
    );
  }

  void _navigateToMatchRequests() {
    Navigator.pushNamed(
      context,
      Routes.matchRequestsScreen,
    );
  }
}
