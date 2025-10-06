import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

class ProductSpecifications extends StatelessWidget {
  final Map<String, dynamic> specifications;

  const ProductSpecifications({
    super.key,
    required this.specifications,
  });

  @override
  Widget build(BuildContext context) {
    if (specifications.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(16.h),
          ...specifications.entries.map((entry) => _buildSpecificationItem(
                entry.key,
                entry.value,
              )),
        ],
      ),
    );
  }

  Widget _buildSpecificationItem(String key, dynamic value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatKey(key),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ),
          Gap(16.w),
          Expanded(
            flex: 3,
            child: Text(
              _formatValue(value),
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48.w,
            color: ColorsManager.onSurfaceVariant,
          ),
          Gap(16.h),
          Text(
            'No specifications available',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          Gap(8.h),
          Text(
            'Specifications will be added soon',
            style: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    // Convert camelCase or snake_case to readable format
    return key
        .replaceAll(RegExp(r'([A-Z])'), ' \$1')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Not specified';
    
    if (value is List) {
      return value.join(', ');
    }
    
    if (value is Map) {
      return value.entries
          .map((e) => '${_formatKey(e.key)}: ${e.value}')
          .join(', ');
    }
    
    return value.toString();
  }
}
