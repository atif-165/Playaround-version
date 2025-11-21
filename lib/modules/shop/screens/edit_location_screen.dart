import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/cloudinary_config.dart';
import '../../../services/cloudinary_service.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/typography.dart';
import '../widgets/shop_theme.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../models/shop_location.dart';
import '../services/shop_location_service.dart';

/// Screen for editing an existing shop location
class EditLocationScreen extends StatefulWidget {
  final ShopLocation location;

  const EditLocationScreen({
    super.key,
    required this.location,
  });

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = ShopLocationService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Form data
  String _selectedCategory = 'Equipment';
  bool _isLoading = false;
  List<String> _existingImages = [];
  final List<File> _newImages = [];
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
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.location.title;
    _descriptionController.text = widget.location.description;
    _addressController.text = widget.location.address;
    _phoneController.text = widget.location.phoneNumber;
    _emailController.text = widget.location.email;
    _websiteController.text = widget.location.website;
    _latitudeController.text = widget.location.latitude.toStringAsFixed(6);
    _longitudeController.text = widget.location.longitude.toStringAsFixed(6);
    _selectedCategory = widget.location.category;
    _existingImages = List<String>.from(widget.location.images);
    if (widget.location.businessHours.isNotEmpty) {
      _businessHours
        ..clear()
        ..addAll(widget.location.businessHours
            .map((key, value) => MapEntry(key, value?.toString() ?? '')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedImages = <String>[];
      updatedImages.addAll(_existingImages);

      if (_newImages.isNotEmpty) {
        for (int i = 0; i < _newImages.length; i++) {
          try {
            final imageUrl = await _cloudinaryService.uploadImage(
              _newImages[i],
              folder: CloudinaryConfig.shopLocationsFolder,
            );
            updatedImages.add(imageUrl);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload image ${i + 1}: $e'),
                ),
              );
            }
          }
        }
      }

      if (updatedImages.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please keep at least one image.')),
          );
        }
        return;
      }

      final updatedLocation = widget.location.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        category: _selectedCategory,
        images: updatedImages,
        businessHours: Map<String, String>.from(_businessHours),
        updatedAt: DateTime.now(),
      );

      await _locationService.updateLocation(
          widget.location.id, updatedLocation);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _buildGlassCard('Images', _buildImageSection()),
                    Gap(18.h),
                      _buildGlassCard('Basic Information', _buildBasicInfo()),
                      Gap(18.h),
                      _buildGlassCard('Location Details', _buildLocationInfo()),
                      Gap(18.h),
                      _buildGlassCard('Contact Information', _buildContactInfo()),
                      Gap(18.h),
                      _buildGlassCard('Category', _buildCategorySelection()),
                    Gap(18.h),
                    _buildGlassCard('Business Hours', _buildBusinessHours()),
                      Gap(28.h),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, topPadding + 10.h, 20.w, 12.h),
      decoration: const BoxDecoration(
        gradient: ShopTheme.heroGradient,
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
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.w,
            ),
          ),
          Expanded(
            child: Text(
              'Edit Location',
              style: AppTypography.headlineMedium
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
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
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      children: [
        AppTextField(
          controller: _addressController,
          labelText: 'Address *',
          hintText: 'Enter full address',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an address';
            }
            return null;
          },
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _latitudeController,
                labelText: 'Latitude',
                readOnly: true,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AppTextField(
                controller: _longitudeController,
                labelText: 'Longitude',
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
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
    );
  }

  Widget _buildCategorySelection() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _categories.map((category) {
        final isSelected = category == _selectedCategory;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedCategory = category;
            });
          },
          selectedColor: ColorsManager.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
          ),
          backgroundColor: Colors.white.withOpacity(0.08),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: AppFilledButton(
        text: _isLoading ? 'Updating...' : 'Update Location',
        onPressed: _isLoading ? null : _updateLocation,
        icon: _isLoading ? null : const Icon(Icons.save),
      ),
    );
  }

  Widget _buildImageSection() {
    final totalCount = _existingImages.length + _newImages.length;
    final canAddMore = totalCount < 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_existingImages.isNotEmpty) ...[
          Text(
            'Current Images',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          Gap(12.h),
          _buildImageGrid(
            itemCount: _existingImages.length,
            itemBuilder: (context, index) => Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.network(
                    _existingImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildRemoveChip(
                    onRemove: () => _removeExistingImage(index),
                  ),
                ),
              ],
            ),
          ),
          Gap(16.h),
        ],
        if (_newImages.isNotEmpty) ...[
          Text(
            'New Images',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          Gap(12.h),
          _buildImageGrid(
            itemCount: _newImages.length,
            itemBuilder: (context, index) => Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    _newImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildRemoveChip(
                    onRemove: () => _removeNewImage(index),
                  ),
                ),
              ],
            ),
          ),
          Gap(16.h),
        ],
        if (canAddMore)
          AppOutlinedButton(
            text: 'Add Images',
            icon: const Icon(Icons.add),
            onPressed: _pickImages,
            fullWidth: true,
          )
        else
          Text(
            'Maximum of 5 images reached.',
            style: AppTypography.bodySmall.copyWith(color: Colors.redAccent),
          ),
      ],
    );
  }

  Widget _buildImageGrid({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  Widget _buildRemoveChip({required VoidCallback onRemove}) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close, color: Colors.white, size: 16.w),
      ),
    );
  }

  Widget _buildBusinessHours() {
    return Column(
      children: _businessHours.entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(
            children: [
              SizedBox(
                width: 80.w,
                child: Text(
                  entry.key,
                  style: AppTypography.bodyMedium
                      .copyWith(color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: TextFormField(
                  initialValue: entry.value,
                  decoration: InputDecoration(
                    hintText: 'e.g., 9:00 AM - 6:00 PM',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    _businessHours[entry.key] = value;
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickImages() async {
    try {
      final result = await _imagePicker.pickMultiImage();
      if (result.isEmpty) return;

      final remainingSlots = 5 - (_existingImages.length + _newImages.length);
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum of 5 images allowed.')),
          );
        }
        return;
      }

      final files = result.take(remainingSlots).map((image) => File(image.path)).toList();

      setState(() {
        _newImages.addAll(files);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Widget _buildGlassCard(String title, Widget child) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: PublicProfileTheme.defaultShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          Gap(16.h),
          child,
        ],
      ),
    );
  }
}

