import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../helpers/extensions.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';

/// Screen for scheduling tournament matches
class MatchSchedulingScreen extends StatefulWidget {
  final Tournament tournament;

  const MatchSchedulingScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<MatchSchedulingScreen> createState() => _MatchSchedulingScreenState();
}

class _MatchSchedulingScreenState extends State<MatchSchedulingScreen> {
  final _tournamentService = TournamentService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _roundController = TextEditingController();
  final _matchNumberController = TextEditingController();

  // Form state
  String? _selectedTeam1Id;
  String? _selectedTeam2Id;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isLoadingTeams = true;

  // Data
  List<TournamentTeamRegistration> _registeredTeams = [];

  @override
  void initState() {
    super.initState();
    _loadRegisteredTeams();
  }

  @override
  void dispose() {
    _roundController.dispose();
    _matchNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadRegisteredTeams() async {
    try {
      final teams = await _tournamentService.getTournamentTeamRegistrations(
        tournamentId: widget.tournament.id,
        status: TeamRegistrationStatus.approved,
      );

      setState(() {
        _registeredTeams = teams;
        _isLoadingTeams = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTeams = false;
      });
      if (mounted) {
        context.showSnackBar('Failed to load teams: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Schedule Match',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorsManager.textPrimary),
      ),
      body: _isLoadingTeams
          ? const Center(child: CustomProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_registeredTeams.length < 2) {
      return _buildInsufficientTeamsMessage();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTournamentInfo(),
            Gap(24.h),
            _buildMatchDetails(),
            Gap(24.h),
            _buildTeamSelection(),
            Gap(24.h),
            _buildDateTimeSelection(),
            Gap(32.h),
            _buildScheduleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsufficientTeamsMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64.sp,
              color: ColorsManager.textSecondary,
            ),
            Gap(16.h),
            Text(
              'Insufficient Teams',
              style: TextStyles.font20DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              'You need at least 2 registered teams to schedule matches.',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: ColorsManager.primary,
                size: 24.sp,
              ),
              Gap(8.w),
              Expanded(
                child: Text(
                  widget.tournament.name,
                  style: TextStyles.font18DarkBlueBold.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Text(
            'Sport: ${widget.tournament.sportType.displayName}',
            style: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
          Text(
            'Format: ${widget.tournament.format.displayName}',
            style: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Details',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _roundController,
                label: 'Round/Stage',
                hint: 'e.g., Quarter Final, Semi Final',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter round/stage';
                  }
                  return null;
                },
              ),
            ),
            Gap(16.w),
            Expanded(
              child: _buildTextField(
                controller: _matchNumberController,
                label: 'Match Number',
                hint: '1',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter match number';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1) {
                    return 'Please enter valid match number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Teams',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(16.h),
        _buildTeamDropdown(
          label: 'Team 1',
          value: _selectedTeam1Id,
          onChanged: (teamId) {
            setState(() {
              _selectedTeam1Id = teamId;
            });
          },
          excludeTeamId: _selectedTeam2Id,
        ),
        Gap(16.h),
        _buildTeamDropdown(
          label: 'Team 2',
          value: _selectedTeam2Id,
          onChanged: (teamId) {
            setState(() {
              _selectedTeam2Id = teamId;
            });
          },
          excludeTeamId: _selectedTeam1Id,
        ),
      ],
    );
  }

  Widget _buildTeamDropdown({
    required String label,
    required String? value,
    required Function(String?) onChanged,
    String? excludeTeamId,
  }) {
    final availableTeams = _registeredTeams
        .where((team) => team.teamId != excludeTeamId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.font14DarkBlueMedium.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        Container(
          decoration: BoxDecoration(
            color: ColorsManager.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: ColorsManager.dividerColor),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: 'Select a team',
              hintStyle: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
            ),
            dropdownColor: ColorsManager.cardBackground,
            items: availableTeams.map((team) {
              return DropdownMenuItem<String>(
                value: team.teamId,
                child: Text(
                  team.teamName,
                  style: TextStyles.font14DarkBlueMedium.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null) {
                return 'Please select a team';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Schedule',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(16.h),
        _buildDateTimeField(
          label: 'Match Date & Time',
          value: _selectedDate != null && _selectedTime != null
              ? '${DateFormat('MMM dd, yyyy').format(_selectedDate!)} at ${_selectedTime!.format(context)}'
              : 'Select date & time',
          onTap: _selectDateTime,
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.font14DarkBlueMedium.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: ColorsManager.cardBackground,
              border: Border.all(color: ColorsManager.dividerColor),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20.sp,
                  color: ColorsManager.primary,
                ),
                Gap(12.w),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyles.font14DarkBlueMedium.copyWith(
                      color: ColorsManager.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: ColorsManager.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.font14DarkBlueMedium.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyles.font14DarkBlueMedium.copyWith(
            color: ColorsManager.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
            filled: true,
            fillColor: ColorsManager.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: ColorsManager.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: ColorsManager.primary),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildScheduleButton() {
    return AppTextButton(
      buttonText: _isLoading ? 'Scheduling...' : 'Schedule Match',
      textStyle: TextStyles.font16WhiteSemiBold,
      onPressed: _isLoading ? null : _scheduleMatch,
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 14, minute: 0),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  Future<void> _scheduleMatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTeam1Id == null || _selectedTeam2Id == null) {
      context.showSnackBar('Please select both teams');
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      context.showSnackBar('Please select match date and time');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final matchDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final team1 = _registeredTeams.firstWhere((t) => t.teamId == _selectedTeam1Id);
      final team2 = _registeredTeams.firstWhere((t) => t.teamId == _selectedTeam2Id);

      await _tournamentService.scheduleMatch(
        tournamentId: widget.tournament.id,
        team1Id: _selectedTeam1Id!,
        team1Name: team1.teamName,
        team2Id: _selectedTeam2Id!,
        team2Name: team2.teamName,
        scheduledDate: matchDateTime,
        round: _roundController.text.trim(),
        matchNumber: int.parse(_matchNumberController.text.trim()),
        venueId: widget.tournament.venueId,
        venueName: widget.tournament.venueName,
      );

      if (mounted) {
        context.showSnackBar('Match scheduled successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to schedule match: ${e.toString()}');
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
