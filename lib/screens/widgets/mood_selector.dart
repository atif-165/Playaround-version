import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';

/// Widget for selecting daily mood
class MoodSelector extends StatefulWidget {
  final Function(String mood, String? description) onMoodSelected;

  const MoodSelector({
    super.key,
    required this.onMoodSelected,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  String? _selectedMood;
  final TextEditingController _descriptionController = TextEditingController();

  final List<Map<String, dynamic>> _moods = [
    {
      'emoji': '😊',
      'name': 'Happy',
      'color': Colors.green,
      'description': 'Feeling great and positive!',
    },
    {
      'emoji': '💪',
      'name': 'Motivated',
      'color': ColorsManager.primary,
      'description': 'Ready to take on challenges!',
    },
    {
      'emoji': '😌',
      'name': 'Relaxed',
      'color': Colors.blue,
      'description': 'Calm and peaceful.',
    },
    {
      'emoji': '🔥',
      'name': 'Energetic',
      'color': Colors.orange,
      'description': 'Full of energy and enthusiasm!',
    },
    {
      'emoji': '🤔',
      'name': 'Thoughtful',
      'color': Colors.purple,
      'description': 'In a reflective mood.',
    },
    {
      'emoji': '😴',
      'name': 'Tired',
      'color': Colors.grey,
      'description': 'Need some rest.',
    },
    {
      'emoji': '😤',
      'name': 'Determined',
      'color': Colors.red,
      'description': 'Focused and determined!',
    },
    {
      'emoji': '🎯',
      'name': 'Focused',
      'color': ColorsManager.secondary,
      'description': 'Locked in and ready to work!',
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Gap(24.h),
            _buildMoodGrid(),
            if (_selectedMood != null) ...[
              Gap(24.h),
              _buildDescriptionSection(),
              Gap(24.h),
              _buildActionButtons(),
            ],
            Gap(20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.mood,
              color: ColorsManager.primary,
              size: 24.sp,
            ),
            Gap(8.w),
            Text(
              'How are you feeling today?',
              style: TextStyles.font18DarkBlue600Weight,
            ),
          ],
        ),
        Gap(8.h),
        Text(
          'Share your mood with others to help them connect with you better.',
          style: TextStyles.font14Grey400Weight,
        ),
      ],
    );
  }

  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.0,
      ),
      itemCount: _moods.length,
      itemBuilder: (context, index) {
        final mood = _moods[index];
        final isSelected = _selectedMood == mood['name'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMood = mood['name'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected 
                  ? mood['color'].withValues(alpha: 0.2)
                  : ColorsManager.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected 
                    ? mood['color']
                    : ColorsManager.outline.withValues(alpha: 0.3),
                width: isSelected ? 2.w : 1.w,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mood['emoji'],
                  style: TextStyle(fontSize: 24.sp),
                ),
                Gap(4.h),
                Text(
                  mood['name'],
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected 
                        ? mood['color']
                        : ColorsManager.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptionSection() {
    final selectedMoodData = _moods.firstWhere(
      (mood) => mood['name'] == _selectedMood,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              selectedMoodData['emoji'],
              style: TextStyle(fontSize: 20.sp),
            ),
            Gap(8.w),
            Text(
              'Feeling ${selectedMoodData['name']}',
              style: TextStyles.font16DarkBlue600Weight,
            ),
          ],
        ),
        Gap(8.h),
        Text(
          selectedMoodData['description'],
          style: TextStyles.font14Grey400Weight,
        ),
        Gap(16.h),
        TextField(
          controller: _descriptionController,
          maxLines: 2,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Add a personal note (optional)...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.outline,
                width: 1.w,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.outline,
                width: 1.w,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: selectedMoodData['color'],
                width: 2.w,
              ),
            ),
            contentPadding: EdgeInsets.all(12.w),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final selectedMoodData = _moods.firstWhere(
      (mood) => mood['name'] == _selectedMood,
    );

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: Text(
              'Cancel',
              style: TextStyles.font16Grey400Weight,
            ),
          ),
        ),
        Gap(12.w),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              widget.onMoodSelected(
                _selectedMood!,
                _descriptionController.text.trim().isEmpty 
                    ? null 
                    : _descriptionController.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedMoodData['color'],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Update Mood',
              style: TextStyles.font16White600Weight,
            ),
          ),
        ),
      ],
    );
  }
}
