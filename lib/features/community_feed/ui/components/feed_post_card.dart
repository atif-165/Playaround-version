import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../theming/colors.dart';
import '../../../community_feed/models/feed_post.dart';
import '../../../community_feed/models/feed_media.dart';
import '../../../community_feed/models/user_post_state.dart';

class FeedPostCard extends HookWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onUpvote,
    this.onDownvote,
    this.onComment,
    this.onSave,
    this.onShare,
    this.onAuthorTap,
    this.expanded = false,
  });

  final FeedPost post;
  final VoidCallback? onTap;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onAuthorTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final revealSensitive = useState(false);
    final flagged = post.isFlagged && !revealSensitive.value;
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: expanded ? 20 : 16,
        vertical: expanded ? 16 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ColorsManager.surfaceVariant.withOpacity(0.6),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: onTap != null
            ? ColorsManager.primary.withOpacity(0.12)
            : Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PostHeader(
                post: post,
                onAuthorTap: onAuthorTap,
              ),
              if (post.title != null && post.title!.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    post.title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ColorsManager.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              if (post.body != null && post.body!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    post.body!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ColorsManager.textSecondary,
                      height: 1.45,
                    ),
                    maxLines: expanded ? null : 4,
                    overflow:
                        expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                ),
              if (post.media.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _MediaPreview(
                    post: post,
                    flagged: flagged,
                    onReveal: () => revealSensitive.value = true,
                  ),
                ),
              if (post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: post.tags
                        .map(
                          (tag) => Chip(
                            label: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: ColorsManager.textSecondary,
                              ),
                            ),
                            backgroundColor:
                                Colors.white.withOpacity(0.06),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (post.isFlagged)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _FlagBadge(
                    nsfw: post.nsfw,
                    spoiler: post.spoiler,
                    sensitive: post.sensitive,
                    flagged: flagged,
                    onReveal: () => revealSensitive.value = true,
                  ),
                ),
              const Gap(12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _PostActions(
                  post: post,
                  onUpvote: onUpvote,
                  onDownvote: onDownvote,
                  onComment: onComment,
                  onSave: onSave,
                  onShare: onShare,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    this.onAuthorTap,
  });

  final FeedPost post;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.08),
            backgroundImage: post.authorAvatarUrl != null &&
                    post.authorAvatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                    as ImageProvider
                : null,
            child: post.authorAvatarUrl == null
                ? Text(
                    post.authorDisplayName.isNotEmpty
                        ? post.authorDisplayName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ColorsManager.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
            ),
          ),
          const Gap(12),
          Expanded(
            child: GestureDetector(
              onTap: onAuthorTap,
              behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorDisplayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ColorsManager.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'u/${post.authorUsername}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorsManager.textSecondary,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Text(
                      '• ${timeago.format(post.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorsManager.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
          if (post.isPinned)
            Icon(
              Icons.push_pin,
              size: 18,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.post,
    required this.flagged,
    required this.onReveal,
  });

  final FeedPost post;
  final bool flagged;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final media = post.media.first;
    final isImageLike =
        media.type == FeedMediaType.image || media.type == FeedMediaType.gif;
    final heroTag = 'feed-post-media-${post.id}';
    final aspectRatio = media.width > 0 && media.height > 0
        ? media.width / media.height
        : 16 / 9;

    Widget child;
    if (isImageLike) {
      child = CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: ColorsManager.surfaceVariant.withOpacity(0.25),
        ),
        errorWidget: (context, url, error) => Container(
          color: ColorsManager.surfaceVariant.withOpacity(0.25),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: ColorsManager.textSecondary,
          ),
        ),
      );
    } else {
      child = Stack(
        fit: StackFit.expand,
        children: [
          if (media.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: media.thumbnailUrl!,
              fit: BoxFit.cover,
            )
          else
            Container(
              color: ColorsManager.surfaceVariant.withOpacity(0.25),
            ),
          Align(
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: !flagged && isImageLike
            ? () => _openFullScreenImage(context, media.url, heroTag)
            : null,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isImageLike)
                Hero(
                  tag: heroTag,
                  child: child,
                )
              else
                child,
              if (flagged)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: onReveal,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Reveal sensitive content'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreenImage(
    BuildContext context,
    String imageUrl,
    String heroTag,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          imageUrl: imageUrl,
          heroTag: heroTag,
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({
    required this.nsfw,
    required this.spoiler,
    required this.sensitive,
    required this.flagged,
    required this.onReveal,
  });

  final bool nsfw;
  final bool spoiler;
  final bool sensitive;
  final bool flagged;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final flags = <String>[];
    if (nsfw) flags.add('NSFW');
    if (spoiler) flags.add('Spoiler');
    if (sensitive) flags.add('Sensitive');
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.shield,
          size: 18,
          color: theme.colorScheme.error,
        ),
        const Gap(8),
        Expanded(
          child: Text(
            '${flags.join(' • ')} content',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (flagged)
          TextButton(
            onPressed: onReveal,
            child: const Text('Reveal'),
          ),
      ],
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    this.onUpvote,
    this.onDownvote,
    this.onComment,
    this.onSave,
    this.onShare,
  });

  final FeedPost post;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final vote = post.safeUserVote;
    final isUpvoted = vote == UserVoteValue.upvote;
    final isDownvoted = vote == UserVoteValue.downvote;
    final isSaved = post.safeIsSaved;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionChip(
            icon: Icons.arrow_upward,
            label: '${post.score}',
            onTap: onUpvote,
            isActive: isUpvoted,
            activeColor: ColorsManager.primary,
          ),
          _ActionChip(
            icon: Icons.arrow_downward,
            label: '',
            onTap: onDownvote,
            isActive: isDownvoted,
            activeColor: ColorsManager.error,
          ),
          _ActionChip(
            icon: Icons.mode_comment_outlined,
            label: '${post.commentCount}',
            onTap: onComment,
          ),
          _ActionChip(
            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
            label: '',
            onTap: onSave,
            isActive: isSaved,
            activeColor: ColorsManager.primary,
          ),
          _ActionChip(
            icon: Icons.ios_share,
            label: '',
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? (activeColor ?? ColorsManager.primary) : ColorsManager.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            if (label.isNotEmpty) ...[
              const Gap(6),
              Text(
                label,
                style: const TextStyle(
                  color: ColorsManager.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

