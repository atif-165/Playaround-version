import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../../../routing/routes.dart';
import '../models/models.dart';
import '../services/community_service.dart';
import '../services/community_user_service.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_loading_shimmer.dart';

/// Main community forum screen with Reddit-like interface
class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<CommunityPost> _posts = [];
  final Map<String, UserLikeStatus> _likeStatuses = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  Stream<List<CommunityPost>>? _postsStream;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  List<String> _activeTags = [];

  @override
  void initState() {
    super.initState();
    _initializePostsStream();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  void _initializePostsStream() {
    _postsStream = CommunityService.getPostsStream();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final page = await CommunityService.fetchPostsPage(
        limit: 20,
        tags: _activeTags.isEmpty ? null : _activeTags,
      );
      await _loadLikeStatuses(page.posts);
      setState(() {
        _posts.clear();
        _posts.addAll(page.posts);
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = await CommunityService.fetchPostsPage(
        limit: 20,
        startAfter: _lastDocument,
        tags: _activeTags.isEmpty ? null : _activeTags,
      );
      await _loadLikeStatuses(page.posts);

      setState(() {
        _posts.addAll(page.posts);
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more posts: $e')),
        );
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadInitialPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community',
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(4.h),
                Text(
                  'Share your sports journey',
                  style: AppTypography.bodyMedium.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _navigateToShop,
                icon: Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 24.w,
                ),
                tooltip: 'Shop',
              ),
              IconButton(
                onPressed: _refreshPosts,
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 24.w,
                ),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _posts.isEmpty) {
      return const CommunityLoadingShimmer();
    }

    if (_error != null && _posts.isEmpty) {
      return _buildErrorState();
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: ColorsManager.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return _buildLoadingIndicator();
          }

          final post = _posts[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: CommunityPostCard(
              post: post,
              onTap: () => _navigateToPostDetail(post),
              onLike: (isLike) => _handleLike(post, isLike),
              onComment: () => _navigateToPostDetail(post),
              onUserTap: () => _navigateToUserProfile(post.authorId),
              onMoreOptions: () => _handleMoreOptions(post),
              hasLiked: _likeStatuses[post.id]?.hasLiked,
              hasDisliked: _likeStatuses[post.id]?.hasDisliked,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80.w,
              color: ColorsManager.error,
            ),
            Gap(16.h),
            Text(
              'Something went wrong',
              style: AppTypography.headlineSmall.copyWith(
                color: ColorsManager.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              _error ?? 'Failed to load posts',
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            AppFilledButton(
              text: 'Try Again',
              onPressed: _refreshPosts,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 80.w,
              color: ColorsManager.onSurfaceVariant,
            ),
            Gap(16.h),
            Text(
              'Welcome to the Community!',
              style: AppTypography.headlineSmall.copyWith(
                color: ColorsManager.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'Be the first to share your sports story',
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            AppFilledButton(
              text: 'Create First Post',
              onPressed: _navigateToCreatePost,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_isLoadingMore) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: const Center(
        child: CircularProgressIndicator(
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToShop() {
    Navigator.pushNamed(context, Routes.shopMap);
  }

  Future<void> _navigateToCreatePost() async {
    final result =
        await Navigator.pushNamed(context, Routes.communityCreatePost);
    if (result == true) {
      await _refreshPosts();
    }
  }

  void _navigateToPostDetail(CommunityPost post) {
    Navigator.pushNamed(
      context,
      Routes.communityPostDetail,
      arguments: post,
    );
  }

  void _navigateToUserProfile(String userId) {
    Navigator.pushNamed(
      context,
      Routes.profileScreen,
      arguments: userId,
    );
  }

  // Load like statuses for posts
  Future<void> _loadLikeStatuses(List<CommunityPost> posts) async {
    for (final post in posts) {
      try {
        final likeStatus = await CommunityService.getUserLikeStatus(post.id);
        _likeStatuses[post.id] = likeStatus;
      } catch (e) {
        // If error loading like status, set to default
        _likeStatuses[post.id] = UserLikeStatus(
          hasLiked: false,
          hasDisliked: false,
          likeId: null,
        );
      }
    }
  }

  // Action handlers
  Future<void> _handleLike(CommunityPost post, bool isLike) async {
    try {
      final userNickname = await CommunityUserService.getCurrentUserNickname();
      final newStatus =
          await CommunityService.toggleLike(post.id, isLike, userNickname);

      // Update local like status
      setState(() {
        _likeStatuses[post.id] = newStatus;
      });

      // Refresh the specific post or update locally
      _refreshPosts();
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

  void _handleMoreOptions(CommunityPost post) {
    final isOwner = CommunityUserService.isCurrentUserPostOwner(post.authorId);

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsManager.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: Icon(Icons.delete, color: ColorsManager.error),
                title: Text(
                  'Delete Post',
                  style: AppTypography.bodyLarge.copyWith(
                    color: ColorsManager.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(post);
                },
              ),
            ],
            ListTile(
              leading:
                  Icon(Icons.report, color: ColorsManager.onSurfaceVariant),
              title: Text(
                'Report Post',
                style: AppTypography.bodyLarge.copyWith(
                  color: ColorsManager.onSurface,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please sign in to report posts')),
                    );
                  }
                  return;
                }
                try {
                  await CommunityService.flagPost(
                    postId: post.id,
                    userId: userId,
                    reason: 'Flagged by community member',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post reported for review')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to report post: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsManager.surface,
        title: Text(
          'Delete Post',
          style: AppTypography.headlineSmall.copyWith(
            color: ColorsManager.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTypography.labelLarge.copyWith(
                color: ColorsManager.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CommunityService.deletePost(post.id);
        _refreshPosts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }
}
