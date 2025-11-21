import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../helpers/distance_helper.dart';

/// Location picker widget that allows users to either:
/// 1. Select a city from a list (with pre-defined coordinates)
/// 2. Use their current GPS location
/// 3. Manually enter a city name
class LocationPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Function(double? latitude, double? longitude)? onLocationChanged;
  final String hint;
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerField({
    super.key,
    required this.controller,
    this.validator,
    this.onLocationChanged,
    this.hint = 'Location',
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  List<String> _filteredCities = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    // Listen to text changes for city suggestions
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text.toLowerCase();
    if (text.isEmpty) {
      setState(() {
        _filteredCities = [];
        _showSuggestions = false;
      });
      return;
    }

    final cities = DistanceHelper.getSupportedCities();
    final filtered =
        cities.where((city) => city.contains(text)).take(5).toList();

    setState(() {
      _filteredCities = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      final permission = await Permission.location.status;
      if (!permission.isGranted) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          if (mounted) {
            _showError(
                'Location permission denied. Please enable it in settings.');
          }
          return;
        }
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showError(
              'Location services are disabled. Please enable them in settings.');
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        widget.controller.text =
            'My Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _showSuggestions = false;
      });

      widget.onLocationChanged?.call(_latitude, _longitude);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Location captured: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            backgroundColor: ColorsManager.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to get location: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _selectCity(String city) {
    widget.controller.text = city;

    // Get coordinates for this city
    final coords = DistanceHelper.getCoordinatesForCity(city);
    if (coords != null) {
      setState(() {
        _latitude = coords.lat;
        _longitude = coords.lng;
        _showSuggestions = false;
      });
      widget.onLocationChanged?.call(_latitude, _longitude);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorsManager.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                validator: widget.validator,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyles.font14Grey400Weight,
                  filled: true,
                  fillColor: ColorsManager.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: ColorsManager.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: ColorsManager.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                        color: ColorsManager.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: ColorsManager.error),
                  ),
                  suffixIcon: _latitude != null && _longitude != null
                      ? Icon(
                          Icons.location_on,
                          color: ColorsManager.success,
                          size: 20.sp,
                        )
                      : null,
                ),
                onTap: () {
                  if (_filteredCities.isEmpty &&
                      widget.controller.text.isEmpty) {
                    _onTextChanged();
                  }
                },
              ),
            ),
            Gap(8.w),
            Container(
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                tooltip: 'Use current location',
              ),
            ),
          ],
        ),

        // City suggestions
        if (_showSuggestions && _filteredCities.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(
              color: ColorsManager.surface,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredCities.length,
              itemBuilder: (context, index) {
                final city = _filteredCities[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_city,
                    color: ColorsManager.primary,
                    size: 18.sp,
                  ),
                  title: Text(
                    city.split(' ').map((word) => word.capitalize()).join(' '),
                    style: TextStyles.font14DarkBlue400Weight,
                  ),
                  onTap: () => _selectCity(city),
                );
              },
            ),
          ),

        // Location status
        if (_latitude != null && _longitude != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: ColorsManager.success,
                  size: 16.sp,
                ),
                Gap(6.w),
                Text(
                  'GPS coordinates captured',
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: ColorsManager.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
