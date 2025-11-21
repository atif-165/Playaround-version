import 'package:cloud_firestore/cloud_firestore.dart';

/// Summary card shown in the team overview header
class TeamOverviewCard {
  final String id;
  final String title;
  final String value;
  final String? trendLabel;
  final bool? trendIsPositive;
  final String? description;
  final String? iconName;

  const TeamOverviewCard({
    required this.id,
    required this.title,
    required this.value,
    this.trendLabel,
    this.trendIsPositive,
    this.description,
    this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'value': value,
      if (trendLabel != null) 'trendLabel': trendLabel,
      if (trendIsPositive != null) 'trendIsPositive': trendIsPositive,
      if (description != null) 'description': description,
      if (iconName != null) 'iconName': iconName,
    };
  }

  factory TeamOverviewCard.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TeamOverviewCard(
      id: doc.id,
      title: data['title']?.toString() ?? 'Untitled',
      value: data['value']?.toString() ?? '--',
      trendLabel: data['trendLabel']?.toString(),
      trendIsPositive: data['trendIsPositive'] as bool?,
      description: data['description']?.toString(),
      iconName: data['iconName']?.toString(),
    );
  }
}

/// Custom stat tracked for a team
class TeamCustomStat {
  final String id;
  final String label;
  final String value;
  final String? units;
  final String? description;

  const TeamCustomStat({
    required this.id,
    required this.label,
    required this.value,
    this.units,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'value': value,
      if (units != null) 'units': units,
      if (description != null) 'description': description,
    };
  }

  factory TeamCustomStat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TeamCustomStat(
      id: doc.id,
      label: data['label']?.toString() ?? 'Stat',
      value: data['value']?.toString() ?? '0',
      units: data['units']?.toString(),
      description: data['description']?.toString(),
    );
  }
}

/// Lightweight player stat for cards/tables
class PlayerHighlightStat {
  final String playerId;
  final String playerName;
  final String avatarUrl;
  final Map<String, num> metrics;

  const PlayerHighlightStat({
    required this.playerId,
    required this.playerName,
    this.avatarUrl = '',
    this.metrics = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      if (avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      'metrics': metrics,
    };
  }

  factory PlayerHighlightStat.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final metricsRaw = data['metrics'];
    return PlayerHighlightStat(
      playerId: data['playerId']?.toString() ?? doc.id,
      playerName: data['playerName']?.toString() ?? 'Unknown Player',
      avatarUrl: data['avatarUrl']?.toString() ?? '',
      metrics: metricsRaw is Map<String, dynamic>
          ? metricsRaw.map(
              (key, value) => MapEntry(
                key,
                value is num
                    ? value
                    : num.tryParse(value?.toString() ?? '0') ?? 0,
              ),
            )
          : const {},
    );
  }
}

/// Historical venue entry for team history timeline
class TeamHistoryEntry {
  final String id;
  final String venue;
  final String opponent;
  final DateTime date;
  final String matchType;
  final String result;
  final String summary;
  final String location;
  final String? matchId;
  final String? venueId;

  const TeamHistoryEntry({
    required this.id,
    required this.venue,
    required this.opponent,
    required this.date,
    required this.matchType,
    required this.result,
    required this.summary,
    required this.location,
    this.matchId,
    this.venueId,
  });

  Map<String, dynamic> toMap() {
    return {
      'venue': venue,
      'opponent': opponent,
      'date': Timestamp.fromDate(date),
      'matchType': matchType,
      'result': result,
      'summary': summary,
      'location': location,
      if (matchId != null) 'matchId': matchId,
      if (venueId != null) 'venueId': venueId,
    };
  }

  factory TeamHistoryEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final timestamp = data['date'];
    return TeamHistoryEntry(
      id: doc.id,
      venue: data['venue']?.toString() ?? 'Unknown Venue',
      opponent: data['opponent']?.toString() ?? 'Unknown Opponent',
      date: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      matchType: data['matchType']?.toString() ?? 'Friendly',
      result: data['result']?.toString() ?? 'Pending',
      summary: data['summary']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      matchId: data['matchId']?.toString(),
      venueId: data['venueId']?.toString(),
    );
  }
}

/// Lightweight tournament card model for team profile page
class TeamTournamentEntry {
  final String id;
  final String tournamentName;
  final String status;
  final String stage;
  final DateTime startDate;
  final String? tournamentId;
  final String? logoUrl;

  const TeamTournamentEntry({
    required this.id,
    required this.tournamentName,
    required this.status,
    required this.stage,
    required this.startDate,
    this.tournamentId,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'tournamentName': tournamentName,
      'status': status,
      'stage': stage,
      'startDate': Timestamp.fromDate(startDate),
      if (tournamentId != null) 'tournamentId': tournamentId,
      if (logoUrl != null) 'logoUrl': logoUrl,
    };
  }

  factory TeamTournamentEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final timestamp = data['startDate'];
    return TeamTournamentEntry(
      id: doc.id,
      tournamentName: data['tournamentName']?.toString() ?? 'Tournament',
      status: data['status']?.toString() ?? 'Upcoming',
      stage: data['stage']?.toString() ?? 'Group Stage',
      startDate: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      tournamentId: data['tournamentId']?.toString(),
      logoUrl: data['logoUrl']?.toString(),
    );
  }
}

/// Quick DTO describing data provenance for UI copy
class TeamDataSourceDescriptor {
  final String label;
  final String description;
  final bool isAutomatic;

  const TeamDataSourceDescriptor({
    required this.label,
    required this.description,
    required this.isAutomatic,
  });
}

