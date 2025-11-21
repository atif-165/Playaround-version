import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../models/player_profile.dart';
import '../../models/coach_profile.dart';
import '../../repositories/user_repository.dart';

part 'onboarding_state.dart';

/// Cubit responsible for managing onboarding flow state
///
/// This cubit handles:
/// - Role selection (Player/Coach)
/// - Profile form submission
/// - Image upload for profile pictures
/// - Profile validation and saving to Firestore
/// - Navigation logic for onboarding completion
class OnboardingCubit extends Cubit<OnboardingState> {
  final UserRepository _userRepository;
  final ImagePicker _imagePicker = ImagePicker();

  OnboardingCubit({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository(),
        super(OnboardingInitial());

  /// Check if user profile already exists
  Future<void> checkExistingProfile() async {
    emit(OnboardingCheckingProfile());

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          debugPrint('❌ OnboardingCubit: No authenticated user found');
        }
        emit(OnboardingError('No authenticated user found'));
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '🔍 OnboardingCubit: Checking profile for user: ${currentUser.uid}');
      }

      final existingProfile =
          await _userRepository.getUserProfile(currentUser.uid);

      if (kDebugMode) {
        debugPrint(
            '📋 OnboardingCubit: Profile found: ${existingProfile != null}');
        if (existingProfile != null) {
          debugPrint(
              '✅ Profile complete: ${existingProfile.isProfileComplete}');
          debugPrint('👤 Profile name: ${existingProfile.fullName}');
          debugPrint('🎭 Profile role: ${existingProfile.role}');
        }
      }

