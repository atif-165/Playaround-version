import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../services/cloudinary_service.dart';

/// Widget for uploading venue images
class ImageUploadSection extends StatefulWidget {
  final List<String> images;
  final Function(List<String>) onImagesChanged;
  final int maxImages;

  const ImageUploadSection({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 5,
  });

  @override
  State<ImageUploadSection> createState() => _ImageUploadSectionState();
}

class _ImageUploadSectionState extends State<ImageUploadSection> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageGrid(),
        if (widget.images.length < widget.maxImages) ...[
          Gap(16.h),
          _buildAddImageButton(),
        ],
        if (_isUploading) ...[
          Gap(16.h),
          _buildUploadingIndicator(),
        ],
      ],
    );
  }

  Widget _buildImageGrid() {
    if (widget.images.isEmpty) {
      return Container(
        height: 120.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 32.sp,
              color: Colors.grey[400],
            ),
            Gap(8.h),
            Text(
              'No images added yet',
              style: TextStyles.font12Grey400Weight,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1,
      ),
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        return _buildImageItem(widget.images[index], index);
      },
    );
  }

  Widget _buildImageItem(String imageUrl, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.grey[400],
                      size: 24.sp,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorsManager.mainBlue,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 4.h,
            right: 4.w,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 12.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _showImageSourceDialog,
      child: Container(
        height: 50.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorsManager.mainBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: ColorsManager.mainBlue.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: ColorsManager.mainBlue,
              size: 20.sp,
            ),
            Gap(8.w),
            Text(
              'Add Image (${widget.images.length}/${widget.maxImages})',
              style: TextStyles.font14MainBlue500Weight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: ColorsManager.mainBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 16.h,
            width: 16.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.mainBlue),
            ),
          ),
          Gap(12.w),
          Text(
            'Uploading image...',
            style: TextStyles.font12MainBlue500Weight,
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(20.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: ColorsManager.mainBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 32.sp,
                            color: ColorsManager.mainBlue,
                          ),
                          Gap(8.h),
                          Text(
                            'Camera',
                            style: TextStyles.font14MainBlue500Weight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Gap(16.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: ColorsManager.mainBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 32.sp,
                            color: ColorsManager.mainBlue,
                          ),
                          Gap(8.h),
                          Text(
                            'Gallery',
                            style: TextStyles.font14MainBlue500Weight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Gap(20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        final imageUrl = await _cloudinaryService.uploadImage(
          File(image.path),
          folder: 'venues',
        );

        final updatedImages = List<String>.from(widget.images)..add(imageUrl);
        widget.onImagesChanged(updatedImages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    final updatedImages = List<String>.from(widget.images)..removeAt(index);
    widget.onImagesChanged(updatedImages);
  }
}
