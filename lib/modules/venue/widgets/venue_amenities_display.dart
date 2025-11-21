import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget for displaying venue amenities
class VenueAmenitiesDisplay extends StatelessWidget {
  final List<String> amenities;

  const VenueAmenitiesDisplay({
    super.key,
    required this.amenities,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16.sp,
              color: Colors.grey[600],
            ),
            Gap(8.w),
            Text(
              'No amenities listed',
              style: TextStyles.font12Grey400Weight,
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: amenities.map((amenity) {
        final amenityInfo = _getAmenityInfo(amenity);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ColorsManager.mainBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: ColorsManager.mainBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                amenityInfo.icon,
                size: 14.sp,
                color: ColorsManager.mainBlue,
              ),
              Gap(6.w),
              Text(
                amenity,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: ColorsManager.mainBlue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  AmenityInfo _getAmenityInfo(String amenityName) {
    switch (amenityName.toLowerCase()) {
      case 'parking':
        return const AmenityInfo(Icons.local_parking, 'Free parking available');
      case 'changing rooms':
        return const AmenityInfo(
            Icons.meeting_room, 'Separate changing facilities');
      case 'restrooms':
        return const AmenityInfo(Icons.wc, 'Clean restroom facilities');
      case 'equipment rental':
        return const AmenityInfo(
            Icons.sports_soccer, 'Sports equipment available for rent');
      case 'refreshments':
        return const AmenityInfo(Icons.local_cafe, 'Food and drinks available');
      case 'first aid':
        return const AmenityInfo(
            Icons.medical_services, 'First aid kit and trained staff');
      case 'lighting':
        return const AmenityInfo(
            Icons.lightbulb, 'Floodlights for evening play');
      case 'seating':
        return const AmenityInfo(
            Icons.event_seat, 'Spectator seating available');
      case 'wi-fi':
        return const AmenityInfo(Icons.wifi, 'Free wireless internet');
      case 'air conditioning':
        return const AmenityInfo(
            Icons.ac_unit, 'Climate controlled environment');
      case 'lockers':
        return const AmenityInfo(Icons.lock, 'Secure storage lockers');
      case 'shower':
        return const AmenityInfo(Icons.shower, 'Hot water shower facilities');
      default:
        return AmenityInfo(Icons.check_circle, amenityName);
    }
  }
}

/// Model for amenity information
class AmenityInfo {
  final IconData icon;
  final String description;

  const AmenityInfo(this.icon, this.description);
}
