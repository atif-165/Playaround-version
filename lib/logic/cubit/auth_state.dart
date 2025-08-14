// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'auth_cubit.dart';

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

@immutable
abstract class AuthState {}

class IsNewUser extends AuthState {
  final GoogleSignInAccount googleUser;
  final OAuthCredential credential;
  IsNewUser({
    required this.googleUser,
    required this.credential,
  });
}

class ResetPasswordSent extends AuthState {}

class UserNotVerified extends AuthState {}

class UserSignedOut extends AuthState {}

class UserSignIn extends AuthState {}

class UserSignupAndLinkedWithGoogle extends AuthState {}

class UserSignupButNotVerified extends AuthState {}

class EmailVerificationSent extends AuthState {}

class EmailVerificationResent extends AuthState {}

class UserNeedsOnboarding extends AuthState {}

class UserProfileComplete extends AuthState {}

class AuthenticatedWithProfile extends AuthState {
  final UserProfile userProfile;

  AuthenticatedWithProfile({required this.userProfile});
}
