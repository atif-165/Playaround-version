import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';

/// Live bracket view widget for tournament matches
class LiveBracketView extends StatefulWidget {
  final Tournament tournament;
  final List<TournamentMatch> matches;
  final Function(TournamentMatch)? onMatchTap;

  const LiveBracketView({
    super.key,
    required this.tournament,
    required this.matches,
    this.onMatchTap,
  });

  @override
  State<LiveBracketView> createState() => _LiveBracketViewState();
}

class _LiveBracketViewState extends State<LiveBracketView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Gap(24.h),
            _buildBracket(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Tournament Bracket',
          style: TextStyles.font20DarkBlueBold,
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  shape: BoxShape.circle,
                ),
              ),
              Gap(6.w),
              Text(
                widget.tournament.status.displayName,
                style: TextStyles.font12Grey400Weight.copyWith(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBracket() {
    final rounds = _organizeMatchesByRound();
    
    if (rounds.isEmpty) {
      return _buildEmptyBracket();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rounds.entries.map((entry) {
          return _buildRound(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyBracket() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              Icons.sports_cricket_outlined,
              size: 64.sp,
              color: ColorsManager.textSecondary,
            ),
            Gap(16.h),
            Text(
              'No Matches Scheduled',
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            Gap(8.h),
            Text(
              'Matches will appear here once the tournament starts',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRound(String roundName, List<TournamentMatch> matches) {
    return Container(
      margin: EdgeInsets.only(right: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roundName,
            style: TextStyles.font16DarkBlueBold,
            textAlign: TextAlign.center,
          ),
          Gap(16.h),
          ...matches.map((match) => _buildMatchCard(match)).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    return Container(
      width: 280.w,
      margin: EdgeInsets.only(bottom: 16.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: InkWell(
          onTap: () => widget.onMatchTap?.call(match),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildMatchHeader(match),
                Gap(12.h),
                _buildTeams(match),
                if (match.team1Score != null && match.team2Score != null) ...[
                  Gap(12.h),
                  _buildScore(match),
                ],
                Gap(12.h),
                _buildMatchFooter(match),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHeader(TournamentMatch match) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Match ${match.matchNumber}',
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _getMatchStatusColor(match.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            match.status.displayName,
            style: TextStyles.font10Grey400Weight.copyWith(
              color: _getMatchStatusColor(match.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeams(TournamentMatch match) {
    return Column(
      children: [
        _buildTeamRow(
          match.team1Name,
          match.team1Score,
          match.winnerTeamId == match.team1Id,
        ),
        Gap(8.h),
        Text(
          'VS',
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap(8.h),
        _buildTeamRow(
          match.team2Name,
          match.team2Score,
          match.winnerTeamId == match.team2Id,
        ),
      ],
    );
  }

  Widget _buildTeamRow(String teamName, int? score, bool isWinner) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            style: TextStyles.font14DarkBlueMedium.copyWith(
              color: isWinner ? ColorsManager.success : ColorsManager.textPrimary,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score != null) ...[
          Gap(8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isWinner 
                  ? ColorsManager.success.withValues(alpha: 0.1)
                  : ColorsManager.cardBackground,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              '$score',
              style: TextStyles.font14DarkBlueMedium.copyWith(
                color: isWinner ? ColorsManager.success : ColorsManager.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScore(TournamentMatch match) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '${match.team1Score} - ${match.team2Score}',
        style: TextStyles.font16DarkBlueBold.copyWith(
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildMatchFooter(TournamentMatch match) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14.sp,
          color: ColorsManager.textSecondary,
        ),
        Gap(4.w),
        Text(
          _formatMatchTime(match.scheduledDate),
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
        const Spacer(),
        if (match.venueName != null) ...[
          Icon(
            Icons.location_on,
            size: 14.sp,
            color: ColorsManager.textSecondary,
          ),
          Gap(4.w),
          Expanded(
            child: Text(
              match.venueName!,
              style: TextStyles.font12Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Map<String, List<TournamentMatch>> _organizeMatchesByRound() {
    final Map<String, List<TournamentMatch>> rounds = {};
    
    for (final match in widget.matches) {
      if (!rounds.containsKey(match.round)) {
        rounds[match.round] = [];
      }
      rounds[match.round]!.add(match);
    }
    
    // Sort matches within each round by match number
    for (final round in rounds.values) {
      round.sort((a, b) => a.matchNumber.compareTo(b.matchNumber));
    }
    
    return rounds;
  }

  Color _getStatusColor() {
    switch (widget.tournament.status) {
      case TournamentStatus.upcoming:
        return ColorsManager.primary;
      case TournamentStatus.registrationOpen:
        return ColorsManager.warning;
      case TournamentStatus.registrationClosed:
        return ColorsManager.textSecondary;
      case TournamentStatus.ongoing:
      case TournamentStatus.inProgress:
        return ColorsManager.success;
      case TournamentStatus.completed:
        return ColorsManager.success;
      case TournamentStatus.cancelled:
        return ColorsManager.error;
    }
  }

  Color _getMatchStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return ColorsManager.primary;
      case MatchStatus.inProgress:
        return ColorsManager.warning;
      case MatchStatus.completed:
        return ColorsManager.success;
      case MatchStatus.cancelled:
        return ColorsManager.error;
    }
  }

  String _formatMatchTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      return 'Completed';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}
