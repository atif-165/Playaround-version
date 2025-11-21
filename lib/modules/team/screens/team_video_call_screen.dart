import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../../config/video_call_config.dart';
import '../../../theming/styles.dart';

/// Hosts 1:1 team calls powered by ZEGO's prebuilt call experience.
class TeamVideoCallScreen extends StatelessWidget {
  const TeamVideoCallScreen({
    super.key,
    required this.teamId,
    required this.callId,
    required this.teamName,
    required this.isVideoCall,
  });

  final String teamId;
  final String callId;
  final String teamName;
  final bool isVideoCall;

  @override
  Widget build(BuildContext context) {
    if (!VideoCallConfig.hasValidZegoCredentials) {
      return _MissingCredentialsScreen(teamName: teamName);
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId =
        currentUser?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final userName = (currentUser?.displayName?.trim().isNotEmpty ?? false)
        ? currentUser!.displayName!.trim()
        : 'Player-${userId.substring(0, 6)}';

    final config = isVideoCall
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
    config.turnOnCameraWhenJoining = isVideoCall;
    config.turnOnMicrophoneWhenJoining = true;
    config.useSpeakerWhenJoining = isVideoCall;
    config.bottomMenuBar = ZegoCallBottomMenuBarConfig(
      buttons: [
        ZegoCallMenuBarButtonName.toggleMicrophoneButton,
        if (isVideoCall) ZegoCallMenuBarButtonName.toggleCameraButton,
        if (isVideoCall) ZegoCallMenuBarButtonName.switchCameraButton,
        ZegoCallMenuBarButtonName.chatButton,
        ZegoCallMenuBarButtonName.hangUpButton,
      ],
    );
    config.topMenuBar = ZegoCallTopMenuBarConfig(
      isVisible: true,
      buttons: const [
        ZegoCallMenuBarButtonName.minimizingButton,
        ZegoCallMenuBarButtonName.switchAudioOutputButton,
      ],
    );

    return WillPopScope(
      onWillPop: () async {
        // Always allow navigation to pop from the call.
        return true;
      },
      child: ZegoUIKitPrebuiltCall(
        appID: VideoCallConfig.zegoAppId,
        appSign: VideoCallConfig.zegoAppSign,
        userID: userId,
        userName: userName,
        callID: callId,
        config: config,
        events: ZegoUIKitPrebuiltCallEvents(
          onHangUpConfirmation: (event, defaultAction) async {
            final shouldLeave = await showDialog<bool>(
                  context: event.context,
                  builder: (context) => AlertDialog(
                    title: const Text('Leave call?'),
                    content: Text(
                      'Everyone in $teamName will see that you left the call.',
                      style: TextStyles.font14DarkBlue500Weight,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Stay'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!shouldLeave) {
              return false;
            }

            return defaultAction();
          },
        ),
      ),
    );
  }
}

class _MissingCredentialsScreen extends StatelessWidget {
  const _MissingCredentialsScreen({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                'Video calling isn\'t configured yet.',
                style: TextStyles.font16DarkBlue600Weight
                    .copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Set ZEGO_APP_ID and ZEGO_APP_SIGN to enable calls for $teamName.',
                style: TextStyles.font12Grey400Weight
                    .copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

