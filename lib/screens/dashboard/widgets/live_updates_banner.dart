import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Live updates banner widget for real-time information
class LiveUpdatesBanner extends StatefulWidget {
  final List<LiveUpdate> updates;
  final VoidCallback? onTap;
  final Duration autoScrollDuration;

  const LiveUpdatesBanner({
    super.key,
    required this.updates,
    this.onTap,
    this.autoScrollDuration = const Duration(seconds: 5),
  });

  @override
  State<LiveUpdatesBanner> createState() => _LiveUpdatesBannerState();
}

class _LiveUpdatesBannerState extends State<LiveUpdatesBanner>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.updates.isNotEmpty) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(widget.autoScrollDuration, () {
      if (mounted && widget.updates.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % widget.updates.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.updates.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 80.h,
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsManager.primary,
              Color(0xFF1E6BFF),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.updates.length,
              itemBuilder: (context, index) {
                return _buildUpdateItem(widget.updates[index]);
              },
            ),
            if (widget.updates.length > 1)
              Positioned(
                bottom: 8.h,
                left: 0,
                right: 0,
                child: _buildPageIndicator(),
              ),
            Positioned(
              top: 8.h,
              left: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Gap(4.w),
                    Text(
                      'LIVE',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateItem(LiveUpdate update) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getUpdateIcon(update.type),
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  update.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(2.h),
                Text(
                  update.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (update.actionText != null) ...[
            Gap(8.w),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                update.actionText!,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.updates.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: index == _currentIndex ? 16.w : 6.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: index == _currentIndex
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
      ),
    );
  }

  IconData _getUpdateIcon(LiveUpdateType type) {
    switch (type) {
      case LiveUpdateType.match:
        return Icons.sports_soccer;
      case LiveUpdateType.tournament:
        return Icons.emoji_events;
      case LiveUpdateType.booking:
        return Icons.calendar_today;
      case LiveUpdateType.team:
        return Icons.group;
      case LiveUpdateType.achievement:
        return Icons.star;
      case LiveUpdateType.news:
        return Icons.article;
    }
  }
}

/// Live update data model
class LiveUpdate {
  final String id;
  final String title;
  final String description;
  final LiveUpdateType type;
  final String? actionText;
  final DateTime timestamp;

  const LiveUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.actionText,
    required this.timestamp,
  });
}

/// Types of live updates
enum LiveUpdateType {
  match,
  tournament,
  booking,
  team,
  achievement,
  news,
}

/// Compact live updates widget for smaller spaces
class CompactLiveUpdatesBanner extends StatelessWidget {
  final List<LiveUpdate> updates;
  final VoidCallback? onTap;

  const CompactLiveUpdatesBanner({
    super.key,
    required this.updates,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return const SizedBox.shrink();
    }

    final latestUpdate = updates.first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: ColorsManager.primaryContainer,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: ColorsManager.primary.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(
                _getUpdateIcon(latestUpdate.type),
                color: ColorsManager.primary,
                size: 16.sp,
              ),
            ),
            Gap(8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latestUpdate.title,
                    style: AppTypography.labelMedium.copyWith(
                      color: ColorsManager.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    latestUpdate.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorsManager.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (updates.length > 1)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: ColorsManager.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '+${updates.length - 1}',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getUpdateIcon(LiveUpdateType type) {
    switch (type) {
      case LiveUpdateType.match:
        return Icons.sports_soccer;
      case LiveUpdateType.tournament:
        return Icons.emoji_events;
      case LiveUpdateType.booking:
        return Icons.calendar_today;
      case LiveUpdateType.team:
        return Icons.group;
      case LiveUpdateType.achievement:
        return Icons.star;
      case LiveUpdateType.news:
        return Icons.article;
    }
  }
}
