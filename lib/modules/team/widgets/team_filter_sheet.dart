import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Team filters data class
class TeamFilterData {
  final List<String> sports;
  final int? minSkill;
  final int? maxSkill;
  final double? radiusKm;
  final List<String> timeSlots;

  const TeamFilterData({
    this.sports = const [],
    this.minSkill,
    this.maxSkill,
    this.radiusKm,
    this.timeSlots = const [],
  });

  bool get isActive {
    return sports.isNotEmpty ||
        minSkill != null ||
        maxSkill != null ||
        radiusKm != null ||
        timeSlots.isNotEmpty;
  }
}

/// Widget for filtering teams
class TeamFilterSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const TeamFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
  });

  @override
  State<TeamFilterSheet> createState() => _TeamFilterSheetState();
}

class _TeamFilterSheetState extends State<TeamFilterSheet> {
  List<String> _selectedSports = [];
  RangeValues _skillRange = const RangeValues(0, 100);
  double _radiusKm = 20.0;
  List<String> _selectedTimeSlots = [];

  final List<String> _availableSports = [
    'Football',
    'Cricket',
    'Basketball',
    'Tennis',
    'Badminton',
    'Volleyball',
  ];

  final List<String> _availableTimeSlots = [
    'Morning (6-12)',
    'Afternoon (12-18)',
    'Evening (18-24)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSports = List<String>.from(widget.currentFilters['sports'] ?? []);
    _skillRange = RangeValues(
      (widget.currentFilters['minSkill'] ?? 0).toDouble(),
      (widget.currentFilters['maxSkill'] ?? 100).toDouble(),
    );
    _radiusKm = widget.currentFilters['radiusKm'] ?? 20.0;
    _selectedTimeSlots =
        List<String>.from(widget.currentFilters['timeSlots'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSportsFilter(),
                  Gap(24.h),
                  _buildSkillRangeFilter(),
                  Gap(24.h),
                  _buildDistanceFilter(),
                  Gap(24.h),
                  _buildTimeSlotFilter(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorsManager.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filter Teams',
            style: TextStyles.font18DarkBlueBold,
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear All',
              style: TextStyles.font14MainBlue500Weight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sports',
          style: TextStyles.font16DarkBlueBold,
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
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Text(
          'From ${_skillRange.start.round()} to ${_skillRange.end.round()}',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        RangeSlider(
          values: _skillRange,
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: ColorsManager.primary,
          onChanged: (values) {
            setState(() {
              _skillRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Text(
          'Within ${_radiusKm.round()} km',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Slider(
          value: _radiusKm,
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: ColorsManager.primary,
          onChanged: (value) {
            setState(() {
              _radiusKm = value;
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
          style: TextStyles.font16DarkBlueBold,
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

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ColorsManager.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsManager.textSecondary,
                side: BorderSide(color: ColorsManager.textSecondary),
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
              child: const Text('Cancel'),
            ),
          ),
          Gap(16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedSports.clear();
      _skillRange = const RangeValues(0, 100);
      _radiusKm = 20.0;
      _selectedTimeSlots.clear();
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'sports': _selectedSports,
      'minSkill': _skillRange.start.round(),
      'maxSkill': _skillRange.end.round(),
      'radiusKm': _radiusKm,
      'timeSlots': _selectedTimeSlots,
    };

    widget.onFiltersApplied(filters);
    Navigator.of(context).pop();
  }
}
