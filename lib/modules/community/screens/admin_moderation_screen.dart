import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../models/community_post.dart';
import '../services/community_service.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderate Posts'),
        backgroundColor: ColorsManager.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_isProcessing)
            const LinearProgressIndicator(
              color: ColorsManager.primary,
              minHeight: 2,
            ),
          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: CommunityService.getFlaggedPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: ColorsManager.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load flagged posts',
                      style: AppTypography.bodyLarge.copyWith(
                        color: ColorsManager.error,
                      ),
                    ),
                  );
                }

                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return Center(
                    child: Text(
                      'No flagged posts at the moment 🎉',
                      style: AppTypography.bodyLarge.copyWith(
                        color: ColorsManager.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _FlaggedPostCard(
                      post: post,
                      onWarnUser: () => _handleWarnUser(post),
                      onRemovePost: () => _handleRemovePost(post),
                      onDismissFlag: () => _handleDismissFlag(post),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWarnUser(CommunityPost post) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) {
      _showSnackBar('Admin authentication required', isError: true);
      return;
    }

    final reason = await _promptForReason(
      title: 'Warn ${post.authorNickname}',
      confirmLabel: 'Send Warning',
      hintText: 'Add a note for the user (optional)',
    );

    if (reason == null && !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await CommunityService.warnUser(
        userId: post.authorId,
        adminId: adminId,
        reason: reason?.trim().isNotEmpty == true ? reason!.trim() : null,
        blockPosting: true,
      );
      await CommunityService.unflagPost(post.id);
      _showSnackBar('Warning sent and user blocked from posting');
    } catch (e) {
      _showSnackBar('Failed to warn user: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleRemovePost(CommunityPost post) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) {
      _showSnackBar('Admin authentication required', isError: true);
      return;
    }

    final reason = await _promptForReason(
      title: 'Remove Post',
      confirmLabel: 'Remove',
      hintText: 'Add a moderation note (optional)',
    );

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove post?'),
        content: Text(
          'This will hide the post from the community. You can optionally block the user from posting.',
          style: AppTypography.bodyMedium.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await CommunityService.adminRemovePost(
        postId: post.id,
        adminId: adminId,
        note: reason?.trim().isNotEmpty == true ? reason!.trim() : null,
      );
      await CommunityService.setUserPostingBlocked(
        userId: post.authorId,
        blocked: true,
        adminId: adminId,
        reason: 'Post removed: ${reason ?? 'Community guidelines violation'}',
      );
      _showSnackBar('Post removed and user blocked from posting');
    } catch (e) {
      _showSnackBar('Failed to remove post: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDismissFlag(CommunityPost post) async {
    setState(() => _isProcessing = true);
    try {
      await CommunityService.unflagPost(post.id);
      _showSnackBar('Flag dismissed');
    } catch (e) {
      _showSnackBar('Failed to dismiss flag: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _promptForReason({
    required String title,
    required String confirmLabel,
    required String hintText,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hintText,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? ColorsManager.error : ColorsManager.primary,
      ),
    );
  }
}

class _FlaggedPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onWarnUser;
  final VoidCallback onRemovePost;
  final VoidCallback onDismissFlag;

  const _FlaggedPostCard({
    required this.post,
    required this.onWarnUser,
    required this.onRemovePost,
    required this.onDismissFlag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.authorProfilePicture != null
                      ? NetworkImage(post.authorProfilePicture!)
                      : null,
                  radius: 24.r,
                  child: post.authorProfilePicture == null
                      ? Text(
                          post.authorNickname.isNotEmpty
                              ? post.authorNickname[0].toUpperCase()
                              : '?',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorNickname,
                        style: AppTypography.titleMedium.copyWith(
                          color: ColorsManager.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        post.createdAt.toLocal().toString(),
                        style: AppTypography.bodySmall.copyWith(
                          color: ColorsManager.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.flaggedBy.isNotEmpty)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorsManager.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${post.flaggedBy.length} flag${post.flaggedBy.length > 1 ? 's' : ''}',
                      style: AppTypography.labelSmall.copyWith(
                        color: ColorsManager.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Gap(12.h),
            Text(
              post.content,
              style: AppTypography.bodyLarge.copyWith(
                color: ColorsManager.onSurface,
                height: 1.5,
              ),
            ),
            if (post.tags.isNotEmpty) ...[
              Gap(8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: post.tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor:
                            ColorsManager.secondary.withValues(alpha: 0.12),
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: ColorsManager.secondary,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (post.flaggedReason != null &&
                post.flaggedReason!.isNotEmpty) ...[
              Gap(12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ColorsManager.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report, color: ColorsManager.warning),
                    Gap(8.w),
                    Expanded(
                      child: Text(
                        post.flaggedReason!,
                        style: AppTypography.bodySmall.copyWith(
                          color: ColorsManager.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Gap(16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDismissFlag,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Dismiss'),
                ),
                Gap(8.w),
                TextButton.icon(
                  onPressed: onWarnUser,
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Warn User'),
                ),
                Gap(8.w),
                ElevatedButton.icon(
                  onPressed: onRemovePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.error,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
