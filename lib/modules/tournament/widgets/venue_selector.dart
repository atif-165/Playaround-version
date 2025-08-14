import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicator.dart';
import '../../../models/venue_model.dart';
import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../venue/services/venue_service.dart';

/// Widget for selecting a venue for tournament
class VenueSelector extends StatefulWidget {
  final VenueModel? selectedVenue;
  final SportType? sportType;
  final Function(VenueModel?) onVenueSelected;

  const VenueSelector({
    super.key,
    this.selectedVenue,
    this.sportType,
    required this.onVenueSelected,
  });

  @override
  State<VenueSelector> createState() => _VenueSelectorState();
}

class _VenueSelectorState extends State<VenueSelector> {
  final VenueService _venueService = VenueService();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Select Venue',
              style: TextStyles.font14DarkBlue600Weight,
            ),
            Text(
              ' *',
              style: TextStyles.font14DarkBlue600Weight.copyWith(color: Colors.red),
            ),
          ],
        ),
        Gap(8.h),
        Text(
          'Choose a venue where the tournament will be held',
          style: TextStyles.font12Grey400Weight,
        ),
        Gap(12.h),
        _buildVenueSelection(),
      ],
    );
  }

  Widget _buildVenueSelection() {
    if (widget.selectedVenue != null) {
      return _buildSelectedVenue();
    }

    return _buildVenueSelector();
  }

  Widget _buildSelectedVenue() {
    final venue = widget.selectedVenue!;
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ColorsManager.mainBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.grey[200],
            ),
            child: venue.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      venue.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildVenuePlaceholder();
                      },
                    ),
                  )
                : _buildVenuePlaceholder(),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.title,
                  style: TextStyles.font14DarkBlueBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(4.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12.sp,
                      color: Colors.grey[600],
                    ),
                    Gap(2.w),
                    Expanded(
                      child: Text(
                        venue.location,
                        style: TextStyles.font10Grey400Weight,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Gap(4.h),
                Text(
                  '₹${venue.hourlyRate.toStringAsFixed(0)}/hour',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          Gap(8.w),
          Column(
            children: [
              GestureDetector(
                onTap: () => widget.onVenueSelected(null),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16.sp,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVenueSelector() {
    return GestureDetector(
      onTap: _showVenueSelectionDialog,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 24.sp,
              color: Colors.grey[600],
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Venue',
                    style: TextStyles.font14DarkBlue600Weight,
                  ),
                  Gap(2.h),
                  Text(
                    'Tap to choose from available venues',
                    style: TextStyles.font12Grey400Weight,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenuePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Icon(
          Icons.location_city,
          size: 24.sp,
          color: ColorsManager.mainBlue.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  void _showVenueSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Select Venue',
                    style: TextStyles.font18DarkBlueBold,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              Gap(16.h),
              Expanded(
                child: StreamBuilder<List<VenueModel>>(
                  stream: _venueService.getVenues(
                    sportType: widget.sportType,
                    limit: 50,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CustomProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48.sp,
                              color: Colors.grey[400],
                            ),
                            Gap(16.h),
                            Text(
                              'Error loading venues',
                              style: TextStyles.font16Grey400Weight,
                            ),
                          ],
                        ),
                      );
                    }

                    final venues = snapshot.data ?? [];

                    if (venues.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_city_outlined,
                              size: 64.sp,
                              color: Colors.grey[400],
                            ),
                            Gap(16.h),
                            Text(
                              'No venues available',
                              style: TextStyles.font16DarkBlue600Weight,
                            ),
                            Gap(8.h),
                            Text(
                              widget.sportType != null
                                  ? 'No venues found for ${widget.sportType!.displayName}'
                                  : 'No venues found',
                              style: TextStyles.font12Grey400Weight,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: venues.length,
                      itemBuilder: (context, index) {
                        final venue = venues[index];
                        return _buildVenueListItem(venue);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueListItem(VenueModel venue) {
    return GestureDetector(
      onTap: () {
        widget.onVenueSelected(venue);
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.r),
                color: Colors.grey[200],
              ),
              child: venue.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Image.network(
                        venue.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildVenuePlaceholder();
                        },
                      ),
                    )
                  : _buildVenuePlaceholder(),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.title,
                    style: TextStyles.font14DarkBlueBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12.sp,
                        color: Colors.grey[600],
                      ),
                      Gap(2.w),
                      Expanded(
                        child: Text(
                          venue.location,
                          style: TextStyles.font10Grey400Weight,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Gap(4.h),
                  Row(
                    children: [
                      Text(
                        '₹${venue.hourlyRate.toStringAsFixed(0)}/hour',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                      const Spacer(),
                      if (venue.averageRating > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 10.sp,
                              color: Colors.amber,
                            ),
                            Gap(2.w),
                            Text(
                              venue.averageRating.toStringAsFixed(1),
                              style: TextStyles.font10DarkBlue600Weight,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
