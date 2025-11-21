import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../modules/team/models/team_model.dart';
import '../modules/chat/services/chat_service.dart';
import '../modules/team/services/team_service.dart';

/// Helper to sync existing teams with their chat members
/// Use this ONCE to fix teams created before automatic chat sync was implemented
class SyncTeamChatMembers {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final TeamService _teamService = TeamService();

  /// Sync a specific team's members with its group chat
  Future<void> syncTeamChat(String teamId) async {
    try {
      print('🔄 Syncing team chat for: $teamId');

      // Get team data
      final team = await _teamService.getTeamById(teamId);
      if (team == null) {
        print('❌ Team not found: $teamId');
        return;
      }

      final chatId = 'team_$teamId';

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat with all members
        print('📝 Creating new group chat for ${team.name}');

        final allMemberIds = <String>[];
        final allMemberNames = <String>[];
        final allMemberImages = <String>[];

        // Add all players
        for (var player in team.players) {
          allMemberIds.add(player.id);
          allMemberNames.add(player.name);
          allMemberImages.add(player.profileImageUrl ?? '');
        }

        // Add all coaches
        for (var coach in team.coaches) {
          allMemberIds.add(coach.id);
          allMemberNames.add(coach.name);
          allMemberImages.add(coach.profileImageUrl ?? '');
        }

        await _chatService.createTeamGroupChat(
          teamId: teamId,
          teamName: team.name,
          teamImageUrl: team.profileImageUrl,
          memberIds: allMemberIds,
          memberNames: allMemberNames,
          memberImageUrls: allMemberImages,
        );

        print('✅ Created group chat with ${allMemberIds.length} members');
      } else {
        // Chat exists - sync members
        print('🔄 Syncing members to existing chat');

        final chatData = chatDoc.data();
        final existingParticipants = (chatData?['participants'] as List?)
                ?.map((p) => (p as Map)['userId'] as String)
                .toSet() ??
            {};

        var addedCount = 0;

        // Add players not in chat
        for (var player in team.players) {
          if (!existingParticipants.contains(player.id)) {
            await _chatService.addParticipantToGroupChat(
              chatId: chatId,
              userId: player.id,
              userName: player.name,
              userImageUrl: player.profileImageUrl,
              role: player.role == TeamRole.owner ? 'admin' : 'member',
            );
            addedCount++;
            print('  ➕ Added player: ${player.name}');
          }
        }

        // Add coaches not in chat
        for (var coach in team.coaches) {
          if (!existingParticipants.contains(coach.id)) {
            await _chatService.addParticipantToGroupChat(
              chatId: chatId,
              userId: coach.id,
              userName: coach.name,
              userImageUrl: coach.profileImageUrl,
              role: 'member',
            );
            addedCount++;
            print('  ➕ Added coach: ${coach.name}');
          }
        }

        print('✅ Synced chat - added $addedCount new members');
      }
    } catch (e) {
      print('❌ Error syncing team chat: $e');
      if (kDebugMode) {
        print('Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Sync all teams in the database
  Future<void> syncAllTeams() async {
    try {
      print('🔄 Starting sync for all teams...');

      final teamsSnapshot = await _firestore.collection('teams').get();
      var successCount = 0;
      var errorCount = 0;

      for (var doc in teamsSnapshot.docs) {
        try {
          await syncTeamChat(doc.id);
          successCount++;
        } catch (e) {
          errorCount++;
          print('❌ Failed to sync team ${doc.id}: $e');
        }
      }

      print('✅ Sync complete: $successCount succeeded, $errorCount failed');
    } catch (e) {
      print('❌ Error syncing all teams: $e');
    }
  }

  /// Sync Thunder Warriors specifically
  Future<void> syncThunderWarriors() async {
    try {
      print('⚡ Syncing Thunder Warriors team...');

      // Search for Thunder Warriors team
      final teamsSnapshot = await _firestore
          .collection('teams')
          .where('name', isEqualTo: 'Thunder Warriors')
          .limit(1)
          .get();

      if (teamsSnapshot.docs.isEmpty) {
        print('❌ Thunder Warriors team not found');
        print('💡 Please provide the exact team name or ID');
        return;
      }

      final teamDoc = teamsSnapshot.docs.first;
      await syncTeamChat(teamDoc.id);

      print('⚡ Thunder Warriors sync complete!');
    } catch (e) {
      print('❌ Error syncing Thunder Warriors: $e');
    }
  }
}
