import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_dropdown_field.dart';
import '../../../core/widgets/app_image_picker.dart';
import '../../../core/widgets/app_multi_select_field.dart';
import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/app_time_slot_picker.dart';
import '../../../core/widgets/progress_indicator.dart';
import '../../../helpers/extensions.dart';
import '../../../helpers/form_validators.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../logic/cubit/onboarding_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../models/player_profile.dart';
import '../../../routing/routes.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';

/// Player onboarding form screen
class PlayerOnboardingScreen extends StatefulWidget {
  const PlayerOnboardingScreen({super.key});

  @override
  State<PlayerOnboardingScreen> createState() => _PlayerOnboardingScreenState();
}

class _PlayerOnboardingScreenState extends State<PlayerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  // Form values
  Gender? _selectedGender;
  List<String> _selectedSports = [];
  SkillLevel? _selectedSkillLevel;
  List<TimeSlot> _selectedTimeSlots = [];
  TrainingType? _selectedTrainingType;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Player Profile',
          style: TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: PublicProfileTheme.backgroundGradient,
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: BlocListener<OnboardingCubit, OnboardingState>(
          listener: (context, state) {
            if (state is OnboardingValidating) {
              AppProgressIndicator.showProgressIndicator(context);
            } else if (state is OnboardingProfileSaved) {
              context.pop(); // Close loading dialog
              _showSuccessDialog();
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
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture uploaded successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is OnboardingImageUploadError) {
              _showErrorDialog('Image Upload Error: ${state.message}');
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
                    // Header
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
                    Gap(20.h),

                    // Full Name
                    AppTextFormField(
                      hint: 'Enter your full name',
                      controller: _nameController,
                      validator: FormValidators.validateName,
                    ),
                    Gap(20.h),

                    // Gender
                    AppDropdownField<Gender>(
                      label: 'Gender',
                      value: _selectedGender,
                      items: DropdownHelper.genderItems(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) =>
                          FormValidators.validateDropdownSelection(
                        value,
                        'gender',
                      ),
                      hint: 'Select your gender',
                      isRequired: true,
                    ),
                    Gap(20.h),

                    // Age
                    AppTextFormField(
                      hint: 'Enter your age',
                      controller: _ageController,
                      validator: FormValidators.validateAge,
                    ),
                    Gap(20.h),

                    // Sports of Interest
                    AppMultiSelectField(
                      label: 'Sports of Interest',
                      options: SportsOptions.availableSports,
                      selectedValues: _selectedSports,
                      onChanged: (values) {
                        setState(() {
                          _selectedSports = values;
                        });
                      },
                      validator: (values) => FormValidators.validateListSelection(
                        values,
                        'sport',
                      ),
                      hint: 'Select sports you\'re interested in',
                      isRequired: true,
                      maxSelections: 5,
                    ),
                    Gap(20.h),

                    // Skill Level
                    AppDropdownField<SkillLevel>(
                      label: 'Skill Level',
                      value: _selectedSkillLevel,
                      items: DropdownHelper.skillLevelItems(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSkillLevel = value;
                        });
                      },
                      validator: (value) =>
                          FormValidators.validateDropdownSelection(
                        value,
                        'skill level',
                      ),
                      hint: 'Select your skill level',
                      isRequired: true,
                    ),
                    Gap(20.h),

                    // Location
                    AppTextFormField(
                      hint: 'Enter your city/location',
                      controller: _locationController,
                      validator: FormValidators.validateLocation,
                    ),
                    Gap(20.h),

                    // Availability
                    AppTimeSlotPicker(
                      label: 'Availability',
                      selectedSlots: _selectedTimeSlots,
                      onChanged: (slots) {
                        setState(() {
                          _selectedTimeSlots = slots;
                        });
                      },
                      validator: FormValidators.validateTimeSlots,
                      isRequired: true,
                    ),
                    Gap(20.h),

                    // Preferred Training Type
                    AppDropdownField<TrainingType>(
                      label: 'Preferred Training Type',
                      value: _selectedTrainingType,
                      items: DropdownHelper.trainingTypeItems(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTrainingType = value;
                        });
                      },
                      validator: (value) =>
                          FormValidators.validateDropdownSelection(
                        value,
                        'training type',
                      ),
                      hint: 'Select your preferred training type',
                      isRequired: true,
                    ),
                    Gap(40.h),

                    // Submit button
                    AppTextButton(
                      buttonText: 'Complete Profile',
                      textStyle: TextStyles.font16White600Weight,
                      onPressed: _submitForm,
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Your Player Profile',
          style: TextStyles.font24Blue700Weight,
        ),
        Gap(8.h),
        Text(
          'Tell us about yourself to get matched with the best coaches',
          style: TextStyles.font14Grey400Weight,
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<OnboardingCubit>().savePlayerProfile(
            fullName: _nameController.text,
            gender: _selectedGender!,
            age: int.parse(_ageController.text),
            location: _locationController.text,
            sportsOfInterest: _selectedSports,
            skillLevel: _selectedSkillLevel!,
            availability: _selectedTimeSlots,
            preferredTrainingType: _selectedTrainingType!,
            profilePictureUrl: _uploadedImageUrl,
          );
    }
  }

  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      title: 'Profile Created!',
      desc: 'Your player profile has been created successfully.',
      btnOkOnPress: () {},
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      title: 'Error',
      desc: message,
    ).show();
  }
}
