import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model for products and shops
class Review {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String? productId;
  final String? shopId;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  final bool isVerified;
  final int helpfulCount;
  final List<String> helpfulUsers;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    this.productId,
    this.shopId,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    required this.isVerified,
    required this.helpfulCount,
    required this.helpfulUsers,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Review(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      userName: (data['userName'] ?? '') as String,
      userImage: (data['userImage'] ?? '') as String,
      productId: data['productId'] as String?,
      shopId: data['shopId'] as String?,
      rating: (data['rating'] ?? 0.0) as double,
      comment: (data['comment'] ?? '') as String,
      images: (data['images'] as List?)?.cast<String>() ?? const [],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      isVerified: (data['isVerified'] ?? false) as bool,
      helpfulCount: (data['helpfulCount'] ?? 0) as int,
      helpfulUsers: (data['helpfulUsers'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'productId': productId,
        'shopId': shopId,
        'rating': rating,
        'comment': comment,
        'images': images,
        'createdAt': Timestamp.fromDate(createdAt),
        'isVerified': isVerified,
        'helpfulCount': helpfulCount,
        'helpfulUsers': helpfulUsers,
      };

  Review copyWith({
    String? userName,
    String? userImage,
    double? rating,
    String? comment,
    List<String>? images,
    bool? isVerified,
    int? helpfulCount,
    List<String>? helpfulUsers,
  }) {
    return Review(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      productId: productId,
      shopId: shopId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      createdAt: createdAt,
      isVerified: isVerified ?? this.isVerified,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulUsers: helpfulUsers ?? this.helpfulUsers,
    );
  }
}

/// Review summary for quick display
class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // rating -> count
  final int verifiedReviews;

  ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedReviews,
  });

  factory ReviewSummary.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) {
      return ReviewSummary(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        verifiedReviews: 0,
      );
    }

    double totalRating = 0.0;
    int verifiedCount = 0;
    Map<int, int> distribution = {};

    for (var review in reviews) {
      totalRating += review.rating;
      if (review.isVerified) verifiedCount++;

      int rating = review.rating.round();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return ReviewSummary(
      averageRating: totalRating / reviews.length,
      totalReviews: reviews.length,
      ratingDistribution: distribution,
      verifiedReviews: verifiedCount,
    );
  }
}
