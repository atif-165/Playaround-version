import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';


import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import '../widgets/chat_room_card.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';
import 'connection_requests_screen.dart';

/// Screen showing list of chat conversations
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _chatService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.chatBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h), // Reduced height
      child: AppBar(
        title: Text(
          'Messages',
          style: TextStyles.font16DarkBlue600Weight.copyWith( // Reduced font size
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorsManager.mainBlue, // Changed to #247CFF
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 56.h, // Reduced toolbar height
        actions: [
          IconButton(
            onPressed: _showConnectionRequests,
            icon: Icon(
              Icons.person_add_outlined,
              color: Colors.white,
              size: 20.sp, // Reduced icon size
            ),
            tooltip: 'Connection Requests',
          ),
          Gap(8.w),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getUserChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final chatRooms = snapshot.data ?? [];

        if (chatRooms.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshChats,
          color: ColorsManager.mainBlue,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return ChatRoomCard(
                chatRoom: chatRoom,
                onTap: () => _openChat(chatRoom),
                onDelete: () => _deleteChatRoom(chatRoom),
                currentUserId: null, // Will use FirebaseAuth.instance.currentUser?.uid
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80.sp,
              color: ColorsManager.gray76,
            ),
            Gap(24.h),
            Text(
              'No conversations yet',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'Start a conversation by tapping the + button below',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(32.h),
            AppTextButton(
              buttonText: 'Find People to Chat',
              textStyle: TextStyles.font16White600Weight,
              onPressed: _openUserSearch,
              backgroundColor: ColorsManager.mainBlue,
              buttonWidth: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80.sp,
              color: ColorsManager.coralRed,
            ),
            Gap(24.h),
            Text(
              'Something went wrong',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'Unable to load your conversations. Please try again.',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(32.h),
            AppTextButton(
              buttonText: 'Retry',
              textStyle: TextStyles.font16White600Weight,
              onPressed: () => setState(() {}),
              backgroundColor: ColorsManager.mainBlue,
              buttonWidth: 120,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: "chat_list_fab",
      onPressed: _openUserSearch,
      backgroundColor: ColorsManager.mainBlue,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  void _openChat(ChatRoom chatRoom) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: chatRoom),
      ),
    );
  }

  void _openUserSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserSearchScreen(),
      ),
    );
  }

  void _showConnectionRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConnectionRequestsScreen(),
      ),
    );
  }

  Future<void> _refreshChats() async {
    // The stream will automatically refresh
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _deleteChatRoom(ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Conversation',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: TextStyles.font14Grey400Weight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteChatRoom(chatRoom);
            },
            child: Text(
              'Delete',
              style: TextStyles.font14Blue400Weight.copyWith(
                color: ColorsManager.coralRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performDeleteChatRoom(ChatRoom chatRoom) {
    // TODO: Implement chat room deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat deletion feature coming soon!'),
        backgroundColor: ColorsManager.mainBlue,
      ),
    );
  }
}
