import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/listing_model.dart';
import '../../../models/venue_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../services/venue_service.dart';
import '../widgets/time_slot_selector.dart';
import '../widgets/image_upload_section.dart';
import '../widgets/amenities_selector.dart';

/// Screen for editing an existing venue
class EditVenueScreen extends StatefulWidget {
  final VenueModel venue;

  const EditVenueScreen({
    super.key,
    required this.venue,
  });

  @override
  State<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final VenueService _venueService = VenueService();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _contactInfoController;

  // Form state
  late SportType _selectedSportType;
  late List<String> _selectedImages;
  late List<TimeSlot> _selectedTimeSlots;
  late List<String> _selectedDays;
  late List<String> _selectedAmenities;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers with existing venue data
    _titleController = TextEditingController(text: widget.venue.title);
    _descriptionController = TextEditingController(text: widget.venue.description);
    _locationController = TextEditingController(text: widget.venue.location);
    _hourlyRateController = TextEditingController(text: widget.venue.hourlyRate.toString());
    _contactInfoController = TextEditingController(text: widget.venue.contactInfo ?? '');

    // Initialize form state with existing venue data
    _selectedSportType = widget.venue.sportType;
    _selectedImages = List<String>.from(widget.venue.images);
    _selectedTimeSlots = List<TimeSlot>.from(widget.venue.availableTimeSlots);
    _selectedDays = List<String>.from(widget.venue.availableDays);
    _selectedAmenities = List<String>.from(widget.venue.amenities);
  }

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
          'Edit Venue',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: ColorsManager.neonBlue,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: ColorsManager.neonBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _resetForm,
            child: Text(
              'Reset',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
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
              _buildActionButtons(),
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
        _buildSportTypeDropdown(),
        Gap(16.h),
        AppTextField(
          controller: _descriptionController,
          labelText: 'Description *',
          hintText: 'Describe your venue, facilities, and features',
          prefixIcon: const Icon(Icons.description),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter venue description';
            }
            if (value.trim().length < 20) {
              return 'Description must be at least 20 characters';
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
          hintText: 'Enter venue address or location',
          prefixIcon: const Icon(Icons.location_on),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter venue location';
            }
            if (value.trim().length < 5) {
              return 'Location must be at least 5 characters';
            }
            return null;
          },
        ),
        Gap(16.h),
        AppTextField(
          controller: _hourlyRateController,
          labelText: 'Hourly Rate (\$) *',
          hintText: 'Enter hourly rate (e.g., 25.00)',
          prefixIcon: const Icon(Icons.attach_money),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter hourly rate';
            }
            final rate = double.tryParse(value.trim());
            if (rate == null || rate <= 0) {
              return 'Please enter a valid hourly rate';
            }
            if (rate > 1000) {
              return 'Hourly rate cannot exceed \$1000';
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
          'Sport Type *',
          style: AppTypography.titleMedium,
        ),
        Gap(8.h),
        DropdownButtonFormField<SportType>(
          initialValue: _selectedSportType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            prefixIcon: const Icon(Icons.sports),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          items: SportType.values.map((sport) {
            return DropdownMenuItem(
              value: sport,
              child: Text(sport.displayName),
            );
          }).toList(),
          onChanged: (SportType? value) {
            if (value != null) {
              setState(() {
                _selectedSportType = value;
              });
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a sport type';
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
          'Add photos to showcase your venue',
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
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              },
              selectedColor: ColorsManager.primary.withValues(alpha: 0.2),
              checkmarkColor: ColorsManager.primary,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        AppFilledButton(
          text: 'Save Changes',
          onPressed: _submitForm,
          isLoading: _isLoading,
          fullWidth: true,
          size: ButtonSize.large,
          variant: ButtonVariant.primary,
          icon: const Icon(Icons.save),
        ),
        Gap(12.h),
        AppOutlinedButton(
          text: 'Cancel',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          fullWidth: true,
          size: ButtonSize.large,
          variant: ButtonVariant.secondary,
          icon: const Icon(Icons.cancel),
        ),
      ],
    );
  }

  void _resetForm() {
    setState(() {
      _titleController.text = widget.venue.title;
      _descriptionController.text = widget.venue.description;
      _locationController.text = widget.venue.location;
      _hourlyRateController.text = widget.venue.hourlyRate.toString();
      _contactInfoController.text = widget.venue.contactInfo ?? '';

      _selectedSportType = widget.venue.sportType;
      _selectedImages = List<String>.from(widget.venue.images);
      _selectedTimeSlots = List<TimeSlot>.from(widget.venue.availableTimeSlots);
      _selectedDays = List<String>.from(widget.venue.availableDays);
      _selectedAmenities = List<String>.from(widget.venue.amenities);
    });
  }

  Future<void> _submitForm() async {
    print('🔄 EditVenueScreen: Save Changes button pressed');

    // Show loading immediately
    setState(() {
      _isLoading = true;
    });

    try {
      // Form validation with detailed checking
      print('🔍 EditVenueScreen: Checking form validation...');
      print('📝 Title: "${_titleController.text.trim()}" (length: ${_titleController.text.trim().length})');
      print('📝 Description: "${_descriptionController.text.trim()}" (length: ${_descriptionController.text.trim().length})');
      print('📝 Location: "${_locationController.text.trim()}" (length: ${_locationController.text.trim().length})');
      print('📝 Hourly Rate: "${_hourlyRateController.text.trim()}"');
      print('📝 Contact Info: "${_contactInfoController.text.trim()}"');

      if (!_formKey.currentState!.validate()) {
        print('❌ EditVenueScreen: Form validation failed');

        // Check each field individually to identify the issue
        String errorDetails = '';

        if (_titleController.text.trim().isEmpty) {
          errorDetails += '• Venue name is required\n';
        } else if (_titleController.text.trim().length < 3) {
          errorDetails += '• Venue name must be at least 3 characters\n';
        } else if (_titleController.text.trim().length > 50) {
          errorDetails += '• Venue name must be less than 50 characters\n';
        }

        if (_descriptionController.text.trim().isEmpty) {
          errorDetails += '• Description is required\n';
        } else if (_descriptionController.text.trim().length < 20) {
          errorDetails += '• Description must be at least 20 characters\n';
        } else if (_descriptionController.text.trim().length > 500) {
          errorDetails += '• Description must be less than 500 characters\n';
        }

        if (_locationController.text.trim().isEmpty) {
          errorDetails += '• Location is required\n';
        } else if (_locationController.text.trim().length < 5) {
          errorDetails += '• Location must be at least 5 characters\n';
        }

        final hourlyRate = double.tryParse(_hourlyRateController.text.trim());
        if (_hourlyRateController.text.trim().isEmpty) {
          errorDetails += '• Hourly rate is required\n';
        } else if (hourlyRate == null || hourlyRate <= 0) {
          errorDetails += '• Please enter a valid hourly rate\n';
        } else if (hourlyRate > 1000) {
          errorDetails += '• Hourly rate cannot exceed \$1000\n';
        }

        if (errorDetails.isEmpty) {
          errorDetails = 'Please check all form fields for errors.';
        }

        _showErrorDialog('Form Validation Error', errorDetails.trim());
        return;
      }

      // Additional validation
      if (_selectedDays.isEmpty) {
        print('❌ EditVenueScreen: No days selected');
        _showErrorDialog('Validation Error', 'Please select at least one available day.');
        return;
      }

      if (_selectedTimeSlots.isEmpty) {
        print('❌ EditVenueScreen: No time slots selected');
        _showErrorDialog('Validation Error', 'Please add at least one time slot.');
        return;
      }

      // Validate hourly rate parsing
      final hourlyRateText = _hourlyRateController.text.trim();
      final hourlyRate = double.tryParse(hourlyRateText);
      if (hourlyRate == null || hourlyRate <= 0) {
        print('❌ EditVenueScreen: Invalid hourly rate: $hourlyRateText');
        _showErrorDialog('Validation Error', 'Please enter a valid hourly rate (greater than 0).');
        return;
      }

      print('🔄 EditVenueScreen: Starting venue update for venue ID: ${widget.venue.id}');
      print('📝 EditVenueScreen: Title: ${_titleController.text.trim()}');
      print('🏃 EditVenueScreen: Sport: $_selectedSportType');
      print('💰 EditVenueScreen: Rate: $hourlyRate');
      print('📅 EditVenueScreen: Days: $_selectedDays');
      print('⏰ EditVenueScreen: Time slots: ${_selectedTimeSlots.length}');

      await _venueService.updateVenue(
        venueId: widget.venue.id,
        title: _titleController.text.trim(),
        sportType: _selectedSportType,
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

      print('✅ EditVenueScreen: Venue updated successfully');

      if (mounted) {
        // Show success dialog
        _showSuccessDialog();
      }
    } catch (e) {
      print('❌ EditVenueScreen: Error updating venue: $e');
      if (mounted) {
        _showErrorDialog('Update Failed', 'Failed to update venue: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Venue updated successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Close edit screen with success result
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
