import 'feed_media.dart';
import 'json_converters.dart';
import 'user_post_state.dart';

enum FeedPostType {
  text,
  link,
  image,
  video,
  gif,
  poll,
}

extension FeedPostTypeX on FeedPostType {
  bool get supportsMedia =>
      this == FeedPostType.image ||
      this == FeedPostType.video ||
      this == FeedPostType.gif;

  bool get supportsLinkPreview => this == FeedPostType.link;

  bool get supportsPoll => this == FeedPostType.poll;
}

class FeedLinkPreview {
  const FeedLinkPreview({
    required this.url,
    this.title,
    this.description,
    this.siteName,
    this.imageUrl,
    this.faviconUrl,
  });

  final String url;
  final String? title;
  final String? description;
  final String? siteName;
  final String? imageUrl;
  final String? faviconUrl;

  FeedLinkPreview copyWith({
    String? url,
    String? title,
    String? description,
    String? siteName,
    String? imageUrl,
    String? faviconUrl,
  }) {
    return FeedLinkPreview(
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      siteName: siteName ?? this.siteName,
      imageUrl: imageUrl ?? this.imageUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'description': description,
      'siteName': siteName,
      'imageUrl': imageUrl,
      'faviconUrl': faviconUrl,
    };
  }

  factory FeedLinkPreview.fromJson(Map<String, dynamic> json) {
    return FeedLinkPreview(
      url: json['url'] as String? ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      siteName: json['siteName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
    );
  }
}

class FeedPollOption {
  const FeedPollOption({
    required this.id,
    required this.label,
    this.votes = 0,
  });

  final String id;
  final String label;
  final int votes;

  FeedPollOption copyWith({
    String? id,
    String? label,
    int? votes,
  }) {
    return FeedPollOption(
      id: id ?? this.id,
      label: label ?? this.label,
      votes: votes ?? this.votes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'votes': votes,
    };
  }

  factory FeedPollOption.fromJson(Map<String, dynamic> json) {
    return FeedPollOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
    );
  }
}

class FeedPoll {
  const FeedPoll({
    required this.id,
    required this.question,
    this.options = const <FeedPollOption>[],
    this.allowMultiple = false,
    this.closesAt,
    this.isClosed = false,
    this.totalVotes = 0,
  });

  final String id;
  final String question;
  final List<FeedPollOption> options;
  final bool allowMultiple;
  final DateTime? closesAt;
  final bool isClosed;
  final int totalVotes;

  bool get isExpired {
    if (closesAt == null) return false;
    return DateTime.now().isAfter(closesAt!);
  }

  FeedPoll copyWith({
    String? id,
    String? question,
    List<FeedPollOption>? options,
    bool? allowMultiple,
    DateTime? closesAt,
    bool? isClosed,
    int? totalVotes,
  }) {
    return FeedPoll(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? List<FeedPollOption>.from(this.options),
      allowMultiple: allowMultiple ?? this.allowMultiple,
      closesAt: closesAt ?? this.closesAt,
      isClosed: isClosed ?? this.isClosed,
      totalVotes: totalVotes ?? this.totalVotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options.map((option) => option.toJson()).toList(),
      'allowMultiple': allowMultiple,
      'closesAt': closesAt?.toIso8601String(),
      'isClosed': isClosed,
      'totalVotes': totalVotes,
    };
  }

