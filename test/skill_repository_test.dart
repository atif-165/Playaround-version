import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:playaround/modules/skill_tracking/models/models.dart';
import 'package:playaround/modules/skill_tracking/repositories/skill_repository.dart';
import 'package:playaround/modules/skill_tracking/services/skill_tracking_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._temporaryPath);

  final String _temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => _temporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;
  late SkillRepository repository;
  late SkillTrackingService service;
  late PathProviderPlatform originalPathProvider;
  late Directory tempDirectory;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository = SkillRepository(firestore: firestore);
    service = SkillTrackingService(repository: repository);
    originalPathProvider = PathProviderPlatform.instance;
    tempDirectory = await Directory.systemTemp.createTemp('skill_export_test');
    PathProviderPlatform.instance =
        _FakePathProviderPlatform(tempDirectory.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('SkillRepository', () {
    const playerId = 'player-1';
    const coachId = 'coach-1';

    SessionLog _buildSessionLog({
      required DateTime date,
      required Map<SkillType, int> scores,
    }) {
      return SessionLog(
        id: '',
        playerId: playerId,
        loggedBy: coachId,
        date: date,
        skillScores: scores,
        skillChanges: {
          for (final entry in scores.entries) entry.key: 0,
        },
        source: SessionLogSource.manual,
        context: 'Training session',
        notes: 'Logged for testing',
        metadata: const {'source': 'test'},
        createdAt: date,
        updatedAt: date,
      );
    }

    test('addSessionLog stores and retrieves session logs by player', () async {
      final now = DateTime(2025, 1, 1);
      final log = _buildSessionLog(
        date: now,
        scores: {
          SkillType.speed: 72,
          SkillType.endurance: 68,
          SkillType.accuracy: 74,
        },
      );

      final logId = await repository.addSessionLog(log);
      expect(logId, isNotNull);

      final fetchedLogs = await repository.getPlayerSessionLogs(playerId);
      expect(fetchedLogs, hasLength(1));

      final storedLog = fetchedLogs.first;
      expect(storedLog.playerId, equals(playerId));
      expect(storedLog.getSkillScore(SkillType.speed), equals(72));
      expect(storedLog.getSkillScore(SkillType.accuracy), equals(74));
    });

    test('active goals update progress when new session logs are added',
        () async {
      final now = DateTime(2025, 2, 1);
      final goal = Goal(
        id: '',
        playerId: playerId,
        skillType: SkillType.speed,
        currentScore: 60,
        targetScore: 80,
        targetDate: now.add(const Duration(days: 30)),
        status: GoalStatus.active,
        description: 'Improve sprint speed',
        createdAt: now,
        updatedAt: now,
      );

      final goalId = await repository.addGoal(goal);
      expect(goalId, isNotNull);

      final sessionLog = _buildSessionLog(
        date: now.add(const Duration(days: 1)),
        scores: {
          SkillType.speed: 85,
          SkillType.endurance: 78,
          SkillType.accuracy: 82,
        },
      );

      await repository.addSessionLog(sessionLog);

      final updatedGoals = await repository.getPlayerGoals(playerId);
      expect(updatedGoals, hasLength(1));
      final updatedGoal = updatedGoals.first;
      expect(updatedGoal.currentScore, equals(85));
      expect(updatedGoal.status, equals(GoalStatus.achieved));
    });
  });

  group('SkillTrackingService export', () {
    const playerId = 'player-2';
    const coachId = 'coach-2';

    SessionLog _buildLog(DateTime date, int speed, int stamina, int accuracy) {
      return SessionLog(
        id: '',
        playerId: playerId,
        loggedBy: coachId,
        date: date,
        skillScores: {
          SkillType.speed: speed,
          SkillType.endurance: stamina,
          SkillType.accuracy: accuracy,
        },
        skillChanges: const {},
        source: SessionLogSource.manual,
        context: 'Daily drill',
        notes: 'Automated test log',
        metadata: const {},
        createdAt: date,
        updatedAt: date,
      );
    }

    test('exportSkillAnalyticsCsv generates file with headers', () async {
      final now = DateTime(2025, 3, 10);

      await repository.addSessionLog(
        _buildLog(now.subtract(const Duration(days: 1)), 70, 68, 75),
      );
      await repository.addSessionLog(
        _buildLog(now, 78, 74, 80),
      );

      final exportFile = await service.exportSkillAnalyticsCsv(
        playerId: playerId,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
      );

      expect(exportFile, isNotNull);
      final contents = await exportFile!.readAsString();

      expect(
        contents,
        contains('Date,Source,Notes,Speed,Stamina,Accuracy'),
      );
      expect(contents.split('\n').length >= 3, isTrue);

      if (await exportFile.exists()) {
        await exportFile.delete();
      }
    });
  });
}
