
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/image_utils.dart';
import '../../../modules/tournament/models/models.dart';
import '../../../modules/team/models/models.dart' as team_models;
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget to display user's tournament participation (past and upcoming)
class ProfileTournamentsWidget extends StatelessWidget {
  final List<Tournament> pastTournaments;
  final List<Tournament> upcomingTournaments;
  final bool isLoading;

  const ProfileTournamentsWidget({
    super.key,
    required this.pastTournaments,
    required this.upcomingTournaments,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Gap(16.h),
          if (isLoading)
            _buildLoadingState()
          else if (pastTournaments.isEmpty && upcomingTournaments.isEmpty)
            _buildEmptyState()
          else
            _buildTournamentsContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalTournaments = pastTournaments.length + upcomingTournaments.length;
    
    return Row(
      children: [
        Icon(
          Icons.emoji_events,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
        Gap(8.w),
        Text(
          'Tournaments',
          style: TextStyles.font18DarkBlueBold,
        ),
        const Spacer(),
        if (totalTournaments > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '$totalTournaments',
              style: TextStyles.font12DarkBlue600Weight.copyWith(
                color: ColorsManager.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.h),
        child: CircularProgressIndicator(
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.h),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(12.h),
            Text(
              'No tournaments yet',
              style: TextStyles.font14Grey400Weight,
            ),
            Gap(8.h),
            Text(
              'Join tournaments to compete and showcase your skills',
              style: TextStyles.font12Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcomingTournaments.isNotEmpty) ...[
          _buildSectionHeader('Upcoming Tournaments', upcomingTournaments.length, Colors.green),
          Gap(8.h),
          _buildTournamentsList(upcomingTournaments, isUpcoming: true),
          if (pastTournaments.isNotEmpty) Gap(20.h),
        ],
        if (pastTournaments.isNotEmpty) ...[
          _buildSectionHeader('Past Tournaments', pastTournaments.length, Colors.grey),
          Gap(8.h),
          _buildTournamentsList(pastTournaments, isUpcoming: false),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        Gap(8.w),
        Text(
          title,
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            '$count',
            style: TextStyles.font10Grey400Weight.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentsList(List<Tournament> tournaments, {required bool isUpcoming}) {
    return Column(
      children: tournaments.take(3).map((tournament) => 
        _buildTournamentTile(tournament, isUpcoming: isUpcoming)
      ).toList(),
    );
  }

  Widget _buildTournamentTile(Tournament tournament, {required bool isUpcoming}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tournament image or icon
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: _getStatusColor(tournament.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ImageUtils.buildSafeCachedImage(
                  imageUrl: tournament.imageUrl,
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8.r),
                  fallbackIcon: Icons.emoji_events,
                  fallbackIconColor: _getStatusColor(tournament.status),
                  fallbackIconSize: 24.sp,
                  backgroundColor: _getStatusColor(tournament.status).withValues(alpha: 0.1),
                ),
              ),
              Gap(12.w),
              // Tournament info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: TextStyles.font16DarkBlue600Weight,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(
                          _getSportIcon(tournament.sportType),
                          size: 14.sp,
                          color: Colors.grey[600],
                        ),
                        Gap(4.w),
                        Text(
                          tournament.sportType.displayName,
                          style: TextStyles.font12Grey400Weight,
                        ),
                        Gap(8.w),
                        Text(
                          '•',
                          style: TextStyles.font12Grey400Weight,
                        ),
                        Gap(8.w),
                        Icon(
                          Icons.groups,
                          size: 14.sp,
                          color: Colors.grey[600],
                        ),
                        Gap(4.w),
                        Text(
                          '${tournament.currentTeamsCount}/${tournament.maxTeams}',
                          style: TextStyles.font12Grey400Weight,
                        ),
                      ],
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(
                          isUpcoming ? Icons.schedule : Icons.check_circle,
                          size: 14.sp,
                          color: isUpcoming ? Colors.orange : Colors.green,
                        ),
                        Gap(4.w),
                        Text(
                          isUpcoming 
                              ? DateFormat('MMM dd, yyyy').format(tournament.startDate)
                              : DateFormat('MMM dd, yyyy').format(tournament.endDate ?? tournament.startDate),
                          style: TextStyles.font12Grey400Weight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge and WIN tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isWinner(tournament)) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: ColorsManager.success,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 12.sp,
                            color: Colors.white,
                          ),
                          Gap(4.w),
                          Text(
                            'WIN',
                            style: TextStyles.font10Grey400Weight.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(4.h),
                  ],
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tournament.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      tournament.status.displayName,
                      style: TextStyles.font10Grey400Weight.copyWith(
                        color: _getStatusColor(tournament.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (tournament.location != null) ...[
            Gap(8.h),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14.sp,
                  color: Colors.grey[600],
                ),
                Gap(4.w),
                Expanded(
                  child: Text(
                    tournament.location!,
                    style: TextStyles.font12Grey400Weight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return Colors.grey;
      case TournamentStatus.registrationOpen:
        return Colors.blue;
      case TournamentStatus.registrationClosed:
        return Colors.orange;
      case TournamentStatus.ongoing:
        return Colors.green;
      case TournamentStatus.inProgress:
        return Colors.green;
      case TournamentStatus.completed:
        return Colors.purple;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getSportIcon(team_models.SportType sportType) {
    switch (sportType) {
      case team_models.SportType.football:
        return Icons.sports_soccer;
      case team_models.SportType.basketball:
        return Icons.sports_basketball;
      case team_models.SportType.tennis:
        return Icons.sports_tennis;
      case team_models.SportType.cricket:
        return Icons.sports_cricket;
      case team_models.SportType.badminton:
        return Icons.sports_tennis;
      case team_models.SportType.volleyball:
        return Icons.sports_volleyball;
      case team_models.SportType.other:
        return Icons.sports;
    }
  }

  /// Check if the current user/team won this tournament
  bool _isWinner(Tournament tournament) {
    // TODO: This needs to be enhanced to check if the current user's team won
    // For now, we'll check if there's a winner and the tournament is completed
    return tournament.status == TournamentStatus.completed &&
           tournament.winnerTeamId != null;
  }
}
