import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../helpers/extensions.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';

/// Screen for declaring tournament winner
class WinnerDeclarationScreen extends StatefulWidget {
  final Tournament tournament;

  const WinnerDeclarationScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<WinnerDeclarationScreen> createState() => _WinnerDeclarationScreenState();
}

class _WinnerDeclarationScreenState extends State<WinnerDeclarationScreen> {
  final _tournamentService = TournamentService();

  // State
  String? _selectedWinnerTeamId;
  bool _isLoading = false;
  bool _isLoadingTeams = true;

  // Data
  List<TournamentTeamRegistration> _registeredTeams = [];

  @override
  void initState() {
    super.initState();
    _loadRegisteredTeams();
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
          'Declare Winner',
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
    if (_registeredTeams.isEmpty) {
      return _buildNoTeamsMessage();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTournamentInfo(),
          Gap(24.h),
          _buildWinnerSelection(),
          Gap(32.h),
          _buildDeclareButton(),
        ],
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
              'No Teams Available',
              style: TextStyles.font20DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              'There are no registered teams to declare as winner.',
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
          if (widget.tournament.winningPrize != null && widget.tournament.winningPrize! > 0) ...[
            Gap(4.h),
            Text(
              'Winning Prize: \$${widget.tournament.winningPrize!.toStringAsFixed(2)}',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.success,
              ),
            ),
          ],
          if (widget.tournament.winnerTeamName != null) ...[
            Gap(8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ColorsManager.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Current Winner: ${widget.tournament.winnerTeamName}',
                style: TextStyles.font14DarkBlueMedium.copyWith(
                  color: ColorsManager.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWinnerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Tournament Winner',
          style: TextStyles.font20DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(8.h),
        Text(
          'Choose the team that won the tournament. This action will complete the tournament and notify all participants.',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Gap(24.h),
        ...(_registeredTeams.map((team) => _buildTeamOption(team)).toList()),
      ],
    );
  }

  Widget _buildTeamOption(TournamentTeamRegistration team) {
    final isSelected = _selectedWinnerTeamId == team.teamId;
    final currentPoints = widget.tournament.teamPoints[team.teamId] ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWinnerTeamId = team.teamId;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isSelected 
                    ? ColorsManager.success
                    : ColorsManager.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                isSelected ? Icons.emoji_events : Icons.groups,
                color: isSelected 
                    ? Colors.white
                    : ColorsManager.primary,
                size: 24.sp,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.teamName,
                    style: TextStyles.font16DarkBlueBold.copyWith(
                      color: isSelected 
                          ? ColorsManager.success
                          : ColorsManager.textPrimary,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    'Captain: ${team.captainName}',
                    style: TextStyles.font14Grey400Weight.copyWith(
                      color: ColorsManager.textSecondary,
                    ),
                  ),
                  Text(
                    '${team.memberCount} members • $currentPoints points',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: ColorsManager.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorsManager.success,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeclareButton() {
    return Column(
      children: [
        AppTextButton(
          buttonText: _isLoading ? 'Declaring Winner...' : 'Declare Winner',
          textStyle: TextStyles.font16WhiteSemiBold,
          onPressed: _isLoading || _selectedWinnerTeamId == null ? null : _declareWinner,
        ),
        Gap(16.h),
        Text(
          'Warning: This action will complete the tournament and cannot be undone.',
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.warning,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _declareWinner() async {
    if (_selectedWinnerTeamId == null) {
      context.showSnackBar('Please select a winner');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsManager.cardBackground,
        title: Text(
          'Confirm Winner Declaration',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to declare ${_registeredTeams.firstWhere((t) => t.teamId == _selectedWinnerTeamId).teamName} as the tournament winner? This action cannot be undone.',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Declare Winner'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final winnerTeam = _registeredTeams.firstWhere((t) => t.teamId == _selectedWinnerTeamId);

      await _tournamentService.declareWinner(
        tournamentId: widget.tournament.id,
        winnerTeamId: _selectedWinnerTeamId!,
        winnerTeamName: winnerTeam.teamName,
      );

      if (mounted) {
        context.showSnackBar('Tournament winner declared successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to declare winner: ${e.toString()}');
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
