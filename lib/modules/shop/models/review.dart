import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final int rating; // 1..5
  final String comment;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Review(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      rating: (data['rating'] ?? 0) as int,
      comment: (data['comment'] ?? '') as String,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

