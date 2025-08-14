import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../models/models.dart';

/// Service for handling tournament-specific notifications
class TournamentNotificationService {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ TEAM REGISTRATION NOTIFICATIONS ============

  /// Send notification when team submits registration
  Future<void> sendTeamRegistrationNotification({
    required Tournament tournament,
    required TournamentTeamRegistration registration,
  }) async {
    try {
      await _notificationService.createNotification(
        userId: tournament.organizerId,
        title: 'New Team Registration',
        message: '${registration.teamName} wants to join ${tournament.name}',
        type: NotificationType.tournamentRegistration,
        data: {
          'tournamentId': tournament.id,
          'tournamentName': tournament.name,
          'teamId': registration.teamId,
          'teamName': registration.teamName,
          'captainId': registration.captainId,
          'captainName': registration.captainName,
          'registrationId': registration.id,
        },
      );

      if (kDebugMode) {
        debugPrint('📧 TournamentNotificationService: Registration notification sent to ${tournament.organizerName}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentNotificationService: Failed to send registration notification - $e');
      }
    }
  }

  /// Send notification when team registration is approved
  Future<void> sendTeamApprovalNotification({
    required Tournament tournament,
    required TournamentTeamRegistration registration,
  }) async {
    try {
      // Notify team captain
      await _notificationService.createNotification(
        userId: registration.captainId,
        title: 'Team Registration Approved! 🎉',
        message: '${registration.teamName} has been approved for ${tournament.name}',
        type: NotificationType.tournamentApproval,
        data: {
          'tournamentId': tournament.id,
          'tournamentName': tournament.name,
          'teamId': registration.teamId,
          'teamName': registration.teamName,
        },
      );

      // Notify all team members
      for (final memberId in registration.teamMemberIds) {
        if (memberId != registration.captainId) {
          await _notificationService.createNotification(
            userId: memberId,
            title: 'Your Team Joined Tournament! 🎉',
            message: '${registration.teamName} has been approved for ${tournament.name}',
            type: NotificationType.tournamentTeamUpdate,
            data: {
              'tournamentId': tournament.id,
              'tournamentName': tournament.name,
              'teamId': registration.teamId,
              'teamName': registration.teamName,
              'captainId': registration.captainId,
              'captainName': registration.captainName,
            },
          );
        }
      }

      if (kDebugMode) {
        debugPrint('📧 TournamentNotificationService: Approval notifications sent to ${registration.teamName}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentNotificationService: Failed to send approval notifications - $e');
      }
    }
  }

  /// Send notification when team registration is rejected
  Future<void> sendTeamRejectionNotification({
    required Tournament tournament,
    required TournamentTeamRegistration registration,
    String? reason,
  }) async {
    try {
      await _notificationService.createNotification(
        userId: registration.captainId,
        title: 'Team Registration Declined',
        message: 'Your registration for ${tournament.name} was not approved${reason != null ? ': $reason' : ''}',
        type: NotificationType.tournamentRejection,
        data: {
          'tournamentId': tournament.id,
          'tournamentName': tournament.name,
          'teamId': registration.teamId,
          'teamName': registration.teamName,
          'reason': reason,
        },
      );

      if (kDebugMode) {
        debugPrint('📧 TournamentNotificationService: Rejection notification sent to ${registration.captainName}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentNotificationService: Failed to send rejection notification - $e');
      }
    }
  }

  /// Send notification when team is removed from tournament
  Future<void> sendTeamRemovalNotification({
    required Tournament tournament,
    required TournamentTeamRegistration registration,
    String? reason,
  }) async {
    try {
      // Notify team captain
      await _notificationService.createNotification(
        userId: registration.captainId,
        title: 'Team Removed from Tournament',
        message: '${registration.teamName} has been removed from ${tournament.name}${reason != null ? ': $reason' : ''}',
        type: NotificationType.tournamentRemoval,
        data: {
          'tournamentId': tournament.id,
          'tournamentName': tournament.name,
          'teamId': registration.teamId,
          'teamName': registration.teamName,
          'reason': reason,
        },
      );

      // Notify all team members
      for (final memberId in registration.teamMemberIds) {
        if (memberId != registration.captainId) {
          await _notificationService.createNotification(
            userId: memberId,
            title: 'Team Removed from Tournament',
            message: '${registration.teamName} has been removed from ${tournament.name}',
            type: NotificationType.tournamentTeamUpdate,
            data: {
              'tournamentId': tournament.id,
              'tournamentName': tournament.name,
              'teamId': registration.teamId,
              'teamName': registration.teamName,
              'reason': reason,
            },
          );
        }
      }

      if (kDebugMode) {
        debugPrint('📧 TournamentNotificationService: Removal notifications sent to ${registration.teamName}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentNotificationService: Failed to send removal notifications - $e');
      }
    }
  }

