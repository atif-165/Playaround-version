import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/upcoming_events_widget.dart';
import '../widgets/team_roster_widget.dart';
import '../widgets/performance_stats_widget.dart';
import '../widgets/community_highlights_widget.dart';
import '../widgets/notifications_panel.dart';
import '../widgets/admin_controls_widget.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';

class MVPDashboardScreen extends StatefulWidget {
  final UserRole userRole;
  final String userId;

  const MVPDashboardScreen({
    Key? key,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  State<MVPDashboardScreen> createState() => _MVPDashboardScreenState();
}

class _MVPDashboardScreenState extends State<MVPDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  DashboardData? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await _dashboardService.getDashboardData(
        widget.userId,
        widget.userRole,
      );
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: ColorsManager.primary,
                backgroundColor: ColorsManager.surface,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header / Hero Section
                      DashboardHeader(
                        userProfile: _dashboardData?.userProfile,
                        userRole: widget.userRole,
                      ),
                      Gap(24.h),

                      // Quick Actions Grid
                      QuickActionsGrid(
                        userRole: widget.userRole,
                        onActionTap: _handleQuickAction,
                      ),
                      Gap(24.h),

                      // Upcoming Events
                      UpcomingEventsWidget(
                        events: _dashboardData?.upcomingEvents ?? [],
                      ),
                      Gap(24.h),

                      // Team Roster (only for team members)
                      if (_dashboardData?.teamInfo != null) ...[
                        TeamRosterWidget(
                          teamInfo: _dashboardData!.teamInfo!,
                        ),
                        Gap(24.h),
                      ],

                      // Performance & Stats
                      PerformanceStatsWidget(
                        stats: _dashboardData?.performanceStats,
                        userRole: widget.userRole,
                      ),
                      Gap(24.h),

                      // Community Highlights
                      CommunityHighlightsWidget(
                        highlights: _dashboardData?.communityHighlights ?? [],
                      ),
                      Gap(24.h),

                      // Admin Controls (only for admins)
                      if (widget.userRole == UserRole.admin) ...[
                        AdminControlsWidget(
                          adminData: _dashboardData?.adminData,
                        ),
                        Gap(24.h),
                      ],

                      // Notifications Panel
                      NotificationsPanel(
                        notifications: _dashboardData?.notifications ?? [],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorsManager.primary,
            strokeWidth: 3.w,
          ),
          Gap(16.h),
          Text(
            'Loading Dashboard...',
            style: TextStyles.font16DarkBlue500Weight,
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(QuickActionType action) {
    switch (action) {
      case QuickActionType.bookFacility:
        Navigator.pushNamed(context, '/venue-booking');
        break;
      case QuickActionType.findCoach:
        Navigator.pushNamed(context, '/coaches');
        break;
      case QuickActionType.joinTeam:
        Navigator.pushNamed(context, '/team-finder');
        break;
      case QuickActionType.trackSkills:
        Navigator.pushNamed(context, '/skill-tracking');
        break;
      case QuickActionType.communityForums:
        Navigator.pushNamed(context, '/community');
        break;
      case QuickActionType.tournaments:
        Navigator.pushNamed(context, '/tournaments');
        break;
    }
  }
}