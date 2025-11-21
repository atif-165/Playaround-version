import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart';

/// Coach profile model extending the base UserProfile
class CoachProfile extends UserProfile {
  final List<String> specializationSports;
  final int experienceYears;
  final List<String>? certifications;
  final double hourlyRate;
  final List<TimeSlot> availableTimeSlots;
  final TrainingType coachingType;
  final String? bio;

  const CoachProfile({
    required super.uid,
    required super.fullName,
    super.nickname,
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
    required this.specializationSports,
    required this.experienceYears,
    this.certifications,
    required this.hourlyRate,
    required this.availableTimeSlots,
    required this.coachingType,
    this.bio,
  }) : super(role: UserRole.coach, bio: bio);

  @override
  Map<String, dynamic> toFirestore() {
    final baseData = baseToFirestore();
    baseData.addAll({
      'specializationSports': specializationSports,
      'experienceYears': experienceYears,
      'certifications': certifications,
      'hourlyRate': hourlyRate,
      'availableTimeSlots':
          availableTimeSlots.map((slot) => slot.toMap()).toList(),
      'coachingType': coachingType.value,
      'bio': bio,
    });
    return baseData;
  }

  static CoachProfile? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;
    data['uid'] ??= doc.id;
    return fromMap(data);
  }

  static CoachProfile? fromMap(Map<String, dynamic> rawData) {
    try {
      final data = Map<String, dynamic>.from(rawData);
      final baseData = UserProfile.baseFromFirestore(data);

      return CoachProfile(
        uid: baseData['uid'],
        fullName: baseData['fullName'],
        nickname: baseData['nickname'],
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
        specializationSports:
            List<String>.from(data['specializationSports'] ?? []),
        experienceYears: data['experienceYears'] as int? ?? 0,
        certifications: data['certifications'] != null
            ? (data['certifications'] is List
                ? List<String>.from(data['certifications'])
                : [data['certifications'].toString()])
            : null,
        hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
        availableTimeSlots: (data['availableTimeSlots'] as List<dynamic>?)
                ?.map((slot) {
                  if (slot is Map<String, dynamic>) {
                    return TimeSlot.fromMap(slot);
                  }
                  if (slot is Map) {
                    return TimeSlot.fromMap(
                      slot.map(
                        (key, value) =>
                            MapEntry(key.toString(), value),
                      ),
                    );
                  }
                  return null;
                })
                .whereType<TimeSlot>()
                .toList() ??
            const [],
        coachingType: TrainingType.fromString(
          data['coachingType'] as String? ?? 'in_person',
        ),
        bio: data['bio'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Create a copy with updated fields
  CoachProfile copyWith({
    String? uid,
    String? fullName,
    Gender? gender,
    int? age,
    String? location,
    String? profilePictureUrl,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? specializationSports,
    int? experienceYears,
    List<String>? certifications,
    double? hourlyRate,
    List<TimeSlot>? availableTimeSlots,
    TrainingType? coachingType,
    String? bio,
  }) {
    return CoachProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      location: location ?? this.location,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specializationSports: specializationSports ?? this.specializationSports,
      experienceYears: experienceYears ?? this.experienceYears,
      certifications: certifications ?? this.certifications,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      coachingType: coachingType ?? this.coachingType,
      bio: bio ?? this.bio,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachProfile &&
        other.uid == uid &&
        other.fullName == fullName &&
        other.gender == gender &&
        other.age == age &&
        other.location == location &&
        other.profilePictureUrl == profilePictureUrl &&
        other.isProfileComplete == isProfileComplete &&
        other.specializationSports.toString() ==
            specializationSports.toString() &&
        other.experienceYears == experienceYears &&
        other.certifications == certifications &&
        other.hourlyRate == hourlyRate &&
        other.availableTimeSlots.toString() == availableTimeSlots.toString() &&
        other.coachingType == coachingType &&
        other.bio == bio;
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
        specializationSports.hashCode ^
        experienceYears.hashCode ^
        (certifications?.hashCode ?? 0) ^
        hourlyRate.hashCode ^
        availableTimeSlots.hashCode ^
        coachingType.hashCode ^
        (bio?.hashCode ?? 0);
  }

  @override
  String toString() {
    return 'CoachProfile(uid: $uid, fullName: $fullName, role: ${role.value}, '
        'specializationSports: $specializationSports, experienceYears: $experienceYears, '
        'hourlyRate: \$${hourlyRate.toStringAsFixed(2)})';
  }
}

/// Validation helper for coach profiles
class CoachProfileValidator {
  static const int maxBioLength = 500;
  static const int minExperienceYears = 0;
  static const int maxExperienceYears = 50;
  static const double minHourlyRate = 0.0;
  static const double maxHourlyRate = 1000.0;

  static String? validateExperienceYears(int? years) {
    if (years == null) return 'Experience years is required';
    if (years < minExperienceYears || years > maxExperienceYears) {
      return 'Experience must be between $minExperienceYears and $maxExperienceYears years';
    }
    return null;
  }

  static String? validateHourlyRate(double? rate) {
    if (rate == null) return 'Hourly rate is required';
    if (rate < minHourlyRate || rate > maxHourlyRate) {
      return 'Hourly rate must be between \$${minHourlyRate.toStringAsFixed(2)} and \$${maxHourlyRate.toStringAsFixed(2)}';
    }
    return null;
  }

  static String? validateBio(String? bio) {
    if (bio != null && bio.length > maxBioLength) {
      return 'Bio must be $maxBioLength characters or less';
    }
    return null;
  }
}
