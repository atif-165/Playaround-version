import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../helpers/extensions.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../team/models/models.dart';
import '../../team/services/team_service.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';

/// Screen for team registration to tournaments
class TournamentTeamRegistrationScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentTeamRegistrationScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentTeamRegistrationScreen> createState() => _TournamentTeamRegistrationScreenState();
}

class _TournamentTeamRegistrationScreenState extends State<TournamentTeamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tournamentService = TournamentService();
  final _teamService = TeamService();

  // Form controllers for qualifying questions
  final List<TextEditingController> _answerControllers = [];
  final _notesController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isLoadingTeams = true;
  UserProfile? _currentUserProfile;
  List<Team> _userTeams = [];
  Team? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeAnswerControllers();
  }

  @override
  void dispose() {
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _initializeAnswerControllers() {
    for (int i = 0; i < widget.tournament.qualifyingQuestions.length; i++) {
      _answerControllers.add(TextEditingController());
    }
  }

  void _loadUserProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
      });
      await _loadUserTeams();
    }
  }

  Future<void> _loadUserTeams() async {
    try {
      final teams = await _teamService.getUserTeams().first;
      setState(() {
        _userTeams = teams.where((team) =>
          team.ownerId == _currentUserProfile!.uid && // Only teams where user is captain
          team.sportType == widget.tournament.sportType // Only teams of matching sport type
        ).toList();
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
          'Register Team',
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
    if (_userTeams.isEmpty) {
      return _buildNoTeamsMessage();
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
            _buildTeamSelection(),
            Gap(24.h),
            _buildQualifyingQuestions(),
            Gap(24.h),
            _buildNotesSection(),
            Gap(32.h),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTeamsMessage() {
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
              'No Eligible Teams',
              style: TextStyles.font20DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              'You need to be a team captain with a ${widget.tournament.sportType.displayName} team to register for this tournament.',
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
        border: Border.all(color: ColorsManager.primary.withOpacity(0.3)),
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
          if (widget.tournament.entryFee != null && widget.tournament.entryFee! > 0) ...[
            Gap(4.h),
            Text(
              'Entry Fee: \$${widget.tournament.entryFee!.toStringAsFixed(2)}',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.warning,
              ),
            ),
          ],
          if (widget.tournament.winningPrize != null && widget.tournament.winningPrize! > 0) ...[
            Gap(4.h),
            Text(
              'Winning Prize: \$${widget.tournament.winningPrize!.toStringAsFixed(2)}',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Team',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        Text(
          'Choose which team you want to register for this tournament',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Gap(16.h),
        Container(
          decoration: BoxDecoration(
            color: ColorsManager.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: ColorsManager.dividerColor),
          ),
          child: DropdownButtonFormField<Team>(
            value: _selectedTeam,
            decoration: InputDecoration(
              hintText: 'Select a team',
              hintStyle: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
            ),
            dropdownColor: ColorsManager.cardBackground,
            items: _userTeams.map((team) {
              return DropdownMenuItem<Team>(
                value: team,
                child: Row(
                  children: [
                    Icon(
                      Icons.groups,
                      color: ColorsManager.primary,
                      size: 20.sp,
                    ),
                    Gap(8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            team.name,
                            style: TextStyles.font14DarkBlueMedium.copyWith(
                              color: ColorsManager.textPrimary,
                            ),
                          ),
                          Text(
                            '${team.members.length} members',
                            style: TextStyles.font12Grey400Weight.copyWith(
                              color: ColorsManager.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (team) {
              setState(() {
                _selectedTeam = team;
              });
            },
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

  Widget _buildQualifyingQuestions() {
    if (widget.tournament.qualifyingQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registration Questions',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        Text(
          'Please answer the following questions to complete your registration',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Gap(16.h),
        ...widget.tournament.qualifyingQuestions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: TextStyles.font14DarkBlueMedium.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
                Gap(4.h),
                Text(
                  question,
                  style: TextStyles.font14Grey400Weight.copyWith(
                    color: ColorsManager.textSecondary,
                  ),
                ),
                Gap(8.h),
                TextFormField(
                  controller: _answerControllers[index],
                  maxLines: 3,
                  style: TextStyles.font14DarkBlueMedium.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your answer...',
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please answer this question';
                    }
                    return null;
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        Text(
          'Any additional information you\'d like to share with the tournament organizer',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Gap(16.h),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          maxLength: 500,
          style: TextStyles.font14DarkBlueMedium.copyWith(
            color: ColorsManager.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Enter any additional notes...',
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
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AppTextButton(
      buttonText: _isLoading ? 'Registering...' : 'Register Team',
      textStyle: TextStyles.font16WhiteSemiBold,
      onPressed: _isLoading ? null : _submitRegistration,
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTeam == null) {
      context.showSnackBar('Please select a team');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare qualifying answers
      final qualifyingAnswers = <Map<String, String>>[];
      for (int i = 0; i < widget.tournament.qualifyingQuestions.length; i++) {
        qualifyingAnswers.add({
          'question': widget.tournament.qualifyingQuestions[i],
          'answer': _answerControllers[i].text.trim(),
        });
      }

      await _tournamentService.submitTeamRegistration(
        tournamentId: widget.tournament.id,
        teamId: _selectedTeam!.id,
        qualifyingAnswers: qualifyingAnswers,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        context.showSnackBar('Team registration submitted successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to register team: ${e.toString()}');
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
