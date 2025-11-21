import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_profile.dart';
import '../../../models/player_profile.dart';
import '../../../models/coach_profile.dart';

/// Enum for swipe actions
enum SwipeAction {
  like('like'),
  dislike('dislike'),
  superLike('super_like');

  const SwipeAction(this.value);
  final String value;

  static SwipeAction fromString(String value) {
    return SwipeAction.values.firstWhere(
      (action) => action.value == value,
      orElse: () => SwipeAction.dislike,
    );
  }

  String get displayName {
    switch (this) {
      case SwipeAction.like:
        return 'Like';
      case SwipeAction.dislike:
        return 'Pass';
      case SwipeAction.superLike:
        return 'Super Like';
    }
  }
}

/// Enum for match status
enum MatchStatus {
  pending('pending'),
  matched('matched'),
  expired('expired'),
  blocked('blocked');

  const MatchStatus(this.value);
  final String value;

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MatchStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case MatchStatus.pending:
        return 'Pending';
      case MatchStatus.matched:
        return 'Matched';
      case MatchStatus.expired:
        return 'Expired';
      case MatchStatus.blocked:
        return 'Blocked';
    }
  }
}

/// Model for a potential match profile (simplified view for swiping)
class MatchProfile {
  final String uid;
  final String fullName;
  final int age;
  final String location;
  final String? profilePictureUrl;
  final List<String> photos; // Additional photos for gallery
  final List<String> sportsOfInterest;
  final SkillLevel skillLevel;
  final String? bio;
  final List<String> interests; // General interests beyond sports
  final double distanceKm; // Distance from current user
  final int compatibilityScore; // 0-100 compatibility score
  final UserRole role;
  final bool isOnline;
  final DateTime lastActive;
  final bool
      isMatched; // Whether this user is already matched with current user

  const MatchProfile({
    required this.uid,
    required this.fullName,
    required this.age,
    required this.location,
    this.profilePictureUrl,
    this.photos = const [],
    required this.sportsOfInterest,
    required this.skillLevel,
    this.bio,
    this.interests = const [],
    required this.distanceKm,
    required this.compatibilityScore,
    required this.role,
    this.isOnline = false,
    required this.lastActive,
    this.isMatched = false,
  });

