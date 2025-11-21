import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:playaround/data/datasources/firestore_matchmaking_data_source.dart';
import 'package:playaround/data/datasources/mock_data_source.dart';
import 'package:playaround/data/models/match_decision_model.dart';
import 'package:playaround/data/models/player_model.dart';
import 'package:playaround/data/repositories/matchmaking_repository.dart';
import 'package:playaround/screens/explore/screens/player_matchmaking_screen.dart';

void main() {
  group('PlayerMatchmakingScreen', () {
    late TestMatchmakingRepository repository;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'test_user'),
      );
      repository = TestMatchmakingRepository(players: _samplePlayers);
    });

    testWidgets('swiping updates like counters', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) => MaterialApp(home: child),
          child: PlayerMatchmakingScreen(
            repository: repository,
            userLocation: const GeoPoint(37.0, -122.0),
            firebaseAuth: mockAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('likes_chip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('like_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('likes_chip')), findsOneWidget);
      expect(repository.decisions.length, 1);
      expect(repository.decisions.first.decision, equals('like'));

      await tester.tap(find.byKey(const Key('super_like_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Super likes 1/3'), findsOneWidget);
      expect(repository.decisions.length, 2);
      expect(repository.decisions.last.decision, equals('superLike'));
    });
  });
}

class TestMatchmakingRepository extends MatchmakingRepository {
  TestMatchmakingRepository({
    required List<PlayerModel> players,
  })  : _players = players,
        decisions = [],
        super(
          mockDataSource: MockDataSource(),
          firestoreDataSource: _FakeFirestoreDataSource(),
          firestore: _fakeFirestoreInstance,
        );

  final List<PlayerModel> _players;
  final List<_Decision> decisions;

  @override
  Future<void> init() async {}

  @override
  Future<List<PlayerModel>> loadPlayers({bool prioritizeRemote = true}) async {
    return _players;
  }

  @override
  Future<void> updateMatchDecision({
    required String swiperId,
    required String targetId,
    required MatchDecisionType decision,
  }) async {
    decisions.add(_Decision(targetId: targetId, decision: decision.name));
  }

  @override
  Future<void> syncMatchDecisions() async {}
}

class _Decision {
  const _Decision({required this.targetId, required this.decision});
  final String targetId;
  final String decision;
}

class _FakeFirestoreDataSource extends FirestoreMatchmakingDataSource {
  _FakeFirestoreDataSource() : super(firestore: _fakeFirestoreInstance);

  @override
  Future<List<PlayerModel>> fetchPlayers({int limit = 50}) async => [];
}

final FakeFirebaseFirestore _fakeFirestoreInstance = FakeFirebaseFirestore();

final _samplePlayers = [
  PlayerModel(
    id: 'p1',
    fullName: 'Alex Morgan',
    age: 25,
    gender: 'female',
    location: 'San Francisco',
    latitude: 37.0,
    longitude: -122.0,
    avatarUrl: null,
    sports: const ['Soccer'],
    skillRatings: const {'Soccer': 0.8},
    experienceLevel: 0.7,
    availability: const ['sat_morning'],
    interests: const [],
    bio: '',
    reputationScore: 4.5,
    lastActive: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  PlayerModel(
    id: 'p2',
    fullName: 'Jamie Lee',
    age: 27,
    gender: 'male',
    location: 'Oakland',
    latitude: 37.8,
    longitude: -122.2,
    avatarUrl: null,
    sports: const ['Basketball'],
    skillRatings: const {'Basketball': 0.6},
    experienceLevel: 0.6,
    availability: const ['sun_evening'],
    interests: const [],
    bio: '',
    reputationScore: 4.0,
    lastActive: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];
