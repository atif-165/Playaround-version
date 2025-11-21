import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a like/dislike on a post or comment
class CommunityLike {
  final String id;
  final String userId;
  final String userNickname;
  final String postId;
  final String? commentId; // Optional - for comment likes
  final bool isLike; // true for like, false for dislike
  final DateTime createdAt;

  const CommunityLike({
    required this.id,
    required this.userId,
    required this.userNickname,
    required this.postId,
    this.commentId,
    required this.isLike,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory CommunityLike.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommunityLike(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userNickname: data['userNickname'] as String? ?? '',
      postId: data['postId'] as String? ?? '',
      commentId: data['commentId'] as String?,
      isLike: data['isLike'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userNickname': userNickname,
      'postId': postId,
      'commentId': commentId,
      'isLike': isLike,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  CommunityLike copyWith({
    String? id,
    String? userId,
    String? userNickname,
    String? postId,
    String? commentId,
    bool? isLike,
    DateTime? createdAt,
  }) {
    return CommunityLike(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userNickname: userNickname ?? this.userNickname,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      isLike: isLike ?? this.isLike,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityLike && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommunityLike(id: $id, userId: $userId, postId: $postId, isLike: $isLike)';
  }
}
