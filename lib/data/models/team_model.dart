import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String sport;
  final String city;
  final String? logoUrl;
  final List<String> memberIds;
  final List<String> tags;
  final double rating;
  final int wins;
  final int losses;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.city,
    this.logoUrl,
    this.memberIds = const [],
    this.tags = const [],
    this.rating = 0,
    this.wins = 0,
    this.losses = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sport: json['sport'] as String? ?? 'Unknown',
      city: json['city'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      memberIds: List<String>.from(json['memberIds'] ?? const []),
      tags: List<String>.from(json['tags'] ?? const []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TeamModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled team',
      sport:
          data['sport'] as String? ?? data['sportType'] as String? ?? 'Unknown',
      city: data['location'] as String? ?? data['city'] as String? ?? '',
      logoUrl: data['logoUrl'] as String? ?? data['badgeUrl'] as String?,
      memberIds:
          List<String>.from(data['memberIds'] ?? data['members'] ?? const []),
      tags: List<String>.from(data['tags'] ?? const []),
      rating: (data['rating'] as num?)?.toDouble() ??
          (data['averageRating'] as num?)?.toDouble() ??
          0,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      losses: (data['losses'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'city': city,
      'logoUrl': logoUrl,
      'memberIds': memberIds,
      'tags': tags,
      'rating': rating,
      'wins': wins,
      'losses': losses,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? sport,
    String? city,
    String? logoUrl,
    List<String>? memberIds,
    List<String>? tags,
    double? rating,
    int? wins,
    int? losses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      city: city ?? this.city,
      logoUrl: logoUrl ?? this.logoUrl,
      memberIds: memberIds ?? this.memberIds,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
