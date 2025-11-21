import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported user roles for the navigation shell.
enum AppUserRole {
  guest,
  player,
  coach,
  teamOwner,
  admin,
  mvp,
}

/// Lightweight auth state used by the router to determine access.
class AuthState {
  const AuthState({
    required this.isAuthenticated,
    required this.role,
  });

  const AuthState.unauthenticated()
      : isAuthenticated = false,
        role = AppUserRole.guest;

  const AuthState.authenticated(AppUserRole role)
      : isAuthenticated = true,
        role = role;

  final bool isAuthenticated;
  final AppUserRole role;

  AuthState copyWith({
    bool? isAuthenticated,
    AppUserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
    );
  }
}

/// Simple auth controller for mocking role changes across the app shell.
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState.unauthenticated());

  final _controller = StreamController<AuthState>.broadcast();

  /// Exposes state changes as a stream for routers/listeners.
  Stream<AuthState> get changes => _controller.stream;

  @override
  set state(AuthState value) {
    super.state = value;
    _controller.add(value);
  }

  void signIn({AppUserRole role = AppUserRole.player}) {
    state = AuthState.authenticated(role);
  }

  void signOut() {
    state = const AuthState.unauthenticated();
  }

  void updateRole(AppUserRole role) {
    state = AuthState.authenticated(role);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});
