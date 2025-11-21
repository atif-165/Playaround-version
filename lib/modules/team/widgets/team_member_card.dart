import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../models/team_model.dart';

class TeamMemberCard extends StatelessWidget {
  final TeamPlayer member;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const TeamMemberCard({
    super.key,
    required this.member,
    required this.isAdmin,
    this.onEdit,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12.r),
          border: (member.role == TeamRole.captain) ||
                  (member.role == TeamRole.coach)
              ? Border.all(color: Colors.amber, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: ColorsManager.mainBlue.withOpacity(0.2),
                  backgroundImage: member.profileImageUrl != null
                      ? CachedNetworkImageProvider(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Text(
                          member.userName[0].toUpperCase(),
                          style: TextStyle(
                            color: ColorsManager.mainBlue,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if ((member.role == TeamRole.captain) ||
                    (member.role == TeamRole.coach))
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 12.sp,
                      ),
                    ),
                  ),
              ],
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(4.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getRoleColor(member.role).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          member.role.displayName,
                          style: TextStyle(
                            color: _getRoleColor(member.role),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((member.role == TeamRole.captain))
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 12.sp, color: Colors.amber),
                          Gap(4.w),
                          Text(
                            'Team Captain',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if ((member.role == TeamRole.coach))
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 12.sp, color: Colors.amber),
                          Gap(4.w),
                          Text(
                            'Head Coach',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (isAdmin && (onEdit != null || onRemove != null)) ...[
              Gap(8.w),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                color: Colors.grey[850],
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) onEdit!();
                  if (value == 'remove' && onRemove != null) onRemove!();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white),
                          Gap(8.w),
                          const Text('Edit',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  if (onRemove != null)
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          Gap(8.w),
                          const Text('Remove',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
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
