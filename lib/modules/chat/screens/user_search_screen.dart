import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/user_profile.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

/// Screen for searching and finding users to start conversations with
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<UserProfile> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _chatService.searchUsers(limit: 20);
      setState(() {
        _searchResults = users;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadInitialUsers();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _chatService.searchUsers(
        query: query.trim(),
        limit: 20,
      );
      setState(() {
        _searchResults = users;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.chatBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h), // Reduced height
      child: AppBar(
        title: Text(
          'Start New Chat',
          style: TextStyles.font16DarkBlue600Weight.copyWith( // Reduced font size
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorsManager.mainBlue, // Changed to #247CFF
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 56.h, // Reduced toolbar height
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _performSearch,
        decoration: InputDecoration(
          hintText: 'Search by name...',
          hintStyle: TextStyles.font14Grey400Weight,
          prefixIcon: Icon(
            Icons.search,
            color: ColorsManager.gray,
            size: 20.sp,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _loadInitialUsers();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: ColorsManager.gray,
                    size: 20.sp,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(
              color: ColorsManager.mainBlue,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorsManager.mainBlue,
        ),
      );
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80.sp,
              color: ColorsManager.gray76,
            ),
            Gap(24.h),
            Text(
              'Find People to Chat',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'Search for players and coaches to start conversations',
              style: TextStyles.font14Grey400Weight,
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
              Icons.person_search,
              size: 80.sp,
              color: ColorsManager.gray76,
            ),
            Gap(24.h),
            Text(
              'No users found',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'Try searching with different keywords',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _startChat(user),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              _buildAvatar(user),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyles.font16DarkBlue600Weight,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            user.role.displayName,
                            style: TextStyles.font12BlueRegular,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            user.location,
                            style: TextStyles.font12Grey400Weight,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chat_bubble_outline,
                color: ColorsManager.mainBlue,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfile user) {
    return Container(
      width: 50.w,
      height: 50.h,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.gray93Color,
      ),
      child: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.profilePictureUrl!,
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
                errorWidget: (context, url, error) => _buildInitialsAvatar(user.fullName),
              ),
            )
          : _buildInitialsAvatar(user.fullName),
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

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Future<void> _startChat(UserProfile user) async {
    try {
      // Check if users can chat
      final canChat = await _chatService.canUsersChat(user.uid);
      if (!canChat) {
        _showConnectionRequiredDialog(user);
        return;
      }

      // Create or get existing chat room
      final chatRoom = await _chatService.getOrCreateDirectChat(user.uid);
      if (chatRoom != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start chat. Please try again.'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error starting chat. Please try again.'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }

  void _showConnectionRequiredDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Connection Required',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: Text(
          'You need to connect with ${user.fullName} before you can start a conversation.',
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
              _sendConnectionRequest(user);
            },
            child: Text(
              'Send Request',
              style: TextStyles.font14Blue400Weight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendConnectionRequest(UserProfile user) async {
    try {
      final success = await _chatService.sendConnectionRequest(
        toUserId: user.uid,
        message: 'Hi! I\'d like to connect with you.',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to ${user.fullName}'),
            backgroundColor: ColorsManager.mainBlue,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send connection request'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending connection request'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }
}
