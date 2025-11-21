import 'feed_media.dart';
import 'json_converters.dart';

class FeedComment {
  const FeedComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorDisplayName,
    required this.authorUsername,
    this.authorAvatarUrl,
    this.parentId,
    this.media = const <FeedMedia>[],
    required this.body,
    this.mentions = const <String>[],
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.isModerator = false,
    this.nsfw = false,
    this.upvotes = 0,
    this.downvotes = 0,
    this.replyCount = 0,
    this.depth = 0,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorDisplayName;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String? parentId;
  final List<FeedMedia> media;
  final String body;
  final List<String> mentions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final bool isModerator;
  final bool nsfw;
  final int upvotes;
  final int downvotes;
  final int replyCount;
  final int depth;
  final Map<String, dynamic> metadata;

  int get score => upvotes - downvotes;

  bool get hasParent => parentId != null && parentId!.isNotEmpty;

  FeedComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorDisplayName,
    String? authorUsername,
    String? authorAvatarUrl,
    String? parentId,
    List<FeedMedia>? media,
    String? body,
    List<String>? mentions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    bool? isModerator,
    bool? nsfw,
    int? upvotes,
    int? downvotes,
    int? replyCount,
    int? depth,
    Map<String, dynamic>? metadata,
  }) {
    return FeedComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      parentId: parentId ?? this.parentId,
      media: media ?? List<FeedMedia>.from(this.media),
      body: body ?? this.body,
      mentions: mentions ?? List<String>.from(this.mentions),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isModerator: isModerator ?? this.isModerator,
      nsfw: nsfw ?? this.nsfw,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      replyCount: replyCount ?? this.replyCount,
      depth: depth ?? this.depth,
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorDisplayName': authorDisplayName,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'parentId': parentId,
      'media': media.map((item) => item.toJson()).toList(),
      'body': body,
      'mentions': mentions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isModerator': isModerator,
      'nsfw': nsfw,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'replyCount': replyCount,
      'depth': depth,
      'metadata': metadata,
    };
  }

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    final timestampConverter = const TimestampConverter();
    final nullableTimestampConverter = const NullableTimestampConverter();
    List<FeedMedia> parseMedia(dynamic data) {
      if (data is List) {
        return data
            .map((value) {
              if (value is Map) {
                return FeedMedia.fromJson(Map<String, dynamic>.from(value));
              }
              if (value is String) {
                return FeedMedia(
                  type: FeedMediaType.image,
                  url: value,
                  isUploaded: true,
                );
              }
              return null;
            })
            .whereType<FeedMedia>()
            .toList();
      }
      return <FeedMedia>[];
    }

    final mediaList = parseMedia(json['media'] ?? json['attachments']);
    if (mediaList.isEmpty) {
      mediaList.addAll(parseMedia(json['images']));
    }

    Map<String, dynamic> parseMetadata(dynamic data) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return const <String, dynamic>{};
    }

    String resolveDisplayName(Map<String, dynamic> data) {
      final display = (data['authorDisplayName'] ??
              data['authorNickname'] ??
              data['authorName'] ??
              '')
          .toString()
          .trim();
      if (display.isNotEmpty) return display;
      final username = data['authorUsername']?.toString().trim();
      if (username != null && username.isNotEmpty) return username;
      return 'User';
    }

    String resolveUsername(Map<String, dynamic> data) {
      final username = (data['authorUsername'] ??
              data['authorNickname'] ??
              data['authorDisplayName'] ??
              data['authorName'] ??
              '')
          .toString()
          .trim();
      if (username.isEmpty) return 'player';
      return username.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    }

    String? resolveAvatar(Map<String, dynamic> data) {
      final avatar =
          data['authorAvatarUrl'] ?? data['authorProfilePicture'] ?? data['avatar'];
      if (avatar is String && avatar.trim().isNotEmpty) return avatar;
      return null;
    }

    String resolveBody(Map<String, dynamic> data) {
      final body = data['body'] ?? data['content'] ?? '';
      return body is String ? body : body.toString();
    }

    int resolveInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return FeedComment(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorDisplayName: resolveDisplayName(json),
      authorUsername: resolveUsername(json),
      authorAvatarUrl: resolveAvatar(json),
      parentId: json['parentId'] as String?,
      media: mediaList,
      body: resolveBody(json),
      mentions: (json['mentions'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const <String>[],
      createdAt: timestampConverter.fromJson(json['createdAt']),
      updatedAt: nullableTimestampConverter.fromJson(json['updatedAt']),
      isEdited: json['isEdited'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      isModerator: json['isModerator'] as bool? ?? false,
      nsfw: json['nsfw'] as bool? ?? false,
      upvotes: resolveInt(json['upvotes'] ?? json['likesCount']),
      downvotes: resolveInt(json['downvotes'] ?? json['dislikesCount']),
      replyCount: resolveInt(json['replyCount'] ?? json['repliesCount']),
      depth: resolveInt(json['depth']),
      metadata: parseMetadata(json['metadata']),
    );
  }
}

