import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_image_picker.dart';
import '../../../core/widgets/progress_indicator.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/app_multi_select_field.dart';
import '../../../helpers/extensions.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../logic/cubit/onboarding_cubit.dart';
import '../../../models/models.dart';
import '../../../routing/routes.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Unified onboarding screen for both players and coaches
/// Collects basic profile information that will be shown in enhanced profile screen
class UnifiedOnboardingScreen extends StatefulWidget {
  final UserRole selectedRole;

  const UnifiedOnboardingScreen({
    super.key,
    required this.selectedRole,
  });

  @override
  State<UnifiedOnboardingScreen> createState() =>
      _UnifiedOnboardingScreenState();
}

class _UnifiedOnboardingScreenState extends State<UnifiedOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();

  // Form state
  Gender? _selectedGender;
  List<String> _selectedSports = [];
  File? _selectedImage;
  String? _uploadedImageUrl;
  int _age = 18;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorsManager.background,
              ColorsManager.surfaceVariant.withValues(alpha: 0.3),
              ColorsManager.background,
            ],
          ),
        ),
        child: BlocListener<OnboardingCubit, OnboardingState>(
          listener: (context, state) {
            if (state is OnboardingValidating) {
              AppProgressIndicator.showProgressIndicator(context);
            } else if (state is OnboardingProfileSaved) {
              context.pop(); // Close loading dialog
            } else if (state is OnboardingComplete) {
              // Refresh auth state with the new profile
              context.read<AuthCubit>().refreshUserProfile();
              context.pushNamedAndRemoveUntil(
                Routes.dashboardScreen,
                predicate: (route) => false,
              );
            } else if (state is OnboardingError) {
              context.pop(); // Close loading dialog
              _showErrorDialog(state.message);
            } else if (state is OnboardingImageUploaded) {
              setState(() {
                _uploadedImageUrl = state.imageUrl;
              });
            }
          },
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Header
                    _buildHeader(),
                    Gap(30.h),

                    // Profile Picture
                    BlocBuilder<OnboardingCubit, OnboardingState>(
                      builder: (context, state) {
                        return AppImagePicker(
                          label: 'Profile Picture',
                          imageFile: _selectedImage,
                          imageUrl: _uploadedImageUrl,
                          isLoading: state is OnboardingImageUploading,
                          onImageSelected: (file) {
                            setState(() {
                              _selectedImage = file;
                            });
                            if (file != null) {
                              context
                                  .read<OnboardingCubit>()
                                  .uploadSelectedImage(file);
                            }
                          },
                        );
                      },
                    ),
                    Gap(24.h),

                    // Basic Information
                    _buildBasicInfoSection(),
                    Gap(24.h),

                    // Sports Interests
                    _buildSportsSection(),
                    Gap(24.h),

                    // Bio Section
                    _buildBioSection(),
                    Gap(40.h),

                    // Submit Button
                    _buildSubmitButton(),
                    Gap(20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isPlayer = widget.selectedRole == UserRole.player;
    final gradient = isPlayer
        ? ColorsManager.successGradient
        : ColorsManager.primaryGradient;
    final accentColor =
        isPlayer ? ColorsManager.playerAccent : ColorsManager.coachAccent;
    final icon = isPlayer ? Icons.sports_basketball : Icons.sports;
    final title = isPlayer ? 'Create Player Profile' : 'Create Coach Profile';
    final subtitle = isPlayer
        ? 'Tell us about yourself to connect with coaches and players'
        : 'Share your basic information to get started as a coach';

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: ColorsManager.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: ColorsManager.onPrimary,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Gap(16.w),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.font20DarkBlueBold.copyWith(
                    color: ColorsManager.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Role icon
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: ColorsManager.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: ColorsManager.onPrimary,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            subtitle,
            style: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.onPrimary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.onBackground,
          ),
        ),
        Gap(16.h),
        AppTextFormField(
          controller: _nameController,
          hint: 'Full Name',
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter your full name' : null,
        ),
        Gap(16.h),
        AppTextFormField(
          controller: _locationController,
          hint: 'Location (City, Country)',
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter your location' : null,
        ),
        Gap(16.h),
        _buildAgeField(),
        Gap(16.h),
        _buildGenderSelector(),
      ],
    );
  }

  Widget _buildSportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sports Interests',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.onBackground,
          ),
        ),
        Gap(8.h),
        Text(
          widget.selectedRole == UserRole.player
              ? 'Select sports you\'re interested in playing'
              : 'Select sports you have experience with',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Gap(16.h),
        AppMultiSelectField(
          label: 'Select Sports',
          options: const [
            'Football',
            'Basketball',
            'Tennis',
            'Cricket',
            'Baseball',
            'Soccer',
            'Volleyball',
            'Badminton',
            'Table Tennis',
            'Swimming',
            'Running',
            'Cycling',
            'Golf',
            'Boxing',
            'Wrestling'
          ],
          selectedValues: _selectedSports,
          onChanged: (sports) {
            setState(() {
              _selectedSports = sports;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About You',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.onBackground,
          ),
        ),
        Gap(8.h),
        Text(
          'Tell others about yourself (optional)',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Gap(16.h),
        AppTextFormField(
          controller: _bioController,
          hint: 'Write a brief description about yourself...',
          maxLines: 4,
          validator: (value) => null, // Optional field, no validation needed
        ),
      ],
    );
  }

  Widget _buildAgeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age: $_age',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: ColorsManager.onBackground,
          ),
        ),
        Gap(8.h),
        Slider(
          value: _age.toDouble(),
          min: 13,
          max: 80,
          divisions: 67,
          activeColor: widget.selectedRole == UserRole.player
              ? ColorsManager.playerAccent
              : ColorsManager.coachAccent,
          onChanged: (value) {
            setState(() {
              _age = value.round();
              _ageController.text = _age.toString();
            });
          },
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: ColorsManager.onBackground,
          ),
        ),
        Gap(12.h),
        Row(
          children: Gender.values.map((gender) {
            final isSelected = _selectedGender == gender;
            final accentColor = widget.selectedRole == UserRole.player
                ? ColorsManager.playerAccent
                : ColorsManager.coachAccent;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                      right: gender != Gender.values.last ? 12.w : 0),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? accentColor : ColorsManager.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? accentColor : ColorsManager.outline,
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    gender.displayName,
                    style: TextStyles.font14DarkBlue500Weight.copyWith(
                      color: isSelected
                          ? ColorsManager.onPrimary
                          : ColorsManager.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isPlayer = widget.selectedRole == UserRole.player;
    final gradient = isPlayer
        ? ColorsManager.successGradient
        : ColorsManager.primaryGradient;
    final accentColor =
        isPlayer ? ColorsManager.playerAccent : ColorsManager.coachAccent;

    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.4),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28.r),
          onTap: _submitForm,
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create Profile',
                  style: TextStyles.font16White600Weight.copyWith(
                    color: ColorsManager.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(8.w),
                Icon(
                  Icons.arrow_forward,
                  size: 20.sp,
                  color: ColorsManager.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        _showErrorDialog('Please select your gender');
        return;
      }

      if (_selectedSports.isEmpty) {
        _showErrorDialog('Please select at least one sport');
        return;
      }

      // Create profile based on selected role
      if (widget.selectedRole == UserRole.player) {
        _createPlayerProfile();
      } else {
        _createCoachProfile();
      }
    }
  }

  void _createPlayerProfile() {
    context.read<OnboardingCubit>().savePlayerProfile(
          fullName: _nameController.text,
          gender: _selectedGender!,
          age: _age,
          location: _locationController.text,
          sportsOfInterest: _selectedSports,
          skillLevel: SkillLevel.beginner, // Default skill level
          availability: [], // Empty availability initially
          preferredTrainingType: TrainingType.inPerson, // Default training type
          profilePictureUrl: _uploadedImageUrl,
        );
  }

  void _createCoachProfile() {
    context.read<OnboardingCubit>().saveCoachProfile(
          fullName: _nameController.text,
          gender: _selectedGender!,
          age: _age,
          location: _locationController.text,
          specializationSports: _selectedSports,
          experienceYears: 1, // Default experience
          hourlyRate: 0.0, // Default rate - can be updated later
          availableTimeSlots: [], // Empty availability initially
          coachingType: TrainingType.inPerson, // Default coaching type
          bio: _bioController.text.isEmpty ? null : _bioController.text,
          profilePictureUrl: _uploadedImageUrl,
        );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
