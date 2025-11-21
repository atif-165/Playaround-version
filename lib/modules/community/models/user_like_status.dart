/// Model representing the current user's like/dislike status on a post
class UserLikeStatus {
  final bool hasLiked;
  final bool hasDisliked;
  final String? likeId; // Document ID of the like/dislike

  const UserLikeStatus({
    this.hasLiked = false,
    this.hasDisliked = false,
    this.likeId,
  });

  /// Check if user has interacted (liked or disliked)
  bool get hasInteracted => hasLiked || hasDisliked;

  /// Get the type of interaction as a string
  String? get interactionType {
    if (hasLiked) return 'like';
    if (hasDisliked) return 'dislike';
    return null;
  }

  /// Create a copy with updated fields
  UserLikeStatus copyWith({
    bool? hasLiked,
    bool? hasDisliked,
    String? likeId,
  }) {
    return UserLikeStatus(
      hasLiked: hasLiked ?? this.hasLiked,
      hasDisliked: hasDisliked ?? this.hasDisliked,
      likeId: likeId ?? this.likeId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserLikeStatus &&
        other.hasLiked == hasLiked &&
        other.hasDisliked == hasDisliked &&
        other.likeId == likeId;
  }

  @override
  int get hashCode => Object.hash(hasLiked, hasDisliked, likeId);

  @override
  String toString() {
    return 'UserLikeStatus(hasLiked: $hasLiked, hasDisliked: $hasDisliked, likeId: $likeId)';
  }
}
