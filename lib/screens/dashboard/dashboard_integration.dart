/// Dashboard Integration Helper
/// Provides integration utilities for dashboard functionality

import 'package:flutter/material.dart';
import '../../routing/routes.dart';
import 'models/dashboard_models.dart';

/// Dashboard integration class for managing dashboard state and actions
class DashboardIntegration {
  /// Get user role from user data
  static UserRole getUserRole(Map<String, dynamic> userData) {
    final roleString = userData['role'] as String?;
    switch (roleString?.toLowerCase()) {
      case 'coach':
        return UserRole.coach;
      case 'team':
        return UserRole.team;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.player;
    }
  }

  /// Convert quick action type to route
  static String? getRouteForAction(QuickActionType actionType) {
    switch (actionType) {
      case QuickActionType.bookFacility:
        return Routes.venueBookingScreen;
      case QuickActionType.userMatchmaking:
        return Routes.playerMatchmakingScreen;
      case QuickActionType.joinTeam:
        return Routes.teamFinderScreen;
      case QuickActionType.trackSkills:
        return Routes.skillDashboardScreen;
      case QuickActionType.communityForums:
        return Routes.communityHome;
      case QuickActionType.tournaments:
        return Routes.tournamentListScreen;
    }
  }

  /// Get icon for quick action
  static IconData getIconForAction(QuickActionType actionType) {
    switch (actionType) {
      case QuickActionType.bookFacility:
        return Icons.location_on;
      case QuickActionType.userMatchmaking:
        return Icons.people_outline;
      case QuickActionType.joinTeam:
        return Icons.groups;
      case QuickActionType.trackSkills:
        return Icons.trending_up;
      case QuickActionType.communityForums:
        return Icons.forum;
      case QuickActionType.tournaments:
        return Icons.emoji_events;
    }
  }

  /// Get color for quick action
  static Color getColorForAction(QuickActionType actionType) {
    switch (actionType) {
      case QuickActionType.bookFacility:
        return Colors.blue;
      case QuickActionType.userMatchmaking:
        return Colors.orange;
      case QuickActionType.joinTeam:
        return Colors.purple;
      case QuickActionType.trackSkills:
        return Colors.green;
      case QuickActionType.communityForums:
        return Colors.teal;
      case QuickActionType.tournaments:
        return Colors.amber;
    }
  }

  /// Format event type for display
  static String formatEventType(String type) {
    switch (type.toLowerCase()) {
      case 'match':
        return 'Match';
      case 'practice':
        return 'Practice';
      case 'tournament':
        return 'Tournament';
      case 'training':
        return 'Training';
      default:
        return type;
    }
  }

  /// Get icon for event type
  static IconData getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'match':
        return Icons.sports_soccer;
      case 'practice':
        return Icons.fitness_center;
      case 'tournament':
        return Icons.emoji_events;
      case 'training':
        return Icons.school;
      default:
        return Icons.event;
    }
  }
}

/// Extension methods for dashboard data
extension DashboardDataExtensions on DashboardData {
  /// Check if user has any upcoming events
  bool get hasUpcomingEvents => upcomingEvents.isNotEmpty;

  /// Check if user is part of a team
  bool get hasTeam => teamInfo != null;

  /// Check if user has performance stats
  bool get hasPerformanceStats => performanceStats != null;

  /// Get unread notifications count
  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;
}
