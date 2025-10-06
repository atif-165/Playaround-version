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

/// Screen for updating match scores and results
class ScoreUpdateScreen extends StatefulWidget {
  final Tournament tournament;

  const ScoreUpdateScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<ScoreUpdateScreen> createState() => _ScoreUpdateScreenState();
}

class _ScoreUpdateScreenState extends State<ScoreUpdateScreen> {
  final _tournamentService = TournamentService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _team1ScoreController = TextEditingController();
  final _team2ScoreController = TextEditingController();

  // Form state
  TournamentMatch? _selectedMatch;
  String? _selectedWinnerId;
  bool _isLoading = false;
  bool _isLoadingMatches = true;

  // Data
  List<TournamentMatch> _availableMatches = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableMatches();
  }

  @override
  void dispose() {
    _team1ScoreController.dispose();
    _team2ScoreController.dispose();
    super.dispose();
  }

  void _loadAvailableMatches() {
    // Load matches that are scheduled or in progress
    _availableMatches = widget.tournament.matches
        .where((match) =>
          match.status == MatchStatus.scheduled ||
          match.status == MatchStatus.inProgress
        )
        .toList();

    setState(() {
      _isLoadingMatches = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Update Match Score',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorsManager.textPrimary),
      ),
      body: _isLoadingMatches
          ? const Center(child: CustomProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_availableMatches.isEmpty) {
      return _buildNoMatchesMessage();
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
            _buildMatchSelection(),
            if (_selectedMatch != null) ...[
              Gap(24.h),
              _buildMatchDetails(),
              Gap(24.h),
              _buildScoreInput(),
              Gap(24.h),
              _buildWinnerSelection(),
              Gap(32.h),
              _buildUpdateButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchesMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_cricket_outlined,
              size: 64.sp,
              color: ColorsManager.textSecondary,
            ),
            Gap(16.h),
            Text(
              'No Matches Available',
              style: TextStyles.font20DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              'There are no scheduled or ongoing matches to update scores for.',
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
            'Available Matches: ${_availableMatches.length}',
            style: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Match',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        Text(
          'Choose the match you want to update scores for',
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
          child: DropdownButtonFormField<TournamentMatch>(
            value: _selectedMatch,
            decoration: InputDecoration(
              hintText: 'Select a match',
              hintStyle: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
            ),
            dropdownColor: ColorsManager.cardBackground,
            items: _availableMatches.map((match) {
              return DropdownMenuItem<TournamentMatch>(
                value: match,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${match.team1Name} vs ${match.team2Name}',
                      style: TextStyles.font14DarkBlueMedium.copyWith(
                        color: ColorsManager.textPrimary,
                      ),
                    ),
                    Text(
                      '${match.round} • ${DateFormat('MMM dd, HH:mm').format(match.scheduledDate)}',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: ColorsManager.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (match) {
              setState(() {
                _selectedMatch = match;
                _selectedWinnerId = null;
                _team1ScoreController.clear();
                _team2ScoreController.clear();
                
                // Pre-fill existing scores if available
                if (match?.team1Score != null) {
                  _team1ScoreController.text = match!.team1Score.toString();
                }
                if (match?.team2Score != null) {
                  _team2ScoreController.text = match!.team2Score.toString();
                }
                if (match?.winnerTeamId != null) {
                  _selectedWinnerId = match!.winnerTeamId;
                }
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a match';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchDetails() {
    if (_selectedMatch == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Details',
            style: TextStyles.font16DarkBlueBold.copyWith(
              color: ColorsManager.textPrimary,
            ),
          ),
          Gap(12.h),
          Row(
            children: [
              Icon(
                Icons.sports,
                color: ColorsManager.primary,
                size: 20.sp,
              ),
              Gap(8.w),
              Text(
                _selectedMatch!.round,
                style: TextStyles.font14DarkBlueMedium.copyWith(
                  color: ColorsManager.textPrimary,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: ColorsManager.secondary,
                size: 20.sp,
              ),
              Gap(8.w),
              Text(
                DateFormat('EEEE, MMM dd, yyyy at HH:mm').format(_selectedMatch!.scheduledDate),
                style: TextStyles.font14Grey400Weight.copyWith(
                  color: ColorsManager.textSecondary,
                ),
              ),
            ],
          ),
          if (_selectedMatch!.venueName != null) ...[
            Gap(8.h),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: ColorsManager.tertiary,
                  size: 20.sp,
                ),
                Gap(8.w),
                Text(
                  _selectedMatch!.venueName!,
                  style: TextStyles.font14Grey400Weight.copyWith(
                    color: ColorsManager.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreInput() {
    if (_selectedMatch == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Scores',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildScoreField(
                controller: _team1ScoreController,
                teamName: _selectedMatch!.team1Name,
                label: 'Team 1 Score',
              ),
            ),
            Gap(16.w),
            Expanded(
              child: _buildScoreField(
                controller: _team2ScoreController,
                teamName: _selectedMatch!.team2Name,
                label: 'Team 2 Score',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreField({
    required TextEditingController controller,
    required String teamName,
    required String label,
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
        Gap(4.h),
        Text(
          teamName,
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyles.font16DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyles.font16DarkBlueBold.copyWith(
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
              return 'Enter score';
            }
            final score = int.tryParse(value);
            if (score == null || score < 0) {
              return 'Invalid score';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWinnerSelection() {
    if (_selectedMatch == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Winner',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        Text(
          'Select the winning team (optional - can be determined by score)',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildWinnerOption(
                teamId: _selectedMatch!.team1Id,
                teamName: _selectedMatch!.team1Name,
                isSelected: _selectedWinnerId == _selectedMatch!.team1Id,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: _buildWinnerOption(
                teamId: _selectedMatch!.team2Id,
                teamName: _selectedMatch!.team2Name,
                isSelected: _selectedWinnerId == _selectedMatch!.team2Id,
              ),
            ),
          ],
        ),
        Gap(16.h),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _selectedWinnerId = null;
              });
            },
            child: Text(
              'Clear Winner Selection',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerOption({
    required String teamId,
    required String teamName,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWinnerId = teamId;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.success.withValues(alpha: 0.1)
              : ColorsManager.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? ColorsManager.success
                : ColorsManager.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: isSelected
                  ? ColorsManager.success
                  : ColorsManager.textSecondary,
              size: 32.sp,
            ),
            Gap(8.h),
            Text(
              teamName,
              style: TextStyles.font14DarkBlueMedium.copyWith(
                color: isSelected
                    ? ColorsManager.success
                    : ColorsManager.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return AppTextButton(
      buttonText: _isLoading ? 'Updating...' : 'Update Match Score',
      textStyle: TextStyles.font16WhiteSemiBold,
      onPressed: _isLoading ? null : _updateMatchScore,
    );
  }

  Future<void> _updateMatchScore() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMatch == null) {
      context.showSnackBar('Please select a match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final team1Score = int.parse(_team1ScoreController.text.trim());
      final team2Score = int.parse(_team2ScoreController.text.trim());

      // Determine winner if not explicitly selected
      String? winnerId = _selectedWinnerId;
      String? winnerName;

      if (winnerId == null && team1Score != team2Score) {
        if (team1Score > team2Score) {
          winnerId = _selectedMatch!.team1Id;
          winnerName = _selectedMatch!.team1Name;
        } else {
          winnerId = _selectedMatch!.team2Id;
          winnerName = _selectedMatch!.team2Name;
        }
      } else if (winnerId != null) {
        winnerName = winnerId == _selectedMatch!.team1Id
            ? _selectedMatch!.team1Name
            : _selectedMatch!.team2Name;
      }

      await _tournamentService.updateMatchScore(
        tournamentId: widget.tournament.id,
        matchId: _selectedMatch!.id,
        team1Score: team1Score,
        team2Score: team2Score,
        winnerTeamId: winnerId,
        winnerTeamName: winnerName,
      );

      if (mounted) {
        context.showSnackBar('Match score updated successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to update match score: ${e.toString()}');
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
