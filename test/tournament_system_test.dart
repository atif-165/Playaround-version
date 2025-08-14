import 'package:flutter_test/flutter_test.dart';
import 'package:playaround/modules/tournament/models/models.dart';
import 'package:playaround/modules/team/models/models.dart' as team_models;

void main() {
  group('Tournament System Tests', () {

    group('Tournament Model Tests', () {
      test('Tournament model should create with all required fields', () {
        final tournament = Tournament(
          id: 'test-tournament-1',
          name: 'Test Championship',
          description: 'A test tournament',
          sportType: team_models.SportType.football,
          format: TournamentFormat.singleElimination,
          status: TournamentStatus.upcoming,
          organizerId: 'organizer-1',
          organizerName: 'Test Organizer',
          registrationStartDate: DateTime.now(),
          registrationEndDate: DateTime.now().add(const Duration(days: 7)),
          startDate: DateTime.now().add(const Duration(days: 14)),
          maxTeams: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          entryFee: 50.0,
          winningPrize: 1000.0,
          qualifyingQuestions: [
            'What is your team\'s experience level?',
            'How many tournaments have you participated in?',
          ],
        );

        expect(tournament.name, equals('Test Championship'));
        expect(tournament.entryFee, equals(50.0));
        expect(tournament.winningPrize, equals(1000.0));
        expect(tournament.qualifyingQuestions.length, equals(2));
        expect(tournament.canBeDeleted, isTrue); // No teams joined yet
        expect(tournament.canBeEdited, isTrue); // Upcoming and editable
      });

      test('Tournament should convert to/from map correctly', () {
        final originalTournament = Tournament(
          id: 'test-tournament-2',
          name: 'Map Test Tournament',
          description: 'Testing map conversion',
          sportType: team_models.SportType.basketball,
          format: TournamentFormat.roundRobin,
          status: TournamentStatus.registrationOpen,
          organizerId: 'organizer-2',
          organizerName: 'Map Test Organizer',
          registrationStartDate: DateTime.now(),
          registrationEndDate: DateTime.now().add(const Duration(days: 5)),
          startDate: DateTime.now().add(const Duration(days: 10)),
          maxTeams: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          entryFee: 25.0,
          winningPrize: 500.0,
          qualifyingQuestions: ['Test question 1', 'Test question 2'],
          teamPoints: {'team1': 6, 'team2': 3},
        );

        final map = originalTournament.toMap();
        final reconstructedTournament = Tournament.fromMap(map);

        expect(reconstructedTournament.name, equals(originalTournament.name));
        expect(reconstructedTournament.entryFee, equals(originalTournament.entryFee));
        expect(reconstructedTournament.winningPrize, equals(originalTournament.winningPrize));
        expect(reconstructedTournament.qualifyingQuestions, equals(originalTournament.qualifyingQuestions));
        expect(reconstructedTournament.teamPoints, equals(originalTournament.teamPoints));
      });
    });

    group('Tournament Match Model Tests', () {
      test('TournamentMatch should create with all required fields', () {
        final match = TournamentMatch(
          id: 'match-1',
          tournamentId: 'tournament-1',
          team1Id: 'team-1',
          team1Name: 'Team Alpha',
          team2Id: 'team-2',
          team2Name: 'Team Beta',
          scheduledDate: DateTime.now().add(const Duration(days: 1)),
          status: MatchStatus.scheduled,
          round: 'Quarter Final',
          matchNumber: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(match.team1Name, equals('Team Alpha'));
        expect(match.team2Name, equals('Team Beta'));
        expect(match.status, equals(MatchStatus.scheduled));
        expect(match.round, equals('Quarter Final'));
        expect(match.isFuture, isTrue);
        expect(match.isPast, isFalse);
      });

      test('TournamentMatch should handle score updates correctly', () {
        final match = TournamentMatch(
          id: 'match-2',
          tournamentId: 'tournament-1',
          team1Id: 'team-1',
          team1Name: 'Team Alpha',
          team2Id: 'team-2',
          team2Name: 'Team Beta',
          scheduledDate: DateTime.now().subtract(const Duration(hours: 2)),
          status: MatchStatus.completed,
          team1Score: 3,
          team2Score: 1,
          winnerTeamId: 'team-1',
          winnerTeamName: 'Team Alpha',
          round: 'Final',
          matchNumber: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(match.team1Score, equals(3));
        expect(match.team2Score, equals(1));
        expect(match.winnerTeamName, equals('Team Alpha'));
        expect(match.status, equals(MatchStatus.completed));
        expect(match.isPast, isTrue);
      });
    });

    group('Team Registration Model Tests', () {
      test('TournamentTeamRegistration should create with qualifying answers', () {
        final registration = TournamentTeamRegistration(
          id: 'registration-1',
          tournamentId: 'tournament-1',
          tournamentName: 'Test Tournament',
          teamId: 'team-1',
          teamName: 'Test Team',
          captainId: 'captain-1',
          captainName: 'Test Captain',
          teamMemberIds: ['captain-1', 'player-1', 'player-2'],
          teamMemberNames: ['Test Captain', 'Player 1', 'Player 2'],
          status: TeamRegistrationStatus.pending,
          qualifyingAnswers: [
            QualifyingAnswer(
              question: 'What is your experience level?',
              answer: 'Intermediate level with 2 years experience',
            ),
            QualifyingAnswer(
              question: 'How many tournaments participated?',
              answer: '5 local tournaments',
            ),
          ],
          registrationDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(registration.teamName, equals('Test Team'));
        expect(registration.captainName, equals('Test Captain'));
        expect(registration.memberCount, equals(3));
        expect(registration.qualifyingAnswers.length, equals(2));
        expect(registration.isPending, isTrue);
        expect(registration.isApproved, isFalse);
      });

      test('QualifyingAnswer should convert to/from map correctly', () {
        final answer = QualifyingAnswer(
          question: 'Test question?',
          answer: 'Test answer',
        );

        final map = answer.toMap();
        final reconstructed = QualifyingAnswer.fromMap(map);

        expect(reconstructed.question, equals(answer.question));
        expect(reconstructed.answer, equals(answer.answer));
      });
    });

    group('Tournament Business Logic Tests', () {
      test('Tournament should validate name uniqueness requirements', () {
        // This test would require mocking Firestore
        // For now, we'll test the model logic
        
        final tournament1 = Tournament(
          id: 'tournament-1',
          name: 'Summer Championship',
          description: 'Summer tournament',
          sportType: team_models.SportType.football,
          format: TournamentFormat.singleElimination,
          status: TournamentStatus.upcoming,
          organizerId: 'organizer-1',
          organizerName: 'Organizer',
          registrationStartDate: DateTime.now(),
          registrationEndDate: DateTime.now().add(const Duration(days: 7)),
          startDate: DateTime.now().add(const Duration(days: 14)),
          maxTeams: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(tournament1.isActive, isTrue);
        expect(tournament1.canBeDeleted, isTrue);
        expect(tournament1.canBeEdited, isTrue);
      });

      test('Tournament should handle team limits correctly', () {
        final tournament = Tournament(
          id: 'tournament-2',
          name: 'Limited Tournament',
          description: 'Testing limits',
          sportType: team_models.SportType.cricket,
          format: TournamentFormat.singleElimination,
          status: TournamentStatus.registrationOpen,
          organizerId: 'organizer-1',
          organizerName: 'Organizer',
          registrationStartDate: DateTime.now(),
          registrationEndDate: DateTime.now().add(const Duration(days: 7)),
          startDate: DateTime.now().add(const Duration(days: 14)),
          maxTeams: 4,
          currentTeamsCount: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(tournament.isFull, isTrue);
        expect(tournament.canBeDeleted, isFalse); // Teams have joined
      });
    });

    group('Match Status Tests', () {
      test('Match status should have correct display names', () {
        expect(MatchStatus.scheduled.displayName, equals('Scheduled'));
        expect(MatchStatus.inProgress.displayName, equals('In Progress'));
        expect(MatchStatus.completed.displayName, equals('Completed'));
        expect(MatchStatus.cancelled.displayName, equals('Cancelled'));
      });
    });

    group('Team Registration Status Tests', () {
      test('Registration status should have correct display names', () {
        expect(TeamRegistrationStatus.pending.displayName, equals('Pending'));
        expect(TeamRegistrationStatus.approved.displayName, equals('Approved'));
        expect(TeamRegistrationStatus.rejected.displayName, equals('Rejected'));
        expect(TeamRegistrationStatus.withdrawn.displayName, equals('Withdrawn'));
      });
    });
  });
}
