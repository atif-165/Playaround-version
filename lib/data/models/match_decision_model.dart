enum MatchDecisionType {
  like,
  dislike,
  superLike;

  static MatchDecisionType fromString(String value) {
    return MatchDecisionType.values.firstWhere(
      (element) => element.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MatchDecisionType.dislike,
    );
  }
}

class MatchDecisionModel {
  final String id;
  final String swiperId;
  final String targetId;
  final MatchDecisionType decision;
  final DateTime timestamp;
  final bool synced;

  const MatchDecisionModel({
    required this.id,
    required this.swiperId,
    required this.targetId,
    required this.decision,
    required this.timestamp,
    this.synced = false,
  });

  factory MatchDecisionModel.fromJson(Map<String, dynamic> json) {
    return MatchDecisionModel(
      id: json['id'] as String,
      swiperId: json['swiperId'] as String,
      targetId: json['targetId'] as String,
      decision: MatchDecisionType.fromString(
        json['decision'] as String? ?? 'dislike',
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'swiperId': swiperId,
      'targetId': targetId,
      'decision': decision.name,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
    };
  }

  MatchDecisionModel markSynced() {
    return MatchDecisionModel(
      id: id,
      swiperId: swiperId,
      targetId: targetId,
      decision: decision,
      timestamp: timestamp,
      synced: true,
    );
  }
}
