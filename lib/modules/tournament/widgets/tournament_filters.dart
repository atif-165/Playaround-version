import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/listing_model.dart';
import '../models/tournament_model.dart';

/// Tournament filters data class
class TournamentFilterData {
  final SportType? sportType;
  final TournamentFormat? format;
  final TournamentStatus? status;
  final double? maxEntryFee;
  final String? location;
  final bool showFreeOnly;
  final bool showPaidOnly;

  const TournamentFilterData({
    this.sportType,
    this.format,
    this.status,
    this.maxEntryFee,
    this.location,
    this.showFreeOnly = false,
    this.showPaidOnly = false,
  });

  /// Check if any filters are active
  bool get isActive {
    return sportType != null ||
        format != null ||
        status != null ||
        maxEntryFee != null ||
        location != null ||
        showFreeOnly ||
        showPaidOnly;
  }
}

/// Widget for filtering tournaments
class TournamentFilters extends StatefulWidget {
  final SportType? selectedSportType;
  final TournamentFormat? selectedFormat;
  final TournamentStatus? selectedStatus;
  final double? maxEntryFee;
  final String? location;
  final bool showFreeOnly;
  final bool showPaidOnly;
  final Function(TournamentFilterData) onApply;

  const TournamentFilters({
    super.key,
    required this.selectedSportType,
    required this.selectedFormat,
    required this.selectedStatus,
    required this.maxEntryFee,
    required this.location,
    required this.showFreeOnly,
    required this.showPaidOnly,
    required this.onApply,
  });

  @override
  State<TournamentFilters> createState() => _TournamentFiltersState();
}

class _TournamentFiltersState extends State<TournamentFilters> {
  late SportType? _selectedSportType;
  late TournamentFormat? _selectedFormat;
  late TournamentStatus? _selectedStatus;
  late double? _maxEntryFee;
  late String? _location;
  late bool _showFreeOnly;
  late bool _showPaidOnly;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _maxFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSportType = widget.selectedSportType;
    _selectedFormat = widget.selectedFormat;
    _selectedStatus = widget.selectedStatus;
    _maxEntryFee = widget.maxEntryFee;
    _location = widget.location;
    _showFreeOnly = widget.showFreeOnly;
    _showPaidOnly = widget.showPaidOnly;

    if (_maxEntryFee != null) {
      _maxFeeController.text = _maxEntryFee!.toStringAsFixed(0);
    }
    _locationController.text = _location ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _maxFeeController.dispose();
    super.dispose();
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
                  _buildSportTypeFilter(),
                  Gap(24.h),
                  _buildFormatFilter(),
                  Gap(24.h),
                  _buildStatusFilter(),
                  Gap(24.h),
                  _buildEntryFeeFilter(),
                  Gap(24.h),
                  _buildLocationFilter(),
                  Gap(24.h),
                  _buildSpecialFilters(),
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
            'Filter Tournaments',
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

  Widget _buildSportTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sport Type',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: SportType.values.map((sport) {
            final isSelected = _selectedSportType == sport;
            return FilterChip(
              label: Text(sport.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSportType = selected ? sport : null;
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

  Widget _buildFormatFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Format',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: TournamentFormat.values.map((format) {
            final isSelected = _selectedFormat == format;
            return FilterChip(
              label: Text(format.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFormat = selected ? format : null;
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

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Status',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: TournamentStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return FilterChip(
              label: Text(status.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : null;
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

  Widget _buildEntryFeeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entry Fee',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _maxFeeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Entry Fee',
                  hintText: 'e.g., 50',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onChanged: (value) {
                  _maxEntryFee = double.tryParse(value);
                },
              ),
            ),
          ],
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text(
                  'Free Only',
                  style: TextStyles.font14DarkBlueMedium,
                ),
                value: _showFreeOnly,
                onChanged: (value) {
                  setState(() {
                    _showFreeOnly = value ?? false;
                    if (_showFreeOnly) {
                      _showPaidOnly = false;
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: Text(
                  'Paid Only',
                  style: TextStyles.font14DarkBlueMedium,
                ),
                value: _showPaidOnly,
                onChanged: (value) {
                  setState(() {
                    _showPaidOnly = value ?? false;
                    if (_showPaidOnly) {
                      _showFreeOnly = false;
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'City or Venue',
            hintText: 'e.g., New York, Central Park',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          onChanged: (value) {
            _location = value.trim().isEmpty ? null : value.trim();
          },
        ),
      ],
    );
  }

  Widget _buildSpecialFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Filters',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'Show Only Tournaments I Can Join',
                    style: TextStyles.font14DarkBlueMedium,
                  ),
                  subtitle: Text(
                    'Filter out tournaments that are full or closed',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: ColorsManager.textSecondary,
                    ),
                  ),
                  trailing: Switch(
                    value: false, // TODO: Implement this filter
                    onChanged: (value) {
                      // TODO: Implement this filter
                    },
                  ),
                ),
                ListTile(
                  title: Text(
                    'Show Only Verified Organizers',
                    style: TextStyles.font14DarkBlueMedium,
                  ),
                  subtitle: Text(
                    'Filter tournaments by verified organizers only',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: ColorsManager.textSecondary,
                    ),
                  ),
                  trailing: Switch(
                    value: false, // TODO: Implement this filter
                    onChanged: (value) {
                      // TODO: Implement this filter
                    },
                  ),
                ),
              ],
            ),
          ),
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
      _selectedSportType = null;
      _selectedFormat = null;
      _selectedStatus = null;
      _maxEntryFee = null;
      _location = null;
      _showFreeOnly = false;
      _showPaidOnly = false;
      _maxFeeController.clear();
      _locationController.clear();
    });
  }

  void _applyFilters() {
    final filters = TournamentFilterData(
      sportType: _selectedSportType,
      format: _selectedFormat,
      status: _selectedStatus,
      maxEntryFee: _maxEntryFee,
      location: _location,
      showFreeOnly: _showFreeOnly,
      showPaidOnly: _showPaidOnly,
    );

    widget.onApply(filters);
    Navigator.of(context).pop();
  }
}
