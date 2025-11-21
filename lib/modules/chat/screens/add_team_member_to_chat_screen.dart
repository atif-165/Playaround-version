import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../team/models/team_model.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';

/// Screen to add team members to group chat
/// Only shows team members who are NOT already in the chat
class AddTeamMemberToChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final TeamModel team;

  const AddTeamMemberToChatScreen({
    super.key,
    required this.chatRoom,
    required this.team,
  });

  @override
  State<AddTeamMemberToChatScreen> createState() =>
      _AddTeamMemberToChatScreenState();
}

class _AddTeamMemberToChatScreenState extends State<AddTeamMemberToChatScreen> {
  final ChatService _chatService = ChatService();
  final Set<String> _selectedMembers = {};
  bool _isLoading = false;

  List<TeamPlayer> get _availableMembers {
    // Get all team members (players + coaches)
    final allMembers = <TeamPlayer>[
      ...widget.team.players,
      ...widget.team.coaches,
    ];

    // Get IDs of members already in chat
    final chatMemberIds =
        widget.chatRoom.participants.map((p) => p.userId).toSet();

    // Filter out members already in chat
    return allMembers
        .where((member) => !chatMemberIds.contains(member.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final availableMembers = _availableMembers;

    return Scaffold(
      backgroundColor: ColorsManager.chatBackground,
      appBar: AppBar(
        title: Text(
          'Add Team Members',
          style:
              TextStyles.font16DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: ColorsManager.mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedMembers.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _addSelectedMembers,
              child: _isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Add (${_selectedMembers.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: availableMembers.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildHeader(availableMembers.length),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: availableMembers.length,
                    itemBuilder: (context, index) {
                      final member = availableMembers[index];
                      final isSelected = _selectedMembers.contains(member.id);
                      return _buildMemberCard(member, isSelected);
                    },
                  ),
                ),
              ],
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
              Icons.check_circle_outline,
              size: 80.sp,
              color: Colors.green,
            ),
            Gap(24.h),
            Text(
              'All Team Members Added',
              style: TextStyles.font20DarkBlueBold,
              textAlign: TextAlign.center,
            ),
            Gap(12.h),
            Text(
              'All members of ${widget.team.name} are already in this chat.',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(32.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int availableCount) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20.sp, color: ColorsManager.mainBlue),
          Gap(12.w),
          Expanded(
            child: Text(
              '$availableCount team member${availableCount != 1 ? 's' : ''} not in chat',
              style: TextStyles.font14DarkBlue600Weight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(TeamPlayer member, bool isSelected) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color:
              isSelected ? ColorsManager.mainBlue : Colors.grey.withAlpha(51),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMembers.remove(member.id);
            } else {
              _selectedMembers.add(member.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(member),
              Gap(12.w),
              // Member info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: TextStyles.font16DarkBlue600Weight,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.jerseyNumber != null) ...[
                          Gap(8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: ColorsManager.mainBlue.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              '#${member.jerseyNumber}',
                              style: TextStyles.font12BlueRegular,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: _getRoleColor(member.role).withAlpha(26),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            member.role.displayName,
                            style: TextStyles.font12Grey400Weight.copyWith(
                              color: _getRoleColor(member.role),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (member.position != null) ...[
                          Gap(8.w),
                          Text(
                            member.position!,
                            style: TextStyles.font12Grey400Weight,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Gap(12.w),
              // Checkbox
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? ColorsManager.mainBlue : Colors.grey,
                    width: 2,
                  ),
                  color:
                      isSelected ? ColorsManager.mainBlue : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(TeamPlayer member) {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.gray93Color,
      ),
      child:
          member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: member.profileImageUrl!,
                    width: 48.w,
                    height: 48.h,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        _buildInitialsAvatar(member.name),
                    errorWidget: (context, url, error) =>
                        _buildInitialsAvatar(member.name),
                  ),
                )
              : _buildInitialsAvatar(member.name),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = _getInitials(name);
    return Center(
      child: Text(
        initials,
        style: TextStyles.font16DarkBlue600Weight.copyWith(
          color: ColorsManager.mainBlue,
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

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return Colors.purple;
      case TeamRole.captain:
        return Colors.amber;
      case TeamRole.coach:
        return Colors.orange;
      case TeamRole.viceCaptain:
        return Colors.blue;
      default:
        return ColorsManager.mainBlue;
    }
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedMembers.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var successCount = 0;
      var errorCount = 0;

      for (final memberId in _selectedMembers) {
        // Find the member in team
        final member = [...widget.team.players, ...widget.team.coaches]
            .firstWhere((m) => m.id == memberId);

        try {
          await _chatService.addParticipantToGroupChat(
            chatId: widget.chatRoom.id,
            userId: member.id,
            userName: member.name,
            userImageUrl: member.profileImageUrl,
            role: member.role == TeamRole.owner ? 'admin' : 'member',
          );
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Error adding ${member.name}: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context, successCount); // Return count of added members

        String message;
        Color bgColor;

        if (errorCount == 0) {
          message =
              '✅ Added $successCount member${successCount != 1 ? 's' : ''} to chat';
          bgColor = Colors.green;
        } else if (successCount > 0) {
          message = '⚠️ Added $successCount, failed $errorCount';
          bgColor = Colors.orange;
        } else {
          message = '❌ Failed to add members';
          bgColor = Colors.red;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