      if (existingProfile != null) {
        if (kDebugMode) {
          debugPrint(
              '🎉 OnboardingCubit: Profile exists, staying on home screen');
        }
        emit(OnboardingProfileExists(existingProfile));
      } else {
        if (kDebugMode) {
          debugPrint(
              '🚨 OnboardingCubit: No profile found, redirecting to role selection');
        }
        emit(OnboardingRoleSelectionRequired());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 OnboardingCubit: Error checking profile: $e');
      }
      emit(
          OnboardingError('Failed to check existing profile: ${e.toString()}'));
    }
  }

  /// Select user role and proceed to form
  void selectRole(UserRole role) {
    emit(OnboardingRoleSelected(role));
  }

  /// Save minimal profile with just role selection (no onboarding form)
  Future<void> saveMinimalProfileWithRole(UserRole role) async {
    emit(OnboardingValidating());

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(OnboardingError('No authenticated user found'));
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '💾 OnboardingCubit: Saving minimal profile with role: ${role.value}');
      }

      final now = DateTime.now();
      final userEmail = currentUser.email ?? '';
      final displayName = currentUser.displayName ?? userEmail.split('@').first;

      UserProfile profile;

      if (role == UserRole.player) {
        profile = PlayerProfile(
          uid: currentUser.uid,
          fullName: displayName,
          gender: Gender.male, // Default value
          age: 18, // Default value
          location: 'Not set', // Default value
          isProfileComplete: false, // Profile is incomplete
          createdAt: now,
          updatedAt: now,
          sportsOfInterest: [], // Empty, user will set later
          skillLevel: SkillLevel.beginner, // Default value
          availability: [], // Empty, user will set later
          preferredTrainingType: TrainingType.inPerson, // Default value
        );
      } else {
        profile = CoachProfile(
          uid: currentUser.uid,
          fullName: displayName,
          gender: Gender.male, // Default value
          age: 18, // Default value
          location: 'Not set', // Default value
          isProfileComplete: false, // Profile is incomplete
          createdAt: now,
          updatedAt: now,
          specializationSports: [], // Empty, user will set later
          experienceYears: 0, // Default value
          hourlyRate: 0.0, // Default value
          availableTimeSlots: [], // Empty, user will set later
          coachingType: TrainingType.inPerson, // Default value
        );
      }

      await _userRepository.saveUserProfile(profile);
      emit(OnboardingProfileSaved(profile));

      // Complete onboarding after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      emit(OnboardingComplete(profile));
    } catch (e) {
      emit(OnboardingError('Failed to save profile: ${e.toString()}'));
    }
  }

  /// Go back to role selection
  void backToRoleSelection() {
    emit(OnboardingRoleSelectionRequired());
  }

  /// Save player profile
  Future<void> savePlayerProfile({
    required String fullName,
    required Gender gender,
    required int age,
    required String location,
    required List<String> sportsOfInterest,
    required SkillLevel skillLevel,
    required List<TimeSlot> availability,
    required TrainingType preferredTrainingType,
    String? profilePictureUrl,
  }) async {
    emit(OnboardingValidating());

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(OnboardingError('No authenticated user found'));
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '💾 OnboardingCubit: Saving player profile with image URL: $profilePictureUrl');
      }

      final now = DateTime.now();
      final playerProfile = PlayerProfile(
        uid: currentUser.uid,
        fullName: fullName.trim(),
        gender: gender,
        age: age,
        location: location.trim(),
        profilePictureUrl: profilePictureUrl,
        isProfileComplete: true,
        createdAt: now,
        updatedAt: now,
        sportsOfInterest: sportsOfInterest,
        skillLevel: skillLevel,
        availability: availability,
        preferredTrainingType: preferredTrainingType,
      );

      await _userRepository.saveUserProfile(playerProfile);
      emit(OnboardingProfileSaved(playerProfile));

      // Complete onboarding after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      emit(OnboardingComplete(playerProfile));
    } catch (e) {
      emit(OnboardingError('Failed to save player profile: ${e.toString()}'));
    }
  }

  /// Save coach profile
  Future<void> saveCoachProfile({
    required String fullName,
    required Gender gender,
    required int age,
    required String location,
    required List<String> specializationSports,
    required int experienceYears,
    String? certifications,
    required double hourlyRate,
    required List<TimeSlot> availableTimeSlots,
    required TrainingType coachingType,
    String? bio,
    String? profilePictureUrl,
  }) async {
    emit(OnboardingValidating());

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(OnboardingError('No authenticated user found'));
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '💾 OnboardingCubit: Saving coach profile with image URL: $profilePictureUrl');
      }

      final now = DateTime.now();
      final coachProfile = CoachProfile(
        uid: currentUser.uid,
        fullName: fullName.trim(),
        gender: gender,
        age: age,
        location: location.trim(),
        profilePictureUrl: profilePictureUrl,
        isProfileComplete: true,
        createdAt: now,
        updatedAt: now,
        specializationSports: specializationSports,
        experienceYears: experienceYears,
        certifications: certifications?.trim().isNotEmpty == true
            ? [certifications!.trim()]
            : null,
        hourlyRate: hourlyRate,
        availableTimeSlots: availableTimeSlots,
        coachingType: coachingType,
        bio: bio?.trim(),
      );

      await _userRepository.saveUserProfile(coachProfile);
      emit(OnboardingProfileSaved(coachProfile));

      // Complete onboarding after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      emit(OnboardingComplete(coachProfile));
    } catch (e) {
      emit(OnboardingError('Failed to save coach profile: ${e.toString()}'));
    }
  }

  /// Upload selected profile image
  Future<void> uploadSelectedImage(File imageFile) async {
    try {
      if (kDebugMode) {
        debugPrint('🎯 OnboardingCubit: Starting image upload process');
      }

      emit(OnboardingImageUploading());

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          debugPrint('❌ OnboardingCubit: No authenticated user found');
        }
        emit(OnboardingImageUploadError('No authenticated user found'));
        return;
      }

      if (kDebugMode) {
        debugPrint('👤 OnboardingCubit: User ID: ${currentUser.uid}');
      }

      final imageUrl = await _userRepository.uploadProfileImage(
        imageFile,
        currentUser.uid,
      );

      if (kDebugMode) {
        debugPrint('✅ OnboardingCubit: Image upload completed successfully');
        debugPrint('🔗 OnboardingCubit: Final image URL: $imageUrl');
      }

      emit(OnboardingImageUploaded(imageUrl));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 OnboardingCubit: Image upload failed: $e');
      }
      emit(OnboardingImageUploadError(
          'Failed to upload image: ${e.toString()}'));
    }
  }

  /// Pick and upload profile image (for future use if needed)
  Future<void> pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      await uploadSelectedImage(File(image.path));
    } catch (e) {
      emit(OnboardingImageUploadError(
          'Failed to pick and upload image: ${e.toString()}'));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(OnboardingInitial());
  }
}
