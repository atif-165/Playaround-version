import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../../chat/models/chat_room.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import '../services/team_service.dart';
import '../screens/team_video_call_screen.dart';

/// Widget for team communication features
class TeamCommunicationWidget extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamCommunicationWidget({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamCommunicationWidget> createState() =>
      _TeamCommunicationWidgetState();
}

class _TeamCommunicationWidgetState extends State<TeamCommunicationWidget> {
  final TeamService _teamService = TeamService();
  final ChatService _chatService = ChatService();

  bool _isOpeningChat = false;
  bool _isStartingVideoCall = false;
  bool _isStartingVoiceCall = false;

  @override
  Widget build(BuildContext context) {
    final radius = 22.r;

    return Container(
      decoration: PublicProfileTheme.glassPanelDecoration(
        borderRadius: radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
            child: Text(
              'Team Communication',
              style: TextStyles.font18White600Weight,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'Keep everyone synced with group chat and instant video huddles.',
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
            ),
          ),
          Gap(16.h),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: _buildCommunicationOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationOptions() {
    return Column(
      children: [
        _buildCommunicationCard(
          icon: Icons.chat,
          title: 'Team Chat',
          subtitle: 'Launch the group chat shared with all team members.',
          color: ColorsManager.mainBlue,
          onTap: _openTeamChat,
          isLoading: _isOpeningChat,
        ),
        Gap(12.h),
        _buildCommunicationCard(
          icon: Icons.video_call,
          title: 'Video Call',
          subtitle: 'Start a live video call and notify every teammate.',
          color: ColorsManager.warning,
          onTap: () => _startRealtimeCall(isVideoCall: true),
          isLoading: _isStartingVideoCall,
        ),
        Gap(12.h),
        _buildCommunicationCard(
          icon: Icons.call,
          title: 'Voice Call',
          subtitle: 'Audio-only huddles that reuse the same call controls.',
          color: ColorsManager.mainBlue,
          onTap: () => _startRealtimeCall(isVideoCall: false),
          isLoading: _isStartingVoiceCall,
        ),
      ],
    );
  }

  Widget _buildCommunicationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: color.withOpacity(0.32)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.font16White600Weight,
                    ),
                    Gap(4.h),
                    Text(
                      subtitle,
                      style: TextStyles.font12White500Weight
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTeamChat() async {
    if (_isOpeningChat) return;

    setState(() {
      _isOpeningChat = true;
    });

    try {
      final chatId =
          await _teamService.ensureTeamGroupChat(widget.teamId);
      ChatRoom? chatRoom = await _chatService.getChatRoom(chatId);
      chatRoom ??= await _chatService.getGroupChatByEntity(
        entityType: 'team',
        entityId: widget.teamId,
      );

      if (!mounted) return;

      if (chatRoom == null) {
        _showSnackBar(
          'Unable to open team chat. Please try again later.',
          Colors.red,
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatRoom: chatRoom!),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Failed to open chat: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningChat = false;
        });
      }
    }
  }

  Future<void> _startRealtimeCall({required bool isVideoCall}) async {
    final isBusy =
        isVideoCall ? _isStartingVideoCall : _isStartingVoiceCall;
    if (isBusy) return;

    final permissionsGranted = await _ensureMediaPermissions();
    if (!permissionsGranted) return;

    setState(() {
      if (isVideoCall) {
        _isStartingVideoCall = true;
      } else {
        _isStartingVoiceCall = true;
      }
    });

    try {
      await _teamService.startTeamVideoMeeting(
        widget.teamId,
        callType: isVideoCall ? 'video' : 'audio',
      );
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TeamVideoCallScreen(
            teamId: widget.teamId,
            teamName: widget.teamName,
            callId: 'team_${widget.teamId}',
            isVideoCall: isVideoCall,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          'Failed to start call: $error',
          Colors.red,
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        if (isVideoCall) {
          _isStartingVideoCall = false;
        } else {
          _isStartingVoiceCall = false;
        }
      });
    }
  }

  Future<bool> _ensureMediaPermissions() async {
    while (true) {
      // Check current statuses
      var cameraStatus = await Permission.camera.status;
      var micStatus = await Permission.microphone.status;

      // If already granted, we are done
      final hasCamera = cameraStatus.isGranted || cameraStatus.isLimited;
      final hasMic = micStatus.isGranted || micStatus.isLimited;
      if (hasCamera && hasMic) {
        return true;
      }

      // Request permissions when they are not yet granted
      if (!hasCamera) {
        cameraStatus = await Permission.camera.request();
      }
      if (!hasMic) {
        micStatus = await Permission.microphone.request();
      }

      final cameraGranted =
          cameraStatus.isGranted || cameraStatus.isLimited;
      final micGranted = micStatus.isGranted || micStatus.isLimited;
      if (cameraGranted && micGranted) {
        return true;
      }

      final permanentlyDenied = cameraStatus.isPermanentlyDenied ||
          micStatus.isPermanentlyDenied;

      // Show dialog to explain next steps
      final shouldRetry = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permissions required'),
              content: const Text(
                'Camera and microphone permissions are required to start a call.\n\n'
                'Please grant access to continue.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                if (permanentlyDenied)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                if (!permanentlyDenied)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ) ??
          false;

      if (!shouldRetry) {
        _showSnackBar(
          'Camera and microphone permissions are required to start the call.',
          Colors.red,
        );
        return false;
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
