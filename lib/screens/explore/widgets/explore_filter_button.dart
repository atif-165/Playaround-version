import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theming/colors.dart';
import 'filter_bottom_sheet.dart';
import '../../../modules/team/widgets/team_filter_sheet.dart';

/// Filter button widget for explore screen
class ExploreFilterButton extends StatelessWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final Map<String, dynamic> currentFilters;
  final int currentTabIndex;

  const ExploreFilterButton({
    super.key,
    required this.onFiltersChanged,
    required this.currentFilters,
    required this.currentTabIndex,
  });

  bool get hasActiveFilters {
    return currentFilters.isNotEmpty &&
        currentFilters.values.any((value) {
          if (value is List) return value.isNotEmpty;
          if (value is String) return value.isNotEmpty;
          if (value is num) return value > 0;
          return value != null;
        });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFilterBottomSheet(context),
      child: Container(
        width: 48.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: hasActiveFilters ? ColorsManager.mainBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: hasActiveFilters ? ColorsManager.mainBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.tune,
                color: hasActiveFilters ? Colors.white : Colors.grey[600],
                size: 20.sp,
              ),
            ),
            if (hasActiveFilters)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Show team filter for teams tab (index 1)
        if (currentTabIndex == 1) {
          return TeamFilterSheet(
            currentFilters: currentFilters,
            onFiltersApplied: onFiltersChanged,
          );
        }
        // Default filter for other tabs
        return FilterBottomSheet(
          currentFilters: currentFilters,
          onFiltersChanged: onFiltersChanged,
        );
      },
    );
  }
}
