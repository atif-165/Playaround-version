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
import '../../team/services/team_service.dart';
import '../../team/models/team_model.dart';

/// Screen for managing team chat settings
/// Replaces GroupChatInfoScreen for team chats
class TeamChatSettingsScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String teamId;

  const TeamChatSettingsScreen({
    super.key,
    required this.chatRoom,
    required this.teamId,
  });

  @override
  State<TeamChatSettingsScreen> createState() => _TeamChatSettingsScreenState();
}

class _TeamChatSettingsScreenState extends State<TeamChatSettingsScreen> {
  final ChatService _chatService = ChatService();
  final TeamService _teamService = TeamService();
  late ChatRoom _chatRoom;
  Team? _team;
  bool _isLoading = true;
  bool _isRemovingMembers = false;
  final Set<String> _selectedMemberIds = {};
  final Set<String> _removingMemberIds = {};

  @override
  void initState() {
    super.initState();
    _chatRoom = widget.chatRoom;
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final team = await _teamService.getTeam(widget.teamId);
      // Also refresh chat room
      final updatedRoom = await _chatService.getChatRoom(widget.chatRoom.id);
      
      if (mounted) {
        setState(() {
          _team = team;
          if (updatedRoom != null) {
            _chatRoom = updatedRoom;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load team data: $e'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }

  bool get _isCurrentUserOwner {
    if (_team == null) return false;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _team!.ownerId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.chatBackground,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamHeader(),
                  Gap(24.h),
                  _buildMembersSection(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: AppBar(
        title: Text(
          'Chat Settings',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorsManager.mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56.h,
      ),
    );
  }

  Widget _buildTeamHeader() {
    if (_team == null) return const SizedBox.shrink();

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
            child: _team!.teamImageUrl != null && _team!.teamImageUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _team!.teamImageUrl!,
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
                      errorWidget: (context, url, error) => _buildTeamIcon(),
                    ),
                  )
                : _buildTeamIcon(),
          ),
          Gap(16.h),
          Text(
            _team!.name,
            style: TextStyles.font20DarkBlueBold,
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Text(
            '${_team!.sportType.displayName} • ${_chatRoom.participants.length} members',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamIcon() {
    return Container(
      width: 100.w,
      height: 100.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.mainBlue.withAlpha(26),
      ),
      child: Icon(
        Icons.group,
        size: 50.sp,
        color: ColorsManager.mainBlue,
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            if (_isCurrentUserOwner && _selectedMemberIds.isNotEmpty)
              TextButton(
                onPressed: _isRemovingMembers ? null : _removeSelectedMembers,
                child: Text(
                  'Remove Selected (${_selectedMemberIds.length})',
                  style: TextStyles.font14Blue400Weight.copyWith(
                    color: ColorsManager.coralRed,
                  ),
                ),
              ),
          ],
        ),
        Gap(16.h),
        ..._chatRoom.participants.map((participant) {
          final isOwner = _team?.ownerId == participant.userId;
          final isCurrentUser = participant.userId ==
              (FirebaseAuth.instance.currentUser?.uid ?? '');
          final isSelected = _selectedMemberIds.contains(participant.userId);
          final isRemoving = _removingMemberIds.contains(participant.userId);

          return _buildMemberCard(
            participant: participant,
            isOwner: isOwner,
            isCurrentUser: isCurrentUser,
            isSelected: isSelected,
            isRemoving: isRemoving,
          );
        }),
      ],
    );
  }

  Widget _buildMemberCard({
    required ChatParticipant participant,
    required bool isOwner,
    required bool isCurrentUser,
    required bool isSelected,
    required bool isRemoving,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: ColorsManager.gray93Color,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: participant.imageUrl != null &&
                  participant.imageUrl!.isNotEmpty
              ? CachedNetworkImageProvider(participant.imageUrl!)
              : null,
          child: participant.imageUrl == null || participant.imageUrl!.isEmpty
              ? Text(
                  participant.name.isNotEmpty
                      ? participant.name[0].toUpperCase()
                      : '?',
                  style: TextStyles.font14DarkBlue600Weight,
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                participant.name,
                style: TextStyles.font14DarkBlue600Weight,
              ),
            ),
            if (isOwner)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Owner',
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: ColorsManager.mainBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          participant.role == 'admin' ? 'Admin' : 'Member',
          style: TextStyles.font12Grey400Weight,
        ),
        trailing: _isCurrentUserOwner && !isCurrentUser && !isOwner
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Promote to Admin button
                  IconButton(
                    onPressed: isRemoving
                        ? null
                        : () => _promoteToAdmin(participant),
                    icon: Icon(
                      Icons.admin_panel_settings,
                      color: ColorsManager.mainBlue,
                      size: 20.sp,
                    ),
                    tooltip: 'Promote to Admin',
                  ),
                  // Remove member checkbox/button
                  Checkbox(
                    value: isSelected,
                    onChanged: isRemoving
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMemberIds.add(participant.userId);
                              } else {
                                _selectedMemberIds.remove(participant.userId);
                              }
                            });
                          },
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _promoteToAdmin(ChatParticipant participant) async {
    if (_team == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text(
          'Are you sure you want to promote ${participant.name} to Team Admin/Owner? This will transfer team ownership permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _removingMemberIds.add(participant.userId);
    });

    try {
      // Transfer team ownership (makes them permanent Team Admin/Owner)
      await _teamService.transferTeamOwnership(
        widget.teamId,
        participant.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${participant.name} is now Team Admin/Owner'),
            backgroundColor: ColorsManager.mainBlue,
          ),
        );
        // Reload team data
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to promote member: $e'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _removingMemberIds.remove(participant.userId);
        });
      }
    }
  }

  Future<void> _removeSelectedMembers() async {
    if (_selectedMemberIds.isEmpty) return;

    final count = _selectedMemberIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Members'),
        content: Text(
          'Are you sure you want to remove $count member(s) from the team chat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRemovingMembers = true;
      _removingMemberIds.addAll(_selectedMemberIds);
    });

    int successCount = 0;
    int failCount = 0;

    for (final memberId in _selectedMemberIds) {
      try {
        // Remove from team
        await _teamService.removeMember(widget.teamId, memberId);
        
        // Remove from chat
        final success = await _chatService.removeMemberFromGroupChat(
          chatId: _chatRoom.id,
          userId: memberId,
        );

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
        _isRemovingMembers = false;
        _selectedMemberIds.clear();
        _removingMemberIds.clear();
      });

      // Reload data
      await _loadTeamData();
      
      // Update chat room
      final updatedRoom = await _chatService.getChatRoom(_chatRoom.id);
      if (updatedRoom != null && mounted) {
        setState(() {
          _chatRoom = updatedRoom;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount > 0
                ? 'Removed $successCount member(s). $failCount failed.'
                : 'Removed $successCount member(s) successfully.',
          ),
          backgroundColor: failCount > 0
              ? ColorsManager.coralRed
              : ColorsManager.mainBlue,
        ),
      );
    }
  }
}

