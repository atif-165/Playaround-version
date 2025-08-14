import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../models/venue_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

import '../widgets/venue_image_carousel.dart';
import '../widgets/venue_booking_calendar.dart';
import '../widgets/venue_reviews_section.dart';
import '../widgets/venue_amenities_display.dart';
import 'edit_venue_screen.dart';

/// Screen displaying detailed venue information
class VenueDetailScreen extends StatefulWidget {
  final VenueModel venue;

  const VenueDetailScreen({
    super.key,
    required this.venue,
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  bool get _isOwner {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == widget.venue.ownerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVenueInfo(),
                _buildDivider(),
                _buildDescription(),
                _buildDivider(),
                _buildAmenities(),
                _buildDivider(),
                _buildAvailability(),
                _buildDivider(),
                _buildReviews(),
                Gap(100.h), // Space for floating action button
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildBookNowButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.h,
      pinned: true,
      backgroundColor: ColorsManager.neonBlue,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: VenueImageCarousel(
          images: widget.venue.images,
          height: 250.h,
        ),
      ),
      actions: [
        if (_isOwner) ...[
          Container(
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _editVenue,
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit Venue',
            ),
          ),
        ],
        Container(
          margin: EdgeInsets.only(right: 16.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _shareVenue,
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueInfo() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.venue.title,
                      style: TextStyles.font20DarkBlueBold,
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 16.sp,
                          color: ColorsManager.mainBlue,
                        ),
                        Gap(4.w),
                        Text(
                          widget.venue.sportType.displayName,
                          style: TextStyles.font14MainBlue500Weight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildRatingSection(),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16.sp,
                color: Colors.grey[600],
              ),
              Gap(4.w),
              Expanded(
                child: Text(
                  widget.venue.location,
                  style: TextStyles.font14Grey400Weight,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Icon(
                Icons.currency_rupee,
                size: 16.sp,
                color: Colors.green[700],
              ),
              Gap(4.w),
              Text(
                '₹${widget.venue.hourlyRate.toStringAsFixed(0)}/hour',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${widget.venue.totalBookings} bookings',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    if (widget.venue.totalReviews == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          'New Venue',
          style: TextStyles.font12Grey400Weight,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 16.sp,
            color: Colors.amber,
          ),
          Gap(4.w),
          Text(
            widget.venue.averageRating.toStringAsFixed(1),
            style: TextStyles.font14DarkBlueBold,
          ),
          Gap(4.w),
          Text(
            '(${widget.venue.totalReviews})',
            style: TextStyles.font12Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(8.h),
          Text(
            widget.venue.description,
            style: TextStyles.font14Grey400Weight,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    if (widget.venue.amenities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(12.h),
          VenueAmenitiesDisplay(amenities: widget.venue.amenities),
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(12.h),
          _buildAvailableDays(),
          Gap(12.h),
          _buildTimeSlots(),
        ],
      ),
    );
  }

  Widget _buildAvailableDays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Days',
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.venue.availableDays.map((day) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: ColorsManager.mainBlue.withValues(alpha: 0.3)),
              ),
              child: Text(
                day,
                style: TextStyles.font12MainBlue500Weight,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Slots',
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.venue.availableTimeSlots.map((slot) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${slot.start} - ${slot.end}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return VenueReviewsSection(
      venueId: widget.venue.id,
      venue: widget.venue,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8.h,
      color: Colors.grey[100],
    );
  }

  Widget _buildBookNowButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ElevatedButton(
        onPressed: _showBookingCalendar,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 20.sp,
            ),
            Gap(8.w),
            Text(
              'Book Now',
              style: TextStyles.font16White600Weight,
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingCalendar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VenueBookingCalendar(
        venue: widget.venue,
        onBookingConfirmed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _shareVenue() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
      ),
    );
  }

  void _editVenue() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVenueScreen(venue: widget.venue),
      ),
    );

    // If venue was updated, refresh the screen
    if (result == true && mounted) {
      // In a real app, you might want to refresh the venue data
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venue updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
