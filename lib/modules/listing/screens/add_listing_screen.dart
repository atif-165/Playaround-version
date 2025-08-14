import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../helpers/extensions.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/listing_model.dart' as listing;
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/listing_service.dart';
import '../widgets/sport_type_dropdown.dart';
import '../widgets/time_slot_selector.dart';
import '../widgets/weekday_selector.dart';

/// Screen for creating new listings (coaches and venues)
class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _listingService = ListingService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _locationController = TextEditingController();

  // Form state
  listing.ListingType _selectedListingType = listing.ListingType.coach;
  listing.SportType? _selectedSportType;
  List<String> _selectedDays = [];
  List<listing.TimeSlot> _selectedTimeSlots = [];
  bool _isLoading = false;

  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
        // Set default listing type based on user role
        if (_currentUserProfile?.role == UserRole.coach) {
          _selectedListingType = listing.ListingType.coach;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Listing',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
      ),
      body: _isLoading
          ? const Center(child: CustomProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Gap(32.h),
                    _buildListingTypeSelector(),
                    Gap(24.h),
                    _buildTitleField(),
                    Gap(16.h),
                    _buildSportTypeDropdown(),
                    Gap(16.h),
                    _buildDescriptionField(),
                    Gap(16.h),
                    _buildHourlyRateField(),
                    Gap(16.h),
                    _buildLocationField(),
                    Gap(24.h),
                    _buildAvailabilitySection(),
                    Gap(32.h),
                    _buildSubmitButton(),
                  ],
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
          _selectedListingType == listing.ListingType.coach
              ? 'Create Coaching Service'
              : 'Create Venue Listing',
          style: TextStyles.font24Blue700Weight,
        ),
        Gap(8.h),
        Text(
          _selectedListingType == listing.ListingType.coach
              ? 'Share your expertise and connect with players'
              : 'List your venue for sports activities',
          style: TextStyles.font14Grey400Weight,
        ),
      ],
    );
  }

  Widget _buildListingTypeSelector() {
    // Only show selector if user is coach (can create both types)
    if (_currentUserProfile?.role != UserRole.coach) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing Type',
          style: TextStyles.font14DarkBlueMedium,
        ),
        Gap(8.h),
        Row(
          children: [
            Expanded(
              child: RadioListTile<listing.ListingType>(
                title: const Text('Coaching Service'),
                value: listing.ListingType.coach,
                groupValue: _selectedListingType,
                onChanged: (value) {
                  setState(() {
                    _selectedListingType = value!;
                  });
                },
                activeColor: ColorsManager.mainBlue,
              ),
            ),
            Expanded(
              child: RadioListTile<listing.ListingType>(
                title: const Text('Venue'),
                value: listing.ListingType.venue,
                groupValue: _selectedListingType,
                onChanged: (value) {
                  setState(() {
                    _selectedListingType = value!;
                  });
                },
                activeColor: ColorsManager.mainBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedListingType == listing.ListingType.coach ? 'Service Title' : 'Venue Name',
          style: TextStyles.font14DarkBlueMedium,
        ),
        Gap(8.h),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: _selectedListingType == listing.ListingType.coach
                ? 'e.g., Professional Cricket Coaching'
                : 'e.g., City Sports Complex',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSportTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sport Type',
          style: TextStyles.font14DarkBlueMedium,
        ),
        Gap(8.h),
        SportTypeDropdown(
          selectedSportType: _selectedSportType,
          onChanged: (sportType) {
            setState(() {
              _selectedSportType = sportType;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyles.font14DarkBlueMedium,
        ),
        Gap(8.h),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: _selectedListingType == listing.ListingType.coach
                ? 'Describe your coaching experience, specialties, and what players can expect...'
                : 'Describe your venue facilities, amenities, and features...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            if (value.trim().length < 20) {
              return 'Description must be at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHourlyRateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hourly Rate (\$)',
          style: TextStyles.font14DarkBlueMedium,
        ),
        Gap(8.h),
        TextFormField(
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '\$ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter hourly rate';
            }
            final rate = double.tryParse(value);
            if (rate == null || rate <= 0) {
              return 'Please enter a valid rate';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyles.font14DarkBlueMedium,
        ),
        Gap(8.h),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Enter address or location',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter location';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: TextStyles.font18DarkBlueBold,
        ),
        Gap(16.h),
        WeekdaySelector(
          selectedDays: _selectedDays,
          onChanged: (days) {
            setState(() {
              _selectedDays = days;
            });
          },
        ),
        Gap(16.h),
        TimeslotSelector(
          selectedTimeSlots: _selectedTimeSlots,
          onChanged: (timeSlots) {
            setState(() {
              _selectedTimeSlots = timeSlots;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AppTextButton(
      buttonText: 'Create Listing',
      textStyle: TextStyles.font16WhiteSemiBold,
      onPressed: _submitForm,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSportType == null) {
      context.showSnackBar('Please select a sport type');
      return;
    }

    if (_selectedDays.isEmpty) {
      context.showSnackBar('Please select at least one available day');
      return;
    }

    if (_selectedTimeSlots.isEmpty) {
      context.showSnackBar('Please add at least one time slot');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _listingService.createListing(
        type: _selectedListingType,
        title: _titleController.text.trim(),
        sportType: _selectedSportType!,
        description: _descriptionController.text.trim(),
        hourlyRate: double.parse(_hourlyRateController.text),
        availableDays: _selectedDays,
        availableTimeSlots: _selectedTimeSlots,
        location: _locationController.text.trim(),
      );

      if (mounted) {
        context.showSnackBar('Listing created successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to create listing: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
