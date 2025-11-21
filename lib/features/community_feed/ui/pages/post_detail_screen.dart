import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../theming/colors.dart';
import '../../../../routing/routes.dart';
import '../../models/feed_comment.dart';
import '../../models/feed_post.dart';
import '../../models/user_post_state.dart';
import '../../state/feed_controller.dart';
import '../../state/post_detail_providers.dart';
import '../components/feed_post_card.dart';

class PostDetailScreen extends HookConsumerWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
    this.focusCommentInput = false,
  });

  final String postId;
  final FeedPost? initialPost;
  final bool focusCommentInput;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(feedPostDetailProvider(postId));
    final commentsAsync = ref.watch(feedPostCommentsProvider(postId));
    final feedController = ref.read(feedControllerProvider.notifier);
    final commentController = useTextEditingController();
    final commentFocusNode = useFocusNode();
    final isSubmitting = useState(false);
    final scrollController = useScrollController();

    useEffect(() {
      if (focusCommentInput) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (commentFocusNode.canRequestFocus) {
            commentFocusNode.requestFocus();
          }
        });
      }
      return null;
    }, [focusCommentInput, commentFocusNode]);

    final post = postAsync.value ?? initialPost;

    ref.listen<AsyncValue<FeedPost?>>(
      feedPostDetailProvider(postId),
      (_, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load post: $error'),
              ),
            );
          },
        );
      },
    );

    ref.listen<AsyncValue<List<FeedComment>>>(
      feedPostCommentsProvider(postId),
      (_, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load comments: $error'),
              ),
            );
          },
        );
      },
    );

    Future<void> submitComment() async {
      final text = commentController.text.trim();
      if (text.isEmpty || post == null) return;

      isSubmitting.value = true;
      try {
        await feedController.addComment(
          post: post,
          content: text,
        );
        commentController.clear();
        if (scrollController.hasClients) {
          await scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add comment: $error'),
            ),
          );
        }
      } finally {
        if (context.mounted) {
          isSubmitting.value = false;
        }
      }
    }

    void focusCommentField() {
      if (commentFocusNode.canRequestFocus) {
        commentFocusNode.requestFocus();
      }
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    Future<void> toggleVote(UserVoteValue vote) async {
      final currentPost = post;
      if (currentPost == null) return;
      await feedController.toggleVote(currentPost, vote: vote);
    }

    Future<void> toggleSave() async {
      final currentPost = post;
      if (currentPost == null) return;
      await feedController.toggleSave(currentPost);
    }

    if (post == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF050414),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ColorsManager.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050414),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Post',
          style: TextStyle(
            color: ColorsManager.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: ColorsManager.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.mode_comment_outlined),
            onPressed: focusCommentField,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: FeedPostCard(
                      post: post,
                      expanded: true,
                      onTap: null,
                      onAuthorTap: () => _openPublicProfile(context, post),
                      onUpvote: () => toggleVote(UserVoteValue.upvote),
                      onDownvote: () => toggleVote(UserVoteValue.downvote),
                      onComment: focusCommentField,
                      onSave: toggleSave,
                      onShare: () => _showShareUnavailable(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CommentsSection(
                        commentsAsync: commentsAsync,
                        onAuthorTap: (comment) =>
                            _openCommentAuthorProfile(context, comment),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            ),
            _CommentComposer(
              controller: commentController,
              focusNode: commentFocusNode,
              isSubmitting: isSubmitting.value,
              onSubmitted: submitComment,
            ),
          ],
        ),
      ),
    );
  }

  void _openPublicProfile(BuildContext context, FeedPost post) {
    Navigator.of(context).pushNamed(
      Routes.communityUserProfile,
      arguments: post.authorId,
    );
  }

  void _openCommentAuthorProfile(
    BuildContext context,
    FeedComment comment,
  ) {
    if (comment.authorId.isEmpty) return;
    Navigator.of(context).pushNamed(
      Routes.communityUserProfile,
      arguments: comment.authorId,
    );
  }

  void _showShareUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing from the detail view is coming soon.'),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.commentsAsync,
    required this.onAuthorTap,
  });

  final AsyncValue<List<FeedComment>> commentsAsync;
  final void Function(FeedComment comment) onAuthorTap;

  @override
  Widget build(BuildContext context) {
    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) {
          return const _EmptyComments();
        }
        final sortedComments = List<FeedComment>.from(comments)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorsManager.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Gap(12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final comment = sortedComments[index];
                return _CommentTile(
                  comment: comment,
                  onAuthorTap: () => onAuthorTap(comment),
                );
              },
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemCount: sortedComments.length,
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: ColorsManager.primary),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorsManager.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorsManager.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Failed to load comments: $error',
                style: const TextStyle(
                  color: ColorsManager.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Comments',
          style: TextStyle(
            color: ColorsManager.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        Gap(12),
        Text(
          'Be the first to share your thoughts.',
          style: TextStyle(
            color: ColorsManager.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onAuthorTap,
  });

  final FeedComment comment;
  final VoidCallback onAuthorTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onAuthorTap,
          behavior: HitTestBehavior.opaque,
          child: CircleAvatar(
            radius: 18,
            backgroundImage: comment.authorAvatarUrl != null
                ? NetworkImage(comment.authorAvatarUrl!)
                : null,
            backgroundColor: ColorsManager.surfaceVariant.withOpacity(0.3),
            child: comment.authorAvatarUrl == null
                ? Text(
                    comment.authorDisplayName.isNotEmpty
                        ? comment.authorDisplayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: ColorsManager.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onAuthorTap,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        comment.authorDisplayName,
                        style: const TextStyle(
                          color: ColorsManager.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    timeago.format(comment.createdAt),
                    style: const TextStyle(
                      color: ColorsManager.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Text(
                comment.body,
                style: const TextStyle(
                  color: ColorsManager.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentComposer extends HookWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final canSubmit = currentUser != null && !isSubmitting;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A1E),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: currentUser == null
                    ? 'Sign in to add a comment'
                    : 'Add a comment...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              enabled: currentUser != null && !isSubmitting,
            ),
          ),
          const Gap(12),
          ElevatedButton(
            onPressed: canSubmit ? onSubmitted : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
              shape: const CircleBorder(),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 18),
          ),
        ],
      ),
    );
  }
}

