import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Represents persisted lightweight profile data for the current session.
class SessionData {
  const SessionData({
    required this.uid,
    required this.email,
    this.displayName,
    this.role,
    this.onboardingComplete,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? role;
  final bool? onboardingComplete;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'email': email,
        if (displayName != null) 'displayName': displayName,
        if (role != null) 'role': role,
        if (onboardingComplete != null)
          'onboardingComplete': onboardingComplete,
      };

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      role: json['role'] as String?,
      onboardingComplete: json['onboardingComplete'] as bool?,
    );
  }
}

/// Handles secure persistence for auth session metadata and user role.
class SessionManager {
  SessionManager({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'session_data';
  static const _roleKey = 'user_role';
  static const _onboardingKey = 'onboarding_complete';

  final FlutterSecureStorage _storage;

  Future<void> persistSession(SessionData session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
    if (session.role != null) {
      await saveRole(session.role!);
    }
    if (session.onboardingComplete != null) {
      await setOnboardingComplete(session.onboardingComplete!);
    }
  }

  Future<SessionData?> getSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    return SessionData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveRole(String role) {
    return _storage.write(key: _roleKey, value: role);
  }

  Future<void> clearRole() {
    return _storage.delete(key: _roleKey);
  }

  Future<String?> getRole() {
    return _storage.read(key: _roleKey);
  }

  Future<void> setOnboardingComplete(bool complete) {
    return _storage.write(
      key: _onboardingKey,
      value: complete ? 'true' : 'false',
    );
  }

  Future<bool> isOnboardingComplete() async {
    final raw = await _storage.read(key: _onboardingKey);
    return raw == 'true';
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _sessionKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _onboardingKey),
    ]);
  }
}
