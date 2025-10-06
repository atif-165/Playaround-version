import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';

/// Widget for tournament comments and engagement
class TournamentComments extends StatefulWidget {
  final Tournament tournament;
  final Function(String)? onCommentAdded;

  const TournamentComments({
    super.key,
    required this.tournament,
    this.onCommentAdded,
  });

  @override
  State<TournamentComments> createState() => _TournamentCommentsState();
}

class _TournamentCommentsState extends State<TournamentComments> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<TournamentComment> _comments = [];
  bool _isLoading = false;
  bool _isPosting = false;
  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load comments from service
      // For now, simulate loading
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _comments = [
          // Mock comments
          TournamentComment(
            id: '1',
            tournamentId: widget.tournament.id,
            userId: 'user1',
            userName: 'John Doe',
            userImageUrl: null,
            content: 'Great tournament! Looking forward to participating.',
            likes: 5,
            replies: 2,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            isLiked: false,
          ),
          TournamentComment(
            id: '2',
            tournamentId: widget.tournament.id,
            userId: 'user2',
            userName: 'Sarah Wilson',
            userImageUrl: null,
            content: 'What time does registration close?',
            likes: 3,
            replies: 1,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            isLiked: true,
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCommentInput(),
        Gap(16.h),
        _buildCommentsList(),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundImage: _currentUserProfile?.photoURL != null
                    ? NetworkImage(_currentUserProfile!.photoURL!)
                    : null,
                child: _currentUserProfile?.photoURL == null
                    ? Icon(
                        Icons.person,
                        size: 16.sp,
                        color: ColorsManager.primary,
                      )
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Text(
                  _currentUserProfile?.displayName ?? 'Anonymous',
                  style: TextStyles.font14DarkBlueMedium,
                ),
              ),
            ],
          ),
          Gap(12.h),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your thoughts about this tournament...',
              hintStyle: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: ColorsManager.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: ColorsManager.primary),
              ),
            ),
          ),
          Gap(12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearComment,
                child: Text(
                  'Cancel',
                  style: TextStyles.font14Grey400Weight.copyWith(
                    color: ColorsManager.textSecondary,
                  ),
                ),
              ),
              Gap(8.w),
              ElevatedButton(
                onPressed: _canPostComment() ? _postComment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                ),
                child: _isPosting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
        ),
      );
    }

    if (_comments.isEmpty) {
      return _buildEmptyComments();
    }

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentCard(comment);
      },
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48.sp,
            color: ColorsManager.textSecondary,
          ),
          Gap(16.h),
          Text(
            'No Comments Yet',
            style: TextStyles.font16DarkBlueBold.copyWith(
              color: ColorsManager.textPrimary,
            ),
          ),
          Gap(8.h),
          Text(
            'Be the first to share your thoughts!',
            style: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(TournamentComment comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16.r,
                    backgroundImage: comment.userImageUrl != null
                        ? NetworkImage(comment.userImageUrl!)
                        : null,
                    child: comment.userImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 16.sp,
                            color: ColorsManager.primary,
                          )
                        : null,
                  ),
                  Gap(12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.userName,
                          style: TextStyles.font14DarkBlueMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy at HH:mm').format(comment.createdAt),
                          style: TextStyles.font12Grey400Weight.copyWith(
                            color: ColorsManager.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 16.sp,
                      color: ColorsManager.textSecondary,
                    ),
                    itemBuilder: (context) => [
                      if (comment.userId == _currentUserProfile?.uid) ...[
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16.sp, color: ColorsManager.primary),
                              Gap(8.w),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16.sp, color: ColorsManager.error),
                              Gap(8.w),
                              const Text('Delete'),
                            ],
                          ),
                        ),
                      ] else ...[
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, size: 16.sp, color: ColorsManager.warning),
                              Gap(8.w),
                              const Text('Report'),
                            ],
                          ),
                        ),
                      ],
                    ],
                    onSelected: (value) => _handleCommentAction(value, comment),
                  ),
                ],
              ),
              Gap(12.h),
              Text(
                comment.content,
                style: TextStyles.font14DarkBlueMedium,
              ),
              Gap(12.h),
              Row(
                children: [
                  _buildActionButton(
                    icon: comment.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${comment.likes}',
                    isActive: comment.isLiked,
                    onTap: () => _toggleLike(comment),
                  ),
                  Gap(16.w),
                  _buildActionButton(
                    icon: Icons.reply,
                    label: 'Reply',
                    onTap: () => _replyToComment(comment),
                  ),
                  Gap(16.w),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () => _shareComment(comment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isActive ? ColorsManager.primary : ColorsManager.textSecondary,
            ),
            Gap(4.w),
            Text(
              label,
              style: TextStyles.font12Grey400Weight.copyWith(
                color: isActive ? ColorsManager.primary : ColorsManager.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canPostComment() {
    return _commentController.text.trim().isNotEmpty && !_isPosting;
  }

  void _clearComment() {
    _commentController.clear();
  }

  Future<void> _postComment() async {
    if (!_canPostComment()) return;

    setState(() {
      _isPosting = true;
    });

    try {
      // TODO: Post comment to service
      await Future.delayed(const Duration(seconds: 1));

      final newComment = TournamentComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tournamentId: widget.tournament.id,
        userId: _currentUserProfile?.uid ?? 'anonymous',
        userName: _currentUserProfile?.displayName ?? 'Anonymous',
        userImageUrl: _currentUserProfile?.photoURL,
        content: _commentController.text.trim(),
        likes: 0,
        replies: 0,
        createdAt: DateTime.now(),
        isLiked: false,
      );

      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });

      widget.onCommentAdded?.call(newComment.content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted successfully!'),
            backgroundColor: ColorsManager.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: ${e.toString()}'),
            backgroundColor: ColorsManager.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _toggleLike(TournamentComment comment) {
    setState(() {
      final index = _comments.indexOf(comment);
      if (index != -1) {
        _comments[index] = TournamentComment(
          id: comment.id,
          tournamentId: comment.tournamentId,
          userId: comment.userId,
          userName: comment.userName,
          userImageUrl: comment.userImageUrl,
          content: comment.content,
          likes: comment.isLiked ? comment.likes - 1 : comment.likes + 1,
          replies: comment.replies,
          createdAt: comment.createdAt,
          isLiked: !comment.isLiked,
        );
      }
    });
  }

  void _replyToComment(TournamentComment comment) {
    // TODO: Implement reply functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reply functionality coming soon!'),
      ),
    );
  }

  void _shareComment(TournamentComment comment) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
      ),
    );
  }

  void _handleCommentAction(String action, TournamentComment comment) {
    switch (action) {
      case 'edit':
        _editComment(comment);
        break;
      case 'delete':
        _deleteComment(comment);
        break;
      case 'report':
        _reportComment(comment);
        break;
    }
  }

  void _editComment(TournamentComment comment) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
      ),
    );
  }

  void _deleteComment(TournamentComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _comments.remove(comment);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reportComment(TournamentComment comment) {
    // TODO: Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report functionality coming soon!'),
      ),
    );
  }
}

/// Tournament comment model
class TournamentComment {
  final String id;
  final String tournamentId;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String content;
  final int likes;
  final int replies;
  final DateTime createdAt;
  final bool isLiked;

  const TournamentComment({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.content,
    required this.likes,
    required this.replies,
    required this.createdAt,
    required this.isLiked,
  });
}
