import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/team_roster_widget.dart';
import '../widgets/upcoming_events_widget.dart';
import '../widgets/performance_stats_widget.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';
import '../../../routing/routes.dart';

/// Team-specific Dashboard Screen
/// Shows team-related information, stats, and actions
class TeamDashboardScreen extends StatefulWidget {
  final String teamId;

  const TeamDashboardScreen({
    super.key,
    required this.teamId,
  });

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  TeamInfo? _teamInfo;
  List<UpcomingEvent> _teamEvents = [];
  PerformanceStats? _teamStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    try {
      // Load team-specific data
      final dashboardData = await _dashboardService.getDashboardData(
        widget.teamId,
        UserRole.team,
      );

      if (mounted) {
        setState(() {
          _teamInfo = dashboardData.teamInfo;
          _teamEvents = dashboardData.upcomingEvents;
          _teamStats = dashboardData.performanceStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading team dashboard data: $e');
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });
    await _loadTeamData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      appBar: AppBar(
        title: Text(_teamInfo?.name ?? 'Team Dashboard'),
        backgroundColor: ColorsManager.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.teamManagementScreen,
                arguments: widget.teamId,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTeamActions,
        backgroundColor: ColorsManager.primary,
        icon: const Icon(Icons.add),
        label: const Text('Team Action'),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Header
                  _buildTeamHeader(),
                  Gap(24.h),

                  // Team Quick Stats
                  _buildTeamQuickStats(),
                  Gap(24.h),

                  // Upcoming Team Events
                  if (_teamEvents.isNotEmpty)
                    UpcomingEventsWidget(events: _teamEvents),
                  Gap(24.h),

                  // Team Roster
                  if (_teamInfo != null) TeamRosterWidget(teamInfo: _teamInfo!),
                  Gap(24.h),

                  // Team Performance
                  if (_teamStats != null)
                    PerformanceStatsWidget(
                      stats: _teamStats!,
                      userRole: UserRole.team,
                    ),
                  Gap(24.h),

                  // Recent Team Activity
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader() {
    if (_teamInfo == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary,
            ColorsManager.primary.withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          // Team Logo
          if (_teamInfo!.logoUrl != null)
            CircleAvatar(
              radius: 40.r,
              backgroundImage: NetworkImage(_teamInfo!.logoUrl!),
            )
          else
            CircleAvatar(
              radius: 40.r,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.groups,
                size: 40.sp,
                color: ColorsManager.primary,
              ),
            ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teamInfo!.name,
                  style: TextStyles.font18DarkBlueBold.copyWith(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
                Gap(4.h),
                Text(
                  _teamInfo!.sport,
                  style: TextStyles.font14Grey400Weight.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Gap(4.h),
                Text(
                  '${_teamInfo!.members.length} Members',
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Matches',
            _teamStats?.analytics['totalMatches']?.toInt().toString() ?? '0',
            Icons.sports_soccer,
            Colors.blue,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildStatCard(
            'Wins',
            _teamStats?.analytics['wins']?.toInt().toString() ?? '0',
            Icons.emoji_events,
            Colors.green,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildStatCard(
            'Win Rate',
            '${_teamStats?.winRate.toStringAsFixed(1) ?? '0'}%',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          Gap(8.h),
          Text(
            value,
            style: TextStyles.font18DarkBlueBold.copyWith(
              color: color,
            ),
          ),
          Gap(4.h),
          Text(
            label,
            style: TextStyles.font12Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(12.h),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_add, color: Colors.blue),
            title: const Text('New member joined'),
            subtitle: const Text('2 hours ago'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sports, color: Colors.green),
            title: const Text('Match scheduled'),
            subtitle: const Text('1 day ago'),
          ),
        ),
      ],
    );
  }

  void _showTeamActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Schedule Match'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to schedule match screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Invite Members'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to invite members screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Team Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.chatListScreen);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Team Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  Routes.teamManagementScreen,
                  arguments: widget.teamId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
