import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';

/// Widget for displaying a list of teams
class TeamListWidget extends StatelessWidget {
  final List<Team> teams;
  final Function(Team)? onTeamTap;
  final Function(Team)? onJoinTeam;
  final bool showJoinButton;
  final bool isLoading;

  const TeamListWidget({
    super.key,
    required this.teams,
    this.onTeamTap,
    this.onJoinTeam,
    this.showJoinButton = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
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
              showJoinButton 
                  ? 'No teams available to join at the moment'
                  : 'You haven\'t joined any teams yet',
              style: TextStyles.font13Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return TeamCard(
          team: team,
          onTap: onTeamTap != null ? () => onTeamTap!(team) : null,
          onJoinTeam: onJoinTeam != null ? () => onJoinTeam!(team) : null,
          showJoinButton: showJoinButton,
        );
      },
    );
  }
}

/// Individual team card widget
class TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback? onTap;
  final VoidCallback? onJoinTeam;
  final bool showJoinButton;

  const TeamCard({
    super.key,
    required this.team,
    this.onTap,
    this.onJoinTeam,
    this.showJoinButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTeamAvatar(),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: TextStyles.font16DarkBlue600Weight,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Gap(4.h),
                          Text(
                            team.sportType.displayName,
                            style: TextStyles.font13Grey400Weight,
                          ),
                        ],
                      ),
                    ),
                    if (showJoinButton && onJoinTeam != null)
                      _buildJoinButton(),
                  ],
                ),
                Gap(12.h),
                Text(
                  team.description,
                  style: TextStyles.font14Blue400Weight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(12.h),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.people,
                      text: '${team.activeMembersCount}/${team.maxMembers}',
                      color: team.isFull ? Colors.red : Colors.green,
                    ),
                    Gap(8.w),
                    if (team.captain != null)
                      _buildInfoChip(
                        icon: Icons.star,
                        text: team.captain!.userName,
                        color: Colors.orange,
                      ),
                    Gap(8.w),
                    _buildInfoChip(
                      icon: team.isPublic ? Icons.public : Icons.lock,
                      text: team.isPublic ? 'Public' : 'Private',
                      color: team.isPublic ? Colors.blue : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamAvatar() {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: team.teamImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                team.teamImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.group,
      color: ColorsManager.mainBlue,
      size: 24.sp,
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      height: 32.h,
      child: ElevatedButton(
        onPressed: team.isFull ? null : onJoinTeam,
        style: ElevatedButton.styleFrom(
          backgroundColor: team.isFull ? Colors.grey : ColorsManager.mainBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Text(
          team.isFull ? 'Full' : 'Join',
          style: TextStyles.font13White400Weight,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          Gap(4.w),
          Text(
            text,
            style: TextStyles.font12DarkBlue400Weight.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
