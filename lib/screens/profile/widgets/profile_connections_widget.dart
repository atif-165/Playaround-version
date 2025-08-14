import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/image_utils.dart';
import '../../../models/models.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget to display user connections (coaches and other players)
class ProfileConnectionsWidget extends StatelessWidget {
  final List<UserProfile> connectedUsers;
  final bool isLoading;

  const ProfileConnectionsWidget({
    super.key,
    required this.connectedUsers,
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
          else if (connectedUsers.isEmpty)
            _buildEmptyState()
          else
            _buildConnectionsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.people,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
        Gap(8.w),
        Text(
          'Connections',
          style: TextStyles.font18DarkBlueBold,
        ),
        const Spacer(),
        if (connectedUsers.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '${connectedUsers.length}',
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
              Icons.people_outline,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(12.h),
            Text(
              'No connections yet',
              style: TextStyles.font14Grey400Weight,
            ),
            Gap(8.h),
            Text(
              'Connect with coaches and other players to build your network',
              style: TextStyles.font12Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsList() {
    // Separate coaches and players
    final coaches = connectedUsers.where((user) => user.role == UserRole.coach).toList();
    final players = connectedUsers.where((user) => user.role == UserRole.player).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (coaches.isNotEmpty) ...[
          _buildSectionHeader('Coaches', coaches.length),
          Gap(8.h),
          _buildUsersList(coaches),
          if (players.isNotEmpty) Gap(16.h),
        ],
        if (players.isNotEmpty) ...[
          _buildSectionHeader('Players', players.length),
          Gap(8.h),
          _buildUsersList(players),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            '$count',
            style: TextStyles.font10Grey400Weight,
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList(List<UserProfile> users) {
    return Column(
      children: users.map((user) => _buildUserTile(user)).toList(),
    );
  }

  Widget _buildUserTile(UserProfile user) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile picture
          ImageUtils.buildSafeCircleAvatar(
            imageUrl: user.profilePictureUrl,
            radius: 20.r,
            backgroundColor: Colors.grey[300],
            fallbackText: ImageUtils.getInitials(user.fullName),
            fallbackTextColor: Colors.grey[600],
          ),
          Gap(12.w),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyles.font14DarkBlue600Weight,
                ),
                Gap(2.h),
                Row(
                  children: [
                    Icon(
                      user.role == UserRole.coach ? Icons.sports : Icons.person,
                      size: 12.sp,
                      color: Colors.grey[600],
                    ),
                    Gap(4.w),
                    Text(
                      user.role.displayName,
                      style: TextStyles.font12Grey400Weight,
                    ),
                    if (user is CoachProfile) ...[
                      Gap(8.w),
                      Text(
                        '•',
                        style: TextStyles.font12Grey400Weight,
                      ),
                      Gap(8.w),
                      Text(
                        user.specializationSports.take(2).join(', '),
                        style: TextStyles.font12Grey400Weight,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Role indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              user.role.displayName,
              style: TextStyles.font10Grey400Weight.copyWith(
                color: _getRoleColor(user.role),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.player:
        return Colors.green;
      case UserRole.coach:
        return Colors.blue;
      case UserRole.admin:
        return Colors.purple;
    }
  }
}