  // ============ MATCH NOTIFICATIONS ============

  /// Send notification when match is scheduled
  Future<void> sendMatchScheduleNotification({
    required Tournament tournament,
    required TournamentMatch match,
    required List<String> participantIds,
  }) async {
    try {
      for (final participantId in participantIds) {
        await _notificationService.createNotification(
          userId: participantId,
          title: 'Match Scheduled 📅',
          message: '${match.team1Name} vs ${match.team2Name} in ${tournament.name}',
          type: NotificationType.matchScheduled,
          data: {
            'tournamentId': tournament.id,
            'tournamentName': tournament.name,
            'matchId': match.id,
            'team1Name': match.team1Name,
            'team2Name': match.team2Name,
            'scheduledDate': match.scheduledDate.toIso8601String(),
            'round': match.round,
          },
        );
      }

      if (kDebugMode) {
        debugPrint('📧 TournamentNotificationService: Match schedule notifications sent for ${match.team1Name} vs ${match.team2Name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentNotificationService: Failed to send match schedule notifications - $e');
      }
    }
  }

  /// Send notification when match score is updated
  Future<void> sendScoreUpdateNotification({
    required Tournament tournament,
    required TournamentMatch match,
    required List<String> participantIds,
  }) async {
    try {
      final scoreText = '${match.team1Name} ${match.team1Score} - ${match.team2Score} ${match.team2Name}';
      final winnerText = match.winnerTeamName != null ? ' • Winner: ${match.winnerTeamName}' : '';

      for (final participantId in participantIds) {
        await _notificationService.createNotification(
          userId: participantId,
          title: 'Match Score Updated 📊',
          message: '$scoreText$winnerText',
          type: NotificationType.scoreUpdate,
          data: {
            'tournamentId': tournament.id,
            'tournamentName': tournament.name,
            'matchId': match.id,
            'team1Name': match.team1Name,
            'team2Name': match.team2Name,
            'team1Score': match.team1Score,
            'team2Score': match.team2Score,
            'winnerTeamId': match.winnerTeamId,
            'winnerTeamName': match.winnerTeamName,
          },
        );
      }

      if (kDebugMode) {
        debugPrint('📧 TournamentNotificationService: Score update notifications sent for ${match.team1Name} vs ${match.team2Name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentNotificationService: Failed to send score update notifications - $e');
      }
    }
  }

  // ============ TOURNAMENT COMPLETION NOTIFICATIONS ============

  /// Send notification when tournament winner is declared
  Future<void> sendWinnerDeclarationNotification({
    required Tournament tournament,
    required List<String> allParticipantIds,
  }) async {
    try {
      for (final participantId in allParticipantIds) {
        await _notificationService.createNotification(
          userId: participantId,
          title: 'Tournament Complete! 🏆',
          message: '${tournament.winnerTeamName} won ${tournament.name}!',
          type: NotificationType.tournamentComplete,
          data: {
            'tournamentId': tournament.id,
            'tournamentName': tournament.name,
            'winnerTeamId': tournament.winnerTeamId,
            'winnerTeamName': tournament.winnerTeamName,
            'winningPrize': tournament.winningPrize,
          },
        );
      }

      if (kDebugMode) {
        debugPrint('📧 TournamentNotificationService: Winner declaration notifications sent for ${tournament.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentNotificationService: Failed to send winner declaration notifications - $e');
      }
    }
  }

  // ============ HELPER METHODS ============

  /// Get all participant IDs for a tournament (all team members)
  Future<List<String>> getTournamentParticipantIds(String tournamentId) async {
    try {
      final registrationsQuery = await _firestore
          .collection('tournament_registrations')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('status', isEqualTo: TeamRegistrationStatus.approved.name)
          .get();

      final participantIds = <String>{};
      
      for (final doc in registrationsQuery.docs) {
        final registration = TournamentTeamRegistration.fromMap(doc.data());
        participantIds.addAll(registration.teamMemberIds);
      }

      return participantIds.toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentNotificationService: Failed to get participant IDs - $e');
      }
      return [];
    }
  }
}
