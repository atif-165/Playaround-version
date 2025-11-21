import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../models/connection.dart';
import '../services/chat_service.dart';

/// Screen for managing connection requests
class ConnectionRequestsScreen extends StatefulWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  State<ConnectionRequestsScreen> createState() =>
      _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.chatBackground,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingRequestsTab(),
          _buildMyConnectionsTab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Connections',
        style: TextStyles.font18DarkBlue600Weight,
      ),
      backgroundColor: ColorsManager.neonBlue,
      foregroundColor: ColorsManager.darkBlue,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        labelColor: ColorsManager.mainBlue,
        unselectedLabelColor: ColorsManager.gray,
        indicatorColor: ColorsManager.mainBlue,
        tabs: const [
          Tab(text: 'Requests'),
          Tab(text: 'My Connections'),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    return StreamBuilder<List<Connection>>(
      stream: _chatService.getPendingConnectionRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading connection requests');
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_add_outlined,
            title: 'No connection requests',
            subtitle: 'You don\'t have any pending connection requests',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildConnectionRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildMyConnectionsTab() {
    return StreamBuilder<List<Connection>>(
      stream: _chatService.getUserConnections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading connections');
        }

        final connections = snapshot.data ?? [];

        if (connections.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'No connections yet',
            subtitle: 'Start connecting with other players and coaches',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections[index];
            return _buildConnectionCard(connection);
          },
        );
      },
    );
  }

  Widget _buildConnectionRequestCard(Connection request) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderName = request.getOtherUserName(currentUserId);
    final senderImageUrl = request.getOtherUserImageUrl(currentUserId);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(senderImageUrl, senderName),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: TextStyles.font16DarkBlue600Weight,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Wants to connect with you',
                        style: TextStyles.font14Grey400Weight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ColorsManager.gray93Color,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.message!,
                  style: TextStyles.font14DarkBlue600Weight,
                ),
              ),
            ],
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: AppTextButton(
                    buttonText: 'Accept',
                    textStyle: TextStyles.font14White600Weight,
                    onPressed: () =>
                        _respondToRequest(request, ConnectionStatus.accepted),
                    backgroundColor: ColorsManager.mainBlue,
                    buttonHeight: 40,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppTextButton(
                    buttonText: 'Decline',
                    textStyle: TextStyles.font14Grey400Weight,
                    onPressed: () =>
                        _respondToRequest(request, ConnectionStatus.rejected),
                    backgroundColor: Colors.grey[200],
                    buttonHeight: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(Connection connection) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final otherUserName = connection.getOtherUserName(currentUserId);
    final otherUserImageUrl = connection.getOtherUserImageUrl(currentUserId);

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
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: _buildAvatar(otherUserImageUrl, otherUserName),
        title: Text(
          otherUserName,
          style: TextStyles.font16DarkBlue600Weight,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Connected',
          style: TextStyles.font12Grey400Weight,
        ),
        trailing: IconButton(
          onPressed: () => _startChat(connection),
          icon: Icon(
            Icons.chat_bubble_outline,
            color: ColorsManager.mainBlue,
            size: 20.sp,
          ),
          tooltip: 'Start Chat',
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80.sp,
              color: ColorsManager.gray76,
            ),
            Gap(24.h),
            Text(
              title,
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              subtitle,
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
              message,
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

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Future<void> _respondToRequest(
      Connection request, ConnectionStatus response) async {
    try {
      final success = await _chatService.respondToConnectionRequest(
        connectionId: request.id,
        response: response,
      );

      if (success) {
        final message = response == ConnectionStatus.accepted
            ? 'Connection request accepted'
            : 'Connection request declined';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: ColorsManager.mainBlue,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to respond to connection request'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error responding to connection request'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }

  Future<void> _startChat(Connection connection) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final otherUserId = connection.getOtherUserId(currentUserId);

      final chatRoom = await _chatService.getOrCreateDirectChat(otherUserId);
      if (chatRoom != null && mounted) {
        Navigator.of(context).pushNamed(
          '/chatScreen',
          arguments: chatRoom,
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
}
