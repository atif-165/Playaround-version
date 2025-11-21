import 'package:flutter/material.dart';

import '../../../modules/community/models/community_post.dart';

enum PublicProfileTab {
  about,
  skills,
  teams,
  venues,
  community,
  matchmaking,
  reviews,
}

class ProfileIdentity {
  const ProfileIdentity({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.tagline,
    required this.city,
    required this.age,
    required this.profilePictureUrl,
    required this.badges,
    this.coverMediaUrl,
    this.isVerified = false,
  });

  final String userId;
  final String fullName;
  final String role;
  final String tagline;
  final String city;
  final int age;
  final String profilePictureUrl;
  final List<String> badges;
  final String? coverMediaUrl;
  final bool isVerified;

  ProfileIdentity copyWith({
    String? fullName,
    String? role,
    String? tagline,
    String? city,
    int? age,
    String? profilePictureUrl,
    List<String>? badges,
    String? coverMediaUrl,
    bool? isVerified,
  }) {
    return ProfileIdentity(
      userId: userId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      tagline: tagline ?? this.tagline,
      city: city ?? this.city,
      age: age ?? this.age,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      badges: badges ?? List<String>.from(this.badges),
      coverMediaUrl: coverMediaUrl ?? this.coverMediaUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class ProfileStat {
  const ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    this.tooltip,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? tooltip;
}

class ProfileConnection {
  const ProfileConnection({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.isFollowing,
  });

  final String userId;
  final String name;
  final String avatarUrl;
  final bool isFollowing;
}

class ProfileAboutData {
  const ProfileAboutData({
    required this.bio,
    required this.sports,
    required this.position,
    required this.availability,
    required this.highlights,
    required this.attributes,
    this.statusMessage,
  });

  final String bio;
  final List<String> sports;
  final String position;
  final String availability;
  final List<String> highlights;
  final Map<String, String> attributes;
  final String? statusMessage;

  ProfileAboutData copyWith({
    String? bio,
    List<String>? sports,
    String? position,
    String? availability,
    List<String>? highlights,
    Map<String, String>? attributes,
    String? statusMessage,
  }) {
    return ProfileAboutData(
      bio: bio ?? this.bio,
      sports: sports ?? List<String>.from(this.sports),
      position: position ?? this.position,
      availability: availability ?? this.availability,
      highlights: highlights ?? List<String>.from(this.highlights),
      attributes: attributes ?? Map<String, String>.from(this.attributes),
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class SkillMetric {
  const SkillMetric({
    required this.name,
    required this.score,
    required this.maxScore,
    required this.description,
    required this.icon,
  });

  final String name;
  final double score;
  final double maxScore;
  final String description;
  final IconData icon;

  double get progress => maxScore == 0 ? 0 : (score / maxScore).clamp(0, 1);
}

class PerformanceTrendPoint {
  const PerformanceTrendPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class AchievementHighlight {
  const AchievementHighlight({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.date,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime date;
}

class SkillPerformanceSummary {
  const SkillPerformanceSummary({
    required this.overallRating,
    required this.skillMetrics,
    required this.recentTrends,
    required this.achievements,
  });

  final double overallRating;
  final List<SkillMetric> skillMetrics;
  final List<PerformanceTrendPoint> recentTrends;
  final List<AchievementHighlight> achievements;
}

class AssociationCardData {
  const AssociationCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.role,
    required this.imageUrl,
    required this.tags,
    this.location,
    this.status,
    this.description,
    this.since,
    this.ownerName,
    this.ownerId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String role;
  final String imageUrl;
  final List<String> tags;
  final String? location;
  final String? status;
  final String? description;
  final DateTime? since;
  final String? ownerName;
  final String? ownerId;
}

class MatchmakingShowcase {
  const MatchmakingShowcase({
    required this.tagline,
    required this.about,
    required this.images,
    required this.age,
    required this.city,
    required this.sports,
    this.seeking = const [],
    this.distanceKm,
    this.distanceLink,
    this.featuredTeam,
    this.featuredVenue,
    this.featuredCoach,
    this.featuredTournament,
    required this.allowMessagesFromFriendsOnly,
  });

  final String tagline;
  final String about;
  final List<String> images;
  final int age;
  final String city;
  final List<String> sports;
  final List<String> seeking;
  final double? distanceKm;
  final String? distanceLink;
  final AssociationCardData? featuredTeam;
  final AssociationCardData? featuredVenue;
  final AssociationCardData? featuredCoach;
  final AssociationCardData? featuredTournament;
  final bool allowMessagesFromFriendsOnly;

  MatchmakingShowcase copyWith({
    String? tagline,
    String? about,
    List<String>? images,
    int? age,
    String? city,
    List<String>? sports,
    List<String>? seeking,
    double? distanceKm,
    String? distanceLink,
    AssociationCardData? featuredTeam,
    AssociationCardData? featuredVenue,
    AssociationCardData? featuredCoach,
    AssociationCardData? featuredTournament,
    bool? allowMessagesFromFriendsOnly,
  }) {
    return MatchmakingShowcase(
      tagline: tagline ?? this.tagline,
      about: about ?? this.about,
      images: images ?? List<String>.from(this.images),
      age: age ?? this.age,
      city: city ?? this.city,
      sports: sports ?? List<String>.from(this.sports),
      seeking: seeking ?? List<String>.from(this.seeking),
      distanceKm: distanceKm ?? this.distanceKm,
      distanceLink: distanceLink ?? this.distanceLink,
      featuredTeam: featuredTeam ?? this.featuredTeam,
      featuredVenue: featuredVenue ?? this.featuredVenue,
      featuredCoach: featuredCoach ?? this.featuredCoach,
      featuredTournament: featuredTournament ?? this.featuredTournament,
      allowMessagesFromFriendsOnly:
          allowMessagesFromFriendsOnly ?? this.allowMessagesFromFriendsOnly,
    );
  }
}

class ReviewEntry {
  const ReviewEntry({
    required this.id,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.rating,
    required this.comment,
    required this.relationship,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String authorAvatarUrl;
  final double rating;
  final String comment;
  final String relationship;
  final DateTime createdAt;
}

class ContactLink {
  const ContactLink({
    this.key,
    required this.label,
    required this.icon,
    required this.url,
  });

  final String? key;
  final String label;
  final IconData icon;
  final String url;
}

class ContactPreferences {
  const ContactPreferences({
    required this.primaryActionLabel,
    required this.links,
    required this.allowMessagesFromFriendsOnly,
  });

  final String primaryActionLabel;
  final List<ContactLink> links;
  final bool allowMessagesFromFriendsOnly;
}

class PublicProfileData {
  const PublicProfileData({
    required this.identity,
    required this.stats,
    required this.about,
    required this.skillPerformance,
    required this.teams,
    required this.tournaments,
    required this.coaches,
    required this.venues,
    required this.communityPosts,
    required this.matchmaking,
    required this.reviews,
    required this.contactPreferences,
    required this.postsCount,
    required this.matchesCount,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    required this.isFollowedByViewer,
    required this.followers,
    required this.following,
    required this.mutualConnections,
    required this.availablePosts,
    required this.availableAssociations,
    required this.matchmakingLibrary,
    required this.featuredPostIds,
  });

  final ProfileIdentity identity;
  final List<ProfileStat> stats;
  final ProfileAboutData about;
  final SkillPerformanceSummary skillPerformance;
  final List<AssociationCardData> teams;
  final List<AssociationCardData> tournaments;
  final List<AssociationCardData> coaches;
  final List<AssociationCardData> venues;
  final List<CommunityPost> communityPosts;
  final MatchmakingShowcase matchmaking;
  final List<ReviewEntry> reviews;
  final ContactPreferences contactPreferences;

  final int postsCount;
  final int matchesCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool isFollowedByViewer;
  final List<ProfileConnection> followers;
  final List<ProfileConnection> following;
  final List<ProfileConnection> mutualConnections;

  /// Posts available for selection in the admin panel
  final List<CommunityPost> availablePosts;

  /// Pool of associations (teams, tournaments, venues, coaches) the player can request
  final Map<String, List<AssociationCardData>> availableAssociations;

  /// Library of matchmaking images that can be added
  final List<String> matchmakingLibrary;

  /// Community posts selected for public display
  final List<String> featuredPostIds;
}

