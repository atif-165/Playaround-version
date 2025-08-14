
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/image_utils.dart';
import '../../../modules/team/models/models.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget to display user's team memberships
class ProfileTeamsWidget extends StatelessWidget {
  final List<Team> teams;
  final bool isLoading;

  const ProfileTeamsWidget({
    super.key,
    required this.teams,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Gap(16.h),
          if (isLoading)
            _buildLoadingState()
          else if (teams.isEmpty)
            _buildEmptyState()
          else
            _buildTeamsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.groups,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
        Gap(8.w),
        Text(
          'Teams',
          style: TextStyles.font18DarkBlueBold,
        ),
        const Spacer(),
        if (teams.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '${teams.length}',
              style: TextStyles.font12DarkBlue600Weight.copyWith(
                color: ColorsManager.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.h),
        child: CircularProgressIndicator(
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.h),
        child: Column(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(12.h),
            Text(
              'No teams yet',
              style: TextStyles.font14Grey400Weight,
            ),
            Gap(8.h),
            Text(
              'Join or create teams to start playing together',
              style: TextStyles.font12Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    return Column(
      children: teams.map((team) => _buildTeamTile(team)).toList(),
    );
  }

  Widget _buildTeamTile(Team team) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Team image or icon
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: _getSportColor(team.sportType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ImageUtils.buildSafeCachedImage(
                  imageUrl: team.teamImageUrl,
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8.r),
                  fallbackIcon: _getSportIcon(team.sportType),
                  fallbackIconColor: _getSportColor(team.sportType),
                  fallbackIconSize: 24.sp,
                  backgroundColor: _getSportColor(team.sportType).withValues(alpha: 0.1),
                ),
              ),
              Gap(12.w),
              // Team info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: TextStyles.font16DarkBlue600Weight,
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(
                          _getSportIcon(team.sportType),
                          size: 14.sp,
                          color: Colors.grey[600],
                        ),
                        Gap(4.w),
                        Text(
                          team.sportType.displayName,
                          style: TextStyles.font12Grey400Weight,
                        ),
                        Gap(8.w),
                        Text(
                          '•',
                          style: TextStyles.font12Grey400Weight,
                        ),
                        Gap(8.w),
                        Icon(
                          Icons.people,
                          size: 14.sp,
                          color: Colors.grey[600],
                        ),
                        Gap(4.w),
                        Text(
                          '${team.members.length}/${team.maxMembers}',
                          style: TextStyles.font12Grey400Weight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Role badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getRoleColor(_getUserRole(team)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _getUserRole(team).displayName,
                  style: TextStyles.font10Grey400Weight.copyWith(
                    color: _getRoleColor(_getUserRole(team)),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (team.description.isNotEmpty) ...[
            Gap(12.h),
            Text(
              team.description,
              style: TextStyles.font12Grey400Weight,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  TeamRole _getUserRole(Team team) {
    // This would need to be passed from the parent or fetched
    // For now, return member as default
    return TeamRole.member;
  }

  Color _getSportColor(SportType sportType) {
    switch (sportType) {
      case SportType.football:
        return Colors.green;
      case SportType.basketball:
        return Colors.orange;
      case SportType.tennis:
        return Colors.blue;
      case SportType.cricket:
        return Colors.red;
      case SportType.badminton:
        return Colors.purple;
      case SportType.volleyball:
        return Colors.indigo;
      case SportType.other:
        return Colors.blueGrey;
    }
  }

  IconData _getSportIcon(SportType sportType) {
    switch (sportType) {
      case SportType.football:
        return Icons.sports_soccer;
      case SportType.basketball:
        return Icons.sports_basketball;
      case SportType.tennis:
        return Icons.sports_tennis;
      case SportType.cricket:
        return Icons.sports_cricket;
      case SportType.badminton:
        return Icons.sports_tennis;
      case SportType.volleyball:
        return Icons.sports_volleyball;
      case SportType.other:
        return Icons.sports;
    }
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return Colors.purple;
      case TeamRole.captain:
        return Colors.blue;
      case TeamRole.viceCaptain:
        return Colors.orange;
      case TeamRole.member:
        return Colors.green;
    }
  }
}
