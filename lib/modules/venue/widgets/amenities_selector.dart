import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget for selecting venue amenities
class AmenitiesSelector extends StatefulWidget {
  final List<String> selectedAmenities;
  final Function(List<String>) onAmenitiesChanged;

  const AmenitiesSelector({
    super.key,
    required this.selectedAmenities,
    required this.onAmenitiesChanged,
  });

  @override
  State<AmenitiesSelector> createState() => _AmenitiesSelectorState();
}

class _AmenitiesSelectorState extends State<AmenitiesSelector> {
  final List<AmenityItem> _availableAmenities = [
    const AmenityItem(
      name: 'Parking',
      icon: Icons.local_parking,
      description: 'Free parking available',
    ),
    const AmenityItem(
      name: 'Changing Rooms',
      icon: Icons.meeting_room,
      description: 'Separate changing facilities',
    ),
    const AmenityItem(
      name: 'Restrooms',
      icon: Icons.wc,
      description: 'Clean restroom facilities',
    ),
    const AmenityItem(
      name: 'Equipment Rental',
      icon: Icons.sports_soccer,
      description: 'Sports equipment available for rent',
    ),
    const AmenityItem(
      name: 'Refreshments',
      icon: Icons.local_cafe,
      description: 'Food and drinks available',
    ),
    const AmenityItem(
      name: 'First Aid',
      icon: Icons.medical_services,
      description: 'First aid kit and trained staff',
    ),
    const AmenityItem(
      name: 'Lighting',
      icon: Icons.lightbulb,
      description: 'Floodlights for evening play',
    ),
    const AmenityItem(
      name: 'Seating',
      icon: Icons.event_seat,
      description: 'Spectator seating available',
    ),
    const AmenityItem(
      name: 'Wi-Fi',
      icon: Icons.wifi,
      description: 'Free wireless internet',
    ),
    const AmenityItem(
      name: 'Air Conditioning',
      icon: Icons.ac_unit,
      description: 'Climate controlled environment',
    ),
    const AmenityItem(
      name: 'Lockers',
      icon: Icons.lock,
      description: 'Secure storage lockers',
    ),
    const AmenityItem(
      name: 'Shower',
      icon: Icons.shower,
      description: 'Hot water shower facilities',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmenitiesGrid(),
        if (widget.selectedAmenities.isNotEmpty) ...[
          Gap(16.h),
          _buildSelectedAmenities(),
        ],
      ],
    );
  }

  Widget _buildAmenitiesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 3.5,
      ),
      itemCount: _availableAmenities.length,
      itemBuilder: (context, index) {
        final amenity = _availableAmenities[index];
        final isSelected = widget.selectedAmenities.contains(amenity.name);
        
        return GestureDetector(
          onTap: () => _toggleAmenity(amenity.name),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? ColorsManager.mainBlue.withValues(alpha: 0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isSelected ? ColorsManager.mainBlue : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  amenity.icon,
                  size: 16.sp,
                  color: isSelected ? ColorsManager.mainBlue : Colors.grey[600],
                ),
                Gap(8.w),
                Expanded(
                  child: Text(
                    amenity.name,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? ColorsManager.mainBlue : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 14.sp,
                    color: ColorsManager.mainBlue,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Amenities (${widget.selectedAmenities.length})',
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: ColorsManager.mainBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: ColorsManager.mainBlue.withValues(alpha: 0.2)),
          ),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: widget.selectedAmenities.map((amenityName) {
              final amenity = _availableAmenities.firstWhere(
                (a) => a.name == amenityName,
                orElse: () => AmenityItem(
                  name: amenityName,
                  icon: Icons.check,
                  description: '',
                ),
              );
              
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      amenity.icon,
                      size: 12.sp,
                      color: Colors.white,
                    ),
                    Gap(4.w),
                    Text(
                      amenity.name,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Gap(4.w),
                    GestureDetector(
                      onTap: () => _toggleAmenity(amenity.name),
                      child: Icon(
                        Icons.close,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _toggleAmenity(String amenityName) {
    final currentAmenities = List<String>.from(widget.selectedAmenities);
    
    if (currentAmenities.contains(amenityName)) {
      currentAmenities.remove(amenityName);
    } else {
      currentAmenities.add(amenityName);
    }
    
    widget.onAmenitiesChanged(currentAmenities);
  }
}

/// Model for amenity items
class AmenityItem {
  final String name;
  final IconData icon;
  final String description;

  const AmenityItem({
    required this.name,
    required this.icon,
    required this.description,
  });
}
