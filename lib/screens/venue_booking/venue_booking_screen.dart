import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../core/widgets/app_text_button.dart';

/// Screen for booking sports venues
class VenueBookingScreen extends StatefulWidget {
  const VenueBookingScreen({super.key});

  @override
  State<VenueBookingScreen> createState() => _VenueBookingScreenState();
}

class _VenueBookingScreenState extends State<VenueBookingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Book Venue',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: ColorsManager.onSurface,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          Gap(32.h),
          _buildSearchSection(),
          Gap(24.h),
          _buildFilterSection(),
          Gap(32.h),
          _buildVenuesList(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: ColorsManager.primary,
                size: 24.sp,
              ),
              Gap(8.w),
              Text(
                'Find & Book Venues',
                style: TextStyles.font18DarkBlue600Weight,
              ),
            ],
          ),
          Gap(8.h),
          Text(
            'Discover and book sports venues near you for training, matches, and events.',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Venues',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by venue name or location...',
            prefixIcon: Icon(
              Icons.search,
              color: ColorsManager.outline,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.outline,
                width: 1.w,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.outline,
                width: 1.w,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.primary,
                width: 2.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildFilterChip('Football', Icons.sports_soccer),
            _buildFilterChip('Basketball', Icons.sports_basketball),
            _buildFilterChip('Tennis', Icons.sports_tennis),
            _buildFilterChip('Swimming', Icons.pool),
            _buildFilterChip('Gym', Icons.fitness_center),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp),
          Gap(4.w),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        // TODO: Implement filter logic
      },
      backgroundColor: ColorsManager.surface,
      selectedColor: ColorsManager.primary.withValues(alpha: 0.2),
      checkmarkColor: ColorsManager.primary,
      side: BorderSide(
        color: ColorsManager.outline,
        width: 1.w,
      ),
    );
  }

  Widget _buildVenuesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Venues',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            TextButton(
              onPressed: () {
                // Navigate to venues screen from main navigation
                Navigator.pushReplacementNamed(context, '/dashboardScreen');
                // TODO: Switch to venues tab
              },
              child: Text(
                'View All',
                style: TextStyles.font16Blue600Weight,
              ),
            ),
          ],
        ),
        Gap(16.h),
        _buildComingSoonCard(),
      ],
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction,
            size: 48.sp,
            color: ColorsManager.primary,
          ),
          Gap(16.h),
          Text(
            'Venue Booking Coming Soon!',
            style: TextStyles.font18DarkBlue600Weight,
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Text(
            'We\'re working hard to bring you the best venue booking experience. Stay tuned!',
            style: TextStyles.font14Grey400Weight,
            textAlign: TextAlign.center,
          ),
          Gap(20.h),
          AppTextButton(
            buttonText: 'Browse Existing Venues',
            textStyle: TextStyles.font16White600Weight,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/dashboardScreen');
              // TODO: Switch to venues tab programmatically
            },
            backgroundColor: ColorsManager.primary,
          ),
        ],
      ),
    );
  }
}
