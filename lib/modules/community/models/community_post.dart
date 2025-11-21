import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:playaround/features/community_feed/models/feed_media.dart';
import 'package:playaround/features/community_feed/models/feed_post.dart';
import 'package:playaround/features/community_feed/models/user_post_state.dart';

/// Model representing a community post
class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorNickname;
  final String? authorProfilePicture;
  final String content;
  final List<String> images; // Image URLs
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final int dislikesCount;
  final int commentsCount;
  final int sharesCount;
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final bool isFlagged;
  final List<String> flaggedBy;
  final String? flaggedReason;
  final DateTime? flaggedAt;

  const CommunityPost({
    required this.id,
    required this.authorId,
    this.authorName = '',
    required this.authorNickname,
    this.authorProfilePicture,
    required this.content,
    this.images = const [],
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.metadata,
    this.isActive = true,
    this.isFlagged = false,
    this.flaggedBy = const [],
    this.flaggedReason,
    this.flaggedAt,
  });

  /// Create from Firestore document
  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommunityPost(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorNickname: data['authorNickname'] as String? ?? '',
      authorProfilePicture: data['authorProfilePicture'] as String?,
      content: data['content'] as String? ?? '',
      images: List<String>.from(
          (data['images'] ?? data['imageUrls'] ?? const <String>[]) as List),
      tags: List<String>.from((data['tags'] ?? const <String>[]) as List),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      likesCount: data['likesCount'] as int? ?? 0,
      dislikesCount: data['dislikesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      sharesCount: data['sharesCount'] as int? ?? 0,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : null,
      isActive: data['isActive'] as bool? ?? true,
      isFlagged: data['isFlagged'] as bool? ?? false,
      flaggedBy: List<String>.from(data['flaggedBy'] as List<dynamic>? ?? []),
      flaggedReason: data['flaggedReason'] as String?,
      flaggedAt: data['flaggedAt'] != null
          ? (data['flaggedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorNickname': authorNickname,
      'authorProfilePicture': authorProfilePicture,
      'content': content,
      'images': images,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'likesCount': likesCount,
      'dislikesCount': dislikesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'metadata': metadata,
      'isActive': isActive,
      'isFlagged': isFlagged,
      'flaggedBy': flaggedBy,
      'flaggedReason': flaggedReason,
      'flaggedAt': flaggedAt != null ? Timestamp.fromDate(flaggedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  CommunityPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorNickname,
    String? authorProfilePicture,
    String? content,
    List<String>? images,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? dislikesCount,
    int? commentsCount,
    int? sharesCount,
    Map<String, dynamic>? metadata,
    bool? isActive,
    bool? isFlagged,
    List<String>? flaggedBy,
    String? flaggedReason,
    DateTime? flaggedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorNickname: authorNickname ?? this.authorNickname,
      authorProfilePicture: authorProfilePicture ?? this.authorProfilePicture,
      content: content ?? this.content,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      isFlagged: isFlagged ?? this.isFlagged,
      flaggedBy: flaggedBy ?? this.flaggedBy,
      flaggedReason: flaggedReason ?? this.flaggedReason,
      flaggedAt: flaggedAt ?? this.flaggedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommunityPost(id: $id, authorName: $authorName, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
  }
}

extension CommunityPostFeedMapper on CommunityPost {
  FeedPost toFeedPost() {
    final mediaList = images
        .map(
          (url) => FeedMedia(
            type: FeedMediaType.image,
            url: url,
            isUploaded: true,
          ),
        )
        .toList();

    final metadataCopy =
        metadata != null ? Map<String, dynamic>.from(metadata!) : <String, dynamic>{};

    bool _flag(String key) {
      final value = metadataCopy[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return false;
    }

    return FeedPost(
      id: id,
      authorId: authorId,
      authorDisplayName: authorName.isNotEmpty ? authorName : authorNickname,
      authorUsername: authorNickname,
      authorAvatarUrl: authorProfilePicture,
      body: content,
      type: mediaList.isNotEmpty ? FeedPostType.image : FeedPostType.text,
      media: mediaList,
      tags: tags,
      primarySport: tags.isNotEmpty ? tags.first : null,
      nsfw: _flag('nsfw'),
      spoiler: _flag('spoiler'),
      sensitive: isFlagged,
      locked: _flag('locked'),
      archived: !isActive,
      isPinned: _flag('pinned'),
      isActive: isActive,
      metadata: metadataCopy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      upvotes: likesCount,
      downvotes: dislikesCount,
      score: likesCount - dislikesCount,
      commentCount: commentsCount,
      shareCount: sharesCount,
      lastActivityAt: updatedAt ?? createdAt,
      reportsCount: flaggedBy.length,
      userVote: UserVoteValue.none,
      isSaved: false,
    );
  }
}
