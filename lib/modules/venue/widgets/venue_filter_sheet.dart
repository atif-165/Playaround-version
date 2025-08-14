import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Bottom sheet for filtering venues
class VenueFilterSheet extends StatefulWidget {
  final SportType? selectedSportType;
  final String? selectedLocation;
  final Function(SportType?, String?) onFiltersApplied;
  final VoidCallback onFiltersCleared;

  const VenueFilterSheet({
    super.key,
    this.selectedSportType,
    this.selectedLocation,
    required this.onFiltersApplied,
    required this.onFiltersCleared,
  });

  @override
  State<VenueFilterSheet> createState() => _VenueFilterSheetState();
}

class _VenueFilterSheetState extends State<VenueFilterSheet> {
  SportType? _selectedSportType;
  String? _selectedLocation;
  final TextEditingController _locationController = TextEditingController();

  // Common locations for quick selection
  final List<String> _commonLocations = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Chennai',
    'Kolkata',
    'Hyderabad',
    'Pune',
    'Ahmedabad',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSportType = widget.selectedSportType;
    _selectedLocation = widget.selectedLocation;
    _locationController.text = _selectedLocation ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildContent(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filter Venues',
            style: TextStyles.font18DarkBlueBold,
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Clear All',
              style: TextStyles.font14MainBlue500Weight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSportTypeSection(),
          Gap(24.h),
          _buildLocationSection(),
          Gap(16.h),
        ],
      ),
    );
  }

  Widget _buildSportTypeSection() {
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
          children: SportType.values.map((sportType) {
            final isSelected = _selectedSportType == sportType;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSportType = isSelected ? null : sportType;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? ColorsManager.mainBlue : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? ColorsManager.mainBlue : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  sportType.displayName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _locationController,
            onChanged: (value) {
              setState(() {
                _selectedLocation = value.isNotEmpty ? value : null;
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter city or area',
              hintStyle: TextStyles.font14Grey400Weight,
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
        ),
        Gap(12.h),
        Text(
          'Popular Cities',
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _commonLocations.map((location) {
            final isSelected = _selectedLocation == location;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLocation = isSelected ? null : location;
                  _locationController.text = _selectedLocation ?? '';
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? ColorsManager.mainBlue.withValues(alpha: 0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isSelected ? ColorsManager.mainBlue : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? ColorsManager.mainBlue : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyles.font14Grey400Weight,
              ),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyles.font14White600Weight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedSportType = null;
      _selectedLocation = null;
      _locationController.clear();
    });
    widget.onFiltersCleared();
    Navigator.pop(context);
  }

  void _applyFilters() {
    widget.onFiltersApplied(_selectedSportType, _selectedLocation);
    Navigator.pop(context);
  }
}
