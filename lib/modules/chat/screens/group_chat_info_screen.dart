import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';

/// Screen for viewing and managing group chat information
class GroupChatInfoScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const GroupChatInfoScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<GroupChatInfoScreen> createState() => _GroupChatInfoScreenState();
}

class _GroupChatInfoScreenState extends State<GroupChatInfoScreen> {
  final ChatService _chatService = ChatService();
  late ChatRoom _chatRoom;

  @override
  void initState() {
    super.initState();
    _chatRoom = widget.chatRoom;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = _chatRoom.isUserAdmin(currentUserId);

    return Scaffold(
      backgroundColor: ColorsManager.chatBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(),
            Gap(24.h),
            _buildGroupDescription(),
            Gap(24.h),
            _buildMembersSection(isAdmin),
            Gap(24.h),
            if (isAdmin) _buildAdminActions(),
            _buildGeneralActions(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h), // Reduced height
      child: AppBar(
        title: Text(
          'Group Info',
          style: TextStyles.font16DarkBlue600Weight.copyWith( // Reduced font size
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorsManager.mainBlue, // Changed to #247CFF
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56.h, // Reduced toolbar height
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100.w,
            height: 100.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ColorsManager.gray93Color,
            ),
            child: _chatRoom.imageUrl != null && _chatRoom.imageUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _chatRoom.imageUrl!,
                      width: 100.w,
                      height: 100.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100.w,
                        height: 100.h,
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
                      errorWidget: (context, url, error) => _buildGroupIcon(),
                    ),
                  )
                : _buildGroupIcon(),
          ),
          Gap(16.h),
          Text(
            _chatRoom.name ?? 'Group Chat',
            style: TextStyles.font20DarkBlueBold,
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Text(
            '${_chatRoom.participants.length} members',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupIcon() {
    return Container(
      width: 100.w,
      height: 100.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.group,
        size: 50.sp,
        color: ColorsManager.mainBlue,
      ),
    );
  }

  Widget _buildGroupDescription() {
    if (_chatRoom.description == null || _chatRoom.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorsManager.gray93Color,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            _chatRoom.description!,
            style: TextStyles.font14DarkBlue600Weight,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members (${_chatRoom.participants.length})',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            if (isAdmin)
              TextButton(
                onPressed: _addMember,
                child: Text(
                  'Add Member',
                  style: TextStyles.font14Blue400Weight,
                ),
              ),
          ],
        ),
        Gap(12.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _chatRoom.participants.length,
          itemBuilder: (context, index) {
            final participant = _chatRoom.participants[index];
            return _buildMemberCard(participant, isAdmin);
          },
        ),
      ],
    );
  }

  Widget _buildMemberCard(ChatParticipant participant, bool isAdmin) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isCurrentUser = participant.userId == currentUserId;
    final isParticipantAdmin = participant.role == 'admin';

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
        contentPadding: EdgeInsets.all(12.w),
        leading: _buildMemberAvatar(participant),
        title: Row(
          children: [
            Expanded(
              child: Text(
                participant.name,
                style: TextStyles.font16DarkBlue600Weight,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isParticipantAdmin)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Admin',
                  style: TextStyles.font12BlueRegular,
                ),
              ),
          ],
        ),
        subtitle: Text(
          isCurrentUser ? 'You' : 'Member',
          style: TextStyles.font12Grey400Weight,
        ),
        trailing: isAdmin && !isCurrentUser && !isParticipantAdmin
            ? PopupMenuButton<String>(
                onSelected: (action) => _handleMemberAction(action, participant),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildMemberAvatar(ChatParticipant participant) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.gray93Color,
      ),
      child: participant.imageUrl != null && participant.imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: participant.imageUrl!,
                width: 40.w,
                height: 40.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 40.w,
                  height: 40.h,
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
                errorWidget: (context, url, error) => _buildInitialsAvatar(participant.name),
              ),
            )
          : _buildInitialsAvatar(participant.name),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = _getInitials(name);
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyles.font14Blue400Weight,
        ),
      ),
    );
  }

  Widget _buildAdminActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Actions',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        AppTextButton(
          buttonText: 'Edit Group Info',
          textStyle: TextStyles.font14Blue400Weight,
          onPressed: _editGroupInfo,
          backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.1),
          buttonHeight: 44,
        ),
        Gap(12.h),
      ],
    );
  }

  Widget _buildGeneralActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextButton(
          buttonText: 'Leave Group',
          textStyle: TextStyles.font14White600Weight,
          onPressed: _leaveGroup,
          backgroundColor: ColorsManager.coralRed,
          buttonHeight: 44,
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  void _addMember() {
    // TODO: Implement add member functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add member feature coming soon!'),
        backgroundColor: ColorsManager.mainBlue,
      ),
    );
  }

  void _handleMemberAction(String action, ChatParticipant participant) {
    if (action == 'remove') {
      _removeMember(participant);
    }
  }

  void _removeMember(ChatParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Member',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: Text(
          'Are you sure you want to remove ${participant.name} from this group?',
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
              _performRemoveMember(participant);
            },
            child: Text(
              'Remove',
              style: TextStyles.font14Blue400Weight.copyWith(
                color: ColorsManager.coralRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performRemoveMember(ChatParticipant participant) async {
    try {
      final success = await _chatService.removeMemberFromGroupChat(
        chatId: _chatRoom.id,
        userId: participant.userId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${participant.name} removed from group'),
            backgroundColor: ColorsManager.mainBlue,
          ),
        );
        // Refresh the screen or update the state
        setState(() {
          _chatRoom = _chatRoom.copyWith(
            participants: _chatRoom.participants
                .where((p) => p.userId != participant.userId)
                .toList(),
          );
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove member'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error removing member'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }

  void _editGroupInfo() {
    // TODO: Implement edit group info functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit group info feature coming soon!'),
        backgroundColor: ColorsManager.mainBlue,
      ),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Leave Group',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: Text(
          'Are you sure you want to leave this group? You won\'t be able to see new messages.',
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
              _performLeaveGroup();
            },
            child: Text(
              'Leave',
              style: TextStyles.font14Blue400Weight.copyWith(
                color: ColorsManager.coralRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLeaveGroup() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final success = await _chatService.removeMemberFromGroupChat(
        chatId: _chatRoom.id,
        userId: currentUserId,
      );

      if (success && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left the group'),
            backgroundColor: ColorsManager.mainBlue,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to leave group'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error leaving group'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }
}
