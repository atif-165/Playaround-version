import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../core/widgets/app_text_button.dart';

/// Filter bottom sheet for explore screen
class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _filters;
  double _radiusKm = 20.0;
  List<String> _selectedSports = [];
  RangeValues _skillRange = const RangeValues(0, 100);
  List<String> _selectedTimeSlots = [];

  final List<String> _availableSports = [
    'Football',
    'Cricket',
    'Basketball',
    'Tennis',
    'Badminton',
    'Swimming',
    'Running',
    'Cycling',
    'Volleyball',
    'Table Tennis',
  ];

  final List<String> _availableTimeSlots = [
    'Morning (6-12)',
    'Afternoon (12-18)',
    'Evening (18-24)',
    'Night (24-6)',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
    _radiusKm = _filters['radiusKm'] ?? 20.0;
    _selectedSports = List<String>.from(_filters['sports'] ?? []);
    _skillRange = RangeValues(
      (_filters['minSkill'] ?? 0).toDouble(),
      (_filters['maxSkill'] ?? 100).toDouble(),
    );
    _selectedTimeSlots = List<String>.from(_filters['timeSlots'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: ColorsManager.mainBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey[200]),

          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(16.h),
                  _buildDistanceFilter(),
                  Gap(24.h),
                  _buildSportsFilter(),
                  Gap(24.h),
                  _buildSkillRangeFilter(),
                  Gap(24.h),
                  _buildTimeSlotFilter(),
                  Gap(32.h),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: AppTextButton(
              buttonText: 'Apply Filters',
              textStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              onPressed: _applyFilters,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Gap(12.h),
        Text(
          'Within ${_radiusKm.round()} km',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        Slider(
          value: _radiusKm,
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: ColorsManager.mainBlue,
          onChanged: (value) {
            setState(() {
              _radiusKm = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSportsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sports',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _availableSports.map((sport) {
            final isSelected = _selectedSports.contains(sport);
            return FilterChip(
              label: Text(sport),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSports.add(sport);
                  } else {
                    _selectedSports.remove(sport);
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

  Widget _buildSkillRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Level',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Gap(12.h),
        Text(
          'From ${_skillRange.start.round()} to ${_skillRange.end.round()}',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        RangeSlider(
          values: _skillRange,
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: ColorsManager.mainBlue,
          onChanged: (values) {
            setState(() {
              _skillRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimeSlotFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _availableTimeSlots.map((timeSlot) {
            final isSelected = _selectedTimeSlots.contains(timeSlot);
            return FilterChip(
              label: Text(timeSlot),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTimeSlots.add(timeSlot);
                  } else {
                    _selectedTimeSlots.remove(timeSlot);
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

  void _clearAllFilters() {
    setState(() {
      _radiusKm = 20.0;
      _selectedSports.clear();
      _skillRange = const RangeValues(0, 100);
      _selectedTimeSlots.clear();
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'radiusKm': _radiusKm,
      'sports': _selectedSports,
      'minSkill': _skillRange.start.round(),
      'maxSkill': _skillRange.end.round(),
      'timeSlots': _selectedTimeSlots,
    };

    widget.onFiltersChanged(filters);
    Navigator.of(context).pop();
  }
}
