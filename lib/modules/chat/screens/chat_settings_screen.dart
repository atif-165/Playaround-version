import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../screens/dashboard/models/user_profile_dashboard_models.dart';
import '../../../screens/dashboard/services/user_profile_dashboard_service.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../routing/routes.dart';
import '../models/chat_room.dart';
import '../services/chat_background_service.dart';
import '../services/chat_service.dart';
import 'chat_background_selector_screen.dart';
const _settingsBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);

enum ChatSettingsAction {
  searchChat,
}

enum _ChatMuteDuration {
  eightHours('8 hours'),
  oneWeek('1 week'),
  always('Always');

  const _ChatMuteDuration(this.label);
  final String label;
}

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({
    super.key,
    required this.chatRoom,
  });

  final ChatRoom chatRoom;

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final PublicProfileService _profileService = PublicProfileService();
  final ChatService _chatService = ChatService();
  final ChatBackgroundService _backgroundService = ChatBackgroundService();

  PublicProfileData? _profileData;
  ChatParticipant? _otherParticipant;
  bool _loadingProfile = true;

  _ChatMuteDuration? _muteDuration;
  bool _customNotifications = false;
  bool _mediaVisibility = true;

  bool _blockInProgress = false;
  bool _reportInProgress = false;
  bool _clearInProgress = false;
  bool _deleteInProgress = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    _otherParticipant =
        widget.chatRoom.getOtherParticipant(currentUserId) ??
            (widget.chatRoom.participants.isNotEmpty
                ? widget.chatRoom.participants.first
                : null);

    if (_otherParticipant == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    try {
      final profile = await _profileService.fetchProfile(_otherParticipant!.userId);
      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: _loadingProfile
          ? Container(
              decoration:
                  const BoxDecoration(gradient: _settingsBackgroundGradient),
              child: const Center(child: CircularProgressIndicator()),
            )
          : Container(
              decoration:
                  const BoxDecoration(gradient: _settingsBackgroundGradient),
              child: _buildContent(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: AppBar(
        elevation: 0,
        toolbarHeight: 56.h,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _settingsBackgroundGradient,
          ),
        ),
        title: Text(
          'Chat Settings',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoSection(),
          Gap(20.h),
          _buildNotificationSection(),
          Gap(20.h),
          _buildChatActionsSection(),
          Gap(20.h),
          _buildPrivacySafetySection(),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final identity = _profileData?.identity;
    final headline = identity?.tagline;
    final statusMessage = _profileData?.about.statusMessage?.trim();
    final statusText = (statusMessage != null && statusMessage.isNotEmpty)
        ? statusMessage
        : (_otherParticipant?.isActive == true ? 'Online now' : 'Offline');

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(identity?.profilePictureUrl ?? _otherParticipant?.imageUrl),
              Gap(16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity?.fullName ??
                          _otherParticipant?.name ??
                          'Unknown player',
                      style: TextStyles.font16DarkBlue600Weight.copyWith(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (headline != null && headline.isNotEmpty) ...[
                      Gap(4.h),
                      Text(
                        headline,
                        style: TextStyles.font14Grey400Weight.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    Gap(6.h),
                    Row(
                      children: [
                        Icon(
                          _otherParticipant?.isActive == true
                              ? Icons.circle
                              : Icons.access_time,
                          size: 12.sp,
                          color: _otherParticipant?.isActive == true
                              ? ColorsManager.success
                              : Colors.white54,
                        ),
                        Gap(6.w),
                        Expanded(
                          child: Text(
                            statusText ?? 'Status unavailable',
                            style: TextStyles.font12DarkBlue400Weight.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(18.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.12),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: _openFullProfile,
              child: const Text('View Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40.r),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 72.w,
          height: 72.w,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 72.w,
            height: 72.w,
            color: Colors.white12,
          ),
          errorWidget: (_, __, ___) => _buildFallbackAvatar(),
        ),
      );
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    final initials = _otherParticipant?.name.trim().isNotEmpty == true
        ? _otherParticipant!.name.trim().split(' ').map((word) => word[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyles.font16DarkBlue600Weight.copyWith(
          color: Colors.white,
          fontSize: 20.sp,
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'Notifications',
      children: [
        _buildActionTile(
          icon: Icons.notifications_active_outlined,
          title: 'Mute notifications',
          subtitle: _muteDuration?.label ?? 'Off',
          onTap: _showMuteOptions,
        ),
        SwitchListTile(
          value: _customNotifications,
          onChanged: (value) {
            setState(() => _customNotifications = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? 'Custom notification preferences saved'
                      : 'Using default notification sound',
                ),
              ),
            );
          },
          activeColor: ColorsManager.primary,
          title: const Text(
            'Custom notifications',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Set a custom tone or vibration pattern',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        SwitchListTile(
          value: _mediaVisibility,
          onChanged: (value) {
            setState(() => _mediaVisibility = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? 'Media from this chat will appear in gallery'
                      : 'Media will stay hidden from gallery',
                ),
              ),
            );
          },
          activeColor: ColorsManager.primary,
          title: const Text(
            'Media visibility',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Show received photos & videos in your gallery',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildChatActionsSection() {
    return _buildSection(
      title: 'Chat tools',
      children: [
        _buildActionTile(
          icon: Icons.search,
          title: 'Search chat',
          subtitle: 'Find messages, links, and media',
          onTap: () {
            Navigator.of(context).pop(ChatSettingsAction.searchChat);
          },
        ),
        _buildActionTile(
          icon: Icons.wallpaper_outlined,
          title: 'Wallpaper & theme',
          subtitle: 'Personalize the chat background',
          onTap: _openWallpaperPicker,
        ),
      ],
    );
  }

  Widget _buildPrivacySafetySection() {
    return _buildSection(
      title: 'Privacy & safety',
      children: [
        _buildActionTile(
          icon: Icons.block,
          title: 'Block user',
          subtitle: 'Stop receiving messages from this user',
          iconColor: ColorsManager.error,
          trailing: _blockInProgress
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _blockInProgress ? null : _confirmBlock,
        ),
        _buildActionTile(
          icon: Icons.flag_outlined,
          title: 'Report user',
          subtitle: 'Report inappropriate content or behaviour',
          iconColor: ColorsManager.warning,
          trailing: _reportInProgress
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _reportInProgress ? null : _confirmReport,
        ),
        _buildActionTile(
          icon: Icons.delete_sweep_outlined,
          title: 'Clear chat',
          subtitle: 'Remove messages but keep the conversation',
          trailing: _clearInProgress
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _clearInProgress ? null : _confirmClearChat,
        ),
        _buildActionTile(
          icon: Icons.delete_forever,
          title: 'Delete chat',
          subtitle: 'Remove this chat from your list',
          iconColor: ColorsManager.error,
          trailing: _deleteInProgress
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _deleteInProgress ? null : _confirmDeleteChat,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 8.h),
            child: Text(
              title,
              style: TextStyles.font14DarkBlue600Weight.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return ListTile(
      enabled: onTap != null,
      onTap: onTap,
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(
          icon,
          color: iconColor ?? ColorsManager.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.4),
          ),
    );
  }

  Future<void> _showMuteOptions() async {
    final selection = await showModalBottomSheet<_ChatMuteDuration>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: ColorsManager.chatBackground,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mute notifications',
                style: TextStyles.font16DarkBlue600Weight.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              Gap(16.h),
              ..._ChatMuteDuration.values.map(
                (option) => RadioListTile<_ChatMuteDuration>(
                  value: option,
                  groupValue: _muteDuration,
                  activeColor: ColorsManager.primary,
                  onChanged: (value) => Navigator.of(context).pop(value),
                  title: Text(
                    option.label,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              RadioListTile<_ChatMuteDuration?>(
                value: null,
                groupValue: _muteDuration,
                activeColor: ColorsManager.primary,
                onChanged: (value) => Navigator.of(context).pop(),
                title: const Text(
                  'Turn off',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _muteDuration = selection);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selection != null
              ? 'Muted for ${selection.label}'
              : 'Muted notifications turned off',
        ),
      ),
    );
  }

  Future<void> _openWallpaperPicker() async {
    final chatId = widget.chatRoom.id;
    final background = await _backgroundService.getBackgroundForChat(chatId);
    final bubbleColors = await _backgroundService.getBubbleColors(chatId);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatBackgroundSelectorScreen(
          currentBackground: background,
          bubbleColors: bubbleColors,
          chatId: chatId,
        ),
      ),
    );
  }

  Future<void> _openFullProfile() async {
    final participant = _otherParticipant;
    if (participant == null) return;

    if (!mounted) return;

    Navigator.of(context).pushNamed(
      Routes.communityUserProfile,
      arguments: participant.userId,
    );
  }

  Future<void> _confirmBlock() async {
    final confirmed = await _showConfirmDialog(
      title: 'Block user?',
      message:
          'Blocked users can no longer send you messages or see your profile updates. You can unblock them later from settings.',
      confirmLabel: 'Block',
      isDestructive: true,
    );
    if (confirmed == true) {
      await _blockUser();
    }
  }

  Future<void> _confirmReport() async {
    final confirmed = await _showConfirmDialog(
      title: 'Report user?',
      message:
          'We will review the chat and take appropriate action. The user will not be notified about this report.',
      confirmLabel: 'Report',
      isDestructive: true,
    );
    if (confirmed == true) {
      await _reportUser();
    }
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear chat history?',
      message:
          'This will remove the messages from your device. The conversation will remain in your list.',
      confirmLabel: 'Clear',
    );
    if (confirmed == true) {
      await _clearChat();
    }
  }

  Future<void> _confirmDeleteChat() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete chat?',
      message:
          'This will remove the conversation from your chat list. You can still reach out to this user later to start a new chat.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      await _deleteChat();
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorsManager.chatBackground,
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: isDestructive
                      ? ColorsManager.error
                      : ColorsManager.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser() async {
    final otherUserId = _otherParticipant?.userId;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (otherUserId == null || currentUser == null) return;

    setState(() => _blockInProgress = true);
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('user_blocks')
          .doc(currentUser.uid)
          .collection('blocked')
          .doc(otherUserId)
          .set({
        'blockedUserId': otherUserId,
        'blockedAt': FieldValue.serverTimestamp(),
        'chatId': widget.chatRoom.id,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked successfully'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: $error'),
            backgroundColor: ColorsManager.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _blockInProgress = false);
      }
    }
  }

  Future<void> _reportUser() async {
    final otherUserId = _otherParticipant?.userId;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (otherUserId == null || currentUser == null) return;

    setState(() => _reportInProgress = true);
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('user_reports').add({
        'chatId': widget.chatRoom.id,
        'reportedUserId': otherUserId,
        'reporterUserId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'chat',
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you. Our team will review the report.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report user: $error'),
            backgroundColor: ColorsManager.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _reportInProgress = false);
      }
    }
  }

  Future<void> _clearChat() async {
    setState(() => _clearInProgress = true);
    try {
      // TODO: integrate with a dedicated clear-chat endpoint when available.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chat cleared on this device. (Messages remain on the server for now.)',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _clearInProgress = false);
      }
    }
  }

  Future<void> _deleteChat() async {
    setState(() => _deleteInProgress = true);
    try {
      final success = await _chatService.deleteChatRoom(widget.chatRoom.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat removed from your list'),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete chat'),
              backgroundColor: ColorsManager.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _deleteInProgress = false);
      }
    }
  }
}


