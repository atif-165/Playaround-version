import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';


import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';
import '../models/tournament_team_registration.dart';

/// Widget for displaying tournament winner highlights and achievements
class TournamentWinnerHighlights extends StatelessWidget {
  final Tournament tournament;
  final List<TournamentMatch> completedMatches;
  final Map<String, int> finalStandings;

  const TournamentWinnerHighlights({
    super.key,
    required this.tournament,
    required this.completedMatches,
    required this.finalStandings,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWinnerSection(),
          Gap(24.h),
          _buildFinalStandings(),
          Gap(24.h),
          _buildTournamentStats(),
          Gap(24.h),
          _buildMatchHighlights(),
          Gap(24.h),
          _buildAchievements(),
        ],
      ),
    );
  }

  Widget _buildWinnerSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber[100]!,
            Colors.amber[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            size: 64.sp,
            color: Colors.amber[700],
          ),
          Gap(16.h),
          Text(
            'Tournament Champion',
            style: TextStyles.font18DarkBlueBold.copyWith(
              color: Colors.amber[800],
            ),
          ),
          Gap(8.h),
          Text(
            tournament.winnerTeamName ?? 'TBD',
            style: TextStyles.font24Blue700Weight.copyWith(
              color: Colors.amber[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          Text(
            '${tournament.name}',
            style: TextStyles.font16DarkBlueBold.copyWith(
              color: Colors.amber[700],
            ),
          ),
          if (tournament.winningPrize != null && tournament.winningPrize! > 0) ...[
            Gap(12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Prize: \$${tournament.winningPrize!.toStringAsFixed(0)}',
                style: TextStyles.font14WhiteSemiBold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinalStandings() {
    final sortedTeams = _getSortedTeams();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Final Standings',
          style: TextStyles.font20DarkBlueBold,
        ),
        Gap(16.h),
        ...sortedTeams.asMap().entries.map((entry) {
          final index = entry.key;
          final team = entry.value;
          final points = finalStandings[team.teamId] ?? 0;
          final position = index + 1;
          
          return _buildStandingCard(team, position, points);
        }).toList(),
      ],
    );
  }

  Widget _buildStandingCard(TournamentTeamRegistration team, int position, int points) {
    final isTopThree = position <= 3;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: isTopThree 
            ? Border.all(color: _getPositionColor(position), width: 2)
            : Border.all(color: ColorsManager.dividerColor),
        boxShadow: isTopThree ? [
          BoxShadow(
            color: _getPositionColor(position).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          _buildPositionBadge(position),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.teamName,
                  style: TextStyles.font16DarkBlueBold.copyWith(
                    color: isTopThree ? _getPositionColor(position) : ColorsManager.textPrimary,
                  ),
                ),
                Gap(4.h),
                Text(
                  'Captain: ${team.captainName}',
                  style: TextStyles.font14Grey400Weight.copyWith(
                    color: ColorsManager.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: TextStyles.font18DarkBlueBold.copyWith(
                  color: isTopThree ? _getPositionColor(position) : ColorsManager.textPrimary,
                ),
              ),
              Text(
                'points',
                style: TextStyles.font12Grey400Weight.copyWith(
                  color: ColorsManager.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionBadge(int position) {
    final isTopThree = position <= 3;
    
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: isTopThree 
            ? _getPositionColor(position)
            : ColorsManager.textSecondary,
        shape: BoxShape.circle,
        boxShadow: isTopThree ? [
          BoxShadow(
            color: _getPositionColor(position).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          '$position',
          style: TextStyles.font16DarkBlueBold.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Statistics',
          style: TextStyles.font20DarkBlueBold,
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Matches',
                '${completedMatches.length}',
                Icons.sports_cricket,
                ColorsManager.primary,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                'Teams Participated',
                '${finalStandings.length}',
                Icons.groups,
                ColorsManager.success,
              ),
            ),
          ],
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Duration',
                _getTournamentDuration(),
                Icons.schedule,
                ColorsManager.warning,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                'Prize Pool',
                '\$${tournament.winningPrize?.toStringAsFixed(0) ?? '0'}',
                Icons.emoji_events,
                Colors.amber[700]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
          Gap(8.h),
          Text(
            value,
            style: TextStyles.font18DarkBlueBold.copyWith(
              color: color,
            ),
          ),
          Gap(4.h),
          Text(
            title,
            style: TextStyles.font12Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHighlights() {
    final recentMatches = completedMatches.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Matches',
          style: TextStyles.font20DarkBlueBold,
        ),
        Gap(16.h),
        ...recentMatches.map((match) => _buildMatchCard(match)).toList(),
      ],
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                match.round,
                style: TextStyles.font12Grey400Weight.copyWith(
                  color: ColorsManager.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorsManager.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Completed',
                  style: TextStyles.font10Grey400Weight.copyWith(
                    color: ColorsManager.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.team1Name,
                  style: TextStyles.font14DarkBlueMedium,
                ),
              ),
              Text(
                '${match.team1Score ?? 0}',
                style: TextStyles.font16DarkBlueBold,
              ),
            ],
          ),
          Gap(4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.team2Name,
                  style: TextStyles.font14DarkBlueMedium,
                ),
              ),
              Text(
                '${match.team2Score ?? 0}',
                style: TextStyles.font16DarkBlueBold,
              ),
            ],
          ),
          if (match.winnerTeamName != null) ...[
            Gap(8.h),
            Text(
              'Winner: ${match.winnerTeamName}',
              style: TextStyles.font12Grey400Weight.copyWith(
                color: ColorsManager.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Achievements',
          style: TextStyles.font20DarkBlueBold,
        ),
        Gap(16.h),
        _buildAchievementCard(
          'Tournament Completed',
          'Successfully completed all matches',
          Icons.check_circle,
          ColorsManager.success,
        ),
        _buildAchievementCard(
          'Fair Play',
          'All matches played with sportsmanship',
          Icons.handshake,
          ColorsManager.primary,
        ),
        _buildAchievementCard(
          'Community Engagement',
          'High participation and engagement',
          Icons.people,
          ColorsManager.warning,
        ),
      ],
    );
  }

  Widget _buildAchievementCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.font14DarkBlueMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(4.h),
                Text(
                  description,
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
  }

  List<TournamentTeamRegistration> _getSortedTeams() {
    // This would come from the actual team registrations
    // For now, return empty list
    return [];
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[600]!;
      default:
        return ColorsManager.textSecondary;
    }
  }

  String _getTournamentDuration() {
    if (tournament.endDate != null) {
      final duration = tournament.endDate!.difference(tournament.startDate);
      if (duration.inDays > 0) {
        return '${duration.inDays} days';
      } else if (duration.inHours > 0) {
        return '${duration.inHours} hours';
      } else {
        return '${duration.inMinutes} minutes';
      }
    }
    return 'Ongoing';
  }
}
