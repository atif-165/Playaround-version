import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a comment on a community post
class CommunityComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorNickname;
  final String? authorProfilePicture;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final int repliesCount;
  final String? parentCommentId; // For nested replies

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorNickname,
    this.authorProfilePicture,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.parentCommentId,
  });

  /// Create from Firestore document
  factory CommunityComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommunityComment(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorNickname: data['authorNickname'] as String? ?? '',
      authorProfilePicture: data['authorProfilePicture'] as String?,
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      likesCount: data['likesCount'] as int? ?? 0,
      repliesCount: data['repliesCount'] as int? ?? 0,
      parentCommentId: data['parentCommentId'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorNickname': authorNickname,
      'authorProfilePicture': authorProfilePicture,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'parentCommentId': parentCommentId,
    };
  }

  /// Create a copy with updated fields
  CommunityComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorNickname,
    String? authorProfilePicture,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? repliesCount,
    String? parentCommentId,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorNickname: authorNickname ?? this.authorNickname,
      authorProfilePicture: authorProfilePicture ?? this.authorProfilePicture,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommunityComment(id: $id, authorName: $authorName, postId: $postId)';
  }
}
