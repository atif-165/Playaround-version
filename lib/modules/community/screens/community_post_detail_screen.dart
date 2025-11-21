import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../routing/routes.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../models/models.dart';
import '../services/community_service.dart';
import '../services/community_user_service.dart';
import '../widgets/community_post_card.dart';

/// Detailed view of a community post with comments
class CommunityPostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const CommunityPostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<CommunityComment> _comments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  Stream<List<CommunityComment>>? _commentsStream;

  @override
  void initState() {
    super.initState();
    _initializeCommentsStream();
  }

  void _initializeCommentsStream() {
    _commentsStream = CommunityService.getCommentsStream(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await CommunityService.getComments(widget.post.id);
      setState(() {
        _comments.clear();
        _comments.addAll(comments);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ColorsManager.background,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsManager.primary.withValues(alpha: 0.9),
              ColorsManager.secondary.withValues(alpha: 0.8),
              ColorsManager.background,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.forum,
              color: Colors.white,
              size: 20.w,
            ),
          ),
          Gap(12.w),
          Text(
            'Post Details',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              // TODO: Implement share functionality
            },
            icon: Icon(
              Icons.share_outlined,
              color: Colors.white,
              size: 20.w,
            ),
            padding: EdgeInsets.all(8.w),
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              // TODO: Implement more options
            },
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 20.w,
            ),
            padding: EdgeInsets.all(8.w),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post card
          CommunityPostCard(
            post: widget.post,
            onTap: () {}, // Already on detail screen
            onLike: _handleLike,
            onComment: () {}, // Already on detail screen
            onUserTap: _navigateToUserProfile,
          ),
          Gap(24.h),

          // Comments section
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManager.surfaceVariant.withValues(alpha: 0.1),
            ColorsManager.background,
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: StreamBuilder<List<CommunityComment>>(
        stream: _commentsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ Comments stream error: ${snapshot.error}');
          }

          if (snapshot.hasData) {
            print('📝 Comments received: ${snapshot.data!.length} comments');
            for (var comment in snapshot.data!) {
              print(
                  '  - Comment: ${comment.content} by ${comment.authorNickname}');
            }
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommentsHeader(0),
                  Gap(16.h),
                  _buildLoadingIndicator(),
                ],
              ),
            );
          }

          final comments = snapshot.data ?? [];

          return Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentsHeader(comments.length),
                Gap(20.h),
                if (comments.isEmpty)
                  _buildEmptyComments()
                else
                  _buildCommentsListFromData(comments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentsHeader(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.primary.withValues(alpha: 0.1),
            ColorsManager.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            color: ColorsManager.primary,
            size: 20.w,
          ),
          Gap(8.w),
          Text(
            'Comments ($count)',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              count.toString(),
              style: AppTypography.labelMedium.copyWith(
                color: ColorsManager.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: ColorsManager.primary),
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.surfaceVariant.withValues(alpha: 0.1),
            ColorsManager.surfaceVariant.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ColorsManager.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorsManager.primary.withValues(alpha: 0.1),
                  ColorsManager.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.sports_esports,
              size: 60.w,
              color: ColorsManager.primary,
            ),
          ),
          Gap(20.h),
          Text(
            'No comments yet',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(8.h),
          Text(
            'Be the first to share your thoughts!',
            style: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: _buildCommentCard(comment),
        );
      },
    );
  }

  Widget _buildCommentsListFromData(List<CommunityComment> comments) {
    final sortedComments = List<CommunityComment>.from(comments)
      ..sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedComments.length,
      itemBuilder: (context, index) {
        final comment = sortedComments[index];
        return _buildCommentCard(comment);
      },
    );
  }

  Widget _buildCommentCard(CommunityComment comment) {
    final VoidCallback? onAuthorTap = comment.authorId.isNotEmpty
        ? () => _openCommentAuthorProfile(comment.authorId)
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.surface,
            ColorsManager.surfaceVariant.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorsManager.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
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
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ColorsManager.primaryGradient,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: ColorsManager.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 18.r,
                      backgroundColor: Colors.transparent,
                      backgroundImage: comment.authorProfilePicture != null
                          ? NetworkImage(comment.authorProfilePicture!)
                          : null,
                      child: comment.authorProfilePicture == null
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: ColorsManager.primaryGradient,
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                              child: Center(
                                child: Text(
                                  comment.authorNickname.isNotEmpty
                                      ? comment.authorNickname[0].toUpperCase()
                                      : 'U',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onAuthorTap,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Text(
                              comment.authorNickname,
                              style: AppTypography.labelLarge.copyWith(
                                color: ColorsManager.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Gap(8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color:
                                    ColorsManager.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
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
                      Gap(2.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: ColorsManager.onSurfaceVariant,
                            size: 12.w,
                          ),
                          Gap(4.w),
                          Text(
                            'Just now', // TODO: Format time
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
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Implement reply functionality
                    },
                    icon: Icon(
                      Icons.reply,
                      color: ColorsManager.onSurfaceVariant,
                      size: 16.w,
                    ),
                    padding: EdgeInsets.all(6.w),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              comment.content,
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurface,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManager.surfaceVariant.withValues(alpha: 0.1),
            ColorsManager.surface,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ColorsManager.primaryGradient,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: ColorsManager.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: Colors.transparent,
              child: Text(
                'U', // TODO: Get user initial
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Gap(16.w),
          Expanded(
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
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: ColorsManager.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorsManager.primary.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(
                      color: ColorsManager.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: ColorsManager.onSurface,
                  fontWeight: FontWeight.w400,
                ),
                onChanged: (value) {
                  setState(() {}); // Rebuild to update send button
                },
              ),
            ),
          ),
          Gap(12.w),
          Container(
            decoration: BoxDecoration(
              gradient: _commentController.text.trim().isEmpty || _isSubmitting
                  ? LinearGradient(
                      colors: [
                        ColorsManager.surfaceVariant.withValues(alpha: 0.5),
                        ColorsManager.surfaceVariant.withValues(alpha: 0.3),
                      ],
                    )
                  : ColorsManager.primaryGradient,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow:
                  _commentController.text.trim().isNotEmpty && !_isSubmitting
                      ? [
                          BoxShadow(
                            color: ColorsManager.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
            ),
            child: IconButton(
              onPressed: _commentController.text.trim().isEmpty || _isSubmitting
                  ? null
                  : _submitComment,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: _commentController.text.trim().isEmpty
                          ? ColorsManager.onSurfaceVariant
                          : Colors.white,
                      size: 20.w,
                    ),
              padding: EdgeInsets.all(12.w),
            ),
          ),
        ],
      ),
    );
  }

  // Action handlers
  Future<void> _handleLike(bool isLike) async {
    try {
      // TODO: Implement like functionality
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to ${isLike ? 'like' : 'dislike'} post: $e')),
        );
      }
    }
  }

  void _navigateToUserProfile() {
    final authorId = widget.post.authorId;
    if (authorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open profile for this user.')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.communityUserProfile,
      arguments: authorId,
    );
  }

  void _openCommentAuthorProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.pushNamed(
      context,
      Routes.communityUserProfile,
      arguments: userId,
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userNickname = await CommunityUserService.getCurrentUserNickname();
      final userProfilePicture =
          await CommunityUserService.getCurrentUserProfilePicture();

      print('🔄 Submitting comment for post: ${widget.post.id}');
      print('👤 User: $userNickname');
      print('💬 Content: ${_commentController.text.trim()}');

      await CommunityService.addComment(
        postId: widget.post.id,
        content: _commentController.text.trim(),
        authorNickname: userNickname,
        authorProfilePicture: userProfilePicture,
      );

      print('✅ Comment submitted successfully');
      _commentController.clear();
      // Comments will update automatically via stream
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
