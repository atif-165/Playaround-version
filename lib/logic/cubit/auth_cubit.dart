import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/models.dart';
import '../../repositories/user_repository.dart';

part 'auth_state.dart';

/// Cubit responsible for managing authentication state throughout the app.
///
/// This cubit handles all authentication operations including:
/// - Email/password sign up and sign in
/// - Google sign in integration
/// - Password reset functionality
/// - Email verification
/// - User account linking
class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  AuthCubit() : super(AuthInitial());

  /// Creates a new Firebase account with email/password and links it with Google account.
  ///
  /// This method is used when a user signs in with Google for the first time
  /// and needs to create a password for their account.
  ///
  /// [email] - The user's email address
  /// [password] - The password to set for the account
  /// [googleUser] - The Google sign-in account information
  /// [credential] - The OAuth credential from Google sign-in
  Future<void> createAccountAndLinkItWithGoogleAccount(
      String email,
      String password,
      GoogleSignInAccount googleUser,
      OAuthCredential credential) async {
    emit(AuthLoading());

    try {
      await _auth.createUserWithEmailAndPassword(
        email: googleUser.email,
        password: password,
      );
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
        await currentUser.updateDisplayName(googleUser.displayName);
        await currentUser.updatePhotoURL(googleUser.photoUrl);
      } else {
        throw Exception('Failed to create user account');
      }
      emit(UserSignupAndLinkedWithGoogle());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getFirebaseErrorMessage(e)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email);
      emit(ResetPasswordSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getFirebaseErrorMessage(e)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        // Reload user to get the latest verification status
        await user.reload();
        final updatedUser = _auth.currentUser;

        if (updatedUser != null && updatedUser.emailVerified) {
          // Check if user profile is complete
          await _checkUserProfileAndEmitState(updatedUser.uid);
        } else {
          // Don't sign out - keep user signed in so they can resend verification
          emit(UserNotVerified());
        }
      } else {
        throw Exception('Failed to sign in');
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getFirebaseErrorMessage(e)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      // Initialize GoogleSignIn if not already done
      await GoogleSignIn.instance.initialize();

      // Authenticate the user
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken, // Note: In v7.x, use idToken for accessToken
        idToken: googleAuth.idToken,
      );
      final UserCredential authResult =
          await _auth.signInWithCredential(credential);
      final additionalUserInfo = authResult.additionalUserInfo;
      if (additionalUserInfo != null && additionalUserInfo.isNewUser) {
        // Sign out the user instead of deleting to preserve the Google account
        // The user will be prompted to create a password in the next screen
        await _auth.signOut();
        emit(IsNewUser(googleUser: googleUser, credential: credential));
      } else {
        // Check if user profile is complete for existing users
        await _checkUserProfileAndEmitState(authResult.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getFirebaseErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Google Sign In failed. Please try again.'));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    await _auth.signOut();
    emit(UserSignedOut());
  }

  /// Resend email verification to the current user
  Future<void> resendEmailVerification() async {
    emit(AuthLoading());
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && !currentUser.emailVerified) {
        await _sendEmailVerificationWithCustomSettings(currentUser);
        emit(EmailVerificationResent());
      } else if (currentUser == null) {
        emit(AuthError('No user found. Please sign up first.'));
      } else {
        emit(AuthError('Email is already verified.'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getFirebaseErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Failed to resend verification email. Please try again.'));
    }
  }

  /// Check if current user's email is verified
  Future<void> checkEmailVerification() async {
    emit(AuthLoading());
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        final updatedUser = _auth.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          // Check if user profile is complete
          await _checkUserProfileAndEmitState(updatedUser.uid);
        } else {
          emit(UserNotVerified());
        }
      } else {
        emit(AuthError('No user found. Please sign up first.'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getFirebaseErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Failed to check verification status. Please try again.'));
    }
  }

  Future<void> signUpWithEmail(
      String name, String email, String password) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final currentUser = userCredential.user;
      if (currentUser != null) {
        await currentUser.updateDisplayName(name);

        // Send email verification with custom action URL
        await _sendEmailVerificationWithCustomSettings(currentUser);

        // Don't sign out immediately - keep user signed in but unverified
        // This allows them to resend verification email if needed
      } else {
        throw Exception('Failed to create user account');
      }
      emit(UserSignupButNotVerified());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getFirebaseErrorMessage(e)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  /// Send email verification with custom settings for better delivery
  Future<void> _sendEmailVerificationWithCustomSettings(User user) async {
    try {
      // Configure action code settings for better email delivery
      final actionCodeSettings = ActionCodeSettings(
        // URL to redirect to after email verification
        url: 'https://playaround-6556e.firebaseapp.com/__/auth/action',
        // This must be true for mobile apps
        handleCodeInApp: true,
        // iOS bundle ID
        iOSBundleId: 'com.playaround.app',
        // Android package name
        androidPackageName: 'com.playaround.app',
        // Install the app if not already installed
        androidInstallApp: true,
        // Minimum version of the app
        androidMinimumVersion: '1',
      );

      await user.sendEmailVerification(actionCodeSettings);
    } catch (e) {
      // Fallback to basic email verification if custom settings fail
      await user.sendEmailVerification();
    }
  }

  /// Check user profile completion and emit appropriate state
  Future<void> _checkUserProfileAndEmitState(String uid) async {
    try {
      final profile = await _userRepository.getUserProfile(uid);

      if (profile != null && profile.isProfileComplete) {
        emit(AuthenticatedWithProfile(userProfile: profile));
      } else {
        emit(UserNeedsOnboarding());
      }
    } catch (e) {
      // If there's an error checking profile, assume onboarding is needed
      emit(UserNeedsOnboarding());
    }
  }

  /// Refresh user profile state (call after profile updates)
  Future<void> refreshUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _checkUserProfileAndEmitState(currentUser.uid);
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'invalid-app-credential':
        return 'Invalid app configuration. Please contact support.';
      case 'app-not-authorized':
        return 'App not authorized. Please check Firebase configuration.';
      case 'keychain-error':
        return 'Keychain error occurred. Please try again.';
      default:
        // Handle reCAPTCHA configuration errors
        if (e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
          return 'Firebase configuration error. Please check your setup.';
        }
        if (e.message?.contains('RecaptchaAction') == true) {
          return 'reCAPTCHA service unavailable. Please try again later.';
        }
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
