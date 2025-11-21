import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
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
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _googleMapsLinkController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _weeklyRateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customSportsController = TextEditingController();

  SportType? _selectedSportType;
  final Set<SportType> _additionalSports = <SportType>{};
  String _selectedCurrency = 'PKR';

  List<String> _selectedImages = [];
  List<TimeSlot> _selectedTimeSlots = [];
  final List<String> _selectedDays = [];
  List<String> _selectedAmenities = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _googleMapsLinkController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _weeklyRateController.dispose();
    _phoneController.dispose();
    _customSportsController.dispose();
    super.dispose();
  }

  Widget _wrapSection(Widget child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSportsSection() {
    final availableSports = SportType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Games Available',
          style: AppTypography.titleLarge,
        ),
        Gap(8.h),
        Text(
          'Select all games that can be played at your venue.',
          style: AppTypography.bodySmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        Gap(16.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: availableSports.map((sport) {
            final isPrimary = sport == _selectedSportType;
            final isSelected =
                isPrimary || _additionalSports.contains(sport);

            return FilterChip(
              selected: isSelected,
              label: Text(sport.displayName),
              onSelected: isPrimary
                  ? null
                  : (selected) {
                      setState(() {
                        if (selected) {
                          _additionalSports.add(sport);
                        } else {
                          _additionalSports.remove(sport);
                        }
                      });
                    },
              selectedColor: ColorsManager.primary,
              checkmarkColor: Colors.white,
              backgroundColor: ColorsManager.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : ColorsManager.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected
                      ? ColorsManager.primary
                      : ColorsManager.outline.withOpacity(0.5),
                ),
              ),
            );
          }).toList(),
        ),
        Gap(16.h),
        AppTextField(
          controller: _customSportsController,
          labelText: 'Custom Games (Optional)',
          hintText: 'Enter additional games separated by commas',
          prefixIcon: const Icon(Icons.sports),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Details',
          style: AppTypography.titleLarge,
        ),
        Gap(8.h),
        Text(
          'Share your complete address so players can find you easily.',
          style: AppTypography.bodySmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        Gap(16.h),
        AppTextField(
          controller: _addressController,
          labelText: 'Street Address *',
          hintText: 'House 12, Sports Avenue, Sector F-11',
          prefixIcon: const Icon(Icons.home_work),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the street address';
            }
            if (value.trim().length < 8) {
              return 'Address must be at least 8 characters';
            }
            return null;
          },
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _cityController,
                labelText: 'City *',
                hintText: 'e.g., Islamabad',
                prefixIcon: const Icon(Icons.location_city),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AppTextField(
                controller: _stateController,
                labelText: 'State / Province',
                hintText: 'Optional',
                prefixIcon: const Icon(Icons.map_outlined),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        Gap(16.h),
        AppTextField(
          controller: _countryController,
          labelText: 'Country *',
          hintText: 'e.g., Pakistan',
          prefixIcon: const Icon(Icons.flag_outlined),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter country';
            }
            return null;
          },
        ),
        Gap(16.h),
        AppTextField(
          controller: _googleMapsLinkController,
          labelText: 'Google Maps Link *',
          hintText: 'https://maps.google.com/...',
          prefixIcon: const Icon(Icons.link),
          keyboardType: TextInputType.url,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide the Google Maps link';
            }
            final trimmed = value.trim();
            if (!trimmed.startsWith('http')) {
              return 'Link should start with http or https';
            }
            if (!trimmed.contains('google')) {
              return 'Please provide a valid Google Maps link';
            }
            return null;
          },
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _latitudeController,
                labelText: 'Latitude *',
                hintText: 'e.g., 33.6844',
                prefixIcon: const Icon(Icons.my_location),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AppTextField(
                controller: _longitudeController,
                labelText: 'Longitude *',
                hintText: 'e.g., 73.0479',
                prefixIcon: const Icon(Icons.explore_outlined),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        Gap(12.h),
        Text(
          'Tip: In Google Maps, long-press your venue location and copy the latitude/longitude pair.',
          style: AppTypography.bodySmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: AppTypography.titleLarge,
        ),
        Gap(8.h),
        Text(
          'Share your standard pricing. Players will see this on the venue page.',
          style: AppTypography.bodySmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        Gap(16.h),
        AppTextField(
          controller: _hourlyRateController,
          labelText: 'Hourly Rate *',
          hintText: 'Enter hourly rate (e.g., 500)',
          prefixIcon: const Icon(Icons.schedule_outlined),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter hourly rate';
            }
            final rate = double.tryParse(value.trim());
            if (rate == null) {
              return 'Please enter a valid number';
            }
            if (rate <= 0) {
              return 'Rate must be greater than zero';
            }
            return null;
          },
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _dailyRateController,
                labelText: 'Daily Rate',
                hintText: 'Optional',
                prefixIcon: const Icon(Icons.calendar_view_day),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AppTextField(
                controller: _weeklyRateController,
                labelText: 'Weekly Rate',
                hintText: 'Optional',
                prefixIcon: const Icon(Icons.calendar_month),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        Gap(16.h),
        AppDropdownField<String>(
          labelText: 'Currency',
          value: _selectedCurrency,
          prefixIcon: const Icon(Icons.payments_outlined),
          items: const [
            DropdownMenuItem(value: 'PKR', child: Text('PKR - Pakistani Rupee')),
            DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
            DropdownMenuItem(value: 'AED', child: Text('AED - Dirham')),
            DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
            DropdownMenuItem(value: 'GBP', child: Text('GBP - Pound Sterling')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedCurrency = value;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          'Add New Venue',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E0C22),
              Color(0xFF04030A),
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Let’s bring your venue to life',
                    style: AppTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(8.h),
                  Text(
                    'Share visuals, availability, and pricing so athletes know exactly what to expect.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.75),
                      height: 1.4,
                    ),
                  ),
                  Gap(24.h),
                  _wrapSection(_buildBasicInfoSection()),
                  Gap(20.h),
                  _wrapSection(_buildSportsSection()),
                  Gap(20.h),
                  _wrapSection(_buildLocationSection()),
                  Gap(20.h),
                  _wrapSection(_buildImageUploadSection()),
                  Gap(20.h),
                  _wrapSection(_buildPricingSection()),
                  Gap(20.h),
                  _wrapSection(_buildAvailabilitySection()),
                  Gap(20.h),
                  _wrapSection(_buildAmenitiesSection()),
                  Gap(20.h),
                  _wrapSection(_buildContactSection()),
                  Gap(28.h),
                  _buildSubmitButton(),
                  Gap(16.h),
                ],
              ),
            ),
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
              if (value != null) {
                _additionalSports.remove(value);
              }
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
          'Upload at least 3 high-quality photos that showcase different areas of your venue (max 8).',
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
          maxImages: 8,
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorsManager.primary
                        : ColorsManager.surfaceVariant,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? ColorsManager.primary
                          : ColorsManager.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    day,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? ColorsManager.onPrimary
                          : ColorsManager.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
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
        Gap(8.h),
        Text(
          'Players will use this number to reach your venue directly from the detail page.',
          style: AppTypography.bodySmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        Gap(16.h),
        AppTextField(
          controller: _phoneController,
          labelText: 'Phone Number *',
          hintText: 'Enter a phone number players can reach',
          prefixIcon: const Icon(Icons.phone),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a phone number';
            }
            if (value.trim().length < 6) {
              return 'Phone number is too short';
            }
            return null;
          },
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

    if (_selectedImages.length < 3) {
      _showErrorSnackBar('Please upload at least 3 venue images');
      return;
    }

    final googleMapsLink = _googleMapsLinkController.text.trim();
    if (googleMapsLink.isEmpty) {
      _showErrorSnackBar('Please provide the Google Maps link for your venue');
      return;
    }
    if (!googleMapsLink.startsWith('http')) {
      _showErrorSnackBar('Google Maps link should start with http or https');
      return;
    }

    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('Please provide a phone number');
      return;
    }

    final city = _cityController.text.trim();
    if (city.isEmpty) {
      _showErrorSnackBar('Please provide the city where your venue is located');
      return;
    }

    final country = _countryController.text.trim();
    if (country.isEmpty) {
      _showErrorSnackBar('Please provide the country for your venue');
      return;
    }

    final latitudeText = _latitudeController.text.trim();
    final longitudeText = _longitudeController.text.trim();
    final latitude = double.tryParse(latitudeText);
    final longitude = double.tryParse(longitudeText);
    if (latitude == null || longitude == null) {
      _showErrorSnackBar('Please provide valid latitude and longitude values');
      return;
    }

    // Build sports list
    final sportsOffered = <String>{_selectedSportType!.displayName};
    sportsOffered
        .addAll(_additionalSports.map((sport) => sport.displayName));
    final customSports = _parseCustomSports();
    sportsOffered.addAll(customSports);

    if (sportsOffered.isEmpty) {
      _showErrorSnackBar('Please add at least one game available at the venue');
      return;
    }

    // Validate hourly rate parsing
    final hourlyRateText = _hourlyRateController.text.trim();
    final hourlyRate = double.tryParse(hourlyRateText);
    if (hourlyRate == null || hourlyRate <= 0) {
      _showErrorSnackBar('Please enter a valid hourly rate');
      return;
    }

    final dailyRateText = _dailyRateController.text.trim();
    final weeklyRateText = _weeklyRateController.text.trim();

    double? dailyRate;
    if (dailyRateText.isNotEmpty) {
      dailyRate = double.tryParse(dailyRateText);
      if (dailyRate == null || dailyRate <= 0) {
        _showErrorSnackBar('Please enter a valid daily rate or leave it empty');
        return;
      }
    }

    double? weeklyRate;
    if (weeklyRateText.isNotEmpty) {
      weeklyRate = double.tryParse(weeklyRateText);
      if (weeklyRate == null || weeklyRate <= 0) {
        _showErrorSnackBar(
            'Please enter a valid weekly rate or leave it empty');
        return;
      }
    }

    final hoursPayload = _buildHoursPayload();

    final metadata = <String, dynamic>{
      'googleMapsLink': googleMapsLink,
      'phoneNumber': phoneNumber,
      'sportsOffered': sportsOffered.toList(),
      'address': {
        'street': _addressController.text.trim(),
        'city': city,
        if (_stateController.text.trim().isNotEmpty)
          'state': _stateController.text.trim(),
        'country': country,
      },
      'coordinates': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'pricing': {
        'hourlyRate': hourlyRate,
        if (dailyRate != null) 'dailyRate': dailyRate,
        if (weeklyRate != null) 'weeklyRate': weeklyRate,
        'currency': _selectedCurrency,
      },
      'availability': {
        'days': _selectedDays,
        'timeSlots': _selectedTimeSlots.map((slot) => slot.toMap()).toList(),
      },
      if (_selectedAmenities.isNotEmpty) 'amenities': _selectedAmenities,
      if (customSports.isNotEmpty) 'customSports': customSports,
    };

    final sanitizedMetadata = _sanitizeMetadata(metadata);

    final gpsCoordinates =
        '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

    setState(() {
      _isLoading = true;
    });

    try {
      await _venueService.createVenue(
        title: _titleController.text.trim(),
        sportType: _selectedSportType!,
        description: _descriptionController.text.trim(),
        location: _addressController.text.trim(),
        city: city,
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        country: country,
        latitude: latitude,
        longitude: longitude,
        googleMapsLink: googleMapsLink,
        hourlyRate: hourlyRate,
        dailyRate: dailyRate,
        weeklyRate: weeklyRate,
        currency: _selectedCurrency,
        sports: sportsOffered.toList(),
        images: _selectedImages,
        availableTimeSlots: _selectedTimeSlots,
        availableDays: _selectedDays,
        amenities: _selectedAmenities,
        contactInfo: phoneNumber,
        phoneNumber: phoneNumber,
        gpsCoordinates: gpsCoordinates,
        hours: hoursPayload,
        metadata: sanitizedMetadata,
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

  Map<String, dynamic>? _buildHoursPayload() {
    if (_selectedDays.isEmpty || _selectedTimeSlots.isEmpty) return null;

    final earliest = _selectedTimeSlots
        .map((slot) => slot.start)
        .reduce(_earliestTime);
    final latest =
        _selectedTimeSlots.map((slot) => slot.end).reduce(_latestTime);

    final weeklyHours = <String, Map<String, dynamic>>{};
    for (final day in _selectedDays) {
      weeklyHours[day] = {
        'isOpen': true,
        'openTime': earliest,
        'closeTime': latest,
      };
    }

    return {
      'weeklyHours': weeklyHours,
      'holidays': <String>[],
    };
  }

  String _earliestTime(String a, String b) {
    return _timeToMinutesValue(a) <= _timeToMinutesValue(b) ? a : b;
  }

  String _latestTime(String a, String b) {
    return _timeToMinutesValue(a) >= _timeToMinutesValue(b) ? a : b;
  }

  int _timeToMinutesValue(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  List<String> _parseCustomSports() {
    final input = _customSportsController.text.trim();
    if (input.isEmpty) return [];
    return input
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _sanitizeMetadata(Map<String, dynamic> metadata) {
    final result = <String, dynamic>{};

    metadata.forEach((key, value) {
      if (value == null) return;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          result[key] = trimmed;
        }
      } else if (value is Map) {
        final cleaned =
            _sanitizeMetadata(Map<String, dynamic>.from(value as Map));
        if (cleaned != null && cleaned.isNotEmpty) {
          result[key] = cleaned;
        }
      } else if (value is Iterable) {
        final cleanedList = value
            .map((item) {
              if (item is String) return item.trim();
              if (item is Map) {
                return _sanitizeMetadata(
                    Map<String, dynamic>.from(item as Map));
              }
              return item;
            })
            .where((item) {
              if (item == null) return false;
              if (item is String) return item.trim().isNotEmpty;
              if (item is Map<String, dynamic>) {
                return item.isNotEmpty;
              }
              return true;
            })
            .toList();
        if (cleanedList.isNotEmpty) {
          result[key] = cleanedList;
        }
      } else {
        result[key] = value;
      }
    });

    return result.isEmpty ? null : result;
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
