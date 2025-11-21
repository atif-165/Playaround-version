import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class CommunityHighlightsWidget extends StatelessWidget {
  final List<dynamic> highlights;

  const CommunityHighlightsWidget({
    Key? key,
    required this.highlights,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Highlights',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(12.h),
          if (highlights.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'No highlights available',
                  style: TextStyles.font14Grey400Weight,
                ),
              ),
            )
          else
            ...highlights
                .take(3)
                .map((highlight) => _buildHighlightItem(highlight)),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(dynamic highlight) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: ColorsManager.primary,
            size: 20.sp,
          ),
          Gap(8.w),
          Expanded(
            child: Text(
              highlight.toString(),
              style: TextStyles.font14DarkBlue400Weight,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
