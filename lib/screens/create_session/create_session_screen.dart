import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../core/widgets/app_text_button.dart';

/// Screen for coaches to create training sessions
class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedSport = 'Football';
  String _selectedLevel = 'Beginner';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 60; // minutes

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Create Session',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: ColorsManager.onSurface,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            Gap(32.h),
            _buildBasicInfoSection(),
            Gap(24.h),
            _buildScheduleSection(),
            Gap(24.h),
            _buildPricingSection(),
            Gap(32.h),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_circle,
                color: ColorsManager.primary,
                size: 24.sp,
              ),
              Gap(8.w),
              Text(
                'Create Training Session',
                style: TextStyles.font18DarkBlue600Weight,
              ),
            ],
          ),
          Gap(8.h),
          Text(
            'Set up a new training session for your students. Define the details, schedule, and pricing.',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Details',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(16.h),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Session Title',
            hintText: 'e.g., Football Training - Beginner Level',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a session title';
            }
            return null;
          },
        ),
        Gap(16.h),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe what will be covered in this session...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                'Sport',
                _selectedSport,
                ['Football', 'Basketball', 'Tennis', 'Swimming', 'Volleyball'],
                (value) => setState(() => _selectedSport = value!),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildDropdownField(
                'Level',
                _selectedLevel,
                ['Beginner', 'Intermediate', 'Advanced'],
                (value) => setState(() => _selectedLevel = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(),
            ),
            Gap(12.w),
            Expanded(
              child: _buildTimeSelector(),
            ),
          ],
        ),
        Gap(16.h),
        _buildDurationSelector(),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(16.h),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Price per session',
            hintText: '0.00',
            prefixText: '\$ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a price';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid price';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border.all(color: ColorsManager.outline),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20.sp),
            Gap(8.w),
            Expanded(
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: TextStyles.font14Grey400Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border.all(color: ColorsManager.outline),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 20.sp),
            Gap(8.w),
            Expanded(
              child: Text(
                _selectedTime.format(context),
                style: TextStyles.font14Grey400Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration: $_duration minutes',
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        Slider(
          value: _duration.toDouble(),
          min: 30,
          max: 180,
          divisions: 5,
          label: '$_duration min',
          onChanged: (value) {
            setState(() {
              _duration = value.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return AppTextButton(
      buttonText: 'Create Session',
      textStyle: TextStyles.font16White600Weight,
      onPressed: _createSession,
      backgroundColor: ColorsManager.primary,
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _createSession() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement session creation logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session creation feature coming soon!'),
        ),
      );
    }
  }
}
