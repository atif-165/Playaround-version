import 'package:flutter/material.dart';
import '../../../theming/colors.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  // Simulate API calls with mock data
  Future<DashboardData> getDashboardData(
      String userId, UserRole userRole) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return DashboardData(
      userProfile: _getMockUserProfile(userId, userRole),
      upcomingEvents: _getMockUpcomingEvents(),
      teamInfo: userRole != UserRole.admin ? _getMockTeamInfo() : null,
      performanceStats: _getMockPerformanceStats(userRole),
      communityHighlights: _getMockCommunityHighlights(),
      notifications: _getMockNotifications(),
      adminData: userRole == UserRole.admin ? _getMockAdminData() : null,
    );
  }

  UserProfile _getMockUserProfile(String userId, UserRole userRole) {
    final roleNames = {
      UserRole.player: 'Player',
      UserRole.coach: 'Coach',
      UserRole.team: 'Team Manager',
      UserRole.admin: 'Administrator',
    };

    return UserProfile(
      id: userId,
      name: 'John Doe',
      role: roleNames[userRole] ?? 'Player',
      photoUrl: null,
      quickStats: QuickStats(
        matches: userRole == UserRole.coach ? 45 : 23,
        wins: userRole == UserRole.coach ? 38 : 18,
        ranking: userRole == UserRole.coach ? 'Elite Coach' : '#247',
        nextEvent: 'Basketball Match - Tomorrow 6:00 PM',
      ),
    );
  }

  List<UpcomingEvent> _getMockUpcomingEvents() {
    return [
      UpcomingEvent(
        id: '1',
        title: 'Basketball Match',
        type: 'Match',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Sports Complex A',
        description: 'Championship semi-final',
      ),
      UpcomingEvent(
        id: '2',
        title: 'Coaching Session',
        type: 'Training',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        location: 'Training Ground B',
        description: 'Skill development session',
      ),
      UpcomingEvent(
        id: '3',
        title: 'Team Practice',
        type: 'Practice',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        location: 'Indoor Court 1',
        description: 'Weekly team practice',
      ),
    ];
  }

  TeamInfo? _getMockTeamInfo() {
    return TeamInfo(
      id: 'team1',
      name: 'Thunder Hawks',
      sport: 'Basketball',
      logoUrl: null,
      members: [
        TeamMember(
          id: '1',
          name: 'Alex Johnson',
          role: 'Captain',
          photoUrl: null,
          isOnline: true,
        ),
        TeamMember(
          id: '2',
          name: 'Sarah Wilson',
          role: 'Player',
          photoUrl: null,
          isOnline: false,
        ),
        TeamMember(
          id: '3',
          name: 'Mike Chen',
          role: 'Player',
          photoUrl: null,
          isOnline: true,
        ),
        TeamMember(
          id: '4',
          name: 'Emma Davis',
          role: 'Player',
          photoUrl: null,
          isOnline: true,
        ),
      ],
    );
  }

  PerformanceStats _getMockPerformanceStats(UserRole userRole) {
    return PerformanceStats(
      winRate: userRole == UserRole.coach ? 84.4 : 78.3,
      topPerformer: userRole == UserRole.coach ? 'Sarah Wilson' : 'You',
      analytics: {
        'Speed': 85.0,
        'Accuracy': 78.0,
        'Stamina': 92.0,
        'Teamwork': 88.0,
      },
      skillProgress: [
        SkillProgress(
          skillName: 'Speed',
          currentLevel: 85.0,
          previousLevel: 80.0,
          color: ColorsManager.success,
        ),
        SkillProgress(
          skillName: 'Accuracy',
          currentLevel: 78.0,
          previousLevel: 75.0,
          color: ColorsManager.warning,
        ),
        SkillProgress(
          skillName: 'Stamina',
          currentLevel: 92.0,
          previousLevel: 88.0,
          color: ColorsManager.primary,
        ),
      ],
    );
  }

  List<CommunityHighlight> _getMockCommunityHighlights() {
    return [
      CommunityHighlight(
        id: '1',
        type: 'Achievement',
        title: 'New Personal Best!',
        content: 'Alex Johnson scored 35 points in last night\'s game!',
        author: 'Team Thunder Hawks',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 24,
      ),
      CommunityHighlight(
        id: '2',
        type: 'Discussion',
        title: 'Training Tips',
        content: 'What\'s your favorite warm-up routine before matches?',
        author: 'Coach Martinez',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 12,
      ),
      CommunityHighlight(
        id: '3',
        type: 'Event',
        title: 'Tournament Registration Open',
        content: 'Summer Championship registration is now open!',
        author: 'PlayAround Admin',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likes: 45,
      ),
    ];
  }

  List<DashboardNotification> _getMockNotifications() {
    return [
      DashboardNotification(
        id: '1',
        title: 'Match Reminder',
        message: 'Your match starts in 2 hours at Sports Complex A',
        type: 'reminder',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
        actionUrl: '/matches/1',
      ),
      DashboardNotification(
        id: '2',
        title: 'Booking Confirmed',
        message: 'Your court booking for tomorrow has been confirmed',
        type: 'booking',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        actionUrl: '/bookings/2',
      ),
      DashboardNotification(
        id: '3',
        title: 'New Message',
        message: 'You have a new message from Coach Martinez',
        type: 'message',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
        actionUrl: '/chat/coach-martinez',
      ),
    ];
  }

  AdminData _getMockAdminData() {
    return AdminData(
      pendingApprovals: 12,
      reportedContent: 3,
      activeUsers: 1247,
      systemStats: {
        'Total Users': 5420,
        'Active Sessions': 234,
        'Bookings Today': 67,
        'Revenue Today': 2340,
      },
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Implementation for marking notification as read
  }

  Future<void> dismissNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Implementation for dismissing notification
  }
}
