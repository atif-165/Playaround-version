import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model for shop locations
class LocationReview {
  final String id;
  final String locationId;
  final String userId;
  final String userName;
  final String userProfileImage;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;
  final bool isVerified;

  LocationReview({
    required this.id,
    required this.locationId,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    this.isVerified = false,
  });

  factory LocationReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationReview(
      id: doc.id,
      locationId: data['locationId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfileImage: data['userProfileImage'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationId': locationId,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'images': images,
      'isVerified': isVerified,
    };
  }

  LocationReview copyWith({
    String? id,
    String? locationId,
    String? userId,
    String? userName,
    String? userProfileImage,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
    bool? isVerified,
  }) {
    return LocationReview(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
