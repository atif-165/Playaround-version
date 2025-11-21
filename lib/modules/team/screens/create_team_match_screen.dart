import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../models/team_match_model.dart';
import '../services/team_service.dart';

class CreateTeamMatchScreen extends StatefulWidget {
  final TeamModel team;

  const CreateTeamMatchScreen({
    super.key,
    required this.team,
  });

  @override
  State<CreateTeamMatchScreen> createState() => _CreateTeamMatchScreenState();
}

class _CreateTeamMatchScreenState extends State<CreateTeamMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TeamService _teamService = TeamService();

  TeamModel? _selectedOpponent;
  TeamMatchType _matchType = TeamMatchType.friendly;
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  List<TeamModel> _availableTeams = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableTeams();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load teams with the same sport type, excluding current team
      final teamsStream = _teamService.getPublicTeams(
        sportType: widget.team.sportType,
        limit: 50,
      );

      final teams = await teamsStream.first;
      setState(() {
        _availableTeams = teams.where((t) => t.id != widget.team.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading teams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createMatch() async {
    if (!_formKey.currentState!.validate() || _selectedOpponent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an opponent team'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      await _teamService.createTeamMatch(
        homeTeamId: widget.team.id,
        awayTeamId: _selectedOpponent!.id,
        homeTeam: TeamScore(
          teamId: widget.team.id,
          teamName: widget.team.name,
          teamLogoUrl: widget.team.profileImageUrl,
        ),
        awayTeam: TeamScore(
          teamId: _selectedOpponent!.id,
          teamName: _selectedOpponent!.name,
          teamLogoUrl: _selectedOpponent!.profileImageUrl,
        ),
        sportType: widget.team.sportType,
        scheduledTime: scheduledDateTime,
        matchType: _matchType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating match: $e'),
            backgroundColor: Colors.red,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Create Match',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _availableTeams.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: ColorsManager.mainBlue),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHomeTeamSection(),
                    Gap(24.h),
                    _buildOpponentTeamSection(),
                    Gap(24.h),
                    _buildMatchTypeSection(),
                    Gap(24.h),
                    _buildDateTimeSection(),
                    Gap(24.h),
                    _buildNotesSection(),
                    Gap(32.h),
                    _buildCreateButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHomeTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home Team',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorsManager.mainBlue, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: widget.team.profileImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          widget.team.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.shield,
                            color: ColorsManager.mainBlue,
                            size: 30.sp,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.shield,
                        color: ColorsManager.mainBlue,
                        size: 30.sp,
                      ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.team.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.team.sportType.displayName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpponentTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Opponent Team',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        GestureDetector(
          onTap: () => _showTeamSelectionDialog(),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _selectedOpponent != null
                    ? ColorsManager.mainBlue
                    : Colors.grey[700]!,
              ),
            ),
            child: _selectedOpponent != null
                ? Row(
                    children: [
                      Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: ColorsManager.mainBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: _selectedOpponent!.profileImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.network(
                                  _selectedOpponent!.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.shield,
                                    color: ColorsManager.mainBlue,
                                    size: 30.sp,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.shield,
                                color: ColorsManager.mainBlue,
                                size: 30.sp,
                              ),
                      ),
                      Gap(12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedOpponent!.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_selectedOpponent!.city ?? "Unknown city"} • ${_selectedOpponent!.activePlayersCount} members',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12.sp,
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
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.grey[400],
                        size: 24.sp,
                      ),
                      Gap(8.w),
                      Text(
                        'Tap to select opponent team',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Type',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: TeamMatchType.values.map((type) {
            final isSelected = _matchType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _matchType = type;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? ColorsManager.mainBlue : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color:
                        isSelected ? ColorsManager.mainBlue : Colors.grey[700]!,
                  ),
                ),
                child: Text(
                  type.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontSize: 14.sp,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: ColorsManager.mainBlue, size: 20.sp),
                      Gap(12.w),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_scheduledDate),
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: ColorsManager.mainBlue, size: 20.sp),
                      Gap(12.w),
                      Text(
                        _scheduledTime.format(context),
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _notesController,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes about the match...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Create Match',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: ColorsManager.mainBlue,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: ColorsManager.mainBlue,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  void _showTeamSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        child: Container(
          padding: EdgeInsets.all(20.w),
          constraints: BoxConstraints(maxHeight: 500.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Opponent Team',
                style: TextStyles.font18DarkBlue600Weight
                    .copyWith(color: Colors.white),
              ),
              Gap(16.h),
              Expanded(
                child: _availableTeams.isEmpty
                    ? Center(
                        child: Text(
                          'No teams available',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 14.sp),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _availableTeams.length,
                        itemBuilder: (context, index) {
                          final team = _availableTeams[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            leading: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: ColorsManager.mainBlue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: team.profileImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.network(
                                        team.profileImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.shield,
                                          color: ColorsManager.mainBlue,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.shield,
                                      color: ColorsManager.mainBlue,
                                    ),
                            ),
                            title: Text(
                              team.name,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14.sp),
                            ),
                            subtitle: Text(
                              '${team.city ?? "Unknown"} • ${team.activePlayersCount} members',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12.sp),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedOpponent = team;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
