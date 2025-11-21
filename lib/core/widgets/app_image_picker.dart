import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/cloudinary_config.dart';
import '../../services/cloudinary_service.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';

/// Image picker widget for profile pictures
class AppImagePicker extends StatefulWidget {
  final String label;
  final String? imageUrl;
  final File? imageFile;
  final Function(File?) onImageSelected;
  final bool isRequired;
  final bool isLoading;

  const AppImagePicker({
    super.key,
    required this.label,
    this.imageUrl,
    this.imageFile,
    required this.onImageSelected,
    this.isRequired = false,
    this.isLoading = false,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();
}

class _AppImagePickerState extends State<AppImagePicker> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyles.font14DarkBlue500Weight,
            ),
            if (widget.isRequired) ...[
              Gap(4.w),
              Text(
                '*',
                style: TextStyles.font14DarkBlue500Weight.copyWith(
                  color: ColorsManager.coralRed,
                ),
              ),
            ],
          ],
        ),
        Gap(8.h),

        // Image display and picker
        Center(
          child: GestureDetector(
            onTap: widget.isLoading ? null : _showImageSourceDialog,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: ColorsManager.lightShadeOfGray,
                borderRadius: BorderRadius.circular(60.w),
                border: Border.all(
                  color: ColorsManager.gray93Color,
                  width: 2.w,
                ),
              ),
              child: widget.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: ColorsManager.mainBlue,
                        strokeWidth: 2.w,
                      ),
                    )
                  : _buildImageContent(),
            ),
          ),
        ),

        Gap(8.h),

        // Helper text
        Center(
          child: Text(
            widget.imageFile != null || widget.imageUrl != null
                ? 'Tap to change photo'
                : 'Tap to add photo',
            style: TextStyles.font12Grey400Weight,
          ),
        ),

        // Remove image button
        if ((widget.imageFile != null || widget.imageUrl != null) &&
            !widget.isLoading) ...[
          Gap(8.h),
          Center(
            child: TextButton(
              onPressed: () => widget.onImageSelected(null),
              child: Text(
                'Remove Photo',
                style: TextStyles.font12Grey400Weight.copyWith(
                  color: ColorsManager.coralRed,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    // Show selected file
    if (widget.imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(58.w),
        child: Image.file(
          widget.imageFile!,
          width: 116.w,
          height: 116.w,
          fit: BoxFit.cover,
        ),
      );
    }

    // Show network image
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      // Use Cloudinary optimized thumbnail for better performance
      final optimizedUrl = _cloudinaryService.getProfileThumbnail(
        widget.imageUrl!,
        size: CloudinaryConfig.profilePictureSize,
      );

      return ClipRRect(
        borderRadius: BorderRadius.circular(58.w),
        child: CachedNetworkImage(
          imageUrl: optimizedUrl,
          width: 116.w,
          height: 116.w,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
              strokeWidth: 2.w,
            ),
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    }

    // Show placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 32.sp,
          color: ColorsManager.gray,
        ),
        Gap(4.h),
        Text(
          'Add Photo',
          style: TextStyles.font11DarkBlue400Weight.copyWith(
            color: ColorsManager.gray,
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Photo',
                style: TextStyles.font18DarkBlue600Weight,
              ),
              Gap(20.h),

              // Camera option
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: ColorsManager.mainBlue,
                  size: 24.sp,
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyles.font15DarkBlue500Weight,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              // Gallery option
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: ColorsManager.mainBlue,
                  size: 24.sp,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyles.font15DarkBlue500Weight,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              Gap(10.h),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyles.font15DarkBlue500Weight.copyWith(
                      color: ColorsManager.gray,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        widget.onImageSelected(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: ColorsManager.coralRed,
          ),
        );
      }
    }
  }
}
