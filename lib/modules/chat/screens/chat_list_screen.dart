import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import '../widgets/chat_room_card.dart';
import 'chat_screen.dart';
import 'connection_requests_screen.dart';
import 'matches_screen.dart';

const _chatBackgroundColor = Color(0xFF050414);
const LinearGradient _chatBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);
const LinearGradient _chatPanelGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF181536),
    Color(0xFF0E0D24),
  ],
);
const Color _chatPanelColor = Color(0xFF14112D);
const Color _chatOverlayColor = Color(0xFF1C1A3C);
const Color _chatAccentColor = Color(0xFFFFC56F);

/// Screen showing list of chat conversations
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedChatIds = {};

  @override
  void initState() {
    super.initState();
    _chatService.initialize();
    // Trigger rebuild when search text changes
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedChatIds.clear();
      }
    });
  }

  void _toggleChatSelection(String chatId) {
    setState(() {
      if (_selectedChatIds.contains(chatId)) {
        _selectedChatIds.remove(chatId);
        if (_selectedChatIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedChatIds.add(chatId);
      }
    });
  }

  void _onChatLongPress(String chatId) {
    setState(() {
      _isSelectionMode = true;
      _selectedChatIds.add(chatId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: _chatBackgroundGradient,
        ),
        child: Column(
          children: [
            _buildEnhancedHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: _chatBackgroundGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
          child: Row(
            children: [
              IconButton(
                onPressed: _isSelectionMode
                    ? _toggleSelectionMode
                    : () => Navigator.of(context).pop(),
                icon: Icon(
                  _isSelectionMode ? Icons.close : Icons.arrow_back_ios,
                  color: Colors.white,
                  size: _isSelectionMode ? 24.sp : 22.sp,
                ),
                tooltip: _isSelectionMode ? 'Cancel' : 'Back',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Gap(12.w),
              Expanded(
                child: Text(
                  _isSelectionMode
                      ? '${_selectedChatIds.length} selected'
                      : 'Messages',
                  style: TextStyles.font20DarkBlueBold.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isSelectionMode)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: _deleteSelectedChats,
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: _showMatches,
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
        ),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16.sp,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.6),
            size: 20.sp,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withOpacity(0.6),
                    size: 20.sp,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getUserChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final chatRooms = snapshot.data ?? [];

        // Apply search filter directly without setState
        final displayChats = _getFilteredChats(chatRooms);

        if (chatRooms.isEmpty) {
          return _buildEmptyState();
        }

        if (displayChats.isEmpty && _searchController.text.isNotEmpty) {
          return _buildNoResultsState();
        }

        final listContent = RefreshIndicator(
          onRefresh: _refreshChats,
          color: _chatAccentColor,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            itemCount: displayChats.length,
            itemBuilder: (context, index) {
              final chatRoom = displayChats[index];
              final isSelected = _selectedChatIds.contains(chatRoom.id);

              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: ChatRoomCard(
                  chatRoom: chatRoom,
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleChatSelection(chatRoom.id);
                    } else {
                      _openChat(chatRoom);
                    }
                  },
                  onLongPress: () => _onChatLongPress(chatRoom.id),
                  onDelete: () => _deleteChatRoom(chatRoom),
                  currentUserId:
                      null, // Will use FirebaseAuth.instance.currentUser?.uid
                  isSelectionMode: _isSelectionMode,
                  isSelected: isSelected,
                ),
              );
            },
          ),
        );

        if (_isSelectionMode) {
          return listContent;
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: _buildSearchField(),
            ),
            Expanded(child: listContent),
          ],
        );
      },
    );
  }

  /// Filter chats based on search query
  List<ChatRoom> _getFilteredChats(List<ChatRoom> allChats) {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      return allChats;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return allChats.where((chat) {
      final displayName = chat.getDisplayName(currentUserId).toLowerCase();
      final lastMessage = (chat.lastMessage ?? '').toLowerCase();
      return displayName.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: _chatAccentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64.sp,
                color: _chatAccentColor,
              ),
            ),
            Gap(24.h),
            Text(
              'No conversations found',
              style: TextStyles.font18DarkBlue600Weight
                  .copyWith(color: Colors.white),
            ),
            Gap(12.h),
            Text(
              'Try searching with a different keyword',
              style: TextStyles.font14Grey400Weight
                  .copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
              color: Colors.white.withOpacity(0.35),
            ),
            Gap(24.h),
            Text(
              'No conversations yet',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'Start chatting with your matches from the heart icon above',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
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
              color: Colors.redAccent,
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
              backgroundColor: _chatAccentColor,
              buttonWidth: 120,
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(ChatRoom chatRoom) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: chatRoom),
      ),
    );
  }

  void _showMatches() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MatchesScreen(),
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
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performDeleteChatRoom(ChatRoom chatRoom) async {
    try {
      final success = await _chatService.deleteChatRoom(chatRoom.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat deleted successfully'),
              backgroundColor: _chatAccentColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete chat. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting chat: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _deleteSelectedChats() {
    if (_selectedChatIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Conversations',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedChatIds.length} conversation${_selectedChatIds.length > 1 ? 's' : ''}? This action cannot be undone.',
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
              _performDeleteSelectedChats();
            },
            child: Text(
              'Delete',
              style: TextStyles.font14Blue400Weight.copyWith(
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performDeleteSelectedChats() async {
    final selectedIds = List<String>.from(_selectedChatIds);
    int successCount = 0;
    int failCount = 0;

    for (final chatId in selectedIds) {
      try {
        final success = await _chatService.deleteChatRoom(chatId);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedChatIds.clear();
      });

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failCount > 0
                  ? 'Deleted $successCount chat${successCount > 1 ? 's' : ''}, failed to delete $failCount'
                  : 'Successfully deleted $successCount chat${successCount > 1 ? 's' : ''}',
            ),
            backgroundColor:
                failCount > 0 ? Colors.orange : _chatAccentColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete chats. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
