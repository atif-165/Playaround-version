import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/image_utils.dart';
import '../../../routing/routes.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../features/community_feed/models/feed_post.dart';
import '../../../features/community_feed/models/feed_media.dart';
import '../../../features/community_feed/models/user_post_state.dart';
import '../models/chat_message.dart';
import '../models/chat_background.dart';

const Color _chatAccentColor = Color(0xFFFFC56F);
/// Widget for displaying individual chat messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isGroupChat;
  final bool showSenderInfo;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ChatBubbleColors bubbleColors;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isGroupChat = false,
    this.showSenderInfo = false,
    this.onDelete,
    this.onTap,
    this.onLongPress,
    this.bubbleColors = ChatBubbleColors.defaults,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = _bubbleColor;
    final borderColor = _bubbleBorderColor;
    final primaryTextColor = _primaryTextColor;
    final secondaryTextColor = _secondaryTextColor;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        // For post entities, show reaction options
        if (message.type == MessageType.entity &&
            message.sharedEntity?.type == EntityType.post) {
          if (onLongPress != null) {
            onLongPress!();
          }
        } else if (isMe) {
          _showMessageOptions();
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8.h,
          left: isMe ? 50.w : 0,
          right: isMe ? 0 : 50.w,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
                  bottomRight: Radius.circular(isMe ? 4.r : 18.r),
                ),
                border: Border.all(
                  color: borderColor,
                  width: 1,
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
        color: _primaryTextColor,
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
          color: _bubbleBorderColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: const Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.white38,
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
        fallbackIconColor: Colors.white38,
        backgroundColor: _bubbleBorderColor.withOpacity(0.12),
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
          color: _secondaryTextColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Special handling for post entities - show full post card
    if (entity.type == EntityType.post) {
      return _buildPostCard(entity);
    }

    // Default entity card for other types
    return Container(
      constraints: BoxConstraints(maxWidth: 250.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _entityBackgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _bubbleBorderColor.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getEntityIcon(entity.type),
                size: 16.sp,
                color: isMe ? _primaryTextColor : _chatAccentColor,
              ),
              SizedBox(width: 6.w),
              Text(
                entity.type.value.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isMe ? _secondaryTextColor : _chatAccentColor,
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
                color: _bubbleBorderColor.withOpacity(0.12),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: _chatAccentColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 80.h,
                  color: _bubbleBorderColor.withOpacity(0.12),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white38),
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
              color: _primaryTextColor,
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
                color: _secondaryTextColor,
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
              color: isMe ? _secondaryTextColor : _chatAccentColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(SharedEntity entity) {
    final metadata = entity.metadata ?? {};
    final postId = metadata['postId'] as String? ?? entity.id;
    final authorName = metadata['authorName'] as String? ?? entity.subtitle ?? 'Unknown';
    final authorAvatar = metadata['authorAvatar'] as String?;
    final body = metadata['body'] as String? ?? entity.title;
    final mediaList = metadata['media'] as List<dynamic>? ?? [];
    final tags = (metadata['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      constraints: BoxConstraints(maxWidth: 280.w),
      decoration: BoxDecoration(
        color: _entityBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _bubbleBorderColor.withOpacity(0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundImage: authorAvatar != null && authorAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(authorAvatar)
                      : null,
                  backgroundColor: _bubbleBorderColor.withOpacity(0.3),
                  child: authorAvatar == null || authorAvatar.isEmpty
                      ? Text(
                          authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Community Post',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.article_outlined,
                  size: 18.sp,
                  color: _chatAccentColor,
                ),
              ],
            ),
          ),
          // Post body
          if (body.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(
                body,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: _primaryTextColor,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          // Media preview
          if (mediaList.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final firstMedia = mediaList.first as Map<String, dynamic>?;
                final mediaUrl = firstMedia?['url'] as String?;
                if (mediaUrl != null && mediaUrl.isNotEmpty) {
                  return ClipRRect(
                    child: CachedNetworkImage(
                      imageUrl: mediaUrl,
                      width: double.infinity,
                      height: 150.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150.h,
                        color: _bubbleBorderColor.withOpacity(0.12),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: _chatAccentColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 150.h,
                        color: _bubbleBorderColor.withOpacity(0.12),
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white38),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(height: 8.h),
          ],
          // Tags
          if (tags.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: tags.take(3).map((tag) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _bubbleBorderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _secondaryTextColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 8.h),
          ],
          // Footer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _bubbleBorderColor.withOpacity(0.1),
              border: Border(
                top: BorderSide(
                  color: _bubbleBorderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 14.sp,
                  color: _chatAccentColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Tap to view • Long press to react',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _chatAccentColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo() {
    final readCount = message.readBy.length;
    final senderIncluded = message.readBy.contains(message.fromId);
    int othersCount = senderIncluded ? readCount - 1 : readCount;
    if (othersCount < 0) othersCount = 0;
    final hasBeenSeen = othersCount > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 11.sp,
            color: _secondaryTextColor,
          ),
        ),
        if (message.isEdited) ...[
          SizedBox(width: 4.w),
          Text(
            '• edited',
            style: TextStyle(
              fontSize: 11.sp,
              color: _secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (isMe) ...[
          SizedBox(width: 4.w),
          Icon(
            hasBeenSeen ? Icons.done_all : Icons.done,
            size: 14.sp,
            color: hasBeenSeen ? _chatAccentColor : _secondaryTextColor,
          ),
        ],
        if (isMe && isGroupChat && othersCount > 0) ...[
          SizedBox(width: 4.w),
          Text(
            '• seen by $othersCount',
            style: TextStyle(
              fontSize: 11.sp,
              color: _secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
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
      case EntityType.post:
        return Icons.article;
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

  Color get _bubbleColor =>
      isMe ? bubbleColors.outgoing : bubbleColors.incoming;

  Brightness get _bubbleBrightness =>
      ThemeData.estimateBrightnessForColor(_bubbleColor);

  Color get _primaryTextColor =>
      _bubbleBrightness == Brightness.dark ? Colors.white : Colors.black87;

  Color get _secondaryTextColor =>
      _bubbleBrightness == Brightness.dark ? Colors.white70 : Colors.black54;

  Color get _bubbleBorderColor => _bubbleColor.withOpacity(
      _bubbleBrightness == Brightness.dark ? 0.35 : 0.25);

  Color get _entityBackgroundColor => _bubbleBrightness == Brightness.dark
      ? Colors.white.withOpacity(0.08)
      : Colors.black.withOpacity(0.06);
}
