import '../../modules/team/models/models.dart';

/// Enum for team permissions
enum TeamPermission {
  // Team management
  editTeamProfile,
  deleteTeam,
  manageTeamSettings,
  
  // Roster management
  addPlayer,
  removePlayer,
  managePlayerRoles,
  viewPlayerDetails,
  
  // Schedule management
  createEvent,
  editEvent,
  deleteEvent,
  manageSchedule,
  
  // Communication
  sendAnnouncements,
  manageTeamChat,
  viewTeamChat,
  
  // Performance
  viewPerformance,
  managePerformance,
  
  // Tournaments
  registerTournament,
  manageTournamentRegistration,
  
  // Admin
  managePermissions,
  viewAdminPanel,
}

/// Class for managing team permissions based on user roles
class TeamPermissions {
  /// Check if a user with given role has a specific permission
  static bool hasPermission(TeamRole role, TeamPermission permission) {
    switch (role) {
      case TeamRole.owner:
        return _ownerPermissions.contains(permission);
      case TeamRole.captain:
        return _captainPermissions.contains(permission);
      case TeamRole.viceCaptain:
        return _viceCaptainPermissions.contains(permission);
      case TeamRole.member:
        return _memberPermissions.contains(permission);
    }
  }

  /// Get all permissions for a given role
  static List<TeamPermission> getPermissionsForRole(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return List.from(_ownerPermissions);
      case TeamRole.captain:
        return List.from(_captainPermissions);
      case TeamRole.viceCaptain:
        return List.from(_viceCaptainPermissions);
      case TeamRole.member:
        return List.from(_memberPermissions);
    }
  }

  /// Check if user can manage team (owner or captain)
  static bool canManageTeam(TeamRole role) {
    return role == TeamRole.owner || role == TeamRole.captain;
  }

  /// Check if user can manage roster
  static bool canManageRoster(TeamRole role) {
    return role == TeamRole.owner || role == TeamRole.captain;
  }

  /// Check if user can manage schedule
  static bool canManageSchedule(TeamRole role) {
    return role == TeamRole.owner || role == TeamRole.captain || role == TeamRole.viceCaptain;
  }

  /// Check if user can send announcements
  static bool canSendAnnouncements(TeamRole role) {
    return role == TeamRole.owner || role == TeamRole.captain;
  }

  /// Check if user can invite players
  static bool canInvitePlayers(TeamRole role) {
    return role == TeamRole.owner || role == TeamRole.captain;
  }

  /// Check if user can view admin panel
  static bool canViewAdminPanel(TeamRole role) {
    return role == TeamRole.owner || role == TeamRole.captain;
  }

  /// Owner permissions - full access
  static const Set<TeamPermission> _ownerPermissions = {
    // Team management
    TeamPermission.editTeamProfile,
    TeamPermission.deleteTeam,
    TeamPermission.manageTeamSettings,
    
    // Roster management
    TeamPermission.addPlayer,
    TeamPermission.removePlayer,
    TeamPermission.managePlayerRoles,
    TeamPermission.viewPlayerDetails,
    
    // Schedule management
    TeamPermission.createEvent,
    TeamPermission.editEvent,
    TeamPermission.deleteEvent,
    TeamPermission.manageSchedule,
    
    // Communication
    TeamPermission.sendAnnouncements,
    TeamPermission.manageTeamChat,
    TeamPermission.viewTeamChat,
    
    // Performance
    TeamPermission.viewPerformance,
    TeamPermission.managePerformance,
    
    // Tournaments
    TeamPermission.registerTournament,
    TeamPermission.manageTournamentRegistration,
    
    // Admin
    TeamPermission.managePermissions,
    TeamPermission.viewAdminPanel,
  };

  /// Captain permissions - most team management except deleting team
  static const Set<TeamPermission> _captainPermissions = {
    // Team management
    TeamPermission.editTeamProfile,
    TeamPermission.manageTeamSettings,
    
    // Roster management
    TeamPermission.addPlayer,
    TeamPermission.removePlayer,
    TeamPermission.managePlayerRoles,
    TeamPermission.viewPlayerDetails,
    
    // Schedule management
    TeamPermission.createEvent,
    TeamPermission.editEvent,
    TeamPermission.deleteEvent,
    TeamPermission.manageSchedule,
    
    // Communication
    TeamPermission.sendAnnouncements,
    TeamPermission.manageTeamChat,
    TeamPermission.viewTeamChat,
    
    // Performance
    TeamPermission.viewPerformance,
    TeamPermission.managePerformance,
    
    // Tournaments
    TeamPermission.registerTournament,
    TeamPermission.manageTournamentRegistration,
    
    // Admin
    TeamPermission.viewAdminPanel,
  };

  /// Vice Captain permissions - limited management
  static const Set<TeamPermission> _viceCaptainPermissions = {
    // Roster management
    TeamPermission.viewPlayerDetails,
    
    // Schedule management
    TeamPermission.createEvent,
    TeamPermission.editEvent,
    TeamPermission.manageSchedule,
    
    // Communication
    TeamPermission.viewTeamChat,
    
    // Performance
    TeamPermission.viewPerformance,
    
    // Tournaments
    TeamPermission.registerTournament,
  };

  /// Member permissions - basic access
  static const Set<TeamPermission> _memberPermissions = {
    // Roster management
    TeamPermission.viewPlayerDetails,
    
    // Communication
    TeamPermission.viewTeamChat,
    
    // Performance
    TeamPermission.viewPerformance,
    
    // Tournaments
    TeamPermission.registerTournament,
  };
}

/// Extension for easy permission checking
extension TeamRolePermissions on TeamRole {
  /// Check if this role has a specific permission
  bool hasPermission(TeamPermission permission) {
    return TeamPermissions.hasPermission(this, permission);
  }

  /// Get all permissions for this role
  List<TeamPermission> get permissions {
    return TeamPermissions.getPermissionsForRole(this);
  }

  /// Check if this role can manage team
  bool get canManageTeam {
    return TeamPermissions.canManageTeam(this);
  }

  /// Check if this role can manage roster
  bool get canManageRoster {
    return TeamPermissions.canManageRoster(this);
  }

  /// Check if this role can manage schedule
  bool get canManageSchedule {
    return TeamPermissions.canManageSchedule(this);
  }

  /// Check if this role can send announcements
  bool get canSendAnnouncements {
    return TeamPermissions.canSendAnnouncements(this);
  }

  /// Check if this role can invite players
  bool get canInvitePlayers {
    return TeamPermissions.canInvitePlayers(this);
  }

  /// Check if this role can view admin panel
  bool get canViewAdminPanel {
    return TeamPermissions.canViewAdminPanel(this);
  }
}
