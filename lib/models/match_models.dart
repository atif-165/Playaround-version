import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for swipe actions
enum SwipeAction {
  like('like'),
  pass('pass');

  const SwipeAction(this.value);
  final String value;

  static SwipeAction fromString(String value) {
    return SwipeAction.values.firstWhere(
      (action) => action.value == value,
      orElse: () => SwipeAction.pass,
    );
  }
}

/// Enum for match status
enum MatchStatus {
  pending('pending'),
  matched('matched'),
  expired('expired');

  const MatchStatus(this.value);
  final String value;

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MatchStatus.pending,
    );
  }
}

/// Model for user swipe actions (likes/passes)
class UserSwipe {
  final String id;
  final String fromUserId;
  final String toUserId;
  final SwipeAction action;
  final DateTime createdAt;

  const UserSwipe({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.action,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'action': action.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory UserSwipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSwipe.fromMap(data);
  }

  /// Create from Map
  factory UserSwipe.fromMap(Map<String, dynamic> map) {
    return UserSwipe(
      id: map['id'] as String,
      fromUserId: map['fromUserId'] as String,
      toUserId: map['toUserId'] as String,
      action: SwipeAction.fromString(map['action'] as String),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Generate unique swipe ID
  static String generateSwipeId(String fromUserId, String toUserId) {
    return '${fromUserId}_${toUserId}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Model for matches between users
class UserMatch {
  final String id;
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;
  final String? user1ImageUrl;
  final String? user2ImageUrl;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime? expiredAt;
  final List<String> commonSports;
  final double compatibilityScore;

  const UserMatch({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    this.user1ImageUrl,
    this.user2ImageUrl,
    required this.status,
    required this.createdAt,
    this.expiredAt,
    required this.commonSports,
    required this.compatibilityScore,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'user1ImageUrl': user1ImageUrl,
      'user2ImageUrl': user2ImageUrl,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiredAt': expiredAt != null ? Timestamp.fromDate(expiredAt!) : null,
      'commonSports': commonSports,
      'compatibilityScore': compatibilityScore,
    };
  }

  /// Create from Firestore document
  factory UserMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserMatch.fromMap(data);
  }

  /// Create from Map
  factory UserMatch.fromMap(Map<String, dynamic> map) {
    return UserMatch(
      id: map['id'] as String,
      user1Id: map['user1Id'] as String,
      user2Id: map['user2Id'] as String,
      user1Name: map['user1Name'] as String,
      user2Name: map['user2Name'] as String,
      user1ImageUrl: map['user1ImageUrl'] as String?,
      user2ImageUrl: map['user2ImageUrl'] as String?,
      status: MatchStatus.fromString(map['status'] as String),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiredAt: map['expiredAt'] != null 
          ? (map['expiredAt'] as Timestamp).toDate() 
          : null,
      commonSports: List<String>.from(map['commonSports'] ?? []),
      compatibilityScore: (map['compatibilityScore'] as num).toDouble(),
    );
  }

  /// Generate unique match ID from two user IDs
  static String generateMatchId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Get the other user's information from the match
  Map<String, String?> getOtherUser(String currentUserId) {
    if (currentUserId == user1Id) {
      return {
        'id': user2Id,
        'name': user2Name,
        'imageUrl': user2ImageUrl,
      };
    } else {
      return {
        'id': user1Id,
        'name': user1Name,
        'imageUrl': user1ImageUrl,
      };
    }
  }
}

/// Model for profile comments
class ProfileComment {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String? fromUserImageUrl;
  final String comment;
  final DateTime createdAt;
  final bool isRead;

  const ProfileComment({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    this.fromUserImageUrl,
    required this.comment,
    required this.createdAt,
    this.isRead = false,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'fromUserImageUrl': fromUserImageUrl,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  /// Create from Firestore document
  factory ProfileComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileComment.fromMap(data);
  }

  /// Create from Map
  factory ProfileComment.fromMap(Map<String, dynamic> map) {
    return ProfileComment(
      id: map['id'] as String,
      fromUserId: map['fromUserId'] as String,
      toUserId: map['toUserId'] as String,
      fromUserName: map['fromUserName'] as String,
      fromUserImageUrl: map['fromUserImageUrl'] as String?,
      comment: map['comment'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}

/// Model for daily mood status
class DailyMood {
  final String id;
  final String userId;
  final String mood;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  const DailyMood({
    required this.id,
    required this.userId,
    required this.mood,
    this.description,
    required this.date,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'mood': mood,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory DailyMood.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyMood.fromMap(data);
  }

  /// Create from Map
  factory DailyMood.fromMap(Map<String, dynamic> map) {
    return DailyMood(
      id: map['id'] as String,
      userId: map['userId'] as String,
      mood: map['mood'] as String,
      description: map['description'] as String?,
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Generate daily mood ID
  static String generateMoodId(String userId, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${userId}_$dateStr';
  }
}
