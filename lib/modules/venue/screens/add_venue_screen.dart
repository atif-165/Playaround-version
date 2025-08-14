import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../services/venue_service.dart';
import '../widgets/time_slot_selector.dart';
import '../widgets/image_upload_section.dart';
import '../widgets/amenities_selector.dart';

/// Screen for adding a new venue
class AddVenueScreen extends StatefulWidget {
  const AddVenueScreen({super.key});

  @override
  State<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends State<AddVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final VenueService _venueService = VenueService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _contactInfoController = TextEditingController();

  // Form state
  SportType? _selectedSportType;
  List<String> _selectedImages = [];
  List<TimeSlot> _selectedTimeSlots = [];
  final List<String> _selectedDays = [];
  List<String> _selectedAmenities = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Venue',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: ColorsManager.neonBlue,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: ColorsManager.neonBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              Gap(24.h),
              _buildImageUploadSection(),
              Gap(24.h),
              _buildAvailabilitySection(),
              Gap(24.h),
              _buildAmenitiesSection(),
              Gap(24.h),
              _buildContactSection(),
              Gap(32.h),
              _buildSubmitButton(),
              Gap(16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: AppTypography.titleLarge,
        ),
        Gap(16.h),
        AppTextField(
          controller: _titleController,
          labelText: 'Venue Name *',
          hintText: 'Enter venue name (e.g., City Sports Complex)',
          prefixIcon: const Icon(Icons.business),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter venue name';
            }
            if (value.trim().length < 3) {
              return 'Venue name must be at least 3 characters';
            }
            if (value.trim().length > 50) {
              return 'Venue name must be less than 50 characters';
            }
            return null;
          },
        ),
        Gap(16.h),
        AppDropdownField<SportType>(
          labelText: 'Sport Type *',
          value: _selectedSportType,
          prefixIcon: const Icon(Icons.sports_soccer),
          items: SportType.values.map((sportType) {
            return DropdownMenuItem(
              value: sportType,
              child: Text(sportType.displayName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSportType = value;
            });
          },
          validator: (value) {
            if (value == null) return 'Please select a sport type';
            return null;
          },
        ),
        Gap(16.h),
        AppTextField(
          controller: _descriptionController,
          labelText: 'Description *',
          hintText: 'Describe your venue facilities, features, and amenities',
          prefixIcon: const Icon(Icons.description),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter venue description';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            if (value.trim().length > 500) {
              return 'Description must be less than 500 characters';
            }
            return null;
          },
        ),
        Gap(16.h),
        AppTextField(
          controller: _locationController,
          labelText: 'Location *',
          hintText: 'Enter complete venue address with city',
          prefixIcon: const Icon(Icons.location_on),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter venue location';
            }
            if (value.trim().length < 10) {
              return 'Please enter a complete address';
            }
            if (value.trim().length > 200) {
              return 'Address must be less than 200 characters';
            }
            return null;
          },
        ),
        Gap(16.h),
        AppTextField(
          controller: _hourlyRateController,
          labelText: 'Hourly Rate (₹) *',
          hintText: 'Enter hourly rate (e.g., 500)',
          prefixIcon: const Icon(Icons.currency_rupee),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter hourly rate';
            }
            final rate = double.tryParse(value.trim());
            if (rate == null) {
              return 'Please enter a valid number';
            }
            if (rate <= 0) {
              return 'Rate must be greater than 0';
            }
            if (rate > 10000) {
              return 'Rate seems too high. Please check.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue Images',
          style: AppTypography.titleLarge,
        ),
        Gap(8.h),
        Text(
          'Add up to 5 images of your venue',
          style: AppTypography.bodySmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        Gap(16.h),
        ImageUploadSection(
          images: _selectedImages,
          onImagesChanged: (images) {
            setState(() {
              _selectedImages = images;
            });
          },
          maxImages: 5,
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
          style: AppTypography.titleLarge,
        ),
        Gap(16.h),
        _buildDaySelector(),
        Gap(16.h),
        TimeSlotSelector(
          selectedTimeSlots: _selectedTimeSlots,
          onTimeSlotsChanged: (timeSlots) {
            setState(() {
              _selectedTimeSlots = timeSlots;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Days *',
          style: AppTypography.titleMedium,
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: days.map((day) {
            final isSelected = _selectedDays.contains(day);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorsManager.primary : ColorsManager.surfaceVariant,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected ? ColorsManager.primary : ColorsManager.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    day,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? ColorsManager.onPrimary : ColorsManager.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: AppTypography.titleLarge,
        ),
        Gap(8.h),
        Text(
          'Select available amenities',
          style: AppTypography.bodySmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        Gap(16.h),
        AmenitiesSelector(
          selectedAmenities: _selectedAmenities,
          onAmenitiesChanged: (amenities) {
            setState(() {
              _selectedAmenities = amenities;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: AppTypography.titleLarge,
        ),
        Gap(16.h),
        AppTextField(
          controller: _contactInfoController,
          labelText: 'Contact Info (Optional)',
          hintText: 'Phone number or additional contact details',
          prefixIcon: const Icon(Icons.phone),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AppFilledButton(
      text: 'Create Venue',
      onPressed: _submitForm,
      isLoading: _isLoading,
      fullWidth: true,
      size: ButtonSize.large,
      variant: ButtonVariant.primary,
      icon: const Icon(Icons.add_business),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation
    if (_selectedSportType == null) {
      _showErrorSnackBar('Please select a sport type');
      return;
    }

    if (_selectedDays.isEmpty) {
      _showErrorSnackBar('Please select at least one available day');
      return;
    }

    if (_selectedTimeSlots.isEmpty) {
      _showErrorSnackBar('Please add at least one time slot');
      return;
    }

    // Validate hourly rate parsing
    final hourlyRateText = _hourlyRateController.text.trim();
    final hourlyRate = double.tryParse(hourlyRateText);
    if (hourlyRate == null || hourlyRate <= 0) {
      _showErrorSnackBar('Please enter a valid hourly rate');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _venueService.createVenue(
        title: _titleController.text.trim(),
        sportType: _selectedSportType!,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        hourlyRate: hourlyRate,
        images: _selectedImages,
        availableTimeSlots: _selectedTimeSlots,
        availableDays: _selectedDays,
        amenities: _selectedAmenities,
        contactInfo: _contactInfoController.text.trim().isNotEmpty
            ? _contactInfoController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Venue created successfully!'),
            backgroundColor: ColorsManager.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to venue details or venues list
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to create venue: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorsManager.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
