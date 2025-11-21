import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/material3/material3_components.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../services/cloudinary_service.dart';
import '../../../screens/dashboard/services/user_profile_dashboard_service.dart';
import '../services/community_service.dart';
import '../services/community_user_service.dart';

/// Screen for creating new community posts
class CommunityCreatePostScreen extends StatefulWidget {
  const CommunityCreatePostScreen({super.key});

  @override
  State<CommunityCreatePostScreen> createState() =>
      _CommunityCreatePostScreenState();
}

class _CommunityCreatePostScreenState extends State<CommunityCreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final PublicProfileService _profileService = PublicProfileService();

  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String _userNickname = 'Loading...';
  String _userInitial = 'U';
  String? _userProfilePicture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final nickname = await CommunityUserService.getCurrentUserNickname();
    final initial = await CommunityUserService.getCurrentUserInitial();
    final profilePicture =
        await CommunityUserService.getCurrentUserProfilePicture();

    if (mounted) {
      setState(() {
        _userNickname = nickname;
        _userInitial = initial;
        _userProfilePicture = profilePicture;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Create Post',
        style: AppTypography.headlineSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading || _contentController.text.trim().isEmpty
              ? null
              : _createPost,
          child: Text(
            'Post',
            style: AppTypography.labelLarge.copyWith(
              color: _isLoading || _contentController.text.trim().isEmpty
                  ? ColorsManager.onSurfaceVariant
                  : ColorsManager.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Gap(8.w),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          Gap(16.h),
          _buildContentInput(),
          Gap(16.h),
          _buildImageSection(),
          Gap(16.h),
          _buildTagsInput(),
          Gap(16.h),
          _buildActionButtons(),
          if (_isLoading) ...[
            Gap(24.h),
            _buildLoadingIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24.r,
          backgroundColor: ColorsManager.primary,
          backgroundImage: _userProfilePicture != null
              ? NetworkImage(_userProfilePicture!)
              : null,
          child: _userProfilePicture == null
              ? Text(
                  _userInitial,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userNickname,
                style: AppTypography.labelLarge.copyWith(
                  color: ColorsManager.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Posting to Community',
                style: AppTypography.bodySmall.copyWith(
                  color: ColorsManager.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentInput() {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        minLines: 5,
        decoration: InputDecoration(
          hintText: 'What\'s on your mind? Share your sports journey...',
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.w),
        ),
        style: AppTypography.bodyLarge.copyWith(
          color: ColorsManager.onSurface,
          height: 1.4,
        ),
        onChanged: (value) {
          setState(() {}); // Rebuild to update post button state
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty) ...[
          _buildImageGrid(),
          Gap(16.h),
        ],
        _buildImageActions(),
      ],
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: AppTypography.labelLarge.copyWith(
            color: ColorsManager.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextField(
          controller: _tagsController,
          decoration: InputDecoration(
            hintText: 'Add tags separated by commas (e.g. training, fitness)',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
            filled: true,
            fillColor: ColorsManager.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.outline.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: ColorsManager.primary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: _buildImageLayout(),
      ),
    );
  }

  Widget _buildImageLayout() {
    if (_selectedImages.length == 1) {
      return _buildSingleImage(0);
    } else if (_selectedImages.length == 2) {
      return _buildTwoImages();
    } else if (_selectedImages.length == 3) {
      return _buildThreeImages();
    } else {
      return _buildMultipleImages();
    }
  }

  Widget _buildSingleImage(int index) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200.h,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(_selectedImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        _buildRemoveButton(index),
      ],
    );
  }

  Widget _buildTwoImages() {
    return SizedBox(
      height: 150.h,
      child: Row(
        children: [
          Expanded(child: _buildImageWithRemove(0)),
          Gap(2.w),
          Expanded(child: _buildImageWithRemove(1)),
        ],
      ),
    );
  }

  Widget _buildThreeImages() {
    return SizedBox(
      height: 150.h,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildImageWithRemove(0),
          ),
          Gap(2.w),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImageWithRemove(1)),
                Gap(2.h),
                Expanded(child: _buildImageWithRemove(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleImages() {
    return SizedBox(
      height: 150.h,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildImageWithRemove(0),
          ),
          Gap(2.w),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImageWithRemove(1)),
                Gap(2.h),
                Expanded(
                  child: Stack(
                    children: [
                      _buildImageWithRemove(2),
                      if (_selectedImages.length > 3)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Center(
                            child: Text(
                              '+${_selectedImages.length - 3}',
                              style: AppTypography.headlineSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithRemove(int index) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(_selectedImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        _buildRemoveButton(index),
      ],
    );
  }

  Widget _buildRemoveButton(int index) {
    return Positioned(
      top: 8.w,
      right: 8.w,
      child: GestureDetector(
        onTap: () => _removeImage(index),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            color: Colors.white,
            size: 16.w,
          ),
        ),
      ),
    );
  }

  Widget _buildImageActions() {
    return Row(
      children: [
        AppOutlinedButton(
          text: 'Add Photos',
          onPressed: _isUploading ? null : _pickImages,
          icon: _isUploading
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorsManager.primary,
                  ),
                )
              : const Icon(Icons.photo_library_outlined),
        ),
        if (_selectedImages.isNotEmpty) ...[
          Gap(12.w),
          Text(
            '${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''} selected',
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppOutlinedButton(
            text: 'Cancel',
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: AppFilledButton(
            text: 'Post',
            onPressed: _isLoading || _contentController.text.trim().isEmpty
                ? null
                : _createPost,
            icon: _isLoading
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(color: ColorsManager.primary),
          Gap(12.h),
          Text(
            'Creating your post...',
            style: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _pickImages() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        for (final image in images) {
          if (_selectedImages.length < 10) {
            // Limit to 10 images
            _selectedImages.add(File(image.path));
          }
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  List<String> _parseTags() {
    return _tagsController.text
        .split(',')
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<List<String>> _uploadImagesToCloudinary(String postId) async {
    if (_selectedImages.isEmpty) return const [];

    final urls = <String>[];
    for (var i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      final imageUrl = await _cloudinaryService.uploadImage(
        image,
        folder: 'community_posts/$postId',
      );
      urls.add(imageUrl);
    }
    return urls;
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final postId =
          FirebaseFirestore.instance.collection('community_posts').doc().id;
      final uploadedImageUrls = await _uploadImagesToCloudinary(postId);

      await CommunityService.createPost(
        postId: postId,
        content: _contentController.text.trim(),
        images: uploadedImageUrls,
        tags: _parseTags(),
        authorNickname: _userNickname,
        authorProfilePicture: _userProfilePicture,
      );

      final authorId = FirebaseAuth.instance.currentUser?.uid;
      if (authorId != null) {
        try {
          await _profileService.notifyFollowersOfUpdate(
            profileUserId: authorId,
            title: '$_userNickname shared a new post',
            message: '$_userNickname just posted in the community.',
            data: {
              'postId': postId,
              'type': 'community_post',
            },
          );
        } catch (error) {
          debugPrint(
              'CommunityCreatePostScreen: failed to notify followers: $error');
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
