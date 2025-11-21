import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';
import '../../team/models/team_model.dart';

class TournamentFilterSheet extends StatefulWidget {
  final SportType? selectedSport;
  final TournamentType? selectedType;
  final TournamentStatus? selectedStatus;
  final String? selectedLocation;
  final Function(SportType?, TournamentType?, TournamentStatus?, String?)
      onApplyFilters;

  const TournamentFilterSheet({
    super.key,
    this.selectedSport,
    this.selectedType,
    this.selectedStatus,
    this.selectedLocation,
    required this.onApplyFilters,
  });

  @override
  State<TournamentFilterSheet> createState() => _TournamentFilterSheetState();
}

class _TournamentFilterSheetState extends State<TournamentFilterSheet> {
  SportType? _selectedSport;
  TournamentType? _selectedType;
  TournamentStatus? _selectedStatus;
  String? _selectedLocation;
  final TextEditingController _locationController = TextEditingController();

  // Common locations for quick selection
  final List<String> _popularLocations = [
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Phoenix',
    'Philadelphia',
    'San Antonio',
    'San Diego',
    'Dallas',
    'San Jose',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.selectedSport;
    _selectedType = widget.selectedType;
    _selectedStatus = widget.selectedStatus;
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
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSportFilter(),
                  Gap(24.h),
                  _buildTournamentTypeFilter(),
                  Gap(24.h),
                  _buildStatusFilter(),
                  Gap(24.h),
                  _buildLocationFilter(),
                  Gap(32.h),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filter Tournaments',
            style: TextStyles.font18DarkBlue600Weight.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSportFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sport Type',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildSportChip(null, 'All Sports'),
            ...SportType.values
                .map((sport) => _buildSportChip(sport, sport.displayName)),
          ],
        ),
      ],
    );
  }

  Widget _buildSportChip(SportType? sport, String label) {
    final isSelected = _selectedSport == sport;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[300],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSport = selected ? sport : null;
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: ColorsManager.mainBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? ColorsManager.mainBlue : Colors.grey[600]!,
      ),
    );
  }

  Widget _buildTournamentTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Type',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildTypeChip(null, 'All Types'),
            ...TournamentType.values
                .map((type) => _buildTypeChip(type, type.displayName)),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(TournamentType? type, String label) {
    final isSelected = _selectedType == type;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[300],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: ColorsManager.mainBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? ColorsManager.mainBlue : Colors.grey[600]!,
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildStatusChip(null, 'All Status'),
            ...TournamentStatus.values
                .map((status) => _buildStatusChip(status, status.displayName)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(TournamentStatus? status, String label) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[300],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: ColorsManager.mainBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? ColorsManager.mainBlue : Colors.grey[600]!,
      ),
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        TextField(
          controller: _locationController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter location',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(
              Icons.location_on,
              color: Colors.grey[400],
            ),
            suffixIcon: _locationController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _locationController.clear();
                      setState(() {
                        _selectedLocation = null;
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[400],
                    ),
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _selectedLocation = value.isNotEmpty ? value : null;
            });
          },
        ),
        Gap(16.h),
        Text(
          'Popular Locations',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: Colors.grey[400],
          ),
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _popularLocations
              .map((location) => _buildLocationChip(location))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLocationChip(String location) {
    final isSelected = _selectedLocation == location;

    return FilterChip(
      label: Text(
        location,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[300],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedLocation = location;
            _locationController.text = location;
          } else {
            _selectedLocation = null;
            _locationController.clear();
          }
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: ColorsManager.mainBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? ColorsManager.mainBlue : Colors.grey[600]!,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.grey),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ),
        Gap(16.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.mainBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('Apply Filters'),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedSport = null;
      _selectedType = null;
      _selectedStatus = null;
      _selectedLocation = null;
      _locationController.clear();
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(
        _selectedSport, _selectedType, _selectedStatus, _selectedLocation);
    Navigator.pop(context);
  }
}
