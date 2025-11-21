import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps [FirebaseAuth] interactions used throughout the authentication flow.
class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  static const bool _useEmulatorGoogleSignIn =
      bool.fromEnvironment('USE_EMULATOR_SIGNIN', defaultValue: false);
  static bool _googleInitialized = false;
  static Completer<void>? _googleInitializationCompleter;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_useEmulatorGoogleSignIn) {
      return;
    }
    if (_googleInitialized) {
      return;
    }
    if (_googleInitializationCompleter != null) {
      return _googleInitializationCompleter!.future;
    }

    final completer = Completer<void>();
    _googleInitializationCompleter = completer;

    try {
      await _googleSignIn.initialize();
      _googleInitialized = true;
      completer.complete();
    } catch (error, stackTrace) {
      _googleInitializationCompleter = null;
      completer.completeError(error, stackTrace);
      rethrow;
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (_useEmulatorGoogleSignIn) {
      debugPrint('Using emulator Google Sign-In bypass');
      final credential = GoogleAuthProvider.credential(
        accessToken: 'test-access-token',
        idToken: 'test-id-token',
      );
      return _auth.signInWithCredential(credential);
    }

    await _ensureGoogleSignInInitialized();

    final googleUser = await _googleSignIn.authenticate(
      scopeHint: const [
        'email',
        'profile',
      ],
    );
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google sign-in flow was cancelled by the user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message:
            'Unable to send verification email without an authenticated user.',
      );
    }
    await user.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Unable to update password without an authenticated user.',
      );
    }
    await user.updatePassword(newPassword);
  }

  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  Future<void> signOut() async {
    if (!_useEmulatorGoogleSignIn) {
      await _ensureGoogleSignInInitialized();
    }
    await Future.wait([
      _auth.signOut(),
      if (!_useEmulatorGoogleSignIn) _googleSignIn.signOut(),
    ]);
  }
}
