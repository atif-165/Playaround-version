/// Application-wide constants used throughout the app.
///
/// This file centralizes all constant values to improve maintainability
/// and reduce the risk of typos or inconsistencies.
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// Design dimensions for responsive UI
  static const double designWidth = 360.0;
  static const double designHeight = 690.0;

  /// Animation durations
  static const Duration shortAnimationDuration = Duration(seconds: 2);
  static const Duration mediumAnimationDuration = Duration(seconds: 3);

  /// Asset paths
  static const String googleLogoSvg = 'assets/svgs/google_logo.svg';
  static const String loadingGif = 'assets/images/loading.gif';
  static const String placeholderImage = 'assets/images/placeholder.png';
  static const String riveAnimationFile = 'assets/animation/headless_bear.riv';

  /// Form validation constants
  static const int minNameLength = 2;
  static const int minPasswordLength = 8;

  /// UI spacing constants
  static const double smallSpacing = 5.0;
  static const double mediumSpacing = 10.0;
  static const double largeSpacing = 15.0;
  static const double extraLargeSpacing = 20.0;

  /// Button dimensions
  static const double defaultButtonHeight = 52.0;
  static const double defaultBorderRadius = 16.0;

  /// Text field dimensions
  static const double textFieldBorderWidth = 1.3;

  /// Animation thresholds
  static const int emailLengthThreshold = 13;

  /// Error messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String unexpectedErrorMessage =
      'An unexpected error occurred. Please try again.';
  static const String googleSignInFailedMessage =
      'Google Sign In failed. Please try again.';

  /// Success messages
  static const String signUpSuccessMessage = 'You have successfully signed up.';
  static const String emailVerificationMessage =
      'Don\'t forget to verify your email check inbox.';
  static const String passwordResetMessage =
      'Link to Reset password send to your email, please check inbox messages.';

  /// Dialog titles
  static const String errorTitle = 'Error';
  static const String successTitle = 'Sign up Success';
  static const String resetPasswordTitle = 'Reset Password';
  static const String emailNotVerifiedTitle = 'Email Not Verified';
  static const String signOutErrorTitle = 'Sign out error';

  /// Navigation labels
  static const String loginTitle = 'Login';
  static const String createAccountTitle = 'Create Account';
  static const String createPasswordTitle = 'Create Password';

  /// Hint texts
  static const String emailHint = 'Email';
  static const String passwordHint = 'Password';
  static const String passwordConfirmationHint = 'Password Confirmation';
  static const String nameHint = 'Name';

  /// Button texts
  static const String loginButtonText = 'Login';
  static const String createAccountButtonText = 'Create Account';
  static const String resetButtonText = 'Reset';
  static const String signOutButtonText = 'Sign Out';

  /// Descriptive texts
  static const String loginSubtitle = 'Login To Continue Using The App';
  static const String signUpSubtitle =
      'Sign up now and start exploring all that our\napp has to offer. We\'re excited to welcome\nyou to our community!';
  static const String signInWithGoogleText = 'or Sign in with';
  static const String alreadyHaveAccountText = 'Already have an account?';
  static const String doNotHaveAccountText = 'Don\'t have an account yet?';
  static const String forgetPasswordText = 'forget password?';

  /// App metadata
  static const String appTitle = 'Login & Signup App';
  static const String defaultUserName = 'User';
}
