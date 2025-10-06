import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../models/sports_categories.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool isGridItem;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onPressed,
    this.isGridItem = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridItem) {
      return _buildGridItem();
    }
    return _buildChip();
  }

  Widget _buildChip() {
    return AppChip(
      label: category,
      variant: ChipVariant.filter,
      selected: isSelected,
      onPressed: onPressed,
    );
  }

  Widget _buildGridItem() {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? ColorsManager.primary : ColorsManager.surfaceVariant,
          borderRadius: BorderRadius.circular(16.r),
          border: isSelected
              ? Border.all(color: ColorsManager.primary, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorsManager.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SportsCategories.getCategoryIcon(category),
              size: 32.w,
              color: isSelected
                  ? ColorsManager.onPrimary
                  : ColorsManager.onSurfaceVariant,
            ),
            Gap(8.h),
            Text(
              category,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? ColorsManager.onPrimary
                    : ColorsManager.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
