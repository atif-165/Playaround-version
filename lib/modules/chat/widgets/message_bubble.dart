import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/image_utils.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/chat_message.dart';

/// Widget for displaying individual chat messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSenderInfo;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderInfo = false,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: isMe ? _showMessageOptions : null,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8.h,
          left: isMe ? 50.w : 0,
          right: isMe ? 0 : 50.w,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSenderInfo) ...[
              Padding(
                padding: EdgeInsets.only(left: 12.w, bottom: 4.h),
                child: Text(
                  message.senderName,
                  style: TextStyles.font12Grey400Weight,
                ),
              ),
            ],
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isMe ? ColorsManager.neonBlue : ColorsManager.neonBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
                  bottomRight: Radius.circular(isMe ? 4.r : 18.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(),
                  SizedBox(height: 4.h),
                  _buildMessageInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.image:
        return _buildImageContent();
      case MessageType.entity:
        return _buildEntityContent();
    }
  }

  Widget _buildTextContent() {
    return Text(
      message.text ?? '',
      style: TextStyle(
        fontSize: 16.sp,
        color: isMe ? Colors.white : ColorsManager.darkBlue,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildImageContent() {
    if (message.imageUrl == null || message.imageUrl!.isEmpty) {
      return Container(
        width: 200.w,
        height: 150.h,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: const Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: 250.w,
        maxHeight: 300.h,
      ),
      child: ImageUtils.buildSafeCachedImage(
        imageUrl: message.imageUrl,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8.r),
        fallbackIcon: Icons.broken_image,
        fallbackIconColor: Colors.grey,
        backgroundColor: Colors.grey[300],
      ),
    );
  }

  Widget _buildEntityContent() {
    final entity = message.sharedEntity;
    if (entity == null) {
      return Text(
        'Shared content unavailable',
        style: TextStyle(
          fontSize: 14.sp,
          color: isMe ? Colors.white70 : Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxWidth: 250.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isMe 
            ? Colors.white.withValues(alpha: 0.1)
            : ColorsManager.mainBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isMe 
              ? Colors.white.withValues(alpha: 0.3)
              : ColorsManager.mainBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getEntityIcon(entity.type),
                size: 16.sp,
                color: isMe ? Colors.white : ColorsManager.mainBlue,
              ),
              SizedBox(width: 6.w),
              Text(
                entity.type.value.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white70 : ColorsManager.mainBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (entity.imageUrl != null && entity.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: CachedNetworkImage(
                imageUrl: entity.imageUrl!,
                width: double.infinity,
                height: 80.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 80.h,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: ColorsManager.mainBlue,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 80.h,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
          Text(
            entity.title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isMe ? Colors.white : ColorsManager.darkBlue,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (entity.subtitle != null && entity.subtitle!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              entity.subtitle!,
              style: TextStyle(
                fontSize: 12.sp,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 6.h),
          Text(
            'Tap to view',
            style: TextStyle(
              fontSize: 11.sp,
              color: isMe ? Colors.white60 : ColorsManager.mainBlue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            fontSize: 11.sp,
            color: isMe ? Colors.white70 : Colors.grey[600],
          ),
        ),
        if (message.isEdited) ...[
          SizedBox(width: 4.w),
          Text(
            '• edited',
            style: TextStyle(
              fontSize: 11.sp,
              color: isMe ? Colors.white60 : Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (isMe) ...[
          SizedBox(width: 4.w),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 14.sp,
            color: message.isRead ? Colors.blue[200] : Colors.white70,
          ),
        ],
      ],
    );
  }

  IconData _getEntityIcon(EntityType type) {
    switch (type) {
      case EntityType.profile:
        return Icons.person;
      case EntityType.venue:
        return Icons.location_city;
      case EntityType.team:
        return Icons.group;
      case EntityType.tournament:
        return Icons.emoji_events;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // This week - show day and time
      return DateFormat('EEE HH:mm').format(dateTime);
    } else {
      // Older - show date and time
      return DateFormat('dd/MM HH:mm').format(dateTime);
    }
  }

  void _showMessageOptions() {
    if (onDelete != null) {
      // This would typically show a bottom sheet or context menu
      // For now, we'll just call the delete callback
      onDelete!();
    }
  }
}
