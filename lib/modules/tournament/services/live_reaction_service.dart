import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live_match_models.dart';

class LiveReactionService {
  LiveReactionService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reactionCollection(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('reactions');
  }

  Stream<List<LiveReaction>> watchReactions(
    String matchId, {
    int limit = 50,
  }) {
    return _reactionCollection(matchId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => LiveReaction(
                  id: doc.id,
                  userId: doc.data()['userId'] as String? ?? 'fan',
                  userName: doc.data()['userName'] as String? ?? 'Fan',
                  emoji: doc.data()['emoji'] as String?,
                  text: doc.data()['text'] as String?,
                  reactionType: doc.data()['reactionType'] as String? ?? 'emoji',
                  timestamp:
                      (doc.data()['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                ),
              )
              .toList(),
        );
  }

  Future<void> addReaction({
    required String matchId,
    required String userId,
    required String userName,
    String? emoji,
    String? text,
    required String reactionType,
  }) async {
    await _reactionCollection(matchId).add({
      'userId': userId,
      'userName': userName,
      'emoji': emoji,
      'text': text,
      'reactionType': reactionType,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

