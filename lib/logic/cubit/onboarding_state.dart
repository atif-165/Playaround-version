part of 'onboarding_cubit.dart';

@immutable
abstract class OnboardingState {}

/// Initial state when onboarding starts
class OnboardingInitial extends OnboardingState {}

/// Loading state during operations
class OnboardingLoading extends OnboardingState {}

/// State when role selection is needed
class OnboardingRoleSelectionRequired extends OnboardingState {}

/// State when role has been selected and form should be shown
class OnboardingRoleSelected extends OnboardingState {
  final UserRole selectedRole;

  OnboardingRoleSelected(this.selectedRole);
}

/// State when profile data is being validated
class OnboardingValidating extends OnboardingState {}

/// State when profile has been successfully saved
class OnboardingProfileSaved extends OnboardingState {
  final UserProfile profile;

  OnboardingProfileSaved(this.profile);
}

/// State when onboarding is complete and user should navigate to main app
class OnboardingComplete extends OnboardingState {
  final UserProfile profile;

  OnboardingComplete(this.profile);
}

/// State when an error occurs during onboarding
class OnboardingError extends OnboardingState {
  final String message;

  OnboardingError(this.message);
}

/// State when checking if user profile already exists
class OnboardingCheckingProfile extends OnboardingState {}

/// State when user profile already exists and onboarding should be skipped
class OnboardingProfileExists extends OnboardingState {
  final UserProfile existingProfile;

  OnboardingProfileExists(this.existingProfile);
}

/// State when image is being uploaded
class OnboardingImageUploading extends OnboardingState {}

/// State when image upload is complete
class OnboardingImageUploaded extends OnboardingState {
  final String imageUrl;

  OnboardingImageUploaded(this.imageUrl);
}

/// State when image upload fails
class OnboardingImageUploadError extends OnboardingState {
  final String message;

  OnboardingImageUploadError(this.message);
}
