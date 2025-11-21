import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_form_field.dart';
import '../../../models/venue_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/coach_associations_service.dart';

/// Dialog for searching and selecting venues to add to coach profile
class VenueSearchDialog extends StatefulWidget {
  final String coachId;
  final String coachName;

  const VenueSearchDialog({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  State<VenueSearchDialog> createState() => _VenueSearchDialogState();
}

class _VenueSearchDialogState extends State<VenueSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final CoachAssociationsService _associationsService =
      CoachAssociationsService();

  List<VenueModel> _venues = [];
  bool _isLoading = false;
  bool _isRequesting = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    
    if (value.trim().length < 2) {
      setState(() {
        _venues = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchVenues();
    });
  }

  Future<void> _searchVenues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final venues =
          await _associationsService.searchVenues(_searchController.text);
      if (mounted) {
        setState(() {
          _venues = venues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching venues: $e')),
        );
      }
    }
  }

  Future<void> _requestVenueAssociation(VenueModel venue) async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final success = await _associationsService.requestVenueAssociation(
        widget.coachId,
        widget.coachName,
        venue,
      );

      if (mounted) {
        setState(() {
          _isRequesting = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request sent to ${venue.ownerName}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send request or venue already added'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.maxFinite,
        height: 600.h,
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Gap(16.h),
            _buildSearchField(),
            Gap(16.h),
            Expanded(child: _buildVenuesList()),
            Gap(16.h),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.add_location,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
        Gap(8.w),
        Expanded(
          child: Text(
            'Add Venue',
            style: TextStyles.font18DarkBlueBold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      autofocus: true,
      onChanged: _onSearchChanged,
      style: TextStyles.font14DarkBlue500Weight,
      decoration: InputDecoration(
        hintText: 'Search venues by name or location...',
        hintStyle: TextStyles.font14Hint500Weight,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isLoading
            ? Padding(
                padding: EdgeInsets.all(12.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _venues = [];
                      });
                    },
                  )
                : null,
        filled: true,
        fillColor: ColorsManager.lightShadeOfGray,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.gray93Color,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.mainBlue,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildVenuesList() {
    if (_searchController.text.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 48.sp,
              color: Colors.grey,
            ),
            Gap(16.h),
            Text(
              'Type at least 2 characters to search',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_venues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48.sp,
              color: Colors.grey,
            ),
            Gap(16.h),
            Text(
              'No venues found',
              style: TextStyles.font14Grey400Weight,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _venues.length,
      itemBuilder: (context, index) {
        final venue = _venues[index];
        return _buildVenueCard(venue);
      },
    );
  }

  Widget _buildVenueCard(VenueModel venue) {
    final isRequesting = _isRequesting;
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: isRequesting ? null : () => _requestVenueAssociation(venue),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: ColorsManager.primary.withAlpha(51),
                radius: 28.r,
                child: Icon(
                  Icons.location_on,
                  color: ColorsManager.primary,
                  size: 24.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.title,
                      style: TextStyles.font16DarkBlue500Weight,
                    ),
                    Gap(4.h),
                    Text(
                      venue.location,
                      style: TextStyles.font12Grey400Weight,
                    ),
                    Gap(2.h),
                    Text(
                      'Owner: ${venue.ownerName}',
                      style: TextStyles.font12Grey400Weight,
                    ),
                    Gap(2.h),
                    Text(
                      '\$${venue.hourlyRate.toStringAsFixed(2)}/hour',
                      style: TextStyles.font12Grey400Weight,
                    ),
                  ],
                ),
              ),
              Gap(8.w),
              ElevatedButton(
                onPressed: isRequesting ? null : () => _requestVenueAssociation(venue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(90.w, 36.h),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                child: isRequesting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
