import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Skeleton loading widget for chat room cards
class ChatRoomCardSkeleton extends StatelessWidget {
  const ChatRoomCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ColorsManager.coralRed,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 56.w,
            height: 56.h,
            decoration: BoxDecoration(
              color: ColorsManager.gray93Color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name skeleton
                Container(
                  height: 16.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: ColorsManager.gray93Color,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 8.h),
                // Message skeleton
                Container(
                  height: 14.h,
                  width: 200.w,
                  decoration: BoxDecoration(
                    color: ColorsManager.gray93Color,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                ),
              ],
            ),
          ),
          // Time skeleton
          Container(
            height: 12.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: ColorsManager.gray93Color,
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for chat list
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ChatRoomCardSkeleton(),
    );
  }
}

/// Optimized loading indicator with timeout
class OptimizedProgressIndicator extends StatefulWidget {
  final Duration timeout;
  final Widget? timeoutWidget;

  const OptimizedProgressIndicator({
    super.key,
    this.timeout = const Duration(seconds: 3),
    this.timeoutWidget,
  });

  @override
  State<OptimizedProgressIndicator> createState() =>
      _OptimizedProgressIndicatorState();
}

class _OptimizedProgressIndicatorState
    extends State<OptimizedProgressIndicator> {
  bool _showTimeout = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.timeout, () {
      if (mounted) {
        setState(() {
          _showTimeout = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showTimeout) {
      return widget.timeoutWidget ?? const ChatListSkeleton();
    }

    return const Center(
      child: CircularProgressIndicator(
        color: ColorsManager.mainBlue,
      ),
    );
  }
}
