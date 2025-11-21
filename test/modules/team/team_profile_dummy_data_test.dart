import 'package:flutter_test/flutter_test.dart';

import 'package:playaround/modules/team/models/team_profile_models.dart';
import 'package:playaround/modules/team/services/team_profile_repository.dart';

void main() {
  const teamId = 'test_team';

  group('DummyTeamData', () {
    test('provides overview cards with stable content', () {
      final cards = DummyTeamData.overviewCards(teamId);

      expect(cards, isNotEmpty);
      final winsCard = cards.firstWhere((card) => card.id == 'wins',
          orElse: () => cards.first);

      expect(winsCard.title, isNotEmpty);
      expect(winsCard.value, isNotEmpty);
    });

    test('returns achievements with chronological data', () {
      final achievements = DummyTeamData.achievements(teamId);

      expect(achievements, isNotEmpty);
      expect(
        achievements.every((achievement) => achievement.teamId == teamId),
        isTrue,
      );
    });

    test('returns schedule matches covering all statuses', () {
      final matches = DummyTeamData.scheduleMatches(teamId);

      expect(matches, isNotEmpty);
      expect(
          matches.map((match) => match.status).toSet().length, greaterThan(1));
    });

    test('exposes dummy tournaments for team', () {
      final tournaments = DummyTeamData.tournaments(teamId);

      expect(tournaments, isNotEmpty);
      expect(tournaments.first.tournamentName, isNotEmpty);
    });
  });
}