  factory FeedPoll.fromJson(Map<String, dynamic> json) {
    final nullableConverter = const NullableTimestampConverter();
    final options = (json['options'] as List<dynamic>?)
            ?.map(
              (value) => FeedPollOption.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList() ??
        const <FeedPollOption>[];

    return FeedPoll(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: options,
      allowMultiple: json['allowMultiple'] as bool? ?? false,
      closesAt: nullableConverter.fromJson(json['closesAt']),
      isClosed: json['isClosed'] as bool? ?? false,
      totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
    );
  }
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorDisplayName,
    required this.authorUsername,
    this.authorAvatarUrl,
    this.authorRole,
    this.moderatorIds = const <String>[],
    this.title,
    this.body,
    this.type = FeedPostType.text,
    this.media = const <FeedMedia>[],
    this.linkUrl,
    this.linkPreview,
    this.poll,
    this.tags = const <String>[],
    this.primarySport,
    this.nsfw = false,
    this.spoiler = false,
    this.sensitive = false,
    this.locked = false,
    this.archived = false,
    this.isPinned = false,
    this.isActive = true,
    this.awardTypes = const <String>[],
    this.awardCounts = const <String, int>{},
    this.metadata = const <String, dynamic>{},
    required this.createdAt,
    this.updatedAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.score = 0,
    this.hotScore = 0.0,
    this.risingScore = 0.0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
    this.lastCommentAuthorName,
    this.lastActivityAt,
    this.reportsCount = 0,
    this.userVote = UserVoteValue.none,
    this.isSaved = false,
  });

  final String id;
  final String authorId;
  final String authorDisplayName;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String? authorRole;
  final List<String> moderatorIds;
  final String? title;
  final String? body;
  final FeedPostType type;
  final List<FeedMedia> media;
  final String? linkUrl;
  final FeedLinkPreview? linkPreview;
  final FeedPoll? poll;
  final List<String> tags;
  final String? primarySport;
  final bool nsfw;
  final bool spoiler;
  final bool sensitive;
  final bool locked;
  final bool archived;
  final bool isPinned;
  final bool isActive;
  final List<String> awardTypes;
  final Map<String, int> awardCounts;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int upvotes;
  final int downvotes;
  final int score;
  final double hotScore;
  final double risingScore;
  final int commentCount;
  final int shareCount;
  final int saveCount;
  final String? lastCommentAuthorName;
  final DateTime? lastActivityAt;
  final int reportsCount;
  final UserVoteValue userVote;
  final bool isSaved;

  int get calculatedScore => upvotes - downvotes;
  bool get isFlagged => nsfw || spoiler || sensitive;

  FeedPost copyWith({
    String? id,
    String? authorId,
    String? authorDisplayName,
    String? authorUsername,
    String? authorAvatarUrl,
    String? authorRole,
    List<String>? moderatorIds,
    String? title,
    String? body,
    FeedPostType? type,
    List<FeedMedia>? media,
    String? linkUrl,
    FeedLinkPreview? linkPreview,
    FeedPoll? poll,
    List<String>? tags,
    String? primarySport,
    bool? nsfw,
    bool? spoiler,
    bool? sensitive,
    bool? locked,
    bool? archived,
    bool? isPinned,
    bool? isActive,
    List<String>? awardTypes,
    Map<String, int>? awardCounts,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? upvotes,
    int? downvotes,
    int? score,
    double? hotScore,
    double? risingScore,
    int? commentCount,
    int? shareCount,
    int? saveCount,
    String? lastCommentAuthorName,
    DateTime? lastActivityAt,
    int? reportsCount,
    UserVoteValue? userVote,
    bool? isSaved,
  }) {
    return FeedPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorRole: authorRole ?? this.authorRole,
      moderatorIds: moderatorIds ?? List<String>.from(this.moderatorIds),
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      media: media ?? List<FeedMedia>.from(this.media),
      linkUrl: linkUrl ?? this.linkUrl,
      linkPreview: linkPreview ?? this.linkPreview,
      poll: poll ?? this.poll,
      tags: tags ?? List<String>.from(this.tags),
      primarySport: primarySport ?? this.primarySport,
      nsfw: nsfw ?? this.nsfw,
      spoiler: spoiler ?? this.spoiler,
      sensitive: sensitive ?? this.sensitive,
      locked: locked ?? this.locked,
      archived: archived ?? this.archived,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      awardTypes: awardTypes ?? List<String>.from(this.awardTypes),
      awardCounts: awardCounts ?? Map<String, int>.from(this.awardCounts),
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      score: score ?? this.score,
      hotScore: hotScore ?? this.hotScore,
      risingScore: risingScore ?? this.risingScore,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      saveCount: saveCount ?? this.saveCount,
      lastCommentAuthorName:
          lastCommentAuthorName ?? this.lastCommentAuthorName,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      reportsCount: reportsCount ?? this.reportsCount,
      userVote: userVote ?? this.userVote,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorDisplayName': authorDisplayName,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'authorRole': authorRole,
      'moderatorIds': moderatorIds,
      'title': title,
      'body': body,
      'type': type.name,
      'media': media.map((item) => item.toJson()).toList(),
      'linkUrl': linkUrl,
      'linkPreview': linkPreview?.toJson(),
      'poll': poll?.toJson(),
      'tags': tags,
      'primarySport': primarySport,
      'nsfw': nsfw,
      'spoiler': spoiler,
      'sensitive': sensitive,
      'locked': locked,
      'archived': archived,
      'isPinned': isPinned,
      'isActive': isActive,
      'awardTypes': awardTypes,
      'awardCounts': awardCounts,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'score': score,
      'hotScore': hotScore,
      'risingScore': risingScore,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'saveCount': saveCount,
      'lastCommentAuthorName': lastCommentAuthorName,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'reportsCount': reportsCount,
      'userVote': userVote.name,
      'isSaved': isSaved,
    };
  }

  static FeedPostType _parsePostType(String? value) {
    return FeedPostType.values.firstWhere(
      (element) => element.name == value,
      orElse: () => FeedPostType.text,
    );
  }

  factory FeedPost.fromJson(Map<String, dynamic> json) {
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
                  type: _inferMediaTypeFromUrl(value),
                  url: value,
                  isUploaded: true,
                );
              }
              return null;
            })
            .whereType<FeedMedia>()
            .toList();
      }
      return const <FeedMedia>[];
    }

    final rawMedia = json['media'] ?? json['mediaItems'];
    final mediaList = List<FeedMedia>.from(parseMedia(rawMedia));
    if (mediaList.isEmpty) {
      mediaList.addAll(parseMedia(json['images']));
    }

    FeedLinkPreview? parseLinkPreview(dynamic data) {
      if (data is Map) {
        return FeedLinkPreview.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    }

    FeedPoll? parsePoll(dynamic data) {
      if (data is Map) {
        return FeedPoll.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    }

    Map<String, int> parseAwardCounts(dynamic data) {
      if (data is Map) {
        return data.map(
          (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        );
      }
      return const <String, int>{};
    }

    Map<String, dynamic> parseMetadata(dynamic data) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return const <String, dynamic>{};
    }

    String resolveAuthorDisplayName(Map<String, dynamic> data) {
      final displayName = (data['authorDisplayName'] ??
              data['authorName'] ??
              data['authorNickname'] ??
              '')
          .toString()
          .trim();
      if (displayName.isNotEmpty) return displayName;
      final user = data['authorUsername']?.toString().trim();
      if (user != null && user.isNotEmpty) return user;
      return 'Unknown';
    }

    String resolveAuthorUsername(Map<String, dynamic> data) {
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

    String? resolveAuthorAvatar(Map<String, dynamic> data) {
      final avatar =
          data['authorAvatarUrl'] ?? data['authorProfilePicture'] ?? data['avatar'];
      return avatar is String && avatar.trim().isNotEmpty ? avatar : null;
    }

    String? resolveBody(Map<String, dynamic> data) {
      final body = data['body'] ?? data['content'] ?? '';
      return body is String ? body : body?.toString();
    }

    final resolvedDisplayName = resolveAuthorDisplayName(json);
    final resolvedUsername = resolveAuthorUsername(json);
    final resolvedAvatar = resolveAuthorAvatar(json);
    final resolvedBody = resolveBody(json);

    int resolveInt(dynamic value, {int fallback = 0}) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final upvotes = resolveInt(json['upvotes'] ?? json['likesCount']);
    final downvotes = resolveInt(json['downvotes'] ?? json['dislikesCount']);
    final score = resolveInt(json['score'], fallback: upvotes - downvotes);
    final commentCount =
        resolveInt(json['commentCount'] ?? json['commentsCount']);
    final shareCount = resolveInt(json['shareCount'] ?? json['sharesCount']);
    final saveCount = resolveInt(json['saveCount'] ?? json['savesCount']);

    UserVoteValue parseUserVote(dynamic value) {
      if (value is UserVoteValue) {
        return value;
      }
      if (value is String && value.isNotEmpty) {
        return UserVoteValue.values.firstWhere(
          (element) => element.name == value,
          orElse: () => UserVoteValue.none,
        );
      }
      return UserVoteValue.none;
    }

    final bool isSaved = json['isSaved'] as bool? ??
        (json['saved'] as bool?) ??
        (json['isBookmarked'] as bool?) ??
        false;

    return FeedPost(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorDisplayName: resolvedDisplayName,
      authorUsername: resolvedUsername,
      authorAvatarUrl: resolvedAvatar,
      authorRole: json['authorRole'] as String?,
      moderatorIds: (json['moderatorIds'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const <String>[],
      title: json['title'] as String?,
      body: resolvedBody,
      type: _parsePostType(json['type'] as String?),
      media: mediaList,
      linkUrl: json['linkUrl'] as String?,
      linkPreview: parseLinkPreview(json['linkPreview']),
      poll: parsePoll(json['poll']),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const <String>[],
      primarySport: json['primarySport'] as String?,
      nsfw: json['nsfw'] as bool? ?? false,
      spoiler: json['spoiler'] as bool? ?? false,
      sensitive: json['sensitive'] as bool? ?? false,
      locked: json['locked'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      awardTypes: (json['awardTypes'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const <String>[],
      awardCounts: parseAwardCounts(json['awardCounts']),
      metadata: parseMetadata(json['metadata']),
      createdAt: timestampConverter.fromJson(json['createdAt']),
      updatedAt: nullableTimestampConverter.fromJson(json['updatedAt']),
      upvotes: upvotes,
      downvotes: downvotes,
      score: score,
      hotScore: (json['hotScore'] as num?)?.toDouble() ?? 0,
      risingScore: (json['risingScore'] as num?)?.toDouble() ?? 0,
      commentCount: commentCount,
      shareCount: shareCount,
      saveCount: saveCount,
      lastCommentAuthorName: json['lastCommentAuthorName'] as String?,
      lastActivityAt:
          nullableTimestampConverter.fromJson(json['lastActivityAt']),
      reportsCount: (json['reportsCount'] as num?)?.toInt() ?? 0,
      userVote: parseUserVote(json['userVote']),
      isSaved: isSaved,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

FeedMediaType _inferMediaTypeFromUrl(String url) {
  final lower = url.toLowerCase();
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.mkv') ||
      lower.contains('video')) {
    return FeedMediaType.video;
  }
  if (lower.endsWith('.gif')) {
    return FeedMediaType.gif;
  }
  return FeedMediaType.image;
}

extension FeedPostSafeAccessors on FeedPost {
  UserVoteValue get safeUserVote {
    final dynamic raw = (this as dynamic).userVote;
    if (raw is UserVoteValue) {
      return raw;
    }
    if (raw is String && raw.isNotEmpty) {
      return UserVoteValue.values.firstWhere(
        (value) => value.name == raw,
        orElse: () => UserVoteValue.none,
      );
    }
    return UserVoteValue.none;
  }

  bool get safeIsSaved {
    final dynamic raw = (this as dynamic).isSaved;
    if (raw is bool) {
      return raw;
    }
    return false;
  }
}

