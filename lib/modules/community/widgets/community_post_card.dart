import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../models/models.dart';
import 'image_full_view_screen.dart';

/// Community post card widget with Reddit-like design
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  final Function(bool isLike) onLike;
  final VoidCallback onComment;
  final VoidCallback onUserTap;
  final VoidCallback? onMoreOptions;
  final bool? hasLiked;
  final bool? hasDisliked;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onComment,
    required this.onUserTap,
    this.onMoreOptions,
    this.hasLiked,
    this.hasDisliked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsManager.surface,
              ColorsManager.surfaceVariant.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: ColorsManager.outline.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContent(),
            if (post.images.isNotEmpty) _buildImages(context),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.primary.withValues(alpha: 0.05),
            ColorsManager.secondary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onUserTap,
            child: SizedBox(
              width: 60.w,
              height: 60.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ColorsManager.primaryGradient,
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: ColorsManager.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CircleAvatar(
                    radius: 27.r,
                    backgroundColor: post.authorProfilePicture != null
                        ? Colors.transparent
                        : ColorsManager.primary.withValues(alpha: 0.2),
                    backgroundImage: post.authorProfilePicture != null
                        ? NetworkImage(post.authorProfilePicture!)
                        : null,
                    child: post.authorProfilePicture == null
                        ? Text(
                            post.authorNickname.isNotEmpty
                                ? post.authorNickname[0].toUpperCase()
                                : 'U',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onUserTap,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.authorNickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: ColorsManager.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Gap(8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: ColorsManager.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Active',
                          style: AppTypography.labelSmall.copyWith(
                            color: ColorsManager.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(4.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: ColorsManager.onSurfaceVariant,
                      size: 14.w,
                    ),
                    Gap(4.w),
                    Text(
                      timeago.format(post.createdAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: ColorsManager.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ColorsManager.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              onPressed: onMoreOptions,
              icon: Icon(
                Icons.more_vert,
                color: ColorsManager.onSurfaceVariant,
                size: 20.w,
              ),
              padding: EdgeInsets.all(8.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.content,
            style: AppTypography.bodyLarge.copyWith(
              color: ColorsManager.onSurface,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (post.tags.isNotEmpty) ...[
            Gap(12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: post.tags.map((tag) {
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: ColorsManager.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    '#$tag',
                    style: AppTypography.labelSmall.copyWith(
                      color: ColorsManager.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: _buildImageGrid(context),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    if (post.images.length == 1) {
      return _buildSingleImage(context, post.images.first);
    } else if (post.images.length == 2) {
      return _buildTwoImages(context);
    } else if (post.images.length == 3) {
      return _buildThreeImages(context);
    } else {
      return _buildMultipleImages(context);
    }
  }

  Widget _buildSingleImage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _openImageFullView(context, 0),
      child: Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages(BuildContext context) {
    return SizedBox(
      height: 150.h,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageFullView(context, 0),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(post.images[0]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Gap(2.w),
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageFullView(context, 1),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(post.images[1]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImages(BuildContext context) {
    return SizedBox(
      height: 150.h,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openImageFullView(context, 0),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(post.images[0]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Gap(2.w),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageFullView(context, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(post.images[1]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Gap(2.h),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageFullView(context, 2),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(post.images[2]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleImages(BuildContext context) {
    return SizedBox(
      height: 150.h,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openImageFullView(context, 0),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(post.images[0]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Gap(2.w),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageFullView(context, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(post.images[1]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Gap(2.h),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageFullView(context, 2),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(post.images[2]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (post.images.length > 3)
                          Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            child: Center(
                              child: Text(
                                '+${post.images.length - 3}',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManager.surfaceVariant.withValues(alpha: 0.1),
            ColorsManager.surfaceVariant.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.thumb_up_outlined,
            activeIcon: Icons.thumb_up,
            count: post.likesCount,
            onTap: () => onLike(true),
            isActive: hasLiked ?? false,
            color: ColorsManager.success,
          ),
          Gap(20.w),
          _buildActionButton(
            icon: Icons.thumb_down_outlined,
            activeIcon: Icons.thumb_down,
            count: post.dislikesCount,
            onTap: () => onLike(false),
            isActive: hasDisliked ?? false,
            color: ColorsManager.error,
          ),
          Gap(20.w),
          _buildActionButton(
            icon: Icons.comment_outlined,
            activeIcon: Icons.comment,
            count: post.commentsCount,
            onTap: onComment,
            isActive: false,
            color: ColorsManager.secondary,
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Implement share functionality
              },
              icon: Icon(
                Icons.share_outlined,
                color: ColorsManager.onSurfaceVariant,
                size: 20.w,
              ),
              padding: EdgeInsets.all(8.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required VoidCallback onTap,
    required bool isActive,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : ColorsManager.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12.r),
          border: isActive
              ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? color : ColorsManager.onSurfaceVariant,
              size: 18.w,
            ),
            if (count > 0) ...[
              Gap(6.w),
              Text(
                count.toString(),
                style: AppTypography.bodySmall.copyWith(
                  color: isActive ? color : ColorsManager.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openImageFullView(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageFullViewScreen(
          imageUrls: post.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}
