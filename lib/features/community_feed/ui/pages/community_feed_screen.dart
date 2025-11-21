import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:playaround/modules/chat/models/connection.dart';
import 'package:playaround/modules/chat/services/chat_service.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../routing/routes.dart';
import '../../../../theming/colors.dart';
import '../../models/feed_post.dart';
import '../../models/user_post_state.dart';
import '../../state/feed_controller.dart';
import '../../state/feed_state.dart';
import '../components/feed_post_card.dart';
import 'post_detail_screen.dart';

const _communityBackground = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);

class CommunityFeedScreen extends HookConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedControllerProvider);
    final feedController = ref.read(feedControllerProvider.notifier);
    final scrollController = useScrollController();

    void openPostDetail(
      BuildContext context,
      FeedPost post, {
      bool focusComment = false,
    }) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId: post.id,
            initialPost: post,
            focusCommentInput: focusComment,
          ),
        ),
      );
    }

    void openShareSheet(BuildContext context, FeedPost post) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to share community posts.'),
          ),
        );
        return;
      }

      final chatService = ChatService();
      bool isSharing = false;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: ColorsManager.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.ios_share,
                              color: ColorsManager.primary,
                            ),
                            const Gap(12),
                            const Expanded(
                              child: Text(
                                'Share with a connection',
                                style: TextStyle(
                                  color: ColorsManager.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => navigator.pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<List<Connection>>(
                        stream: chatService.getUserConnections(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorsManager.primary,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Failed to load connections: ${snapshot.error}',
                                style: const TextStyle(
                                  color: ColorsManager.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          final connections =
                              snapshot.data ?? const <Connection>[];

                          if (connections.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No accepted connections yet. Connect with players via matchmaking to share posts.',
                                style: TextStyle(
                                  color: ColorsManager.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          final availableHeight =
                              MediaQuery.of(context).size.height * 0.5;
                          final sheetHeight =
                              availableHeight.clamp(220.0, 420.0).toDouble();

                          return SizedBox(
                            height: sheetHeight,
                            child: ListView.separated(
                              itemCount: connections.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final connection = connections[index];
                                final targetUserId =
                                    connection.getOtherUserId(currentUserId);
                                final targetUserName =
                                    connection.getOtherUserName(currentUserId);
                                final targetImage =
                                    connection.getOtherUserImageUrl(
                                  currentUserId,
                                );
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: targetImage != null
                                        ? NetworkImage(targetImage)
                                        : null,
                                    backgroundColor: ColorsManager.surfaceVariant
                                        .withOpacity(0.4),
                                    child: targetImage == null
                                        ? Text(
                                            targetUserName.isNotEmpty
                                                ? targetUserName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: ColorsManager.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    targetUserName,
                                    style: const TextStyle(
                                      color: ColorsManager.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    connection.status.displayName,
                                    style: const TextStyle(
                                      color: ColorsManager.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: isSharing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: ColorsManager.primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send,
                                          color: ColorsManager.primary,
                                        ),
                                  onTap: isSharing
                                      ? null
                                      : () async {
                                          setModalState(
                                            () => isSharing = true,
                                          );
                                          try {
                                            await feedController.sharePost(
                                              post: post,
                                              connectionUserId: targetUserId,
                                            );
                                            navigator.pop();
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Shared with $targetUserName',
                                                ),
                                              ),
                                            );
                                          } catch (error) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to share post: $error',
                                                ),
                                              ),
                                            );
                                          } finally {
                                            if (context.mounted) {
                                              setModalState(
                                                () => isSharing = false,
                                              );
                                            }
                                          }
                                        },
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const Gap(12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;
        final position = scrollController.position;
        if (position.pixels >= position.maxScrollExtent - 560) {
          feedController.fetchNextPage();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, feedController]);

    final theme = Theme.of(context);

    void openShop() {
      Navigator.of(context).pushNamed(Routes.shopMap);
    }

    void openNotifications() {
      Navigator.of(context).pushNamed(Routes.notifications);
    }

    void openChat() {
      Navigator.of(context).pushNamed(Routes.chatListScreen);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050414),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 16,
        title: const Text(
          'Community',
          style: TextStyle(
            color: ColorsManager.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Shop',
            icon: const Icon(Icons.storefront_outlined),
            color: ColorsManager.textSecondary,
            onPressed: openShop,
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            color: ColorsManager.textSecondary,
            onPressed: openNotifications,
          ),
          IconButton(
            tooltip: 'Chat',
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            color: ColorsManager.textSecondary,
            onPressed: openChat,
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _communityBackground),
            ),
          ),
          RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () => feedController.refresh(),
            child: SafeArea(
              top: false,
              child: _FeedBody(
                controller: scrollController,
                state: feedState,
                feedController: feedController,
                onOpenPostDetail: openPostDetail,
                onOpenShareSheet: openShareSheet,
                onRetry: () => feedController.refresh(silent: false),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community-feed-fab',
        onPressed: () {
          // TODO: navigate to post composer
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FeedBody extends StatelessWidget {
  const _FeedBody({
    required this.controller,
    required this.state,
    required this.feedController,
    required this.onOpenPostDetail,
    required this.onOpenShareSheet,
    required this.onRetry,
  });

  final ScrollController controller;
  final FeedState state;
  final FeedController feedController;
  final void Function(
    BuildContext context,
    FeedPost post, {
    bool focusComment,
  }) onOpenPostDetail;
  final void Function(BuildContext context, FeedPost post) onOpenShareSheet;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.posts.isEmpty) {
      return const _FeedLoading();
    }

    if (state.hasError && state.posts.isEmpty) {
      return _FeedError(
        message: state.errorMessage ?? 'Something went wrong',
        onRetry: onRetry,
      );
    }

    if (state.posts.isEmpty) {
      return const _FeedEmpty();
    }

    final posts = state.posts;

    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(height: kToolbarHeight + 24),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= posts.length) {
                return const SizedBox.shrink();
              }
              final post = posts[index];
              return FeedPostCard(
                post: post,
                onTap: () => onOpenPostDetail(context, post),
                onUpvote: () => feedController.toggleVote(
                  post,
                  vote: UserVoteValue.upvote,
                ),
                onDownvote: () => feedController.toggleVote(
                  post,
                  vote: UserVoteValue.downvote,
                ),
                onComment: () =>
                    onOpenPostDetail(context, post, focusComment: true),
                onSave: () => feedController.toggleSave(post),
                onShare: () => onOpenShareSheet(context, post),
                onAuthorTap: () => onOpenPostDetail(context, post),
              );
            },
            childCount: posts.length,
          ),
        ),
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: state.hasMore
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: state.isLoadingMore
                          ? CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : const SizedBox.shrink(),
                    ),
                  )
                : const SizedBox(height: 32),
          ),
        ),
        if (state.hasError && state.posts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _InlineError(
                message: state.errorMessage!,
                onRetry: onRetry,
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const _FeedSkeleton();
      },
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Shimmer.fromColors(
        baseColor: ColorsManager.shimmerBase,
        highlightColor: ColorsManager.shimmerHighlight,
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: ColorsManager.surfaceVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 48,
              color: ColorsManager.error,
            ),
            const Gap(16),
            const Text(
              'Failed to load feed',
              style: TextStyle(
                color: ColorsManager.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              message,
              style: const TextStyle(
                color: ColorsManager.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.sports_soccer,
              size: 48,
              color: ColorsManager.primary,
            ),
            Gap(16),
            Text(
              'No posts yet',
              style: TextStyle(
                color: ColorsManager.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8),
            Text(
              'Be the first to share your sports story.',
              style: TextStyle(
                color: ColorsManager.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.errorContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.error.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: ColorsManager.onErrorContainer,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ColorsManager.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

