import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/typography.dart';
import '../widgets/shop_theme.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../../../services/cloudinary_service.dart';
import '../../../config/cloudinary_config.dart';
import '../models/shop_location.dart';
import '../services/shop_location_service.dart';

const _shopHeroGradient = ShopTheme.heroGradient;

/// Screen for adding a new shop location
class AddLocationScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const AddLocationScreen({
    super.key,
    this.initialPosition,
  });

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = ShopLocationService();
  final _cloudinaryService = CloudinaryService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Form data
  String _selectedCategory = 'Equipment';
  double _latitude = 37.7749;
  double _longitude = -122.4194;
  bool _isLoading = false;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Business hours
  final Map<String, String> _businessHours = {
    'Monday': '',
    'Tuesday': '',
    'Wednesday': '',
    'Thursday': '',
    'Friday': '',
    'Saturday': '',
    'Sunday': '',
  };

  final List<String> _categories = [
    'Equipment',
    'Outwear',
    'Repairing',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _latitude = widget.initialPosition!.latitude;
      _longitude = widget.initialPosition!.longitude;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          final newFiles = images.map((image) => File(image.path)).toList();
          _selectedImages = [
            ..._selectedImages,
            ...newFiles,
          ];
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.take(5).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images to Cloudinary
      final List<String> imageUrls = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        try {
          final imageUrl = await _cloudinaryService.uploadImage(
            _selectedImages[i],
            folder: CloudinaryConfig.shopLocationsFolder,
          );
          imageUrls.add(imageUrl);
        } catch (e) {
          // If one image fails, continue with others
          print('Failed to upload image ${i + 1}: $e');
        }
      }

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload any images');
      }

      final location = ShopLocation(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        ownerId: _locationService.currentUserId,
        ownerName: 'Current User', // TODO: Get from user service
        category: _selectedCategory,
        images: imageUrls,
        address: 'Current Location', // Will be determined by coordinates
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        businessHours: _businessHours,
        rating: 0.0,
        reviewCount: 0,
        isActive: true,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: [],
        additionalInfo: {},
      );

      await _locationService.addLocation(location);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location added successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: PublicProfileTheme.backgroundGradient,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfo(),
                      Gap(24.h),
                      _buildImagePicker(),
                      Gap(24.h),
                      _buildContactInfo(),
                      Gap(24.h),
                      _buildBusinessHours(),
                      Gap(24.h),
                      _buildCategorySelection(),
                      Gap(32.h),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, topPadding + 6.h, 20.w, 6.h),
      decoration: const BoxDecoration(
        gradient: _shopHeroGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Location',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(4.h),
                Text(
                  'Drop a pin, add details and help players discover venues.',
                  style: AppTypography.bodySmall
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(16.h),
          AppTextField(
            controller: _titleController,
            labelText: 'Title *',
            hintText: 'Enter location title',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          Gap(16.h),
          AppTextField(
            controller: _descriptionController,
            labelText: 'Description *',
            hintText: 'Enter location description',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Images (Required)',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(8.h),
          Text(
            'Add up to 5 images of your location',
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          Gap(16.h),
          if (_selectedImages.isEmpty)
            Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: ColorsManager.outline,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: InkWell(
                onTap: _pickImages,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 32.w,
                      color: ColorsManager.onSurfaceVariant,
                    ),
                    Gap(8.h),
                    Text(
                      'Tap to add images',
                      style: AppTypography.bodyMedium.copyWith(
                        color: ColorsManager.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: 8.h,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
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
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16.w,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Gap(12.h),
                if (_selectedImages.length < 5)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add),
                      label: const Text('Add More Images'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information (Optional)',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(8.h),
          Text(
            'Add your contact details to help customers reach you',
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          Gap(16.h),
          AppTextField(
            controller: _phoneController,
            labelText: 'Phone Number',
            hintText: 'Enter phone number',
            keyboardType: TextInputType.phone,
          ),
          Gap(16.h),
          AppTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter email address',
            keyboardType: TextInputType.emailAddress,
          ),
          Gap(16.h),
          AppTextField(
            controller: _websiteController,
            labelText: 'Website',
            hintText: 'Enter website URL',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHours() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Hours (Optional)',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(8.h),
          Text(
            'Set your business hours for each day',
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          Gap(16.h),
          ..._businessHours.entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80.w,
                      child: Text(
                        entry.key,
                        style: AppTypography.bodyMedium.copyWith(
                          color: ColorsManager.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: TextFormField(
                        initialValue: entry.value,
                        decoration: InputDecoration(
                          hintText: 'e.g., 9:00 AM - 6:00 PM',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                        ),
                        onChanged: (value) {
                          _businessHours[entry.key] = value;
                        },
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _categories.map((category) {
              final isSelected = category == _selectedCategory;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                selectedColor: ColorsManager.primaryContainer,
                checkmarkColor: ColorsManager.onPrimaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: AppFilledButton(
        text: _isLoading ? 'Uploading & Adding...' : 'Add Location Pin',
        onPressed: _isLoading ? null : _saveLocation,
        icon: _isLoading ? null : const Icon(Icons.add_location),
      ),
    );
  }
}