  /// Create from UserProfile (PlayerProfile or CoachProfile)
  factory MatchProfile.fromUserProfile(
    UserProfile userProfile, {
    required double distanceKm,
    required int compatibilityScore,
    List<String> photos = const [],
    String? bio,
    List<String> interests = const [],
    bool isOnline = false,
    bool isMatched = false,
  }) {
    // Extract sports and skill level based on profile type
    List<String> sports = [];
    SkillLevel skillLevel = SkillLevel.beginner;

    if (userProfile is PlayerProfile) {
      sports = userProfile.sportsOfInterest;
      skillLevel = userProfile.skillLevel;
    } else if (userProfile is CoachProfile) {
      sports = userProfile.specializationSports;
      skillLevel = SkillLevel.pro; // Coaches are considered pro level
      bio = userProfile.bio;
    }

    return MatchProfile(
      uid: userProfile.uid,
      fullName: userProfile.fullName,
      age: userProfile.age,
      location: userProfile.location,
      profilePictureUrl: userProfile.profilePictureUrl,
      photos: photos,
      sportsOfInterest: sports,
      skillLevel: skillLevel,
      bio: bio,
      interests: interests,
      distanceKm: distanceKm,
      compatibilityScore: compatibilityScore,
      role: userProfile.role,
      isOnline: isOnline,
      lastActive: DateTime.now(),
      isMatched: isMatched,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'age': age,
      'location': location,
      'profilePictureUrl': profilePictureUrl,
      'photos': photos,
      'sportsOfInterest': sportsOfInterest,
      'skillLevel': skillLevel.value,
      'bio': bio,
      'interests': interests,
      'distanceKm': distanceKm,
      'compatibilityScore': compatibilityScore,
      'role': role.value,
      'isOnline': isOnline,
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  static MatchProfile? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    try {
      return MatchProfile(
        uid: data['uid'] as String,
        fullName: data['fullName'] as String,
        age: data['age'] as int,
        location: data['location'] as String,
        profilePictureUrl: data['profilePictureUrl'] as String?,
        photos: List<String>.from(data['photos'] ?? []),
        sportsOfInterest: List<String>.from(data['sportsOfInterest'] ?? []),
        skillLevel:
            SkillLevel.fromString(data['skillLevel'] as String? ?? 'beginner'),
        bio: data['bio'] as String?,
        interests: List<String>.from(data['interests'] ?? []),
        distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
        compatibilityScore: data['compatibilityScore'] as int? ?? 0,
        role: UserRole.fromString(data['role'] as String? ?? 'player'),
        isOnline: data['isOnline'] as bool? ?? false,
        lastActive:
            (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get primary photo URL (profile picture or first photo)
  String? get primaryPhotoUrl =>
      profilePictureUrl ?? (photos.isNotEmpty ? photos.first : null);

  /// Get all photos including profile picture
  List<String> get allPhotos {
    final List<String> allPhotos = [];
    if (profilePictureUrl != null) allPhotos.add(profilePictureUrl!);
    allPhotos.addAll(photos);
    return allPhotos.toSet().toList(); // Remove duplicates
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km away';
    } else {
      return '${distanceKm.round()}km away';
    }
  }

  /// Get age display string
  String get ageDisplay => '$fullName, $age';

  /// Check if user is recently active (within last 24 hours)
  bool get isRecentlyActive {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    return difference.inHours < 24;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchProfile && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'MatchProfile(uid: $uid, fullName: $fullName, age: $age, '
        'sportsOfInterest: $sportsOfInterest, distanceKm: $distanceKm)';
  }
}

/// Model for tracking swipe actions
class SwipeRecord {
  final String id;
  final String swiperId; // User who performed the swipe
  final String targetId; // User who was swiped on
  final SwipeAction action;
  final DateTime timestamp;

  const SwipeRecord({
    required this.id,
    required this.swiperId,
    required this.targetId,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'swiperId': swiperId,
      'targetId': targetId,
      'action': action.value,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static SwipeRecord? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    try {
      return SwipeRecord(
        id: data['id'] as String,
        swiperId: data['swiperId'] as String,
        targetId: data['targetId'] as String,
        action: SwipeAction.fromString(data['action'] as String),
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwipeRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model for a successful match between two users
class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;
  final String? user1PhotoUrl;
  final String? user2PhotoUrl;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime? expiredAt;
  final List<String> commonSports;
  final int compatibilityScore;
  final String? chatRoomId; // Associated chat room ID
  final bool isUser1SuperLike; // Did user1 super like user2?
  final bool isUser2SuperLike; // Did user2 super like user1?

  const Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    this.user1PhotoUrl,
    this.user2PhotoUrl,
    required this.status,
    required this.createdAt,
    this.expiredAt,
    required this.commonSports,
    required this.compatibilityScore,
    this.chatRoomId,
    this.isUser1SuperLike = false,
    this.isUser2SuperLike = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'user1PhotoUrl': user1PhotoUrl,
      'user2PhotoUrl': user2PhotoUrl,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiredAt': expiredAt != null ? Timestamp.fromDate(expiredAt!) : null,
      'commonSports': commonSports,
      'compatibilityScore': compatibilityScore,
      'chatRoomId': chatRoomId,
      'isUser1SuperLike': isUser1SuperLike,
      'isUser2SuperLike': isUser2SuperLike,
    };
  }

  static Match? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    try {
      return Match(
        id: data['id'] as String,
        user1Id: data['user1Id'] as String,
        user2Id: data['user2Id'] as String,
        user1Name: data['user1Name'] as String,
        user2Name: data['user2Name'] as String,
        user1PhotoUrl: data['user1PhotoUrl'] as String?,
        user2PhotoUrl: data['user2PhotoUrl'] as String?,
        status: MatchStatus.fromString(data['status'] as String),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        expiredAt: (data['expiredAt'] as Timestamp?)?.toDate(),
        commonSports: List<String>.from(data['commonSports'] ?? []),
        compatibilityScore: data['compatibilityScore'] as int? ?? 0,
        chatRoomId: data['chatRoomId'] as String?,
        isUser1SuperLike: data['isUser1SuperLike'] as bool? ?? false,
        isUser2SuperLike: data['isUser2SuperLike'] as bool? ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the other user's ID given current user ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  /// Get the other user's name given current user ID
  String getOtherUserName(String currentUserId) {
    return currentUserId == user1Id ? user2Name : user1Name;
  }

  /// Get the other user's photo URL given current user ID
  String? getOtherUserPhotoUrl(String currentUserId) {
    return currentUserId == user1Id ? user2PhotoUrl : user1PhotoUrl;
  }

  /// Check if match is expired
  bool get isExpired {
    if (expiredAt == null) return false;
    return DateTime.now().isAfter(expiredAt!);
  }

  /// Check if either user super liked
  bool get hasSuperLike => isUser1SuperLike || isUser2SuperLike;

  /// Get formatted common sports string
  String get formattedCommonSports {
    if (commonSports.isEmpty) return 'No common sports';
    if (commonSports.length == 1) return commonSports.first;
    if (commonSports.length == 2)
      return '${commonSports.first} & ${commonSports.last}';
    return '${commonSports.first} & ${commonSports.length - 1} more';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Match && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Match(id: $id, user1: $user1Name, user2: $user2Name, '
        'status: ${status.value}, commonSports: $commonSports)';
  }
}
