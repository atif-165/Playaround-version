import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/chat_room.dart';

/// Card widget for displaying chat room in list
class ChatRoomCard extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onDelete;
  final String? currentUserId;
  final bool isSelectionMode;
  final bool isSelected;

  const ChatRoomCard({
    super.key,
    required this.chatRoom,
    required this.onTap,
    this.onLongPress,
    required this.onDelete,
    this.currentUserId,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final userId =
        currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final displayName = chatRoom.getDisplayName(userId);
    final displayImage = chatRoom.getDisplayImage(userId);
    final unreadCount = chatRoom.getUnreadCount(userId);
    Map<String, dynamic>? nonConnectionMeta;
    if (chatRoom.metadata != null) {
      final raw = chatRoom.metadata!['nonConnection'];
      if (raw is Map<String, dynamic>) {
        nonConnectionMeta = Map<String, dynamic>.from(raw);
      }
    }
    final status =
        (nonConnectionMeta?['status'] as String?)?.toLowerCase() ?? 'none';
    final initiatorId = nonConnectionMeta?['initiatorId'] as String?;
    final bool isPending = status == 'pending';
    final bool isPendingRequest =
        isPending && initiatorId != null && initiatorId != userId;
    final bool isPendingInitiator =
        isPending && initiatorId != null && initiatorId == userId;
    final bool hasUnread = unreadCount > 0;

    String subtitle = chatRoom.lastMessage ?? 'No messages yet';
    if (isPending) {
      subtitle = isPendingInitiator
          ? 'Message request sent'
          : 'Message request pending';
    }

    final TextStyle subtitleStyle = isPending
        ? TextStyles.font14DarkBlue600Weight
            .copyWith(color: ColorsManager.warning)
        : (hasUnread
            ? TextStyles.font14DarkBlue600Weight
            : TextStyles.font14Grey400Weight);

    return Dismissible(
      key: Key(chatRoom.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: EdgeInsets.only(bottom: 8.h),
        elevation: 0,
        color: ColorsManager.neonBlue.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: ColorsManager.neonBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: ColorsManager.neonBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  _buildAvatar(displayImage, displayName),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyles.font16DarkBlue600Weight,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chatRoom.lastMessageAt != null)
                              Text(
                                _formatTime(chatRoom.lastMessageAt!),
                                style: TextStyles.font12Grey400Weight,
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subtitle,
                                style: subtitleStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread) ...[
                              SizedBox(width: 8.w),
                              _buildUnreadBadge(unreadCount),
                            ],
                          ],
                        ),
                        if (isPendingRequest) ...[
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: 14.sp,
                                color: ColorsManager.warning,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Message request',
                                style: TextStyles.font12Grey400Weight
                                    .copyWith(color: ColorsManager.warning),
                              ),
                            ],
                          ),
                        ],
                        if (chatRoom.type == ChatType.group) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.group,
                                size: 14.sp,
                                color: ColorsManager.gray,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${chatRoom.participants.length} members',
                                style: TextStyles.font12Grey400Weight,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl, String name) {
    return Container(
      width: 50.w,
      height: 50.h,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.gray93Color,
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 50.w,
                height: 50.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorsManager.gray93Color,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: ColorsManager.mainBlue,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildInitialsAvatar(name),
              ),
            )
          : _buildInitialsAvatar(name),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = _getInitials(name);
    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyles.font16Blue600Weight,
        ),
      ),
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ColorsManager.neonBlue,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyles.font12WhiteMedium,
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.w),
      decoration: BoxDecoration(
        color: ColorsManager.coralRed,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.delete,
        color: Colors.white,
        size: 24.sp,
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEE').format(dateTime);
    } else {
      // Older - show date
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}
