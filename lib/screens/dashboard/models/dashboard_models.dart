import 'package:flutter/material.dart';

enum UserRole { player, coach, team, admin }

enum QuickActionType {
  bookFacility,
  findCoach,
  joinTeam,
  trackSkills,
  communityForums,
  tournaments,
}

class DashboardData {
  final UserProfile? userProfile;
  final List<UpcomingEvent> upcomingEvents;
  final TeamInfo? teamInfo;
  final PerformanceStats? performanceStats;
  final List<CommunityHighlight> communityHighlights;
  final List<DashboardNotification> notifications;
  final AdminData? adminData;

  DashboardData({
    this.userProfile,
    this.upcomingEvents = const [],
    this.teamInfo,
    this.performanceStats,
    this.communityHighlights = const [],
    this.notifications = const [],
    this.adminData,
  });
}

class UserProfile {
  final String id;
  final String name;
  final String role;
  final String? photoUrl;
  final QuickStats quickStats;

  UserProfile({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
    required this.quickStats,
  });
}

class QuickStats {
  final int matches;
  final int wins;
  final String ranking;
  final String? nextEvent;

  QuickStats({
    required this.matches,
    required this.wins,
    required this.ranking,
    this.nextEvent,
  });

  double get winRate => matches > 0 ? (wins / matches) * 100 : 0.0;
}

class UpcomingEvent {
  final String id;
  final String title;
  final String type;
  final DateTime dateTime;
  final String location;
  final String? description;

  UpcomingEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.location,
    this.description,
  });
}

class TeamInfo {
  final String id;
  final String name;
  final String sport;
  final List<TeamMember> members;
  final String? logoUrl;

  TeamInfo({
    required this.id,
    required this.name,
    required this.sport,
    required this.members,
    this.logoUrl,
  });
}

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String? photoUrl;
  final bool isOnline;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
    this.isOnline = false,
  });
}

class PerformanceStats {
  final double winRate;
  final List<SkillProgress> skillProgress;
  final String topPerformer;
  final Map<String, double> analytics;

  PerformanceStats({
    required this.winRate,
    required this.skillProgress,
    required this.topPerformer,
    required this.analytics,
  });
}

class SkillProgress {
  final String skillName;
  final double currentLevel;
  final double previousLevel;
  final Color color;

  SkillProgress({
    required this.skillName,
    required this.currentLevel,
    required this.previousLevel,
    required this.color,
  });

  double get improvement => currentLevel - previousLevel;
}

class CommunityHighlight {
  final String id;
  final String type;
  final String title;
  final String content;
  final String author;
  final DateTime timestamp;
  final int likes;

  CommunityHighlight({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.author,
    required this.timestamp,
    required this.likes,
  });
}

class DashboardNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;

  DashboardNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
  });
}

class AdminData {
  final int pendingApprovals;
  final int reportedContent;
  final int activeUsers;
  final Map<String, int> systemStats;

  AdminData({
    required this.pendingApprovals,
    required this.reportedContent,
    required this.activeUsers,
    required this.systemStats,
  });
}

class QuickAction {
  final QuickActionType type;
  final String title;
  final IconData icon;
  final Color color;
  final bool isVisible;

  QuickAction({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    this.isVisible = true,
  });
}