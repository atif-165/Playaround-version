import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/firebase_auth_service.dart';
import '../../data/services/session_manager.dart';

final authRepositoryProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionManagerProvider),
  ),
);

final onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
  (ref) => OnboardingController(ref, ref.watch(sessionManagerProvider)),
);

enum AuthStatus {
  unauthenticated,
  emailUnverified,
  authenticatedPlayer,
  authenticatedCoach,
}

enum UserRole {
  player,
  coach,
}

extension UserRoleX on UserRole {
  String get asStorageValue => name;
}

UserRole? userRoleFromStorage(String? value) {
  if (value == null) return null;
  return UserRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => UserRole.player,
  );
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.role,
    this.isLoading = false,
    this.errorMessage,
    this.isOnboardingComplete = false,
  });

  const AuthState.initial()
      : status = AuthStatus.unauthenticated,
        user = null,
        role = null,
        isLoading = false,
        errorMessage = null,
        isOnboardingComplete = false;

  final AuthStatus status;
  final User? user;
  final UserRole? role;
  final bool isLoading;
  final String? errorMessage;
  final bool isOnboardingComplete;

  static const Object _sentinel = Object();

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserRole? role,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? isOnboardingComplete,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._authService, this._sessionManager)
      : super(const AuthState.initial()) {
    _init();
  }

  final FirebaseAuthService _authService;
  final SessionManager _sessionManager;
  StreamSubscription<User?>? _authSubscription;

  void _init() {
    _authSubscription = _authService.authStateChanges().listen((user) async {
      await _emitStateForUser(user);
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _authService.reloadCurrentUser();
      await _emitStateForUser(_authService.currentUser);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? e.code,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _authService.sendEmailVerification();
      await _authService.reloadCurrentUser();
      await _emitStateForUser(_authService.currentUser);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? e.code,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signInWithGoogle();
      await _authService.reloadCurrentUser();
      await _emitStateForUser(_authService.currentUser);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? e.code,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> sendEmailVerification() {
    return _authService.sendEmailVerification();
  }

  Future<void> refreshUser() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.reloadCurrentUser();
      await _emitStateForUser(_authService.currentUser);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signOut();
      await _sessionManager.clearSession();
      state = const AuthState.initial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markOnboardingComplete() async {
    final user = _authService.currentUser;
    await _sessionManager.setOnboardingComplete(true);
    if (user != null) {
      await _persistSession(
        user,
        role: state.role,
        onboardingComplete: true,
      );
    }
    state = state.copyWith(isOnboardingComplete: true);
  }

  Future<void> markOnboardingIncomplete() async {
    final user = _authService.currentUser;
    await _sessionManager.setOnboardingComplete(false);
    if (user != null) {
      await _persistSession(
        user,
        role: state.role,
        onboardingComplete: false,
      );
    }
    state = state.copyWith(isOnboardingComplete: false);
  }

  Future<void> setRole(UserRole role) async {
    await _sessionManager.saveRole(role.asStorageValue);
    final currentUser = _authService.currentUser;
    await _persistSession(
      currentUser,
      role: role,
      onboardingComplete: state.isOnboardingComplete,
    );
    await _emitStateForUser(currentUser);
  }

  Future<void> _emitStateForUser(User? user) async {
    if (user == null) {
      await _sessionManager.clearSession();
      state = const AuthState.initial();
      debugPrint('[AuthStateNotifier] user=null -> unauthenticated');
      return;
    }

    final storedRole = await _sessionManager.getRole();
    final role = userRoleFromStorage(storedRole);
    final onboardingComplete = await _sessionManager.isOnboardingComplete();

    await _persistSession(
      user,
      role: role,
      onboardingComplete: onboardingComplete,
    );

    if (!user.emailVerified) {
      state = AuthState(
        status: AuthStatus.emailUnverified,
        user: user,
        role: role,
        isLoading: false,
        isOnboardingComplete: onboardingComplete,
      );
      debugPrint(
        '[AuthStateNotifier] user=${user.uid} emailVerified=false -> emailUnverified (role=$role, onboardingComplete=$onboardingComplete)',
      );
      return;
    }

    state = AuthState(
      status: _statusForRole(role),
      user: user,
      role: role,
      isLoading: false,
      isOnboardingComplete: onboardingComplete,
    );
    debugPrint(
      '[AuthStateNotifier] user=${user.uid} emailVerified=true -> status=${_statusForRole(role)} (role=$role, onboardingComplete=$onboardingComplete)',
    );
  }

  AuthStatus _statusForRole(UserRole? role) {
    switch (role) {
      case UserRole.coach:
        return AuthStatus.authenticatedCoach;
      case UserRole.player:
        return AuthStatus.authenticatedPlayer;
      case null:
        return AuthStatus.authenticatedPlayer;
    }
  }

  Future<void> _persistSession(
    User? user, {
    UserRole? role,
    bool? onboardingComplete,
  }) async {
    if (user == null) return;
    await _sessionManager.persistSession(
      SessionData(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        role: (role ?? state.role)?.asStorageValue,
        onboardingComplete: onboardingComplete ?? state.isOnboardingComplete,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}

class OnboardingState {
  const OnboardingState({
    this.selectedRole,
    this.currentPage = 0,
    this.isComplete = false,
  });

  final UserRole? selectedRole;
  final int currentPage;
  final bool isComplete;

  OnboardingState copyWith({
    UserRole? selectedRole,
    int? currentPage,
    bool? isComplete,
  }) {
    return OnboardingState(
      selectedRole: selectedRole ?? this.selectedRole,
      currentPage: currentPage ?? this.currentPage,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref, this._sessionManager)
      : super(const OnboardingState()) {
    _restoreState();
  }

  final Ref _ref;
  final SessionManager _sessionManager;

  final List<OnboardingPageContent> pages = const [
    OnboardingPageContent(
      title: 'Track Your Progress',
      description:
          'Monitor your skills, training sessions, and milestones with personalized dashboards.',
      asset: 'assets/images/placeholder.png',
    ),
    OnboardingPageContent(
      title: 'Discover Venues',
      description: 'Find and book nearby fields, courts, and gyms in minutes.',
      asset: 'assets/images/no-internet.png',
    ),
    OnboardingPageContent(
      title: 'Connect With Coaches',
      description: 'Chat with experienced coaches to elevate your performance.',
      asset: 'assets/images/loading.gif',
    ),
  ];

  Future<void> selectRole(UserRole role) async {
    state = state.copyWith(selectedRole: role, isComplete: false);
    await _sessionManager.saveRole(role.asStorageValue);
    await _ref.read(authStateProvider.notifier).markOnboardingIncomplete();
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  Future<void> complete() async {
    state = state.copyWith(isComplete: true);
    await _ref.read(authStateProvider.notifier).markOnboardingComplete();
    await _sessionManager.setOnboardingComplete(true);
  }

  Future<void> reset() async {
    state = const OnboardingState();
    await _sessionManager.clearRole();
    await _ref.read(authStateProvider.notifier).markOnboardingIncomplete();
  }

  Future<void> _restoreState() async {
    final storedRole = await _sessionManager.getRole();
    final restoredRole = userRoleFromStorage(storedRole);
    final onboardingComplete = await _sessionManager.isOnboardingComplete();
    state = state.copyWith(
      selectedRole: restoredRole,
      isComplete: onboardingComplete,
    );
  }
}

class OnboardingPageContent {
  const OnboardingPageContent({
    required this.title,
    required this.description,
    required this.asset,
  });

  final String title;
  final String description;
  final String asset;
}
