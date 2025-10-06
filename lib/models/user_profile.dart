import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Enum representing user roles in the application
enum UserRole {
  player('player'),
  coach('coach'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.player,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.player:
        return 'Player';
      case UserRole.coach:
        return 'Coach';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// Enum representing gender options
enum Gender {
  male('male'),
  female('female'),
  other('other');

  const Gender(this.value);
  final String value;

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.value == value,
      orElse: () => Gender.male,
    );
  }

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

/// Base user profile model containing common fields for both players and coaches
abstract class UserProfile {
  final String uid;
  final String fullName;
  final Gender gender;
  final int age;
  final String location;
  final String? profilePictureUrl;
  final UserRole role;
  final bool isProfileComplete;
  final String? teamId; // Add teamId field
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.gender,
    required this.age,
    required this.location,
    this.profilePictureUrl,
    required this.role,
    required this.isProfileComplete,
    this.teamId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore();

  /// Create from Firestore document
  /// This method should be overridden by specific profile classes
  static UserProfile? fromFirestore(DocumentSnapshot doc) {
    // This method is implemented in the UserRepository to avoid circular imports
    return null;
  }

  /// Common fields for Firestore conversion
  @protected
  Map<String, dynamic> baseToFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'gender': gender.value,
      'age': age,
      'location': location,
      'profilePictureUrl': profilePictureUrl,
      'role': role.value,
      'isProfileComplete': isProfileComplete,
      'teamId': teamId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Common fields from Firestore conversion
  @protected
  static Map<String, dynamic> baseFromFirestore(Map<String, dynamic> data) {
    return {
      'uid': data['uid'] as String,
      'fullName': data['fullName'] as String,
      'gender': Gender.fromString(data['gender'] as String? ?? 'male'),
      'age': data['age'] as int,
      'location': data['location'] as String,
      'profilePictureUrl': data['profilePictureUrl'] as String?,
      'role': UserRole.fromString(data['role'] as String),
      'isProfileComplete': data['isProfileComplete'] as bool? ?? false,
      'teamId': data['teamId'] as String?,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    };
  }

  /// Get user ID (alias for uid)
  String get id => uid;

  /// Get display name (alias for fullName)
  String get displayName => fullName;

  /// Get photo URL (alias for profilePictureUrl)
  String? get photoURL => profilePictureUrl;
}

/// Enum for skill levels
enum SkillLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  pro('pro');

  const SkillLevel(this.value);
  final String value;

  static SkillLevel fromString(String value) {
    return SkillLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => SkillLevel.beginner,
    );
  }

  String get displayName {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.pro:
        return 'Pro';
    }
  }
}

/// Enum for training/coaching types
enum TrainingType {
  inPerson('in_person'),
  online('online'),
  both('both');

  const TrainingType(this.value);
  final String value;

  static TrainingType fromString(String value) {
    return TrainingType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TrainingType.inPerson,
    );
  }

  String get displayName {
    switch (this) {
      case TrainingType.inPerson:
        return 'In-person';
      case TrainingType.online:
        return 'Online';
      case TrainingType.both:
        return 'Both';
    }
  }
}

/// Time slot model for availability
class TimeSlot {
  final String day;
  final String startTime;
  final String endTime;

  const TimeSlot({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  static TimeSlot fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      day: map['day'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
    );
  }

  @override
  String toString() => '$day: $startTime - $endTime';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot &&
        other.day == day &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => day.hashCode ^ startTime.hashCode ^ endTime.hashCode;
}
