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
  final String? nickname;
  final String? bio;
  final Gender gender;
  final int age;
  final String location;
  final double? latitude; // GPS latitude coordinate
  final double? longitude; // GPS longitude coordinate
  final String? profilePictureUrl;
  final List<String> profilePhotos; // Multiple photos support
  final UserRole role;
  final bool isProfileComplete;
  final String? teamId; // Add teamId field
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.fullName,
    this.nickname,
    this.bio,
    required this.gender,
    required this.age,
    required this.location,
    this.latitude,
    this.longitude,
    this.profilePictureUrl,
    this.profilePhotos = const [],
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
      'nickname': nickname,
      'bio': bio,
      'gender': gender.value,
      'age': age,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'profilePictureUrl': profilePictureUrl,
      'profilePhotos': profilePhotos,
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
    String? _asString(dynamic value) {
      if (value == null) return null;
      final stringValue = value.toString().trim();
      return stringValue.isEmpty ? null : stringValue;
    }

    double? _asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int _asInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    DateTime _asDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is num) {
        final milliseconds =
            value > 1000000000000 ? value.toInt() : value.toInt() * 1000;
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    List<String> _asStringList(dynamic value) {
      if (value is Iterable) {
        return value
            .where((element) => element != null)
            .map((element) => element.toString())
            .where((element) => element.trim().isNotEmpty)
            .toList();
      }
      return <String>[];
    }

    final uid = _asString(data['uid']) ?? _asString(data['id']);
    if (uid == null) {
      throw StateError('User profile document is missing a uid.');
    }

    final roleString = _asString(data['role']) ?? 'player';

    final profilePhotos = <String>{
      ..._asStringList(data['profilePhotos']),
      ..._asStringList(data['galleryPhotos']),
      ..._asStringList(data['gallery']),
    }.toList();

    return {
      'uid': uid,
      'fullName': _asString(data['fullName']) ??
          _asString(data['name']) ??
          'Unnamed User',
      'nickname': _asString(data['nickname']),
      'bio': _asString(data['bio']) ??
          _asString(data['about']) ??
          _asString(data['description']),
      'gender': Gender.fromString(_asString(data['gender']) ?? 'male'),
      'age': _asInt(data['age']),
      'location': _asString(data['location']) ??
          _asString(data['city']) ??
          _asString(data['country']) ??
          'Unknown',
      'latitude': _asDouble(data['latitude']),
      'longitude': _asDouble(data['longitude']),
      'profilePictureUrl': _asString(data['profilePictureUrl']) ??
          _asString(data['photoUrl']) ??
          _asString(data['avatarUrl']) ??
          _asString(data['imageUrl']),
      'profilePhotos': profilePhotos,
      'role': UserRole.fromString(roleString),
      'isProfileComplete': data['isProfileComplete'] is bool
          ? data['isProfileComplete'] as bool
          : true,
      'teamId': _asString(data['teamId']) ?? _asString(data['team']),
      'createdAt': _asDateTime(data['createdAt']),
      'updatedAt': _asDateTime(data['updatedAt']),
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
    String _asString(dynamic value, String fallback) {
      if (value == null) return fallback;
      final stringValue = value.toString().trim();
      return stringValue.isEmpty ? fallback : stringValue;
    }

    final resolvedDay = _asString(
      map['day'] ??
          map['weekday'] ??
          map['dayOfWeek'] ??
          map['label'] ??
          'Flexible',
      'Flexible',
    );

    final resolvedStart = _asString(
      map['startTime'] ?? map['start'] ?? map['from'] ?? map['open'],
      'Anytime',
    );

    final resolvedEnd = _asString(
      map['endTime'] ?? map['end'] ?? map['to'] ?? map['close'],
      'Anytime',
    );

    return TimeSlot(
      day: resolvedDay,
      startTime: resolvedStart,
      endTime: resolvedEnd,
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
