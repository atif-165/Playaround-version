import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/material3/material3_components.dart';

class SearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function(String) onFilterChanged;
  final String selectedFilter;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.selectedFilter,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'All', 'icon': Icons.grid_view},
    {'key': 'featured', 'label': 'Featured', 'icon': Icons.star},
    {'key': 'exclusive', 'label': 'Exclusive', 'icon': Icons.diamond},
    {'key': 'sale', 'label': 'On Sale', 'icon': Icons.local_offer},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        Gap(12.h),
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildSearchField() {
    return AppSearchField(
      controller: widget.searchController,
      hintText: 'Search sports equipment, brands, shops...',
      onChanged: widget.onSearchChanged,
      onClear: () => widget.onSearchChanged(''),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = widget.selectedFilter == filter['key'];

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: AppChip(
              label: filter['label'],
              variant: ChipVariant.filter,
              selected: isSelected,
              onPressed: () => widget.onFilterChanged(filter['key']),
            ),
          );
        },
      ),
    );
  }
}
