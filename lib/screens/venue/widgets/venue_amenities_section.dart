import 'package:flutter/material.dart';
import '../../../models/venue.dart';

class VenueAmenitiesSection extends StatelessWidget {
  final List<VenueAmenity> amenities;

  const VenueAmenitiesSection({
    Key? key,
    required this.amenities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: amenities.length,
          itemBuilder: (context, index) {
            final amenity = amenities[index];
            return _buildAmenityItem(context, amenity);
          },
        ),
      ],
    );
  }

  Widget _buildAmenityItem(BuildContext context, VenueAmenity amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: amenity.isAvailable
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: amenity.isAvailable
              ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getAmenityIcon(amenity.icon),
            color: amenity.isAvailable
                ? Theme.of(context).primaryColor
                : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  amenity.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: amenity.isAvailable ? null : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (amenity.description.isNotEmpty)
                  Text(
                    amenity.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: amenity.isAvailable ? Colors.grey[600] : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(
            amenity.isAvailable ? Icons.check_circle : Icons.cancel,
            color: amenity.isAvailable ? Colors.green : Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'parking':
        return Icons.local_parking;
      case 'wifi':
        return Icons.wifi;
      case 'air_conditioning':
        return Icons.ac_unit;
      case 'changing_rooms':
        return Icons.change_circle;
      case 'lighting':
        return Icons.lightbulb;
      case 'shower':
        return Icons.shower;
      case 'locker':
        return Icons.lock;
      case 'cafeteria':
        return Icons.restaurant;
      case 'first_aid':
        return Icons.medical_services;
      case 'equipment':
        return Icons.sports;
      case 'water':
        return Icons.water_drop;
      case 'security':
        return Icons.security;
      case 'accessibility':
        return Icons.accessibility;
      case 'wifi':
        return Icons.wifi;
      default:
        return Icons.check_circle;
    }
  }
}
