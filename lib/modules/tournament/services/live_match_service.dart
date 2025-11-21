import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live_match_models.dart';
import '../models/tournament_match_model.dart';
import 'tournament_match_service.dart';

/// Service that aggregates live match data (scores, commentary, reactions,
/// stats) from Firestore. The initial version relies on the base
/// [TournamentMatchService] and enriches it with additional collections.
class LiveMatchService {
  LiveMatchService({
    TournamentMatchService? matchService,
    FirebaseFirestore? firestore,
  })  : _matchService = matchService ?? TournamentMatchService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final TournamentMatchService _matchService;
  final FirebaseFirestore _firestore;

  Stream<LiveMatch> watchMatch(String matchId) async* {
    await for (final match in _matchService.getMatchStream(matchId)) {
      if (match == null) continue;
      final live = await _composeLiveMatch(match);
      yield live;
    }
  }

  Future<LiveMatch> _composeLiveMatch(TournamentMatch match) async {
    final live = LiveMatchMapper.fromTournamentMatch(match);

    final reactions = await _firestore
        .collection('matches')
        .doc(match.id)
        .collection('reactions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final reactionModels = reactions.docs
        .map(
          (doc) => LiveReaction(
            id: doc.id,
            userId: doc['userId'] as String? ?? 'unknown',
            userName: doc['userName'] as String? ?? 'Fan',
            emoji: doc['emoji'] as String?,
            text: doc['text'] as String?,
            reactionType: doc['reactionType'] as String? ?? 'emoji',
            timestamp:
                (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        )
        .toList();

    return LiveMatch(
      id: live.id,
      tournamentId: live.tournamentId,
      phase: live.phase,
      template: live.template,
      teamA: live.teamA,
      teamB: live.teamB,
      startTime: live.startTime,
      venueName: live.venueName,
      commentary: live.commentary,
      reactions: reactionModels,
      matchStats: live.matchStats,
      playerStats: live.playerStats,
      metadata: match.metadata != null
          ? Map<String, dynamic>.from(match.metadata!)
          : null,
      admins: live.admins,
      lockedAt: live.lockedAt,
      winnerTeamId: live.winnerTeamId,
      countdownSeconds: live.countdownSeconds,
      currentMinute: live.currentMinute,
    );
  }
}

