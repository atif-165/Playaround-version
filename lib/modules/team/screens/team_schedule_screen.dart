import 'package:flutter/material.dart';

import 'team_matches_overview_screen.dart';

/// Legacy route wrapper that now forwards to the matches overview experience.
class TeamScheduleScreen extends StatelessWidget {
  const TeamScheduleScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  final String teamId;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    return TeamMatchesOverviewScreen(
      teamId: teamId,
      teamName: teamName,
    );
  }
}
 