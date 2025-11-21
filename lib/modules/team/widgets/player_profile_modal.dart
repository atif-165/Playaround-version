import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/team_model.dart';

class PlayerProfileModal extends StatelessWidget {
  final TeamPlayer player;
  final bool isCoach;

  const PlayerProfileModal({
    super.key,
    required this.player,
    this.isCoach = false,
  });

  static void show(BuildContext context, TeamPlayer player,
      {bool isCoach = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerProfileModal(
        player: player,
        isCoach: isCoach,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  Gap(24.h),
                  // Stats and trophies features not yet implemented in TeamMember model
                  Gap(24.h),
                  _buildDetailsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${isCoach ? "Coach" : "Player"} Profile',
              style: TextStyles.font18DarkBlue600Weight.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorsManager.mainBlue,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: player.profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: player.profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.person,
                              size: 60.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: Text(
                                player.userName[0].toUpperCase(),
                                style: TextStyle(
                                  color: ColorsManager.mainBlue,
                                  fontSize: 48.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: ColorsManager.mainBlue.withOpacity(0.2),
                          child: Center(
                            child: Text(
                              player.userName[0].toUpperCase(),
                              style: TextStyle(
                                color: ColorsManager.mainBlue,
                                fontSize: 48.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          Gap(16.h),
          Text(
            player.userName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _getRoleColor(player.role).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _getRoleColor(player.role)),
            ),
            child: Text(
              player.role.displayName,
              style: TextStyle(
                color: _getRoleColor(player.role),
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (player.role == TeamRole.captain ||
              player.role == TeamRole.coach) ...[
            Gap(8.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16.sp),
                Gap(4.w),
                Text(
                  player.role == TeamRole.captain ? 'Team Captain' : 'Coach',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // TODO: Implement when extended player properties are added to TeamMember model
  // Widget _buildStatsSection() { ... }

  // TODO: Implement when rating property is added to TeamMember model
  // Widget _buildRatingSection() { ... }

  // TODO: Implement when trophies property is added to TeamMember model
  // Widget _buildTrophiesSection() { ... }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: TextStyles.font18DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap(12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              _buildInfoRow('Status', player.isActive ? 'Active' : 'Inactive'),
              Gap(12.h),
              _buildInfoRow(
                'Joined',
                player.joinedAt != null
                    ? '${player.joinedAt!.day}/${player.joinedAt!.month}/${player.joinedAt!.year}'
                    : 'Unknown',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return Colors.purple;
      case TeamRole.captain:
        return Colors.amber;
      case TeamRole.coach:
        return Colors.orange;
      case TeamRole.viceCaptain:
        return Colors.blue;
      default:
        return ColorsManager.mainBlue;
    }
  }
}
