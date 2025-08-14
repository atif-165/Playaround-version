import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/user_profile.dart';
import '../../team/services/team_service.dart';
import '../../venue/services/venue_service.dart';

/// Service to handle tournament creation permissions
class TournamentPermissionService {
  final TeamService _teamService = TeamService();
  final VenueService _venueService = VenueService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user can create tournaments
  /// 
  /// Users can create tournaments if they are:
  /// 1. Coach (role == 'coach')
  /// 2. Team Captain (captain in any team)
  /// 3. Venue Owner (owns at least one venue)
  Future<TournamentCreationPermission> checkTournamentCreationPermission(
    UserProfile? userProfile,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const TournamentCreationPermission(
          canCreate: false,
          reason: 'User not authenticated',
        );
      }

      if (userProfile == null) {
        return const TournamentCreationPermission(
          canCreate: false,
          reason: 'User profile not found',
        );
      }

      // Check if user is a coach
      if (userProfile.role == UserRole.coach) {
        return const TournamentCreationPermission(
          canCreate: true,
          reason: 'User is a coach',
          permissionType: TournamentCreationPermissionType.coach,
        );
      }

      // Check if user is a team captain
      final isTeamCaptain = await _checkIfUserIsTeamCaptain();
      if (isTeamCaptain) {
        return const TournamentCreationPermission(
          canCreate: true,
          reason: 'User is a team captain',
          permissionType: TournamentCreationPermissionType.teamCaptain,
        );
      }

      // Check if user owns any venues
      final ownsVenues = await _checkIfUserOwnsVenues();
      if (ownsVenues) {
        return const TournamentCreationPermission(
          canCreate: true,
          reason: 'User owns venues',
          permissionType: TournamentCreationPermissionType.venueOwner,
        );
      }

      // User doesn't meet any criteria
      return const TournamentCreationPermission(
        canCreate: false,
        reason: 'Only Team Captains, Coaches, or Venue Owners can create tournaments',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking tournament creation permission: $e');
      }
      return TournamentCreationPermission(
        canCreate: false,
        reason: 'Error checking permissions: $e',
      );
    }
  }

  /// Check if user is a captain in any team
  Future<bool> _checkIfUserIsTeamCaptain() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final teams = await _teamService.getUserTeams().first;
      
      for (final team in teams) {
        final userMember = team.members.where(
          (member) => member.userId == user.uid,
        ).firstOrNull;
        
        if (userMember != null && 
            (userMember.role.name == 'captain' || userMember.role.name == 'owner')) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking team captain status: $e');
      }
      return false;
    }
  }

  /// Check if user owns any venues
  Future<bool> _checkIfUserOwnsVenues() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final venues = await _venueService.getMyVenues().first;
      return venues.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking venue ownership: $e');
      }
      return false;
    }
  }

  /// Get permission denial dialog message
  String getPermissionDenialMessage() {
    return 'Only Team Captains, Coaches, or Venue Owners can create tournaments.\n\n'
           'To create tournaments, you need to:\n'
           '• Be registered as a Coach, OR\n'
           '• Be a Captain of a team, OR\n'
           '• Own at least one venue';
  }
}

/// Result of tournament creation permission check
class TournamentCreationPermission {
  final bool canCreate;
  final String reason;
  final TournamentCreationPermissionType? permissionType;

  const TournamentCreationPermission({
    required this.canCreate,
    required this.reason,
    this.permissionType,
  });
}

/// Types of tournament creation permissions
enum TournamentCreationPermissionType {
  coach,
  teamCaptain,
  venueOwner,
}

extension TournamentCreationPermissionTypeExtension on TournamentCreationPermissionType {
  String get displayName {
    switch (this) {
      case TournamentCreationPermissionType.coach:
        return 'Coach';
      case TournamentCreationPermissionType.teamCaptain:
        return 'Team Captain';
      case TournamentCreationPermissionType.venueOwner:
        return 'Venue Owner';
    }
  }
}
