import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:playaround/data/services/firebase_auth_service.dart';
import 'package:playaround/data/services/session_manager.dart';
import 'package:playaround/presentation/auth/providers.dart';

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

class MockSessionManager extends Mock implements SessionManager {}

class MockUser extends Mock implements User {}

class SessionDataFake extends Fake implements SessionData {
  @override
  String get uid => 'fake-uid';

  @override
  String get email => 'fake@example.com';

  @override
  String? get displayName => 'Fake User';

  @override
  String? get role => 'player';

  @override
  bool? get onboardingComplete => false;
}

Future<void> _pumpEventQueue([int times = 5]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(SessionDataFake());
    registerFallbackValue(false);
  });

  group('AuthStateNotifier', () {
    late MockFirebaseAuthService mockAuthService;
    late MockSessionManager mockSessionManager;
    late StreamController<User?> controller;
    late AuthStateNotifier notifier;

    setUp(() {
      mockAuthService = MockFirebaseAuthService();
      mockSessionManager = MockSessionManager();
      controller = StreamController<User?>();

      when(() => mockAuthService.authStateChanges())
          .thenAnswer((_) => controller.stream);
      when(() => mockAuthService.currentUser).thenReturn(null);
      when(() => mockSessionManager.clearSession()).thenAnswer((_) async {});
      when(() => mockSessionManager.getRole()).thenAnswer((_) async => null);
      when(() => mockSessionManager.isOnboardingComplete())
          .thenAnswer((_) async => false);
      when(() => mockSessionManager.persistSession(any<SessionData>()))
          .thenAnswer((_) async {});
      when(() => mockSessionManager.setOnboardingComplete(any<bool>()))
          .thenAnswer((_) async {});

      notifier = AuthStateNotifier(mockAuthService, mockSessionManager);
    });

    tearDown(() async {
      await controller.close();
      notifier.dispose();
    });

    test('emits unauthenticated when Firebase user is null', () async {
      controller.add(null);
      await _pumpEventQueue();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      verify(() => mockSessionManager.clearSession()).called(1);
    });

    test('emits emailUnverified for unverified users', () async {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(false);
      when(() => mockUser.uid).thenReturn('user-123');
      when(() => mockUser.email).thenReturn('user@example.com');
      when(() => mockUser.displayName).thenReturn('User');
      when(() => mockAuthService.currentUser).thenReturn(mockUser);

      controller.add(mockUser);
      await _pumpEventQueue();

      expect(notifier.state.status, AuthStatus.emailUnverified);
      expect(notifier.state.user, mockUser);
      expect(notifier.state.isOnboardingComplete, isFalse);
      verify(() => mockSessionManager.persistSession(any<SessionData>()))
          .called(1);
    });

    test('emits authenticatedCoach with onboarding complete flag', () async {
      final mockUser = MockUser();
      when(() => mockUser.emailVerified).thenReturn(true);
      when(() => mockUser.uid).thenReturn('coach-1');
      when(() => mockUser.email).thenReturn('coach@example.com');
      when(() => mockUser.displayName).thenReturn('Coach');
      when(() => mockAuthService.currentUser).thenReturn(mockUser);
      when(() => mockSessionManager.getRole()).thenAnswer((_) async => 'coach');
      when(() => mockSessionManager.isOnboardingComplete())
          .thenAnswer((_) async => true);

      controller.add(mockUser);
      await _pumpEventQueue();

      expect(notifier.state.status, AuthStatus.authenticatedCoach);
      expect(notifier.state.role, UserRole.coach);
      expect(notifier.state.isOnboardingComplete, isTrue);
      verify(() => mockSessionManager.persistSession(any<SessionData>()))
          .called(1);
    });

    test('markOnboardingComplete updates state and session', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid');
      when(() => mockUser.email).thenReturn('complete@example.com');
      when(() => mockUser.displayName).thenReturn('Complete');
      when(() => mockAuthService.currentUser).thenReturn(mockUser);

      await notifier.markOnboardingComplete();

      expect(notifier.state.isOnboardingComplete, isTrue);
      verify(() => mockSessionManager.setOnboardingComplete(any<bool>()))
          .called(greaterThanOrEqualTo(1));
      verify(() => mockSessionManager.persistSession(any<SessionData>()))
          .called(1);
    });
  });

  group('OnboardingController', () {
    late MockFirebaseAuthService mockAuthService;
    late MockSessionManager mockSessionManager;
    late MockUser mockUser;
    late ProviderContainer container;

    setUp(() async {
      mockAuthService = MockFirebaseAuthService();
      mockSessionManager = MockSessionManager();
      mockUser = MockUser();
      var onboardingCompleteFlag = false;

      when(() => mockAuthService.authStateChanges())
          .thenAnswer((_) => const Stream<User?>.empty());
      when(() => mockAuthService.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('onboarding-user');
      when(() => mockUser.email).thenReturn('onboarding@example.com');
      when(() => mockUser.displayName).thenReturn('Onboarded');

      when(() => mockSessionManager.getRole()).thenAnswer((_) async => null);
      when(() => mockSessionManager.isOnboardingComplete())
          .thenAnswer((_) async => onboardingCompleteFlag);
      when(() => mockSessionManager.saveRole(any<String>()))
          .thenAnswer((_) async {});
      when(() => mockSessionManager.clearRole()).thenAnswer((_) async {});
      when(() => mockSessionManager.persistSession(any<SessionData>()))
          .thenAnswer((_) async {});
      when(() => mockSessionManager.setOnboardingComplete(any<bool>()))
          .thenAnswer((invocation) async {
        onboardingCompleteFlag = invocation.positionalArguments.first as bool;
      });

      container = ProviderContainer(
        overrides: [
          sessionManagerProvider.overrideWithValue(mockSessionManager),
          authRepositoryProvider.overrideWithValue(mockAuthService),
          authStateProvider.overrideWith(
            (ref) => AuthStateNotifier(mockAuthService, mockSessionManager),
          ),
        ],
      );

      await _pumpEventQueue();
    });

    tearDown(() {
      container.dispose();
    });

    test('selectRole persists role and marks onboarding incomplete', () async {
      final controller = container.read(onboardingProvider.notifier);

      await controller.selectRole(UserRole.coach);

      final state = controller.state;
      expect(state.selectedRole, UserRole.coach);
      expect(state.isComplete, isFalse);
      verify(() => mockSessionManager.saveRole('coach')).called(1);
      verify(() => mockSessionManager.setOnboardingComplete(false)).called(1);
    });

    test('complete marks onboarding as finished', () async {
      final controller = container.read(onboardingProvider.notifier);

      await controller.complete();
      await _pumpEventQueue();

      final onboardingState = controller.state;
      final authState = container.read(authStateProvider);
      expect(onboardingState.isComplete, isTrue);
      expect(authState.isOnboardingComplete, isTrue);
      verify(() => mockSessionManager.setOnboardingComplete(true))
          .called(greaterThanOrEqualTo(1));
    });

    test('reset clears role and onboarding completion', () async {
      final controller = container.read(onboardingProvider.notifier);

      await controller.reset();

      final state = controller.state;
      final authState = container.read(authStateProvider);
      expect(state.selectedRole, isNull);
      expect(state.isComplete, isFalse);
      expect(authState.isOnboardingComplete, isFalse);
      verify(() => mockSessionManager.clearRole()).called(1);
      verify(() => mockSessionManager.setOnboardingComplete(false)).called(1);
    });
  });
}
