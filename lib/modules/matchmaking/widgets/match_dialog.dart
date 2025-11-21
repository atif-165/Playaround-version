import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../routing/routes.dart';
import '../models/matchmaking_models.dart';

/// Dialog shown when users match
class MatchDialog extends StatefulWidget {
  final Match match;
  final String currentUserId;

  const MatchDialog({
    super.key,
    required this.match,
    required this.currentUserId,
  });

  @override
  State<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<MatchDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _heartController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = _getOtherUser();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: ColorsManager.background,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Gap(24.h),
                  _buildProfileImages(),
                  Gap(24.h),
                  _buildMatchInfo(otherUser),
                  Gap(32.h),
                  _buildActionButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _heartAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _heartAnimation.value,
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: ColorsManager.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ColorsManager.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sports_tennis,
                  color: Colors.white,
                  size: 30.sp,
                ),
              ),
            );
          },
        ),
        Gap(16.h),
        Text(
          'You\'ve Connected!',
          style: TextStyles.font28White700Weight.copyWith(
            color: ColorsManager.primary,
          ),
        ),
        Gap(8.h),
        Text(
          'You and ${_getOtherUser().name} are ready to play together!',
          style: TextStyles.font16White400Weight,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileImages() {
    final currentUser = _getCurrentUser();
    final otherUser = _getOtherUser();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProfileImage(currentUser.photoUrl, isCurrentUser: true),
        Gap(20.w),
        AnimatedBuilder(
          animation: _heartAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _heartAnimation.value,
              child: Icon(
                Icons.handshake,
                color: ColorsManager.primary,
                size: 24.sp,
              ),
            );
          },
        ),
        Gap(20.w),
        _buildProfileImage(otherUser.photoUrl, isCurrentUser: false),
      ],
    );
  }

  Widget _buildProfileImage(String? imageUrl, {required bool isCurrentUser}) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ColorsManager.primary,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: ColorsManager.surfaceVariant,
                  child: Icon(
                    Icons.person,
                    color: ColorsManager.textSecondary,
                    size: 40.sp,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: ColorsManager.surfaceVariant,
                  child: Icon(
                    Icons.person,
                    color: ColorsManager.textSecondary,
                    size: 40.sp,
                  ),
                ),
              )
            : Container(
                color: ColorsManager.surfaceVariant,
                child: Icon(
                  Icons.person,
                  color: ColorsManager.textSecondary,
                  size: 40.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildMatchInfo(({String name, String? photoUrl}) otherUser) {
    return Column(
      children: [
        if (widget.match.commonSports.isNotEmpty) ...[
          Text(
            'You Both Play',
            style: TextStyles.font14White600Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
          Gap(8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: widget.match.commonSports.take(3).map((sport) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: ColorsManager.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports,
                      color: ColorsManager.primary,
                      size: 14.sp,
                    ),
                    Gap(4.w),
                    Text(
                      sport,
                      style: TextStyles.font12White600Weight.copyWith(
                        color: ColorsManager.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Gap(16.h),
        ],
        if (widget.match.compatibilityScore >= 70) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: ColorsManager.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: ColorsManager.success,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: ColorsManager.success,
                  size: 16.sp,
                ),
                Gap(6.w),
                Text(
                  'Great Match: ${widget.match.compatibilityScore}%',
                  style: TextStyles.font14White600Weight.copyWith(
                    color: ColorsManager.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ColorsManager.outline),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Find More Partners',
              style: TextStyles.font16White600Weight,
            ),
          ),
        ),
        Gap(16.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _openChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Start Chat',
              style: TextStyles.font16White600Weight,
            ),
          ),
        ),
      ],
    );
  }

  ({String name, String? photoUrl}) _getCurrentUser() {
    if (widget.match.user1Id == widget.currentUserId) {
      return (
        name: widget.match.user1Name,
        photoUrl: widget.match.user1PhotoUrl
      );
    } else {
      return (
        name: widget.match.user2Name,
        photoUrl: widget.match.user2PhotoUrl
      );
    }
  }

  ({String name, String? photoUrl}) _getOtherUser() {
    if (widget.match.user1Id == widget.currentUserId) {
      return (
        name: widget.match.user2Name,
        photoUrl: widget.match.user2PhotoUrl
      );
    } else {
      return (
        name: widget.match.user1Name,
        photoUrl: widget.match.user1PhotoUrl
      );
    }
  }

  void _openChat() {
    Navigator.pop(context);
    if (widget.match.chatRoomId != null) {
      Navigator.pushNamed(
        context,
        Routes.chatScreen,
        arguments: widget.match.chatRoomId,
      );
    }
  }
}
