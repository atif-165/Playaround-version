import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? avatarUrl;
  final List<String> sports;
  final List<String> gallery;
  final Map<String, double> skillRatings;
  final double experienceLevel;
  final List<String> availability;
  final List<String> interests;
  final String? bio;
  final double reputationScore;
  final DateTime lastActive;
  final DateTime updatedAt;

  const PlayerModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.location,
    this.latitude,
    this.longitude,
    this.avatarUrl,
    this.sports = const [],
    this.gallery = const [],
    this.skillRatings = const {},
    this.experienceLevel = 0,
    this.availability = const [],
    this.interests = const [],
    this.bio,
    this.reputationScore = 0,
    required this.lastActive,
    required this.updatedAt,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      age: (json['age'] as num).toInt(),
      gender: json['gender'] as String? ?? 'unspecified',
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      avatarUrl: json['avatarUrl'] as String?,
      sports: List<String>.from(json['sports'] ?? const []),
      gallery: List<String>.from(json['gallery'] ?? const []),
      skillRatings: (json['skillRatings'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      experienceLevel: (json['experienceLevel'] as num?)?.toDouble() ?? 0,
      availability: List<String>.from(json['availability'] ?? const []),
      interests: List<String>.from(json['interests'] ?? const []),
      bio: json['bio'] as String?,
      reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0,
      lastActive: DateTime.tryParse(json['lastActive'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory PlayerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final sports = _extractStringList(
      data['sportsOfInterest'] ?? data['sports'],
      preferenceOrder: const ['name', 'sport', 'title', 'label'],
    );

    final availability = _extractStringList(
      data['availability'],
      preferenceOrder: const ['label', 'display', 'day'],
    );

    final interests = _extractStringList(data['interests']);

    final rawSkillRatings =
        data['skillRatings'] ?? data['skillScores'] ?? <String, dynamic>{};

    final parsedSkillRatings = <String, double>{};
    if (rawSkillRatings is Map) {
      rawSkillRatings.forEach((key, value) {
        if (key == null) return;
        final safeKey = key.toString();
        if (safeKey.isEmpty) return;
        if (value is num) {
          parsedSkillRatings[safeKey] = value.toDouble();
        } else if (value is String) {
          final parsedValue = double.tryParse(value);
          if (parsedValue != null) {
            parsedSkillRatings[safeKey] = parsedValue;
          }
        }
      });
    }

    return PlayerModel(
      id: doc.id,
      fullName: data['fullName'] as String? ?? 'Unknown player',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: data['gender'] as String? ?? 'unspecified',
      location: data['location'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      avatarUrl:
          data['profilePictureUrl'] as String? ?? data['avatarUrl'] as String?,
      sports: sports,
      gallery: List<String>.from(
        data['profilePhotos'] ?? data['gallery'] ?? const [],
      ),
      skillRatings: parsedSkillRatings,
      experienceLevel: (data['experienceLevel'] as num?)?.toDouble() ??
          (data['skillLevel'] is String
              ? _skillStringToLevel(data['skillLevel'] as String)
              : 0),
      availability: availability,
      interests: interests,
      bio: data['bio'] as String?,
      reputationScore: (data['reputationScore'] as num?)?.toDouble() ?? 0,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ??
          DateTime.tryParse(data['lastSeen'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'avatarUrl': avatarUrl,
      'sports': sports,
      'gallery': gallery,
      'skillRatings': skillRatings,
      'experienceLevel': experienceLevel,
      'availability': availability,
      'interests': interests,
      'bio': bio,
      'reputationScore': reputationScore,
      'lastActive': lastActive.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PlayerModel copyWith({
    String? id,
    String? fullName,
    int? age,
    String? gender,
    String? location,
    double? latitude,
    double? longitude,
    String? avatarUrl,
    List<String>? sports,
    List<String>? gallery,
    Map<String, double>? skillRatings,
    double? experienceLevel,
    List<String>? availability,
    List<String>? interests,
    String? bio,
    double? reputationScore,
    DateTime? lastActive,
    DateTime? updatedAt,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sports: sports ?? this.sports,
      gallery: gallery ?? this.gallery,
      skillRatings: skillRatings ?? this.skillRatings,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      availability: availability ?? this.availability,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      reputationScore: reputationScore ?? this.reputationScore,
      lastActive: lastActive ?? this.lastActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _skillStringToLevel(String value) {
    switch (value.toLowerCase()) {
      case 'beginner':
        return 0.25;
      case 'intermediate':
        return 0.5;
      case 'advanced':
        return 0.75;
      case 'pro':
      case 'professional':
        return 1;
      default:
        return 0;
    }
  }

  static List<String> _extractStringList(
    dynamic raw, {
    List<String> preferenceOrder = const [],
  }) {
    if (raw == null) return const [];

    Iterable<dynamic> iterable;
    if (raw is List) {
      iterable = raw;
    } else if (raw is Map) {
      iterable = raw.values;
    } else {
      return raw is String && raw.trim().isNotEmpty ? [raw.trim()] : const [];
    }

    final seen = <String>{};
    final result = <String>[];

    for (final item in iterable) {
      if (item == null) continue;

      if (item is String) {
        final trimmed = item.trim();
        if (trimmed.isEmpty || seen.contains(trimmed)) continue;
        seen.add(trimmed);
        result.add(trimmed);
        continue;
      }

      if (item is Map) {
        String? candidate;
        for (final key in preferenceOrder) {
          final value = item[key];
          if (value is String && value.trim().isNotEmpty) {
            candidate = value.trim();
            break;
          }
        }
        candidate ??= item.values
            .whereType<String>()
            .map((value) => value.trim())
            .firstWhere(
              (value) => value.isNotEmpty,
              orElse: () => '',
            );
        if (candidate.isNotEmpty && !seen.contains(candidate)) {
          seen.add(candidate);
          result.add(candidate);
        }
        continue;
      }

      final fallback = item.toString().trim();
      if (fallback.isNotEmpty && !seen.contains(fallback)) {
        seen.add(fallback);
        result.add(fallback);
      }
    }

    return result;
  }
}
