import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';

import '../models/models.dart';
import '../services/skill_tracking_service.dart';

/// Screen for adding new skill goals
class AddGoalScreen extends StatefulWidget {
  final String playerId;
  final Map<SkillType, int> currentSkillScores;

  const AddGoalScreen({
    super.key,
    required this.playerId,
    required this.currentSkillScores,
  });

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final SkillTrackingService _skillService = SkillTrackingService();

  SkillType? _selectedSkillType;
  int _targetScore = 80;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Text(
        'Set New Goal',
        style: TextStyles.font18DarkBlue600Weight
            .copyWith(fontSize: 20.sp, color: Colors.white),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkillSelection(),
            Gap(24.h),
            _buildTargetScoreSection(),
            Gap(24.h),
            _buildTargetDateSection(),
            Gap(24.h),
            _buildDescriptionSection(),
            Gap(24.h),
            _buildGoalPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Skill',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        Text(
          'Choose which skill you want to improve',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        Gap(16.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: SkillType.allSkills.map((skillType) {
            final isSelected = _selectedSkillType == skillType;
            final currentScore = widget.currentSkillScores[skillType] ?? 0;

            return GestureDetector(
              onTap: () => setState(() => _selectedSkillType = skillType),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorsManager.mainBlue.withValues(alpha: 0.3)
                      : Colors.black,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color:
                        isSelected ? ColorsManager.mainBlue : Colors.grey[300]!,
                    width: isSelected ? 2.w : 1.w,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getSkillIcon(skillType),
                      color: isSelected
                          ? ColorsManager.mainBlue
                          : Color(int.parse(
                              '0xFF${skillType.colorHex.substring(1)}')),
                      size: 24.sp,
                    ),
                    Gap(8.h),
                    Text(
                      skillType.displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? ColorsManager.mainBlue
                            : Colors.grey[800],
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      'Current: $currentScore',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTargetScoreSection() {
    final currentScore = _selectedSkillType != null
        ? widget.currentSkillScores[_selectedSkillType!] ?? 0
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Score',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        Text(
          'Set your target score (current: $currentScore)',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        Gap(16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target: $_targetScore',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: ColorsManager.mainBlue,
                    ),
                  ),
                  Text(
                    '+${_targetScore - currentScore} points',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Gap(16.h),
              Slider(
                value: _targetScore.toDouble(),
                min: (currentScore + 1).toDouble(),
                max: 100,
                divisions: 100 - currentScore - 1,
                activeColor: ColorsManager.mainBlue,
                onChanged: (value) =>
                    setState(() => _targetScore = value.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currentScore + 1}',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                  ),
                  Text(
                    '100',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Date',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        Text(
          'When do you want to achieve this goal?',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        Gap(16.h),
        GestureDetector(
          onTap: _selectTargetDate,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: ColorsManager.mainBlue,
                  size: 20.sp,
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(_targetDate),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Gap(2.h),
                      Text(
                        '${_targetDate.difference(DateTime.now()).inDays} days from now',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        Text(
          'Add a personal note or motivation for this goal',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        Gap(16.h),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText:
                'e.g., "Improve my sprint speed for the upcoming tournament"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            contentPadding: EdgeInsets.all(16.w),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildGoalPreview() {
    if (_selectedSkillType == null) return const SizedBox.shrink();

    final currentScore = widget.currentSkillScores[_selectedSkillType!] ?? 0;
    final improvement = _targetScore - currentScore;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border:
            Border.all(color: ColorsManager.mainBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: ColorsManager.mainBlue,
                size: 20.sp,
              ),
              Gap(8.w),
              Text(
                'Goal Preview',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.mainBlue,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            'Improve ${_selectedSkillType!.displayName} from $currentScore to $_targetScore (+$improvement points) by ${DateFormat('MMM d, y').format(_targetDate)}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ),
          if (_descriptionController.text.isNotEmpty) ...[
            Gap(8.h),
            Text(
              '"${_descriptionController.text}"',
              style: TextStyle(
                fontSize: 11.sp,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: SafeArea(
        child: AppTextButton(
          buttonText: _isLoading ? 'Creating Goal...' : 'Create Goal',
          textStyle: TextStyles.font16White600Weight,
          onPressed:
              _selectedSkillType != null && !_isLoading ? _createGoal : null,
          buttonHeight: 48.h,
        ),
      ),
    );
  }

  Future<void> _selectTargetDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: ColorsManager.mainBlue,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() => _targetDate = selectedDate);
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate() || _selectedSkillType == null)
      return;

    setState(() => _isLoading = true);

    try {
      final currentScore = widget.currentSkillScores[_selectedSkillType!] ?? 0;

      final goal = _skillService.createSkillGoal(
        playerId: widget.playerId,
        skillType: _selectedSkillType!,
        currentScore: currentScore,
        targetScore: _targetScore,
        targetDate: _targetDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      final result = await _skillService.addSkillGoal(goal);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Goal created successfully!'),
              backgroundColor: Colors.green[600],
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to create goal');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create goal: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getSkillIcon(SkillType skillType) {
    switch (skillType) {
      case SkillType.speed:
        return Icons.speed;
      case SkillType.strength:
        return Icons.fitness_center;
      case SkillType.endurance:
        return Icons.directions_run;
      case SkillType.accuracy:
        return Icons.gps_fixed;
      case SkillType.teamwork:
        return Icons.group;
    }
  }
}
