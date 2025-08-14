import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';

import '../models/models.dart';
import '../services/skill_tracking_service.dart';

/// Screen for coaches to log player performance
class CoachLoggingScreen extends StatefulWidget {
  final String coachId;
  final String playerId;
  final String playerName;

  const CoachLoggingScreen({
    super.key,
    required this.coachId,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<CoachLoggingScreen> createState() => _CoachLoggingScreenState();
}

class _CoachLoggingScreenState extends State<CoachLoggingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final SkillTrackingService _skillService = SkillTrackingService();

  DateTime _selectedDate = DateTime.now();
  Map<SkillType, int> _skillScores = {};
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeSkillScores();
    _loadLatestScores();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeSkillScores() {
    for (final skillType in SkillType.allSkills) {
      _skillScores[skillType] = 50; // Default middle score
    }
  }

  Future<void> _loadLatestScores() async {
    try {
      final latestScores = await _skillService.getLatestSkillScores(widget.playerId);
      if (latestScores.isNotEmpty && mounted) {
        setState(() {
          _skillScores = Map.from(latestScores);
        });
      }
    } catch (e) {
      // Use default scores if loading fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Performance',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Text(
            widget.playerName,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios,
          color: ColorsManager.mainBlue,
          size: 20.sp,
        ),
      ),
      actions: [
        if (_hasUnsavedChanges)
          IconButton(
            onPressed: _saveDraft,
            icon: Icon(
              Icons.save_outlined,
              color: Colors.orange[600],
              size: 20.sp,
            ),
          ),
      ],
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
            _buildDateSection(),
            Gap(24.h),
            _buildSkillScoresSection(),
            Gap(24.h),
            _buildNotesSection(),
            Gap(24.h),
            _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Date',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!),
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
                  child: Text(
                    DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
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

  Widget _buildSkillScoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Skill Scores',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            TextButton(
              onPressed: _resetAllScores,
              child: Text(
                'Reset All',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        Gap(12.h),
        Text(
          'Rate each skill from 0-100 based on today\'s performance',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        Gap(16.h),
        for (final skillType in SkillType.allSkills) _buildSkillScoreSlider(skillType),
      ],
    );
  }

  Widget _buildSkillScoreSlider(SkillType skillType) {
    final score = _skillScores[skillType] ?? 50;
    
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getSkillIcon(skillType),
                  color: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')),
                  size: 16.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skillType.displayName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      skillType.description,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')),
                  ),
                ),
              ),
            ],
          ),
          Gap(16.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')),
              inactiveTrackColor: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')).withValues(alpha: 0.2),
              thumbColor: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')),
              overlayColor: Color(int.parse('0xFF${skillType.colorHex.substring(1)}')).withValues(alpha: 0.2),
              trackHeight: 6.h,
            ),
            child: Slider(
              value: score.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  _skillScores[skillType] = value.round();
                  _hasUnsavedChanges = true;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
              Text('50', style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
              Text('100', style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Notes',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        Text(
          'Add observations, feedback, or areas for improvement',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        Gap(16.h),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'e.g., "Great improvement in sprint technique. Focus on endurance next session."',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            contentPadding: EdgeInsets.all(16.w),
          ),
          maxLines: 4,
          onChanged: (value) => setState(() => _hasUnsavedChanges = true),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final averageScore = _skillScores.values.isEmpty 
        ? 0.0 
        : _skillScores.values.reduce((a, b) => a + b) / _skillScores.values.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.mainBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: ColorsManager.mainBlue,
                size: 20.sp,
              ),
              Gap(8.w),
              Text(
                'Session Summary',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.mainBlue,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Date', DateFormat('MMM d, y').format(_selectedDate)),
              ),
              Expanded(
                child: _buildSummaryItem('Average Score', averageScore.toStringAsFixed(1)),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Highest', _getHighestSkill()),
              ),
              Expanded(
                child: _buildSummaryItem('Lowest', _getLowestSkill()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[600],
          ),
        ),
        Gap(2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppTextButton(
                buttonText: 'Save as Draft',
                onPressed: !_isLoading ? _saveDraft : null,
                backgroundColor: Colors.grey[100],
                textStyle: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                buttonHeight: 48.h,
              ),
            ),
            Gap(12.w),
            Expanded(
              flex: 2,
              child: AppTextButton(
                buttonText: _isLoading ? 'Logging...' : 'Log Performance',
                textStyle: TextStyles.font16White600Weight,
                onPressed: !_isLoading ? _logPerformance : null,
                buttonHeight: 48.h,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
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
      setState(() {
        _selectedDate = selectedDate;
        _hasUnsavedChanges = true;
      });
    }
  }

  void _resetAllScores() {
    setState(() {
      for (final skillType in SkillType.allSkills) {
        _skillScores[skillType] = 50;
      }
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveDraft() async {
    // TODO: Implement draft saving functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved locally')),
    );
    setState(() => _hasUnsavedChanges = false);
  }

  Future<void> _logPerformance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final skillLog = _skillService.createSkillLog(
        playerId: widget.playerId,
        coachId: widget.coachId,
        skillScores: Map.from(_skillScores),
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      final result = await _skillService.addSkillLog(skillLog);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Performance logged successfully!'),
              backgroundColor: Colors.green[600],
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to log performance');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log performance: ${e.toString()}'),
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

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  String _getHighestSkill() {
    if (_skillScores.isEmpty) return 'N/A';
    final highest = _skillScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${highest.key.displayName} (${highest.value})';
  }

  String _getLowestSkill() {
    if (_skillScores.isEmpty) return 'N/A';
    final lowest = _skillScores.entries.reduce((a, b) => a.value < b.value ? a : b);
    return '${lowest.key.displayName} (${lowest.value})';
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
