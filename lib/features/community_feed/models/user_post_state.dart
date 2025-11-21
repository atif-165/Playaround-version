import 'json_converters.dart';

enum UserVoteValue {
  none,
  upvote,
  downvote,
}

extension UserVoteValueX on UserVoteValue {
  int get asScore {
    switch (this) {
      case UserVoteValue.upvote:
        return 1;
      case UserVoteValue.downvote:
        return -1;
      case UserVoteValue.none:
        return 0;
    }
  }
}

class UserPostState {
  const UserPostState({
    required this.postId,
    required this.userId,
    this.vote = UserVoteValue.none,
    this.saved = false,
    this.awardsGiven = const <String, int>{},
    this.metadata = const <String, dynamic>{},
    required this.createdAt,
    this.updatedAt,
    this.savedAt,
    this.lastSyncedAt,
  });

  final String postId;
  final String userId;
  final UserVoteValue vote;
  final bool saved;
  final Map<String, int> awardsGiven;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? savedAt;
  final DateTime? lastSyncedAt;

  static UserPostState initial(String postId, String userId) => UserPostState(
        postId: postId,
        userId: userId,
        createdAt: DateTime.now(),
      );

  UserPostState copyWith({
    String? postId,
    String? userId,
    UserVoteValue? vote,
    bool? saved,
    Map<String, int>? awardsGiven,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? savedAt,
    DateTime? lastSyncedAt,
  }) {
    return UserPostState(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      vote: vote ?? this.vote,
      saved: saved ?? this.saved,
      awardsGiven: awardsGiven ?? Map<String, int>.from(this.awardsGiven),
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      savedAt: savedAt ?? this.savedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'userId': userId,
      'vote': vote.name,
      'saved': saved,
      'awardsGiven': awardsGiven,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'savedAt': savedAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory UserPostState.fromJson(Map<String, dynamic> json) {
    final timestampConverter = const TimestampConverter();
    final nullableTimestampConverter = const NullableTimestampConverter();

    UserVoteValue parseVote(String? value) {
      return UserVoteValue.values.firstWhere(
        (element) => element.name == value,
        orElse: () => UserVoteValue.none,
      );
    }

    Map<String, int> parseAwards(dynamic data) {
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

    return UserPostState(
      postId: json['postId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      vote: parseVote(json['vote'] as String?),
      saved: json['saved'] as bool? ?? false,
      awardsGiven: parseAwards(json['awardsGiven']),
      metadata: parseMetadata(json['metadata']),
      createdAt: timestampConverter.fromJson(json['createdAt']),
      updatedAt: nullableTimestampConverter.fromJson(json['updatedAt']),
      savedAt: nullableTimestampConverter.fromJson(json['savedAt']),
      lastSyncedAt: nullableTimestampConverter.fromJson(json['lastSyncedAt']),
    );
  }
}

