import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/team_service.dart';

/// Widget for team communication features
class TeamCommunicationWidget extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamCommunicationWidget({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamCommunicationWidget> createState() => _TeamCommunicationWidgetState();
}

class _TeamCommunicationWidgetState extends State<TeamCommunicationWidget> {
  final TeamService _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Communication',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(16.h),
          _buildCommunicationOptions(),
        ],
      ),
    );
  }

  Widget _buildCommunicationOptions() {
    return Column(
      children: [
        _buildCommunicationCard(
          icon: Icons.chat,
          title: 'Team Chat',
          subtitle: 'Group chat for team members',
          color: ColorsManager.mainBlue,
          onTap: _openTeamChat,
        ),
        Gap(12.h),
        _buildCommunicationCard(
          icon: Icons.file_upload,
          title: 'File Sharing',
          subtitle: 'Share documents, images, and videos',
          color: ColorsManager.success,
          onTap: _openFileSharing,
        ),
        Gap(12.h),
        _buildCommunicationCard(
          icon: Icons.video_call,
          title: 'Video Meetings',
          subtitle: 'Schedule and join team video calls',
          color: ColorsManager.warning,
          onTap: _openVideoMeetings,
        ),
        Gap(12.h),
        _buildCommunicationCard(
          icon: Icons.notifications,
          title: 'Team Notifications',
          subtitle: 'Manage team notification settings',
          color: ColorsManager.darkBlue,
          onTap: _openNotificationSettings,
        ),
      ],
    );
  }

  Widget _buildCommunicationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.font16DarkBlue600Weight,
                  ),
                  Gap(2.h),
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
    );
  }

  Future<void> _openTeamChat() async {
    try {
      final hasChat = await _teamService.hasTeamGroupChat(widget.teamId);
      
      if (!hasChat) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team chat not available yet'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // TODO: Navigate to team chat screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening team chat...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFileSharing() {
    // TODO: Implement file sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File sharing coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openVideoMeetings() {
    // TODO: Implement video meetings functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video meetings coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openNotificationSettings() {
    // TODO: Implement notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
