import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theming/colors.dart';

/// Loading widget for showing loading states
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetSize = size ?? 40.w;
        final shouldScaleWidth = constraints.maxWidth.isFinite &&
            constraints.maxWidth < targetSize;
        final shouldScaleHeight = constraints.maxHeight.isFinite &&
            constraints.maxHeight < targetSize;
        final shouldScaleDown = shouldScaleWidth || shouldScaleHeight;

        Widget indicator = SizedBox(
          width: targetSize,
          height: targetSize,
          child: const CircularProgressIndicator(
            color: ColorsManager.primary,
            strokeWidth: 3.0,
          ),
        );

        if (shouldScaleDown) {
          indicator = FittedBox(
            fit: BoxFit.scaleDown,
            child: indicator,
          );
        }

        final hasMessage = message != null && message!.isNotEmpty;
        final canShowMessage = hasMessage &&
            (!constraints.maxHeight.isFinite ||
                constraints.maxHeight >= (targetSize + 24.h));

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              indicator,
              if (canShowMessage) ...[
                SizedBox(height: 16.h),
                Text(
                  message!,
                  style: TextStyle(
                    color: ColorsManager.textSecondary,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
