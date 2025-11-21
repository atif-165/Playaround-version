import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/booking_model.dart';
import '../../../models/listing_model.dart';

/// Widget for filtering booking history
class BookingFilterWidget extends StatefulWidget {
  final BookingStatus? selectedStatus;
  final SportType? selectedSport;
  final DateTimeRange? selectedDateRange;
  final Function(BookingStatus?) onStatusChanged;
  final Function(SportType?) onSportChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final VoidCallback onClearFilters;

  const BookingFilterWidget({
    super.key,
    this.selectedStatus,
    this.selectedSport,
    this.selectedDateRange,
    required this.onStatusChanged,
    required this.onSportChanged,
    required this.onDateRangeChanged,
    required this.onClearFilters,
  });

  @override
  State<BookingFilterWidget> createState() => _BookingFilterWidgetState();
}

class _BookingFilterWidgetState extends State<BookingFilterWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Gap(20.h),
          _buildStatusFilter(),
          Gap(20.h),
          _buildSportFilter(),
          Gap(20.h),
          _buildDateRangeFilter(),
          Gap(24.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Filter Bookings',
          style: TextStyles.font18DarkBlueBold,
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: ColorsManager.gray,
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyles.font14DarkBlueBold,
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildFilterChip(
              label: 'All',
              isSelected: widget.selectedStatus == null,
              onTap: () => widget.onStatusChanged(null),
            ),
            ...BookingStatus.values.map((status) => _buildFilterChip(
                  label: status.displayName,
                  isSelected: widget.selectedStatus == status,
                  onTap: () => widget.onStatusChanged(status),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildSportFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sport',
          style: TextStyles.font14DarkBlueBold,
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildFilterChip(
              label: 'All Sports',
              isSelected: widget.selectedSport == null,
              onTap: () => widget.onSportChanged(null),
            ),
            ...SportType.values.map((sport) => _buildFilterChip(
                  label: sport.displayName,
                  isSelected: widget.selectedSport == sport,
                  onTap: () => widget.onSportChanged(sport),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: TextStyles.font14DarkBlueBold,
        ),
        Gap(8.h),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(color: ColorsManager.gray76),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: ColorsManager.mainBlue,
                  size: 20.w,
                ),
                Gap(8.w),
                Expanded(
                  child: Text(
                    widget.selectedDateRange != null
                        ? '${_formatDate(widget.selectedDateRange!.start)} - ${_formatDate(widget.selectedDateRange!.end)}'
                        : 'Select date range',
                    style: widget.selectedDateRange != null
                        ? TextStyles.font14DarkBlue500Weight
                        : TextStyles.font14Grey400Weight,
                  ),
                ),
                if (widget.selectedDateRange != null)
                  GestureDetector(
                    onTap: () => widget.onDateRangeChanged(null),
                    child: Icon(
                      Icons.clear,
                      color: ColorsManager.gray,
                      size: 20.w,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? ColorsManager.mainBlue : Colors.transparent,
          border: Border.all(
            color: isSelected ? ColorsManager.mainBlue : ColorsManager.gray76,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: isSelected
              ? TextStyles.font12WhiteMedium
              : TextStyles.font12Grey400Weight,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClearFilters,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ColorsManager.mainBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Clear All',
              style: TextStyles.font14BlueRegular,
            ),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.mainBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Apply Filters',
              style: TextStyles.font14White500Weight,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: widget.selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: ColorsManager.mainBlue,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onDateRangeChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
