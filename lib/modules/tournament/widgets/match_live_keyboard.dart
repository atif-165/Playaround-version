import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

typedef OnQuickSend = void Function(String text);

/// A compact in-app keyboard for live reactions & quick comments.
class MatchLiveKeyboard extends StatefulWidget {
  const MatchLiveKeyboard({
    super.key,
    required this.onSend,
    this.quickReplies = const ['Great play!', 'Let’s go!', 'Come on!', '🔥'],
    this.emojis = const ['👏', '🔥', '⚽', '🏀', '💪', '❤️'],
  });

  final OnQuickSend onSend;
  final List<String> quickReplies;
  final List<String> emojis;

  @override
  State<MatchLiveKeyboard> createState() => _MatchLiveKeyboardState();
}

class _MatchLiveKeyboardState extends State<MatchLiveKeyboard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend([String? text]) {
    final value = (text ?? _controller.text).trim();
    if (value.isEmpty) return;
    widget.onSend(value);
    if (text == null) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'React & cheer',
            style: TextStyles.font12White600Weight,
          ),
          Gap(6.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: widget.emojis
                .map(
                  (emoji) => _reactionChip(
                    label: emoji,
                    onTap: () => _handleSend(emoji),
                  ),
                )
                .toList(),
          ),
          Gap(10.h),
          SizedBox(
            height: 48.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.quickReplies.length,
              separatorBuilder: (_, __) => Gap(8.w),
              itemBuilder: (context, index) {
                final text = widget.quickReplies[index];
                return _quickReplyChip(title: text);
              },
            ),
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyles.font12White500Weight,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type a cheer...',
                    ),
                    minLines: 1,
                    maxLines: 2,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _handleSend,
                  ),
                ),
              ),
              Gap(10.w),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  fixedSize: Size(42.w, 42.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () => _handleSend(),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickReplyChip({required String title}) {
    return GestureDetector(
      onTap: () => _handleSend(title),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          title,
          style: TextStyles.font12White500Weight,
        ),
      ),
    );
  }

  Widget _reactionChip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.15),
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

