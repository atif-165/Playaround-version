import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

class ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final int selectedIndex;
  final Function(int) onImageSelected;

  const ProductImageGallery({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onImageSelected,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildPlaceholder();
    }

    return Column(
      children: [
        _buildMainImage(),
        if (widget.images.length > 1) ...[
          Gap(16.h),
          _buildThumbnailList(),
        ],
      ],
    );
  }

  Widget _buildMainImage() {
    return Container(
      height: 300.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: widget.onImageSelected,
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return Image.network(
              widget.images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnailList() {
    return SizedBox(
      height: 80.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final isSelected = index == widget.selectedIndex;
          
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 80.w,
              height: 80.h,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: ColorsManager.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? ColorsManager.primary : ColorsManager.outline,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image,
                      color: ColorsManager.onSurfaceVariant,
                      size: 32.w,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 300.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorsManager.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports,
            size: 80.w,
            color: ColorsManager.onSurfaceVariant,
          ),
          Gap(16.h),
          Text(
            'No Image Available',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
