import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart';

/// Player profile model extending the base UserProfile
class PlayerProfile extends UserProfile {
  final List<String> sportsOfInterest;
  final SkillLevel skillLevel;
  final List<TimeSlot> availability;
  final TrainingType preferredTrainingType;

  const PlayerProfile({
    required super.uid,
    required super.fullName,
    super.nickname,
    super.bio,
    required super.gender,
    required super.age,
    required super.location,
    super.latitude,
    super.longitude,
    super.profilePictureUrl,
    super.profilePhotos = const [],
    required super.isProfileComplete,
    super.teamId,
    required super.createdAt,
    required super.updatedAt,
    required this.sportsOfInterest,
    required this.skillLevel,
    required this.availability,
    required this.preferredTrainingType,
  }) : super(role: UserRole.player);

  @override
  Map<String, dynamic> toFirestore() {
    final baseData = baseToFirestore();
    baseData.addAll({
      'sportsOfInterest': sportsOfInterest,
      'skillLevel': skillLevel.value,
      'availability': availability.map((slot) => slot.toMap()).toList(),
      'preferredTrainingType': preferredTrainingType.value,
    });
    return baseData;
  }

  static PlayerProfile? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;
    data['uid'] ??= doc.id;
    return fromMap(data);
  }

  static PlayerProfile? fromMap(Map<String, dynamic> rawData) {
    try {
      final data = Map<String, dynamic>.from(rawData);
      final baseData = UserProfile.baseFromFirestore(data);

      return PlayerProfile(
        uid: baseData['uid'],
        fullName: baseData['fullName'],
        nickname: baseData['nickname'],
        bio: baseData['bio'],
        gender: baseData['gender'],
        age: baseData['age'],
        location: baseData['location'],
        latitude: baseData['latitude'],
        longitude: baseData['longitude'],
        profilePictureUrl: baseData['profilePictureUrl'],
        profilePhotos: baseData['profilePhotos'],
        isProfileComplete: baseData['isProfileComplete'],
        createdAt: baseData['createdAt'],
        updatedAt: baseData['updatedAt'],
        sportsOfInterest: List<String>.from(data['sportsOfInterest'] ?? []),
        skillLevel:
            SkillLevel.fromString(data['skillLevel'] as String? ?? 'beginner'),
        availability: (data['availability'] as List<dynamic>?)
                ?.map((slot) => TimeSlot.fromMap(
                      Map<String, dynamic>.from(slot as Map),
                    ))
                .toList() ??
            [],
        preferredTrainingType: TrainingType.fromString(
          data['preferredTrainingType'] as String? ?? 'in_person',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Create a copy with updated fields
  PlayerProfile copyWith({
    String? uid,
    String? fullName,
    Gender? gender,
    int? age,
    String? location,
    String? profilePictureUrl,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? sportsOfInterest,
    SkillLevel? skillLevel,
    List<TimeSlot>? availability,
    TrainingType? preferredTrainingType,
  }) {
    return PlayerProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      location: location ?? this.location,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sportsOfInterest: sportsOfInterest ?? this.sportsOfInterest,
      skillLevel: skillLevel ?? this.skillLevel,
      availability: availability ?? this.availability,
      preferredTrainingType:
          preferredTrainingType ?? this.preferredTrainingType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerProfile &&
        other.uid == uid &&
        other.fullName == fullName &&
        other.gender == gender &&
        other.age == age &&
        other.location == location &&
        other.profilePictureUrl == profilePictureUrl &&
        other.isProfileComplete == isProfileComplete &&
        other.sportsOfInterest.toString() == sportsOfInterest.toString() &&
        other.skillLevel == skillLevel &&
        other.availability.toString() == availability.toString() &&
        other.preferredTrainingType == preferredTrainingType;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        fullName.hashCode ^
        gender.hashCode ^
        age.hashCode ^
        location.hashCode ^
        (profilePictureUrl?.hashCode ?? 0) ^
        isProfileComplete.hashCode ^
        sportsOfInterest.hashCode ^
        skillLevel.hashCode ^
        availability.hashCode ^
        preferredTrainingType.hashCode;
  }

  @override
  String toString() {
    return 'PlayerProfile(uid: $uid, fullName: $fullName, role: ${role.value}, '
        'sportsOfInterest: $sportsOfInterest, skillLevel: ${skillLevel.value})';
  }
}

/// Common sports options for the app
class SportsOptions {
  static const List<String> availableSports = [
    'Football',
    'Basketball',
    'Tennis',
    'Soccer',
    'Baseball',
    'Volleyball',
    'Swimming',
    'Running',
    'Cycling',
    'Golf',
    'Boxing',
    'Martial Arts',
    'Yoga',
    'Fitness Training',
    'CrossFit',
    'Weightlifting',
    'Badminton',
    'Table Tennis',
    'Cricket',
    'Hockey',
  ];
}
