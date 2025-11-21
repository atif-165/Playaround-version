import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../screens/chat_list_screen.dart';

/// Chat icon widget with badge for unread message count
class ChatIcon extends StatelessWidget {
  final ChatService _chatService = ChatService();

  ChatIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      // For now, we'll use a simple stream. In a real implementation,
      // you'd want to create a specific stream for unread counts
      stream: _chatService.getUserChatRooms().map((rooms) => rooms),
      builder: (context, snapshot) {
        // Calculate total unread count from all chat rooms
        int unreadCount = 0;
        if (snapshot.hasData) {
          final rooms = snapshot.data!;
          for (final room in rooms) {
            // This would need to be implemented based on current user ID
            // For now, we'll use a placeholder
            unreadCount += room.getUnreadCount('current_user_id') as int;
          }
        }

        return Stack(
          children: [
            IconButton(
              onPressed: () => _navigateToChats(context),
              icon: Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 24.sp,
              ),
              tooltip: 'Messages',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8.w,
                top: 8.h,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.h,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _navigateToChats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatListScreen(),
      ),
    );
  }
}
